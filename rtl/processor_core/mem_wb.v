// -----------------------------------------------------------------
// Filename: mem_wb.v                                             
// 
// Company: 
// Description:                                                     
// 
// 
//                                                                  
// Author: Elvis.Lu<lzyelvis@gmail.com>                            
// Create Date: 04/16/2022                                           
// Comments:                                                        
// 
// -----------------------------------------------------------------


module mem_wb   #(parameter WIDTH=32)
(
    input  wire                     clk,
    input  wire                     rst_n,

    // ctrl-------------------------------------
    input  wire     [4:0]           ctrl_stall,
    input  wire                     ctrl_flush,

    // mem--------------------------------------
    input  wire                     rd_we,
    input  wire     [4:0]           rd_addr,
    input  wire     [WIDTH-1:0]     rd_wdata,

    input  wire                     csr_we,
    input  wire     [11:0]          csr_waddr,
    input  wire     [WIDTH-1:0]     csr_wdata,

    // wb---------------------------------------
    output reg                      rd_we_out,
    output reg      [4:0]           rd_addr_out,
    output reg      [WIDTH-1:0]     rd_wdata_out,

    output reg                      csr_we_out,
    output reg      [11:0]          csr_waddr_out,
    output reg      [WIDTH-1:0]     csr_wdata_out,

    output reg                      inst_processed

);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
       rd_we_out        <= 1'b0;
       rd_addr_out      <= 5'd0;
       rd_wdata_out     <= 'd0;
       
       csr_we_out       <= 1'b0;
       csr_waddr_out    <= 12'd0;
       csr_wdata_out    <= 'd0;

       inst_processed   <= 1'b0;
    end
    else if(ctrl_flush) begin
        rd_we_out        <= 1'b0;
        rd_addr_out      <= 5'd0;
        rd_wdata_out     <= 'd0;
        
        csr_we_out       <= 1'b0;
        csr_waddr_out    <= 12'd0;
        csr_wdata_out    <= 'd0;
 
        inst_processed   <= 1'b0;
    end
    else begin
        if(ctrl_stall[4]) begin     // stall mem_wb
            rd_we_out        <= 1'b0;
            rd_addr_out      <= 5'd0;
            rd_wdata_out     <= 'd0;
            
            csr_we_out       <= 1'b0;
            csr_waddr_out    <= 12'd0;
            csr_wdata_out    <= 'd0;
     
            inst_processed   <= 1'b0;
        end
        else begin
            rd_we_out        <= rd_we;
            rd_addr_out      <= rd_addr;
            rd_wdata_out     <= rd_wdata;
            
            csr_we_out       <= csr_we;
            csr_waddr_out    <= csr_waddr;
            csr_wdata_out    <= csr_wdata;
     
            inst_processed   <= 1'b1;
        end
    end
end










endmodule