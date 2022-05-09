// -----------------------------------------------------------------
// Filename: soc_top.v                                             
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


module soc_top #(parameter WIDTH=32)
(
    input  wire                 clk,
    input  wire                 rst_n
);

// core_top Inputs
wire   [WIDTH-1:0]  rom_data;
wire   [WIDTH-1:0]  ram_data;

// core_top Outputs
wire    [WIDTH-1:0] rom_addr;
wire    [WIDTH-1:0] core_ram_data;
wire    [WIDTH-1:0] ram_addr;
wire                ram_ce;
wire    [3:0]       ram_sel;
wire                ram_we;



core_top  u_core_top (
    .clk                     ( clk                       ),
    .rst_n                   ( rst_n                     ),
    .rom_data                ( rom_data                  ),
    .ram_data_in             ( ram_data                  ),
    .irq_sw                  ( 1'b0                      ),
    .irq_timer               ( 1'b0                      ),
    .irq_external            ( 1'b0                      ),

    .rom_addr                ( rom_addr                  ),
    .ram_data_out            ( core_ram_data             ),
    .ram_addr                ( ram_addr                  ),
    .ram_ce                  ( ram_ce                    ),
    .ram_sel                 ( ram_sel                   ),
    .ram_we                  ( ram_we                    )
);

ram #(.WIDTH(WIDTH), .DEPTH(2048))
 u_ram (
    .clk                     ( clk                      ),
    .rst_n                   ( rst_n                    ),
    .ram_ce                  ( ram_ce                   ),
    .ram_sel                 ( ram_sel                  ),
    .ram_addr                ( ram_addr                 ),
    .ram_we                  ( ram_we                   ),
    .ram_data_in             ( core_ram_data            ),

    .ram_rvalid              ( ram_rvalid               ),
    .ram_data                ( ram_data                 )
);


rom #(.WIDTH(WIDTH), .DEPTH(1024))
 u_rom (
    .clk                     ( clk                   ),
    .rst_n                   ( rst_n                 ),
    .rom_ce                  ( 1'b1                  ),
    .rom_addr                ( rom_addr              ),

    .rom_data                ( rom_data              )
);



endmodule