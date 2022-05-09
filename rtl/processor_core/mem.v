// -----------------------------------------------------------------
// Filename: mem.v                                             
// 
// Company: 
// Description:                                                     
// 
// 
//                                                                  
// Author: Elvis.Lu<lzyelvis@gmail.com>                            
// Create Date: 04/15/2022                                           
// Comments:                                                        
// 
// -----------------------------------------------------------------

`include "param_def.v"

module mem  #(parameter WIDTH=32)
(
    input  wire                 rst_n,

    // ex------------------------------------------------
    input  wire     [WIDTH-1:0] pc,
    input  wire     [WIDTH-1:0] inst,

    input  wire     [5:0]       inst_decode,

    input  wire                 rd_we,
    input  wire     [4:0]       rd_addr,
    input  wire     [WIDTH-1:0] rd_wdata,

    input  wire     [WIDTH-1:0] mem_addr,
    input  wire     [WIDTH-1:0] mem_wdata,

    input  wire                 csr_we,
    input  wire     [11:0]      csr_waddr,
    input  wire     [WIDTH-1:0] csr_wdata,

    input  wire     [WIDTH-1:0] exception,

    // ram-----------------------------------------------
    output wire     [WIDTH-1:0] mem_addr_out,
    output wire                 mem_we_out,

    output reg      [3:0]       mem_sel_out,
    output reg      [WIDTH-1:0] mem_wdata_out,
    output wire                 mem_ce_out,

    input  wire     [WIDTH-1:0] mem_rdata,

    // to wb_mem-----------------------------------------
    output wire                 rd_we_out,
    output wire     [4:0]       rd_addr_out,
    output wire     [WIDTH-1:0] rd_wdata_out,

    output wire                 csr_we_out,
    output wire     [11:0]      csr_waddr_out,
    output wire     [WIDTH-1:0] csr_wdata_out,

    // to ctrl-------------------------------------------
    output wire     [WIDTH-1:0] pc_out,
    output wire     [WIDTH-1:0] inst_out,

    output wire     [WIDTH-1:0] exception_out

);

//-----------------------------------------------------------------------------------------
// Addr aligned exception
//-----------------------------------------------------------------------------------------
wire is_load    = inst[6:0]==`OPCODE_LTYPE;
wire is_store   = inst[6:0]==`OPCODE_STYPE;

wire halfword_type  = (inst_decode==`INST_LH) || (inst_decode==`INST_LHU) || (inst_decode==`INST_SH);
wire word_type      = (inst_decode==`INST_LW) || (inst_decode==`INST_SW);
wire byte_type      = (inst_decode==`INST_LB) || (inst_decode==`INST_LBU) || (inst_decode==`INST_SB);

wire halfword_addr_aligned  = halfword_type && (mem_addr[0]==1'b0);
wire word_addr_aligned      = word_type && (mem_addr[1:0]==2'b00);


wire addr_align_exception   = ~(halfword_addr_aligned || word_addr_aligned || byte_type);

wire load_addr_exception    = is_load && addr_align_exception;
wire store_addr_exception   = is_store && addr_align_exception;

assign  exception_out   = {25'd0, load_addr_exception, store_addr_exception, exception[4:0]};

//-----------------------------------------------------------------------------------------
// Memory data ctrl
//-----------------------------------------------------------------------------------------
reg     [WIDTH-1:0] load_data;

always @(*) begin
    if(!rst_n) begin
        load_data       = 'd0;          // to rd
        mem_sel_out     = 4'd0;         // to mem
        mem_wdata_out   = 'd0;          // to mem
    end
    else begin
        load_data       = 'd0;
        mem_sel_out     = 4'd0;
        mem_wdata_out   = 'd0;

        case(inst_decode)
            `INST_LB: begin
                case(mem_addr[1:0])
                    2'b00: begin
                        load_data   = {{24{mem_rdata[7]}}, mem_rdata[7:0]};
                        mem_sel_out = 4'd0;
                    end
                    2'b01: begin
                        load_data   = {{24{mem_rdata[15]}}, mem_rdata[15:8]};
                        mem_sel_out = 4'd0;
                    end
                    2'b10: begin
                        load_data   = {{24{mem_rdata[23]}}, mem_rdata[23:16]};
                        mem_sel_out = 4'd0;
                    end
                    2'b11: begin
                        load_data   = {{24{mem_rdata[31]}}, mem_rdata[31:23]};
                        mem_sel_out = 4'd0;
                    end
                    default: begin
                    end
                endcase    
            end

            `INST_LBU: begin
                case(mem_addr[1:0])
                    2'b00: begin
                        load_data   = {{24{1'b0}}, mem_rdata[7:0]};
                        mem_sel_out = 4'd0;
                    end
                    2'b01: begin
                        load_data   = {{24{1'b0}}, mem_rdata[15:8]};
                        mem_sel_out = 4'd0;
                    end
                    2'b10: begin
                        load_data   = {{24{1'b0}}, mem_rdata[23:16]};
                        mem_sel_out = 4'd0;
                    end
                    2'b11: begin
                        load_data   = {{24{1'b0}}, mem_rdata[31:23]};
                        mem_sel_out = 4'd0;
                    end
                    default: begin
                    end
                endcase    
            end

            `INST_LH: begin
                case(mem_addr[0])
                    1'b0: begin
                        load_data   = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
                        mem_sel_out = 4'd0;
                    end
                    1'b1: begin
                        load_data   = {{16{mem_rdata[31]}}, mem_rdata[31:16]};
                        mem_sel_out = 4'd0;
                    end
                    default: begin
                    end
                endcase    
            end

            `INST_LHU: begin
                case(mem_addr[0])
                    1'b0: begin
                        load_data   = {{16{1'b0}}, mem_rdata[15:0]};
                        mem_sel_out = 4'd0;
                    end
                    1'b1: begin
                        load_data   = {{16{1'b0}}, mem_rdata[31:16]};
                        mem_sel_out = 4'd0;
                    end
                    default: begin
                    end
                endcase    
            end

            `INST_LW: begin
                load_data   = mem_rdata;
                mem_sel_out = 4'd0;
            end

            `INST_SB: begin
                mem_wdata_out   = {mem_wdata[7:0], mem_wdata[7:0], mem_wdata[7:0], mem_wdata[7:0]}; 
                case(mem_addr[1:0])
                    2'b00: begin
                        mem_sel_out = 4'b0001;
                    end
                    2'b01: begin
                        mem_sel_out = 4'b0010;
                    end
                    2'b10: begin
                        mem_sel_out = 4'b0100;
                    end
                    2'b11: begin
                        mem_sel_out = 4'b1000;
                    end
                    default: begin
                    end
                endcase    
            end

            `INST_SH: begin
                mem_wdata_out   = {mem_wdata[15:0], mem_wdata[15:0]}; 
                case(mem_addr[0])
                    1'b0: begin
                        mem_sel_out = 4'b0011;
                    end
                    1'b1: begin
                        mem_sel_out = 4'b1100;
                    end
                    default: begin
                        mem_sel_out = 4'b0000;
                    end
                endcase    
            end

            `INST_SW: begin
                mem_wdata_out   = mem_wdata;
                mem_sel_out     = 4'b1111;
            end

            default: begin

            end
        endcase
    end
end


//-----------------------------------------------------------------------------------------
// Out
//-----------------------------------------------------------------------------------------
assign pc_out           = pc;
assign inst_out         = inst;

assign rd_we_out        = rd_we;
assign rd_addr_out      = rd_addr;
assign rd_wdata_out     = is_load ? load_data : rd_wdata;

assign csr_we_out       = csr_we;
assign csr_waddr_out    = csr_waddr;
assign csr_wdata_out    = csr_wdata;

assign mem_we_out       = is_store && ~(|exception_out);    // store
assign mem_ce_out       = mem_we_out | is_load;             // when ce && !we, load
assign mem_addr_out     = mem_addr;

endmodule