// -----------------------------------------------------------------
// Filename: ex.v                                             
// 
// Company: 
// Description:                                                     
// 
// 
//                                                                  
// Author: Elvis.Lu<lzyelvis@gmail.com>                            
// Create Date: 04/08/2022                                           
// Comments:                                                        
// 
// -----------------------------------------------------------------

`include "param_def.v"

module ex   #(parameter WIDTH=32)
(
    input  wire                     clk,
    input  wire                     rst_n,

    // id------------------------------------------------
    input  wire     [WIDTH-1:0]     pc,
    input  wire     [WIDTH-1:0]     inst,
    input  wire     [WIDTH-1:0]     imm,

    input  wire     [5:0]           inst_decode,
    input  wire     [3:0]           aluop,
    input  wire     [2:0]           result_sel,

    input  wire     [WIDTH-1:0]     rs1_data,
    input  wire     [WIDTH-1:0]     rs2_data,
    input  wire                     rd_we,
    input  wire     [4:0]           rd_addr,

    input  wire                     csr_we,
    input  wire     [11:0]          csr_addr,

    input  wire     [WIDTH-1:0]     branch_predict_pc,
    input  wire                     branch_taken,
    input  wire                     branch_pc_re,

    input  wire     [WIDTH-1:0]     exception,

    // mem-----------------------------------------------
    // csr forward
    input  wire                     mem_csr_we,
    input  wire     [11:0]          mem_csr_waddr,  
    input  wire     [WIDTH-1:0]     mem_csr_wdata,


    // wb------------------------------------------------
    // csr forward
    input  wire                     wb_csr_we,
    input  wire     [11:0]          wb_csr_waddr,
    input  wire     [WIDTH-1:0]     wb_csr_wdata,


    // csr-----------------------------------------------
    input  wire     [WIDTH-1:0]     csr_rdata,
    
    output reg      [11:0]          csr_raddr_out,
    output wire                     csr_we_out,
    output wire     [11:0]          csr_waddr_out,
    output reg      [WIDTH-1:0]     csr_wdata_out,
    

    // to branch--------------------------------------------
    output reg                      branch_ex_req_out,
    output reg                      branch_ex_taken_out,
    output reg                      branch_ex_jump_out,
    output reg                      branch_ex_call_out,
    output reg                      branch_ex_ret_out,
    output reg      [WIDTH-1:0]     branch_ex_next_pc_out,  // true next pc after branch cmp
    output reg                      branch_tag,

    output reg                      branch_miss_out,        // if branch miss
    output reg      [WIDTH-1:0]     branch_miss_pc_out,     // reassign pc after branch miss

    output wire                     branch_pc_re_out,       // branch pc reassign start signal pipe from if


    // to ex_mem-----------------------------------------------
    output wire     [WIDTH-1:0]     pc_out,
    output wire     [WIDTH-1:0]     inst_out,

    output wire                     rd_we_out,
    output wire     [4:0]           rd_addr_out,
    output reg      [WIDTH-1:0]     rd_wdata_out,

    output wire     [5:0]           inst_decode_out,

    output wire     [WIDTH-1:0]     mem_addr_out,
    output wire     [WIDTH-1:0]     mem_wdata_out,

    // to ctrl----------------------------------------------
    output wire                     stall_req_out,

    output wire     [WIDTH-1:0]     exception_out
);

//-----------------------------------------------------------------------------------------
// Declareation
//-----------------------------------------------------------------------------------------
wire    [6:0]   opcode = inst[6:0];
wire    is_itype    = opcode == `OPCODE_ITYPE;
wire    is_csr      = opcode == `OPCODE_CSR;
wire    is_branch   = (opcode==`OPCODE_JAL) || (opcode==`OPCODE_JALR) || (opcode==`OPCODE_BRANCH);   

wire    [4:0]   rs1_addr = inst[19:15];

wire    [WIDTH-1:0] pc_add_4    = pc + 32'd4;
wire    [WIDTH-1:0] pc_add_imm  = pc + imm;

// CSR
reg     [WIDTH-1:0]     csr_out;

// ALU
reg     [WIDTH-1:0]     operand1;
reg     [WIDTH-1:0]     operand2;
wire    [WIDTH-1:0]     alu_out;


// Branch
reg     [WIDTH-1:0]     jump_out;


// MUL
wire    [WIDTH-1:0]     mul_out;



// Divider
reg                     div_stall;
reg     [WIDTH-1:0]     div_out;

reg     div_sign;
reg     div_start;
wire    div_busy;
reg     [WIDTH-1:0] dividend;
reg     [WIDTH-1:0] divisor;
wire    [WIDTH-1:0] quotient;
wire    [WIDTH-1:0] remainder;

//-----------------------------------------------------------------------------------------
// CSR
//-----------------------------------------------------------------------------------------
// read csr
always @(*) begin
    csr_out         = 'd0;
    csr_raddr_out   = 'd0;

    if(is_csr) begin
        csr_raddr_out   = csr_addr;
        csr_out         = csr_rdata;

        // forward
        if(mem_csr_we && mem_csr_waddr == csr_addr) begin
            csr_out     = mem_csr_wdata;
        end
        else if(wb_csr_we && wb_csr_waddr == csr_addr) begin
            csr_out     = wb_csr_wdata;
        end
    end
end


// write csr
always @(*) begin
    if(!rst_n) begin
        csr_wdata_out   = 'd0;
    end
    else begin
        csr_wdata_out   = 'd0;
        case(inst_decode) 
            `INST_CSRRW: begin                              // csr read and write
                csr_wdata_out   = rs1_data;                 //[rd]=CSR[csr]; CSR[csr]=[rs1]

            end
            `INST_CSRRWI: begin                             // csr read and write imm
                csr_wdata_out   = imm;                      // [rd]=CSR[csr]; CSR[csr]=imm
                
            end
            `INST_CSRRS: begin                              // csr read and set
                csr_wdata_out   = csr_out | rs1_data;       // [rd]=CSR[csr]; CSR[csr]=CSR[csr] | [rs1]
                 
            end
            `INST_CSRRSI: begin                             // csr read and set imm
                csr_wdata_out   = csr_out | imm;            // [rd]=CSR[csr]; CSR[csr]=CSR[csr] | imm
                 
            end
            `INST_CSRRC: begin                              // csr read and clear
                csr_wdata_out   = csr_out & (~rs1_data);    // [rd]=CSR[csr]; CSR[csr]=CSR[csr] & ~[rs1]
                 
            end
            `INST_CSRRCI: begin                             // csr read and clear imm
                csr_wdata_out   = csr_out & (~imm);         // [rd]=CSR[csr]; CSR[csr]=CSR[csr] & ~imm
                
            end
            default: begin

            end
        endcase
    end
end

//-----------------------------------------------------------------------------------------
// ALU
//-----------------------------------------------------------------------------------------
// rs1
always @(*) begin
    if(!rst_n) begin
        operand1    = 'd0;
        operand2    = 'd0;
    end
    else begin
        operand1    = 'd0;
        operand2    = 'd0;
        case(opcode)
            `OPCODE_LUI: begin
                operand1    = 'd0;
                operand2    = imm;
            end
            `OPCODE_AUIPC, `OPCODE_JAL: begin
                operand1    = pc;
                operand2    = imm; 
            end
            `OPCODE_JALR, `OPCODE_ITYPE: begin
                operand1    = rs1_data;
                operand2    = imm;
            end  
            `OPCODE_BRANCH, `OPCODE_RTYPE: begin
                operand1    = rs1_data;
                operand2    = rs2_data;
            end
            `OPCODE_LTYPE, `OPCODE_STYPE: begin
                operand1    = rs1_data;
                operand2    = imm;
            end 
            default: begin

            end
        endcase
    end
end


alu u_alu(
    .alu_op                      (aluop              ),
    .operand1                    (operand1           ),
    .operand2                    (operand2           ),
    .alu_out                     (alu_out            )
);


//-----------------------------------------------------------------------------------------
// Load/Save
//-----------------------------------------------------------------------------------------
assign mem_addr_out     = alu_out;
assign mem_wdata_out    = rs2_data;



//-----------------------------------------------------------------------------------------
// Branch
//-----------------------------------------------------------------------------------------
// branch compara
always @(*) begin
    if(!rst_n) begin
        jump_out                = 'd0;

        branch_ex_jump_out      = 1'b0;
        branch_ex_call_out      = 1'b0;
        branch_ex_ret_out       = 1'b0;
        branch_ex_taken_out     = 1'b0;
        branch_ex_next_pc_out   = 'd0;
        branch_tag              = 1'b0;
       
    end
    else begin
        jump_out                = 'd0;

        branch_ex_jump_out      = 1'b0;
        branch_ex_call_out      = 1'b0;
        branch_ex_ret_out       = 1'b0;
        branch_ex_taken_out     = 1'b0;
        branch_ex_next_pc_out   = 'd0;
        branch_tag              = 1'b0;
        
        case(inst_decode)
            `INST_JAL: begin
                jump_out                = pc_add_4;
                branch_ex_next_pc_out   = alu_out;
                branch_ex_taken_out     = 1'b1;

                // JAL push RAS when rd=x1/x5.
                if( (rd_addr == 5'b00001) || (rd_addr == 5'b00101) ) begin
                    branch_ex_call_out = 1'b1;
                end else begin
                    branch_ex_jump_out = 1'b1;
                end

            end
            `INST_JALR: begin
                jump_out                = pc_add_4;
                branch_ex_next_pc_out   = alu_out;
                branch_ex_taken_out     = 1'b1;
            
                // JALR instructions should push/pop a RAS as shown in the Table
                //    ------------------------------------------------
                //    rd    |   rs1    | rs1=rd  |   RAS action
                //    !link |   !link  | -       |   none
                //    !link |   link   | -       |   pop
                //    link  |   !link  | -       |   push
                //    link  |   link   | 0       |   push and pop
                //    link  |   link   | 1       |   push
                // ------------------------------------------------ */
                if(rd_addr == 5'b00001 || rd_addr == 5'b00101) begin           // rd is link reg
                    if(rs1_addr == 5'b00001 || rs1_addr == 5'b00101) begin         // rs1 is link reg
                        if(rd_addr == rs1_addr) begin                                  // rd==rs1
                            branch_ex_call_out = 1'b1;                                     // push
                        end else begin                                                 // rd!=rs1
                            branch_ex_call_out = 1'b1;                                     // push and pop
                            branch_ex_ret_out = 1'b1;
                        end
                    end else begin                                                 // rs1 is not link reg
                        branch_ex_call_out = 1'b1;                                     // push
                    end 
                end else begin                                                 //rd is not link reg
                    if(rs1_addr == 5'b00001 || rs1_addr == 5'b00101) begin         // rs1 is link reg
                        branch_ex_ret_out = 1'b1;                                      // pop
                    end else begin                                                 //rs1 is not link reg
                        branch_ex_jump_out = 1'b1;                                     // none
                    end
                end 

            end
            `INST_BEQ: begin
                branch_ex_next_pc_out   = pc_add_imm;
                branch_ex_taken_out     = alu_out[0];
            end
            `INST_BNE: begin
                branch_ex_next_pc_out   = pc_add_imm;
                branch_ex_taken_out     = alu_out[0];
            end
            `INST_BGE: begin
                branch_ex_next_pc_out   = pc_add_imm;
                branch_ex_taken_out     = alu_out[0];
            end
            `INST_BGEU: begin
                branch_ex_next_pc_out   = pc_add_imm;
                branch_ex_taken_out     = alu_out[0];
            end
            `INST_BLT: begin
                branch_ex_next_pc_out   = pc_add_imm;
                branch_ex_taken_out     = alu_out[0];
            end
            `INST_BLTU: begin
                branch_ex_next_pc_out   = pc_add_imm;
                branch_ex_taken_out     = alu_out[0];
            end
            default: begin
            
            end
        endcase 
    end
end

// branch detect
always @(*) begin
    if(!rst_n) begin
        branch_ex_req_out       = 1'b0;
        branch_miss_out         = 1'b0;
        branch_miss_pc_out      = 'd0;
    end
    else begin
        branch_ex_req_out       = 1'b0;
        branch_miss_out         = 1'b0;
        branch_miss_pc_out      = 'd0;

        if(is_branch) begin
            branch_ex_req_out   = 1'b1;
            if(branch_ex_taken_out) begin
                if(!branch_taken || (branch_predict_pc!=branch_ex_next_pc_out)) begin // should take but no take
                    branch_miss_out     = 1'b1;
                    branch_miss_pc_out  = branch_ex_next_pc_out;
                    branch_tag = branch_pc_re_out;
                end
            end
            else begin
                if(branch_taken) begin                      // should not take but take
                    branch_miss_out     = 1'b1;
                    branch_miss_pc_out  = pc_add_4;
                    branch_tag          = branch_pc_re_out;
                end
            end
        end
    end
end


//-----------------------------------------------------------------------------------------
// Multiplier
//-----------------------------------------------------------------------------------------
multiplier   #(32) u_multiplier
(
    .rst_n              (rst_n),
    .inst_type          (inst_decode),
    .rs1_data           (rs1_data),
    .rs2_data           (rs2_data),
    .mul_out            (mul_out)
);



//-----------------------------------------------------------------------------------------
// Divider
//-----------------------------------------------------------------------------------------


divider #(.WIDTH(WIDTH), .CBIT(5)) u_divider 
(
    .clk                     ( clk                    ),
    .rst_n                   ( rst_n                  ),
    .dividend                ( dividend               ),
    .divisor                 ( divisor                ),
    .div_sign                ( div_sign               ),
    .start                   ( div_start              ),

    .busy                    ( div_busy               ),
    .quotient                ( quotient               ),
    .remainder               ( remainder              )
);


always @(*) begin
    if(!rst_n) begin
        div_sign    = 1'b0;
        div_start   = 1'b0;
        div_out     = 'd0;
        div_stall   = 'd0;
        dividend    = 'd0;
        divisor     = 'd0;
    end
    else begin
        div_sign    = 1'b0;
        div_start   = 1'b0;
        div_out     = 'd0;
        div_stall   = 'd0;

        case(inst_decode)
            `INST_DIV: begin
                if(div_busy) begin
                    dividend    = rs1_data;
                    divisor     = rs2_data;
                    div_start   = 1'b0;
                    div_sign    = 1'b0;
                    div_stall   = 1'b1;
                end 
                else begin
                    dividend    = rs1_data;
                    divisor     = rs2_data;
                    div_start   = 1'b1;
                    div_sign    = 1'b0;
                    div_stall   = 1'b0;
                    div_out     = quotient; 
                end
            end
            `INST_DIVU: begin
                if(div_busy) begin
                    dividend    = rs1_data;
                    divisor     = rs2_data;
                    div_start   = 1'b0;
                    div_sign    = 1'b1;
                    div_stall   = 1'b1;
                end 
                else begin
                    dividend    = rs1_data;
                    divisor     = rs2_data;
                    div_start   = 1'b1;
                    div_sign    = 1'b1;
                    div_stall   = 1'b0;
                    div_out     = quotient; 
                end
            end
            `INST_REM: begin
                if(div_busy) begin
                    dividend    = rs1_data;
                    divisor     = rs2_data;
                    div_start   = 1'b0;
                    div_sign    = 1'b0;
                    div_stall   = 1'b1;
                end 
                else begin
                    dividend    = rs1_data;
                    divisor     = rs2_data;
                    div_start   = 1'b1;
                    div_sign    = 1'b0;
                    div_stall   = 1'b0;
                    div_out     = remainder; 
                end
            end
            `INST_REMU: begin
                if(div_busy) begin
                    dividend    = rs1_data;
                    divisor     = rs2_data;
                    div_start   = 1'b0;
                    div_sign    = 1'b1;
                    div_stall   = 1'b1;
                end 
                else begin
                    dividend    = rs1_data;
                    divisor     = rs2_data;
                    div_start   = 1'b1;
                    div_sign    = 1'b1;
                    div_stall   = 1'b0;
                    div_out     = remainder; 
                end
            end
            default: begin

            end
        endcase
    end
end


//-----------------------------------------------------------------------------------------
// Out
//-----------------------------------------------------------------------------------------
assign  pc_out              = pc;
assign  inst_out            = inst;

assign  branch_pc_re_out    = branch_pc_re;

assign  csr_we_out          = csr_we;
assign  csr_waddr_out       = csr_addr;

assign  rd_we_out           = rd_we;
assign  rd_addr_out         = rd_addr;

assign  inst_decode_out     = inst_decode;

assign  stall_req_out       = div_stall;
assign  exception_out       = exception;

always @(*) begin
    case(result_sel)
        `EX_SEL_ALU: begin
            rd_wdata_out    = alu_out;
        end
        `EX_SEL_MUL: begin
            rd_wdata_out    = mul_out;
        end
        `EX_SEL_DIV: begin
            rd_wdata_out    = div_out;
        end
        `EX_SEL_CSR: begin
            rd_wdata_out    = csr_out;
        end
        `EX_SEL_JUMP: begin
            rd_wdata_out    = jump_out;
        end
        default: begin
            rd_wdata_out    = 'd0;
        end
    endcase
end


endmodule