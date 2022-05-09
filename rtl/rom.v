// -----------------------------------------------------------------
// Filename: rom.v                                             
// 
// Company: 
// Description:                                                     
// 
// 
//                                                                  
// Author: Elvis.Lu<lzyelvis@gmail.com>                            
// Create Date: 05/06/2022                                           
// Comments:                                                        
// 
// -----------------------------------------------------------------


module rom #(parameter WIDTH=32, parameter DEPTH=1024) (
	input wire				    clk,
    input wire                  rst_n,
	input wire					rom_ce,
	input wire  [WIDTH-1:0]	    rom_addr,

	output reg  [WIDTH-1:0]		rom_data   
);

    parameter ADDR_WIDTH = $clog2(DEPTH);
    (*ram_style="block"*) reg [31:0] rom_mem [DEPTH-1:0];


    always @ (*) begin
		if (rom_ce == 1'b0) begin
			rom_data = 32'd0;
		end else begin
			rom_data = rom_mem[rom_addr[ADDR_WIDTH+1:2]];
		end
	end


endmodule