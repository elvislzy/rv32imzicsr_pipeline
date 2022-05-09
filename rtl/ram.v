// -----------------------------------------------------------------
// Filename: ram.v                                             
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


module ram #(parameter WIDTH=32, parameter DEPTH=2048)
(
	input wire				      clk,
	input wire                    rst_n,

	input wire					  ram_ce,
	input wire  [3:0]			  ram_sel,
	input wire  [WIDTH-1:0] 	  ram_addr,
	input wire					  ram_we,
	input wire  [WIDTH-1:0]		  ram_data_in,

	output wire                   ram_rvalid,
	output reg  [WIDTH-1:0]		  ram_data
);
    parameter ADDR_WIDTH = $clog2(DEPTH);

    reg     [WIDTH-1:0]  ram_mem [DEPTH-1:0];

    assign ram_rvalid = ram_ce & (~ram_we);

	always @ (posedge clk) begin
		if( (ram_ce != 1'b0) && (ram_we == 1'b1) )begin
			if (ram_sel[3] == 1'b1) begin
				ram_mem[ram_addr[ADDR_WIDTH+1:2]][31:24] <= ram_data_in[31:24];
			end

			if (ram_sel[2] == 1'b1) begin
				ram_mem[ram_addr[ADDR_WIDTH+1:2]][23:16] <= ram_data_in[23:16];
			end

			if (ram_sel[1] == 1'b1) begin
				ram_mem[ram_addr[ADDR_WIDTH+1:2]][15:8] <= ram_data_in[15:8];
			end

			if (ram_sel[0] == 1'b1) begin
				ram_mem[ram_addr[ADDR_WIDTH+1:2]][7:0] <= ram_data_in[7:0];
			end
		end
	end

	always @ (*) begin
		if (ram_ce == 1'b0) begin
			ram_data = 32'd0;
	    end else if(ram_we == 1'b0) begin
		    ram_data =  ram_mem[ram_addr[ADDR_WIDTH+1:2]];
		end else begin
			ram_data = 32'd0;
		end
	end

endmodule

