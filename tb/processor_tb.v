// -----------------------------------------------------------------
// Filename: processor_tb.v                                             
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
`timescale  1ns / 1ps


module processor_tb;

// soc_top Parameters
parameter PERIOD  = 10;


// soc_top Inputs
reg   clk                                  = 0 ;
reg   rst_n                                = 0 ;

// soc_top Outputs


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst_n  =  1;
end

soc_top  u_soc_top (
    .clk                     ( clk     ),
    .rst_n                   ( rst_n   )
);





initial
begin

    $finish;
end

endmodule











endmodule