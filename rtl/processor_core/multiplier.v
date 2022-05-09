// -----------------------------------------------------------------
// Filename: multiplier.v                                             
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

`include "param_def.v"

module multiplier   #(parameter WIDTH=32)
(
    input  wire                 rst_n,

    input  wire     [5:0]       inst_type,

    input  wire     [WIDTH-1:0] rs1_data,
    input  wire     [WIDTH-1:0] rs2_data,

    output reg      [WIDTH-1:0] mul_out

);

reg     [WIDTH:0]     mul_operand1;
reg     [WIDTH:0]     mul_operand2;

wire    [2*WIDTH-1:0]   mul_tmp;
wire    [2*WIDTH-1:0]   mul_tmp_t = ~mul_tmp + 1'b1;

// two's complement
wire    [WIDTH-1:0]     rs1_data_t = ~rs1_data + 1'b1;      
wire    [WIDTH-1:0]     rs2_data_t = ~rs2_data + 1'b1;

always @(*) begin
    mul_operand1    = rs1_data;
    mul_operand2    = rs2_data;
    mul_out         = 'd0; 
    case(inst_type)
        `INST_MUL: begin                    // unsigned * unsigned
            mul_operand1    = rs1_data;
            mul_operand2    = rs2_data;
            mul_out         = mul_tmp[31:0];
        end
        `INST_MULHU: begin
            mul_operand1    = rs1_data;
            mul_operand2    = rs2_data;
            mul_out         = mul_tmp[63:32];
        end
        `INST_MULHSU: begin                 // signed * unsigned 
            mul_operand1    = rs1_data[WIDTH-1] ? rs1_data_t : rs1_data;
            mul_operand2    = rs2_data;
            mul_out         = rs1_data[WIDTH-1] ? mul_tmp_t[63:32] : mul_tmp[63:32];
        end
        `INST_MULH: begin
            mul_operand1    = rs1_data[WIDTH-1] ? rs1_data_t : rs1_data;
            mul_operand2    = rs2_data[WIDTH-1] ? rs2_data_t : rs2_data;
            mul_out         = (~rs1_data[WIDTH-1] & ~rs2_data[WIDTH-1] & mul_tmp[63:32]) |
                              ( rs1_data[WIDTH-1] & ~rs2_data[WIDTH-1] & mul_tmp_t[63:32]) |
                              (~rs1_data[WIDTH-1] &  rs2_data[WIDTH-1] & mul_tmp[63:32]) |
                              ( rs1_data[WIDTH-1] &  rs2_data[WIDTH-1] & mul_tmp[63:32]);
        end
        default: begin
        
        end
    endcase
end


endmodule