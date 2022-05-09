// -----------------------------------------------------------------
// Filename: alu.v                                             
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


module alu  #(parameter WIDTH=32)
(
    input   wire    [3:0]           alu_op,
    input   wire    [WIDTH-1:0]     operand1,
    input   wire    [WIDTH-1:0]     operand2,
    output  reg     [WIDTH-1:0]     alu_out
);


wire        [31:0]  alu_add;
wire        [31:0]  alu_sub;
wire        [31:0]  alu_sll;
wire                less_then;
wire                u_less_then;
wire        [31:0]  alu_xor;
wire        [31:0]  alu_srl;
wire        [31:0]  alu_sra;
wire        [31:0]  alu_or;
wire        [31:0]  alu_and;
wire                direction;
wire        [31:0]  shift_out;
wire        [31:0]  add1;
wire        [31:0]  add2;
wire        [31:0]  add_out;

// assign alu_add = operand1 + operand2;
// assign alu_sub = operand1 - operand2;
assign alu_sll = operand1 << operand2[4:0];
assign less_then = $signed(operand1) < $signed(operand2);
assign u_less_then = operand1 < operand2;
assign alu_xor = operand1 ^ operand2;
assign alu_sra = ({{31{operand1[31]}}, 1'b0} << (~operand2[4:0])) | (operand1 >> operand2[4:0]);
assign alu_or = operand1 | operand2;
assign alu_and = operand1 & operand2;
assign direction = alu_op == 4'b0001 ? 1'b1 : 1'b0;

assign add1 = operand1;
assign add2 = alu_op == 4'b1000 ? (~operand2 + 1'b1) : operand2;
assign add_out = add1 + add2;
assign alu_eq = operand1 == operand2;

shifter u_shifter(
    .data           (operand1       ),
    .direction      (direction      ),
    .shift          (operand2[4:0]  ),
    .shift_out      (shift_out      )
    );
    

always @(*) begin
    case(alu_op)
        4'b0000: alu_out = add_out;
        4'b1000: alu_out = add_out;       
        4'b0001: alu_out = shift_out;       
        4'b0010: alu_out = {31'b0, less_then};
        4'b0011: alu_out = {31'b0, u_less_then};
        4'b0100: alu_out = alu_xor;
        4'b0101: alu_out = shift_out;
        4'b1101: alu_out = alu_sra;
        4'b0110: alu_out = alu_or;
        4'b0111: alu_out = alu_and;
        4'b1111: alu_out = {31'b0, alu_eq};             // beq
        4'b1110: alu_out = {31'b0, ~alu_eq};            // bne
        4'b1100: alu_out = {31'b0,~less_then};          // bge
        4'b1001: alu_out = {31'b0,~u_less_then};        // bgeu
        default: alu_out = 32'd0;
    endcase
end










endmodule