// -----------------------------------------------------------------
// Filename: id.v                                             
// 
// Company: 
// Description:                                                     
// 
// 
//                                                                  
// Author: Elvis.Lu<lzyelvis@gmail.com>                            
// Create Date: 04/11/2022                                           
// Comments:                                                        
// 
// -----------------------------------------------------------------

`include "param_def.v"

module id   #(parameter WIDTH=32)
(
    input  wire                     rst_n,

    // if_id-------------------------------------------
    input  wire     [WIDTH-1:0]     pc_in,
    input  wire     [WIDTH-1:0]     inst_in,
    input  wire     [WIDTH-1:0]     branch_predict_pc,
    input  wire                     branch_taken,
    input  wire                     branch_pc_re,

    // regfile-----------------------------------------
    input  wire     [WIDTH-1:0]     rs1_rdata,
    input  wire     [WIDTH-1:0]     rs2_rdata,

    output reg                      rs1_re_out,
    output reg                      rs2_re_out,
    output wire     [4:0]           rs1_raddr_out,
    output wire     [4:0]           rs2_raddr_out,

    // ex----------------------------------------------
    input  wire                     branch_miss,

    // forward
    input  wire     [6:0]           ex_opcode,
    input  wire                     ex_rd_we,
    input  wire     [4:0]           ex_rd_waddr,
    input  wire     [WIDTH-1:0]     ex_rd_wdata,


    output wire     [WIDTH-1:0]     pc_out,
    output reg      [WIDTH-1:0]     inst_out,
    output reg      [WIDTH-1:0]     imm_out,

    // csr addr
    output reg                      csr_we_out,
    output reg      [11:0]          csr_addr_out,           // csr r/w address

    // rs data
    output reg      [WIDTH-1:0]     rs1_rdata_out,
    output reg      [WIDTH-1:0]     rs2_rdata_out,
    output reg                      rd_we_out,
    output reg      [4:0]           rd_waddr_out,

    // decoded instructions
    output reg      [5:0]           inst_decode_out,
    output reg      [3:0]           aluop_out,
    output reg      [2:0]           result_sel_out,

    // branch
    output wire     [WIDTH-1:0]     branch_predict_pc_out,
    output wire                     branch_taken_out,
    output wire                     branch_pc_re_out,

    output wire     [WIDTH-1:0]     exception_out,

    // mem---------------------------------------------
    // forward
    input  wire                     mem_rd_we,
    input  wire     [4:0]           mem_rd_waddr,
    input  wire     [WIDTH-1:0]     mem_rd_wdata,

    // ctrl--------------------------------------------
    output wire                     stall_req_out

);

//-----------------------------------------------------------------------------------------
// Declareation
//-----------------------------------------------------------------------------------------
reg     rs1_load_hazard;    // rs1 is the rd of load instruction in ex
reg     rs2_load_hazard;    // rs2 is the rd of load instruction in ex

reg     inst_valid;         // instruction is valid or not

reg     exception_ecall;
reg     exception_ebreak;
reg     exception_mret;
reg     exception_invalid_inst;

wire     ex_inst_load;       // instruction processing in ex is load type
assign  ex_inst_load = (ex_opcode == `OPCODE_LTYPE);
assign stall_req_out = rs1_load_hazard | rs2_load_hazard;

//-----------------------------------------------------------------------------------------
// Instruction Decode
//-----------------------------------------------------------------------------------------
wire    [6:0]   opcode      = inst_in[6:0];
wire    [4:0]   rd_addr     = inst_in[11:7];
wire    [2:0]   funct3      = inst_in[14:12];
wire    [4:0]   rs1_addr    = inst_in[19:15];
wire    [4:0]   rs2_addr    = inst_in[24:20];
wire    [6:0]   funct7      = inst_in[31:25];
wire            inst30      = inst_in[30];

//-----------------------------------------------------------------------------------------
// Reg Data Sel
//-----------------------------------------------------------------------------------------
// rs1
wire    rs1_ex_forward  = ex_rd_we && (ex_rd_waddr==rs1_raddr_out);
wire    rs1_mem_forward = mem_rd_we && (mem_rd_waddr==rs1_raddr_out);

always @(*) begin
    if(!rst_n) begin
        rs1_rdata_out   = 'd0;
        rs1_load_hazard = 1'b0;
    end
    else begin
        rs1_rdata_out   = 'd0;
        rs1_load_hazard = 1'b0;
        if(rs1_raddr_out=='d0) begin
            rs1_rdata_out   = 'd0;
        end
        else if(rs1_re_out) begin
            if(ex_inst_load && rs1_ex_forward) begin
                rs1_load_hazard = 1'b1;
            end
            else if(rs1_ex_forward) begin
                rs1_rdata_out   = ex_rd_wdata;
            end
            else if(rs1_mem_forward) begin
                rs1_rdata_out   = mem_rd_wdata;
            end
            else begin
                rs1_rdata_out   = rs1_rdata;
            end
        end
    end
end

// rs2
wire    rs2_ex_forward  = ex_rd_we && (ex_rd_waddr==rs2_raddr_out);
wire    rs2_mem_forward = mem_rd_we && (mem_rd_waddr==rs2_raddr_out);

always @(*) begin
    if(!rst_n) begin
        rs2_rdata_out   = 'd0;
        rs2_load_hazard = 1'b0;
    end
    else begin
        rs2_rdata_out   = 'd0;
        rs2_load_hazard = 1'b0;
        if(rs2_raddr_out=='d0) begin
            rs2_rdata_out   = 'd0;
        end
        else if(rs2_re_out) begin
            if(ex_inst_load && rs2_ex_forward) begin
                rs2_load_hazard = 1'b1;
            end
            else if(rs2_ex_forward) begin
                rs2_rdata_out   = ex_rd_wdata;
            end
            else if(rs2_mem_forward) begin
                rs2_rdata_out   = mem_rd_wdata;
            end
            else begin
                rs2_rdata_out   = rs2_rdata;
            end
        end
    end
end


//-----------------------------------------------------------------------------------------
// Output
//-----------------------------------------------------------------------------------------
assign  pc_out      = pc_in;
assign  branch_predict_pc_out = branch_predict_pc;
assign  branch_taken_out        = branch_taken;
assign  branch_pc_re_out        = branch_pc_re;

assign rs1_raddr_out            = rs1_addr;
assign rs2_raddr_out            = rs2_addr;

// encode exception = {25'b0 ,misaligned_load, misaligned_store, illegal_inst, misaligned_inst, ebreak, ecall, mret}
// will decode in ctrl after mem stage
assign exception_out            = {28'b0, exception_invalid_inst, exception_ebreak, exception_ecall, exception_mret};



always @(*) begin
    if(!rst_n ) begin
        inst_out                = `NOP;
        
        rs1_re_out              = 1'b0;
        rs2_re_out              = 1'b0;

        rd_we_out               = 1'b0;
        rd_waddr_out            = 'd0;

        csr_we_out              = 1'b0;
        csr_addr_out            = 'd0;

        imm_out                 = 'd0;

        exception_ebreak        = 1'b0;
        exception_ecall         = 1'b0;
        exception_invalid_inst  = 1'b0;
        exception_mret          = 1'b0;
        inst_valid              = 1'b1;

        inst_decode_out         = 'd0;
        aluop_out               = 'd0;
        result_sel_out          = 3'd0;

    end
    else begin
        inst_out                = inst_in;
        
        rs1_re_out              = 1'b0;
        rs2_re_out              = 1'b0;

        rd_we_out               = 1'b0;
        rd_waddr_out            = 'd0;

        csr_we_out              = 1'b0;
        csr_addr_out            = 'd0;

        imm_out                 = 'd0;

        exception_ebreak        = 1'b0;
        exception_ecall         = 1'b0;
        exception_invalid_inst  = 1'b0;
        exception_mret          = 1'b0;
        inst_valid              = 1'b1;

        inst_decode_out         = 'd0;
        aluop_out               = 'd0;
        result_sel_out          = 3'd0;

        case(opcode)
            `OPCODE_LUI: begin      //LUI: [rd] = imm[31:12]<<12
                imm_out         = {inst_in[31:12], 12'b0};
                // rs1_re_out      = 1'b0;
                // rs2_re_out      = 1'b0;
                rd_we_out       = 1'b1;
                rd_waddr_out    = rd_addr;
                // csr_we_out              = 1'b0;
                // csr_addr_out            = 'd0;
                inst_decode_out = `INST_LUI;
                aluop_out       = 4'b0000;
                result_sel_out  = `EX_SEL_ALU;
                inst_valid      = 1'b1;
            end

            `OPCODE_AUIPC: begin    //AUIPC: [rd] = pc + imm[31:12]<<12
                imm_out         = {inst_in[31:12], 12'b0};
                // rs1_re_out      = 1'b0;
                // rs2_re_out      = 1'b0;
                rd_we_out       = 1'b1;
                rd_waddr_out    = rd_addr;
                // csr_we_out              = 1'b0;
                // csr_addr_out            = 'd0;
                inst_decode_out = `INST_AUIPC;
                aluop_out       = 4'b0000;
                result_sel_out  = `EX_SEL_ALU;
                inst_valid      = 1'b1;
            end

            `OPCODE_JAL: begin      // JAL: [rd] = pc + 4; pc = pc + imm
                imm_out         = {{12{inst_in[31]}}, inst_in[19:12], inst_in[20], inst_in[30:21], 1'b0};
                // rs1_re_out      = 1'b0;
                // rs2_re_out      = 1'b0;
                rd_we_out       = 1'b1;
                rd_waddr_out    = rd_addr;
                // csr_we_out              = 1'b0;
                // csr_addr_out            = 'd0;
                inst_decode_out = `INST_JAL;
                aluop_out       = 4'b0000;
                result_sel_out  = `EX_SEL_JUMP;
                inst_valid      = 1'b1;
            end

            `OPCODE_JALR: begin     // JALR: [rd] = pc + 4, pc = [rs1] + imm
                imm_out         = {{20{inst_in[31]}}, inst_in[31:20]};
                rs1_re_out      = 1'b1;
                // rs2_re_out      = 1'b0;
                rd_we_out       = 1'b1;
                rd_waddr_out    = rd_addr;
                // csr_we_out              = 1'b0;
                // csr_addr_out            = 'd0;
                inst_decode_out = `INST_JALR;
                aluop_out       = 4'b0000;
                result_sel_out  = `EX_SEL_JUMP;
                inst_valid      = 1'b1;
            end

            // B_type----------------------------------------------------------------------------------------
            `OPCODE_BRANCH: begin
                imm_out         = {{20{inst_in[31]}}, inst_in[7], inst_in[30:25], inst_in[11:8], 1'b0};
                rs1_re_out      = 1'b1;
                rs2_re_out      = 1'b1;
                // rd_we_out       = 1'b1;
                // rd_waddr_out    = rd_addr;
                // csr_we_out              = 1'b0;
                // csr_addr_out            = 'd0;
                result_sel_out  = `EX_SEL_ALU;
                inst_valid      = 1'b1;
                
                case(funct3)
                    `FUNCT3_BEQ: begin
                        inst_decode_out = `INST_BEQ;
                        aluop_out       = 4'b1111;
                    end
                    `FUNCT3_BNE: begin
                        inst_decode_out = `INST_BNE;
                        aluop_out       = 4'b1110;
                    end
                    `FUNCT3_BGE: begin
                        inst_decode_out = `INST_BGE;
                        aluop_out       = 4'b1100;
                    end
                    `FUNCT3_BGEU: begin
                        inst_decode_out = `INST_BGEU;
                        aluop_out       = 4'b1001;
                    end
                    `FUNCT3_BLT: begin
                        inst_decode_out = `INST_BLT;
                        aluop_out       = 4'b0010;
                    end
                    `FUNCT3_BLTU: begin
                        inst_decode_out = `INST_BLTU;
                        aluop_out       = 4'b0011;
                    end
                    default: begin
                        inst_valid  = 1'b0;
                    end
                endcase
            end

            // L_type----------------------------------------------------------------------------------------            
            `OPCODE_LTYPE: begin
                imm_out         = {{20{inst_in[31]}}, inst_in[31:20]};
                rs1_re_out      = 1'b1;
                // rs2_re_out      = 1'b1;
                rd_we_out       = 1'b1;
                rd_waddr_out    = rd_addr;
                // csr_we_out              = 1'b0;
                // csr_addr_out            = 'd0;
                result_sel_out  = `EX_SEL_ALU;
                inst_valid      = 1'b1;
                
                case(funct3)
                    `FUNCT3_LB: begin
                        inst_decode_out = `INST_LB;
                    end
                    `FUNCT3_LBU: begin
                        inst_decode_out = `INST_LBU;
                    end
                    `FUNCT3_LH: begin
                        inst_decode_out = `INST_LH;
                    end
                    `FUNCT3_LHU: begin
                        inst_decode_out = `INST_LHU;
                    end
                    `FUNCT3_LW: begin
                        inst_decode_out = `INST_LW;
                    end
                    default: begin
                        inst_valid  = 1'b0;
                    end
                endcase
            end

            // S_type----------------------------------------------------------------------------------------
            `OPCODE_STYPE: begin
                imm_out         = {{20{inst_in[31]}}, inst_in[31:25], inst_in[11:7]};
                rs1_re_out      = 1'b1;
                rs2_re_out      = 1'b1;
                // rd_we_out       = 1'b1;
                // rd_waddr_out    = rd_addr;
                // csr_we_out              = 1'b0;
                // csr_addr_out            = 'd0;
                result_sel_out  = `EX_SEL_ALU;
                inst_valid      = 1'b1;
                
                case(funct3)
                    `FUNCT3_SB: begin
                        inst_decode_out = `INST_SB;
                    end
                    `FUNCT3_SH: begin
                        inst_decode_out = `INST_SH;
                    end
                    `FUNCT3_SW: begin
                        inst_decode_out = `INST_SW;
                    end
                    default: begin
                        inst_valid  = 1'b0;
                    end
                endcase
            end

            // I_type----------------------------------------------------------------------------------------
            `OPCODE_ITYPE: begin
                rs1_re_out      = 1'b1;
                // rs2_re_out      = 1'b1;
                rd_we_out       = 1'b1;
                rd_waddr_out    = rd_addr;
                // csr_we_out              = 1'b0;
                // csr_addr_out            = 'd0;
                result_sel_out  = `EX_SEL_ALU;
                inst_valid      = 1'b1;
                aluop_out       = {1'b0,funct3};
                
                case(funct3)
                    `FUNCT3_ADDI: begin
                        imm_out         = {{20{inst_in[31]}}, inst_in[31:20]};
                        inst_decode_out = `INST_ADDI;
                    end
                    `FUNCT3_SLTI: begin
                        imm_out         = {{20{inst_in[31]}}, inst_in[31:20]};
                        inst_decode_out = `INST_SLTI;
                    end
                    `FUNCT3_SLTIU: begin
                        imm_out         = {{20{inst_in[31]}}, inst_in[31:20]};
                        inst_decode_out = `INST_SLTIU;
                    end
                    `FUNCT3_ANDI: begin
                        imm_out         = {{20{inst_in[31]}}, inst_in[31:20]};
                        inst_decode_out = `INST_ANDI;
                    end
                    `FUNCT3_ORI: begin
                        imm_out         = {{20{inst_in[31]}}, inst_in[31:20]};
                        inst_decode_out = `INST_ORI;
                    end
                    `FUNCT3_XORI: begin
                        imm_out         = {{20{inst_in[31]}}, inst_in[31:20]};
                        inst_decode_out = `INST_XORI;
                    end
                    `FUNCT3_SLLI: begin
                        imm_out         = {27'b0, inst_in[24:20]};
                        inst_decode_out = `INST_SLLI;
                    end
                    `FUNCT3_SRLI_SRAI: begin
                        imm_out         = {27'b0, inst_in[24:20]};

                        if(inst30) begin    // SRAI
                            inst_decode_out = `INST_SRAI;
                        end
                        else begin          // SRLI
                            inst_decode_out = `INST_SRLI;
                        end
                    end
                    default: begin
                        inst_valid  = 1'b0;
                    end
                endcase
            end

            // R_type----------------------------------------------------------------------------------------
            `OPCODE_RTYPE: begin
                rs1_re_out      = 1'b1;
                rs2_re_out      = 1'b1;
                rd_we_out       = 1'b1;
                rd_waddr_out    = rd_addr;
                // csr_we_out              = 1'b0;
                // csr_addr_out            = 'd0;
                inst_valid      = 1'b1;
                aluop_out       = {inst30, funct3};
                
                if(funct7==7'b000_0000 || funct7==7'b010_0000) begin // STANDARD RTYPE
                    result_sel_out  = `EX_SEL_ALU;
                    case(funct3)
                        `FUNCT3_ADD_SUB: begin
                            if(inst30) begin    // SUB
                                inst_decode_out = `INST_SUB;
                            end
                            else begin          // ADD
                                inst_decode_out = `INST_ADD;
                            end
                        end
                        `FUNCT3_SLL: begin
                            inst_decode_out = `INST_SLL;
                        end
                        `FUNCT3_SLT: begin
                            inst_decode_out = `INST_SLT;
                        end
                        `FUNCT3_SLTU: begin
                            inst_decode_out = `INST_SLTU;
                        end
                        `FUNCT3_SRL_SRA: begin
                            if(inst30) begin    // SRA
                                inst_decode_out = `INST_SRA;
                            end
                            else begin          // SRL
                                inst_decode_out = `INST_SRL;
                            end
                        end
                        `FUNCT3_AND: begin
                            inst_decode_out = `INST_AND;
                        end
                        `FUNCT3_OR: begin
                            inst_decode_out = `INST_OR;
                        end
                        `FUNCT3_XOR: begin
                            inst_decode_out = `INST_XOR;
                        end
                        default: begin
                            inst_valid  = 1'b0;
                        end
                    endcase
                end 
                else if(funct7==7'b000_0001) begin // MUL/DIV
                    case(funct3)
                        `FUNCT3_MUL: begin
                            inst_decode_out = `INST_MUL;
                            result_sel_out  = `EX_SEL_MUL;
                        end
                        `FUNCT3_MULH: begin
                            inst_decode_out = `INST_MULH;
                            result_sel_out  = `EX_SEL_MUL;
                        end
                        `FUNCT3_MULHU: begin
                            inst_decode_out = `INST_MULHU;
                            result_sel_out  = `EX_SEL_MUL;
                        end
                        `FUNCT3_MULHSU: begin
                            inst_decode_out = `INST_MULHSU;
                            result_sel_out  = `EX_SEL_MUL;
                        end
                        `FUNCT3_DIV: begin
                            inst_decode_out = `INST_DIV;
                            result_sel_out  = `EX_SEL_DIV;
                        end
                        `FUNCT3_DIVU: begin
                            inst_decode_out = `INST_DIVU;
                            result_sel_out  = `EX_SEL_DIV;
                        end
                        `FUNCT3_REM: begin
                            inst_decode_out = `INST_REM;
                            result_sel_out  = `EX_SEL_DIV;
                        end
                        `FUNCT3_REMU: begin
                            inst_decode_out = `INST_REMU;
                            result_sel_out  = `EX_SEL_DIV;
                        end
                        default: begin
                            inst_valid  = 1'b0;
                        end
                    endcase  
                end
            end

            // CSR------------------------------------------------------------------------------------------
            `OPCODE_CSR: begin
                imm_out         = {27'b0, inst_in[19:15]};
                rd_waddr_out    = rd_addr;
                csr_addr_out    = inst_in[31:20];
                inst_valid      = 1'b1;
            
                case(funct3)            
                    `FUNCT3_CSRRW: begin            // csr read and write
                        rs1_re_out      = 1'b1;     //[rd]=CSR[csr]; CSR[csr]=[rs1]
                        rd_we_out       = 1'b1;
                        csr_we_out      = 1'b1;

                        inst_decode_out = `INST_CSRRW;
                        result_sel_out  = `EX_SEL_CSR;
                    end
                    `FUNCT3_CSRRWI: begin           // csr read and write imm
                        rd_we_out       = 1'b1;     // [rd]=CSR[csr]; CSR[csr]=imm
                        csr_we_out      = 1'b1;

                        inst_decode_out = `INST_CSRRWI;
                        result_sel_out  = `EX_SEL_CSR;
                    end
                    `FUNCT3_CSRRS: begin            // csr read and set
                        rs1_re_out      = 1'b1;     // [rd]=CSR[csr]; CSR[csr]=CSR[csr] | [rs1]
                        rd_we_out       = 1'b1;
                        csr_we_out      = 1'b1;

                        inst_decode_out = `INST_CSRRS;
                        result_sel_out  = `EX_SEL_CSR;
                    end
                    `FUNCT3_CSRRSI: begin           // csr read and set imm
                        rd_we_out       = 1'b1;     // [rd]=CSR[csr]; CSR[csr]=CSR[csr] | imm
                        csr_we_out      = 1'b1;

                        inst_decode_out = `INST_CSRRSI;
                        result_sel_out  = `EX_SEL_CSR;
                    end
                    `FUNCT3_CSRRC: begin            // csr read and clear
                        rs1_re_out      = 1'b1;     // [rd]=CSR[csr]; CSR[csr]=CSR[csr] & ~[rs1]
                        rd_we_out       = 1'b1;
                        csr_we_out      = 1'b1;

                        inst_decode_out = `INST_CSRRC;
                        result_sel_out  = `EX_SEL_CSR;
                    end
                    `FUNCT3_CSRRCI: begin           // csr read and clear imm
                        rd_we_out       = 1'b1;     // [rd]=CSR[csr]; CSR[csr]=CSR[csr] & ~imm
                        csr_we_out      = 1'b1;

                        inst_decode_out = `INST_CSRRCI;
                        result_sel_out  = `EX_SEL_CSR;
                    end
                    // ECALL, EBREAK, MRET
                    `FUNCT3_CSR_SPECIAL: begin
                        if(funct7==7'b000_0000 && rs2_addr==5'b0_0000) begin // ECALL
                            inst_decode_out = `INST_ECALL;
                            result_sel_out  = `EX_SEL_NOP;
                            exception_ecall = 1'b1;
                        end
                        if(funct7==7'b001_1000 && rs2_addr==5'b0_0010) begin // MRET
                            inst_decode_out = `INST_MRET;
                            result_sel_out  = `EX_SEL_NOP;
                            exception_mret  = 1'b1;
                        end
                    end
                endcase
            end

            // FENCE---------------------------------------------------------------------------
            `OPCODE_FENCE: begin
                
            end
            default: begin
                inst_valid  = 1'b0;
            end
        endcase
    end
end

endmodule