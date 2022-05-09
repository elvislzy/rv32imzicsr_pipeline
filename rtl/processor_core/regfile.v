// -----------------------------------------------------------------
// Filename: regfile.v                                             
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


module regfile(
    input   wire            clk,
    input   wire            rst_n,

    input   wire            rd_we,        //write_enable control siginal
    input   wire    [4:0]   rd_addr,

    input   wire            rs1_re,
    input   wire    [4:0]   rs1_addr,

    input   wire            rs2_re,
    input   wire    [4:0]   rs2_addr,

    input   wire    [31:0]  rd_data_in,
    output  reg     [31:0]  rs1_data,
    output  reg     [31:0]  rs2_data
    );
    
    reg [31:0]  regfile [0:31];
    integer j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(j=0;j<=31;j=j+1) begin
                regfile [j]     <= 32'b0;
            end
        end
        else if(rd_we && (rd_addr!='d0)) begin
            regfile [rd_addr]   <= rd_data_in;
        end
    end


    always @(*) begin
        if(!rst_n) begin
            rs1_data    = 32'd0;
        end
        else if(rs1_addr==32'd0) begin
            rs1_data    = 32'd0;
        end
        else if((rs1_addr==rd_addr) && rd_we && rs1_re) begin
            rs1_data    = rd_data_in;
        end
        else if(rs1_re) begin
            rs1_data    = regfile[rs1_addr];
        end
        else begin
            rs1_data    = 32'd0;
        end
    end

    always @(*) begin
        if(!rst_n) begin
            rs2_data    = 32'd0;
        end
        else if(rs2_addr==32'd0) begin
            rs2_data    = 32'd0;
        end
        else if((rd_addr == rs2_addr) && rd_we && rs2_re) begin
            rs2_data    = rd_data_in;
        end
        else if(rs2_re) begin
            rs2_data    = regfile[rs2_addr];
        end
        else begin
            rs2_data    = 32'd0;
        end
    end

endmodule









