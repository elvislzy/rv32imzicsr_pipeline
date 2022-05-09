// -----------------------------------------------------------------
// Filename: ex_mem.v                                             
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

module ex_mem   #(parameter WIDTH=32)
(
    input  wire                 clk,
    input  wire                 rst_n,


    // ctrl-----------------------------------------------
    input  wire     [4:0]       ctrl_stall,
    input  wire                 ctrl_flush,


    // ex-------------------------------------------------
    input  wire     [WIDTH-1:0] pc,
    input  wire     [WIDTH-1:0] inst,

    input  wire     [5:0]       inst_decode,

    // branch
    input  wire                 branch_tag,
    input  wire                 branch_pc_re,

    // rd
    input  wire                 rd_we,
    input  wire     [4:0]       rd_addr,
    input  wire     [WIDTH-1:0] rd_wdata,

    // mem
    input  wire     [WIDTH-1:0] mem_addr,
    input  wire     [WIDTH-1:0] mem_wdata,

    //csr
    input  wire                 csr_we,
    input  wire     [11:0]      csr_waddr,
    input  wire     [WIDTH-1:0] csr_wdata,

    input  wire     [WIDTH-1:0] exception,


    // to mem----------------------------------------------
    output reg      [WIDTH-1:0] pc_out,
    output reg      [WIDTH-1:0] inst_out,

    output reg      [5:0]       inst_decode_out,

    output reg                  rd_we_out,
    output reg      [4:0]       rd_addr_out,
    output reg      [WIDTH-1:0] rd_wdata_out,

    output reg      [WIDTH-1:0] mem_addr_out,
    output reg      [WIDTH-1:0] mem_wdata_out,

    output reg                  csr_we_out,
    output reg      [11:0]      csr_waddr_out,
    output reg      [WIDTH-1:0] csr_wdata_out,
    
    output reg      [WIDTH-1:0] exception_out

);

reg     [WIDTH-1:0] pc_buf;
reg                 branch_tag_buf;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pc_out                  <= 'd0;
        pc_buf                  <= 'd0;
        branch_tag_buf          <= 1'b0;
        inst_out                <= `NOP;
        inst_decode_out         <= `INST_NOP;

        rd_we_out               <= 1'b0;
        rd_addr_out             <= 5'd0;
        rd_wdata_out            <= 'd0;

        mem_addr_out            <= 'd0;
        mem_wdata_out           <= 'd0;

        csr_we_out              <= 1'b0;
        csr_waddr_out           <= 12'd0;
        csr_wdata_out           <= 'd0;

        exception_out           <= 'd0;
    end
    else begin
        if(ctrl_flush) begin
            pc_out                  <= 'd0;
            pc_buf                  <= 'd0;
            branch_tag_buf          <= 1'b0;
            inst_out                <= `NOP;
            inst_decode_out         <= `INST_NOP;
    
            rd_we_out               <= 1'b0;
            rd_addr_out             <= 5'd0;
            rd_wdata_out            <= 'd0;
    
            mem_addr_out            <= 'd0;
            mem_wdata_out           <= 'd0;
    
            csr_we_out              <= 1'b0;
            csr_waddr_out           <= 12'd0;
            csr_wdata_out           <= 'd0;
    
            exception_out           <= 'd0;      

        end
        else begin
            if(ctrl_stall[3]) begin         // stall ex_mem
                if(!ctrl_stall[4]) begin        // not stall mem_wb
                    pc_out                  <= pc;
                    pc_buf                  <= 'd0;
                    branch_tag_buf          <= 1'b0;

                    inst_out                <= `NOP;
                    inst_decode_out         <= `INST_NOP;
    
                    rd_we_out               <= 1'b0;
                    rd_addr_out             <= 5'd0;
                    rd_wdata_out            <= 'd0;
    
                    mem_addr_out            <= 'd0;
                    mem_wdata_out           <= 'd0;
    
                    csr_we_out              <= 1'b0;
                    csr_waddr_out           <= 12'd0;
                    csr_wdata_out           <= 'd0;
    
                    exception_out           <= 'd0; 
                end
                else begin                      // stall ex_mem & mem_wb
                    pc_out                  <= pc_out;
                    pc_buf                  <= pc_buf;
                    branch_tag_buf          <= branch_tag_buf;
                    inst_out                <= inst_out;
                    inst_decode_out         <= inst_decode_out;
    
                    rd_we_out               <= rd_we_out;
                    rd_addr_out             <= rd_addr_out;
                    rd_wdata_out            <= rd_wdata_out;
    
                    mem_addr_out            <= mem_addr_out;
                    mem_wdata_out           <= mem_wdata_out;
    
                    csr_we_out              <= csr_we_out;
                    csr_waddr_out           <= csr_waddr_out;
                    csr_wdata_out           <= csr_wdata_out;
    
                    exception_out           <= exception_out; 
                end
            end
            else begin
                if(branch_tag) begin                           // is branch miss
                    branch_tag_buf     <= 1'b1;
                    pc_buf              <= pc;
                end
                else begin
                    if(branch_tag_buf && branch_pc_re) begin   // stall pc until pc reassign signal from ifu arrive
                        branch_tag_buf     <= 1'b0;
                    end
                end

                if(branch_tag_buf) begin
                    pc_out  <= pc_buf;
                end
                else begin
                    pc_out  <= pc;
                end

                inst_out                <= inst;
                inst_decode_out         <= inst_decode;
    
                rd_we_out               <= rd_we;
                rd_addr_out             <= rd_addr;
                rd_wdata_out            <= rd_wdata;
    
                mem_addr_out            <= mem_addr;
                mem_wdata_out           <= mem_wdata;
    
                csr_we_out              <= csr_we;
                csr_waddr_out           <= csr_waddr;
                csr_wdata_out           <= csr_wdata;
    
                exception_out           <= exception; 


            end
        end
    end
end


endmodule