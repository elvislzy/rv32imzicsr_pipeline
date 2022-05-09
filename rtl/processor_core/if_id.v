// -----------------------------------------------------------------
// Filename: if_id.v                                             
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
`include "param_def.v"

module if_id    #(parameter WIDTH=32)
(
    input  wire                 clk,
    input  wire                 rst_n,

    // instruction memory
    input  wire     [WIDTH-1:0] inst,

    // if
    input  wire     [WIDTH-1:0] pc,
    input  wire                 branch_pc_re,

    // branch predictor(if)
    input  wire                 branch_taken,
    input  wire     [WIDTH-1:0] branch_predict_pc,      // branch pc reassign(branch misspredicted)

    // branch comperator(ex)
    input  wire                 branch_miss,

    // ctrl
    input  wire     [4:0]       ctrl_stall,     // 5 bits stall fetch | decode | ex | mem | wb
    input  wire                 ctrl_flush,
    input  wire                 ctrl_pc_re,

    // to id
    output reg      [WIDTH-1:0] pc_out,
    output reg      [WIDTH-1:0] inst_out,
    output reg      [WIDTH-1:0] branch_predict_pc_out,
    output reg                  branch_taken_out,
    output reg                  branch_pc_re_out

);

// localparam NOP = 32'h0000_0013;     // addi x0, x0, 0

// reg     branch_miss_buf;
// always @(posedge clk or negedge rst_n) begin    // make sure 1 NOP after if_unit process branch miss signal(when if_unit stall)
//     if(!rst_n) begin                            //                  |      __    __    __    __    __    __
//         branch_miss_buf     <= 1'b0;            // clk              |   __/  \__/  \__/  \__/  \__/  \__/  \__/
//     end                                         //                  |      _____
//     else if(branch_miss) begin                  // branch_miss      |   __/     \______________________________
//         branch_miss_buf     <= 1'b1;            //                  |                        _____
//     end                                         // branch_pc_re     |   ____________________/     \____________ (stall for 2 clk)
//     else if(branch_pc_re) begin                 //                  |      _______________________
//         branch_miss_buf     <= 1'b0;            // branch_miss_buf  |   __/                       \____________
//     end
// end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pc_out                  <= 'd0;
        inst_out                <= `NOP;
        branch_predict_pc_out   <= 'd0;
        branch_taken_out        <= 1'b0;
        branch_pc_re_out        <= 1'b0;
    end
    else begin
        if(ctrl_flush | ctrl_pc_re) begin
            pc_out              <= pc;
            inst_out            <= `NOP;
            branch_pc_re_out    <= branch_pc_re;
        end
        else begin
            branch_pc_re_out    <= branch_pc_re;
            if(branch_miss) begin
                pc_out            <= pc;
                inst_out          <= `NOP;
            end
            else begin
                if(ctrl_stall[1]) begin                // stall fetch
                    if(!ctrl_stall[2]) begin                 // keep decode
                        pc_out      <= pc;
                        inst_out    <= `NOP;
                    end
                    else begin                              // stall decode             
                        pc_out                  <= pc_out;
                        inst_out              <= inst_out;
                        branch_predict_pc_out   <= branch_predict_pc_out;
                        branch_taken_out        <= branch_taken_out;
                    end
                end
                else begin
                    pc_out                  <= pc;
                    inst_out              <= inst;
                    branch_predict_pc_out   <= branch_predict_pc;
                    branch_taken_out        <= branch_taken;
                end
            end
        
    end
    end

end

endmodule