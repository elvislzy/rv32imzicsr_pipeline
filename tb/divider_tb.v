`timescale  1ns / 1ps
// -----------------------------------------------------------------
// Filename: divider_tb.v                                             
// 
// Company: 
// Description:                                                     
// 
// 
//                                                                  
// Author: Elvis.Lu<lzyelvis@gmail.com>                            
// Create Date: 04/14/2022                                           
// Comments:                                                        
// 
// -----------------------------------------------------------------


module divider_tb;   

// divider Parameters
parameter PERIOD = 10;
parameter CBIT  = 5;
parameter WIDTH =32;

// divider Inputs
reg   clk                                  = 0 ;
reg   rst_n                                = 0 ;
reg   [WIDTH-1:0]  dividend                = 0 ;
reg   [WIDTH-1:0]  divisor                 = 0 ;
reg   sign                                 = 0 ;
reg   start                                = 0 ;

// divider Outputs
wire  [WIDTH-1:0]  quotient                ;
wire  [WIDTH-1:0]  remainder               ;
wire  busy;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst_n  =  1;
end

divider #(
    .CBIT ( CBIT ))
 u_divider1 (
    .clk                     ( clk                    ),
    .rst_n                   ( rst_n                  ),
    .dividend                ( dividend   [WIDTH-1:0] ),
    .divisor                 ( divisor    [WIDTH-1:0] ),
    .div_sign                ( sign                   ),
    .start                   ( start                  ),

    .busy                    ( busy                   ),
    .quotient                ( quotient   [WIDTH-1:0] ),
    .remainder               ( remainder  [WIDTH-1:0] )
);

reg     [WIDTH-1:0] div=0;
reg     [WIDTH-1:0] rem=0;
reg     [WIDTH-1:0] signed_div=0;
reg     [WIDTH-1:0] signed_rem=0;
reg     [WIDTH-1:0] unsigned_div=0;
reg     [WIDTH-1:0] unsigned_rem=0;

initial
begin
    #100;
    dividend    = -32'd349;
    divisor     = 32'd26;
    
    sign    = 1'b0;
    
    start   = 1'b1;

    // @(posedge dout_vld);
    @(negedge busy);
    start       = 1'b0;
    @(posedge clk);
    div         = quotient;
    rem         = remainder;
    

    signed_div = $signed(dividend)/$signed(divisor);
    signed_rem = $signed(dividend) % $signed(divisor);

    unsigned_div = dividend/divisor;   
    unsigned_rem = dividend % divisor;

    if(!sign) begin
        if(div!=unsigned_div)
            $fatal("unsigned div error");
        if(rem!=unsigned_rem)
            $fatal("unsigned rem error");
    end
    else begin
        if(div!=signed_div)
            $fatal("signed div error");
        if(rem!=signed_rem)
            $fatal("signed rem error");
    end

    
    #100;
    $display("quotient=%5d, remainder=%5d", div, rem);
    $finish;
end

endmodule