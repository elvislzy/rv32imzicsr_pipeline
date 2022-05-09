`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/22 15:07:01
// Design Name: 
// Module Name: shifter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module shifter(
    data,
    direction,
    shift,
    shift_out
    );
    
    input   [31:0]  data;
    input           direction;              //if direction = 1 -> left rotate, if direction = 0 -> right rotate
    input   [4:0]   shift;
    output  [31:0]  shift_out;
    
    wire    [31:0]  right_string;
    wire    [31:0]  srl_res;
	wire	[31:0]	sll_res;
	wire	[31:0]	shift_string;
    wire    [31:0]  shift_out;



	assign right_string = {
						data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7],
						data[8],data[9],data[10],data[11],data[12],data[13],data[14],data[15],
						data[16],data[17],data[18],data[19],data[20],data[21],data[22],data[23],
						data[24],data[25],data[26],data[27],data[28],data[29],data[30],data[31]
						};

 	assign shift_string = direction ? data : right_string; 
	assign sll_res = shift_string << shift;
   	assign srl_res = {
                   sll_res[0],sll_res[1],sll_res[2],sll_res[3],
				   sll_res[4],sll_res[5],sll_res[6],sll_res[7],
                   sll_res[8],sll_res[9],sll_res[10],sll_res[11],
				   sll_res[12],sll_res[13],sll_res[14],sll_res[15],
                   sll_res[16],sll_res[17],sll_res[18],sll_res[19],
				   sll_res[20],sll_res[21],sll_res[22],sll_res[23],
                   sll_res[24],sll_res[25],sll_res[26],sll_res[27],
				   sll_res[28],sll_res[29],sll_res[30],sll_res[31]
                   };

	assign shift_out = direction ? sll_res : srl_res;
   

endmodule
