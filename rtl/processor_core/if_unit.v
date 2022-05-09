// -----------------------------------------------------------------
// Filename: if_unit.v                                             
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


module if_unit  #(parameter WIDTH=32)
(
    input  wire                     clk,
    input  wire                     rst_n,

    // instruction memory
    output reg      [WIDTH-1:0]     pc_out,
    // output wire                     rom_cs, 

    // ctrl
    input  wire     [4:0]           ctrl_stall,         // ctrl stall signal
    input  wire                     ctrl_pc_re,         // ctrl pc reassign
    input  wire                     ctrl_flush,         // ctrl flush signal
    input  wire     [WIDTH-1:0]     ctrl_next_pc,       // next pc from ctrl

    // branch predictor(IF)
    input  wire     [WIDTH-1:0]     branch_predict_pc,  // predicted pc
    input  wire                     branch_taken,       // predicted branch taken/not taken

    // branch comperator(EX)
    input  wire                     branch_miss,        // branch miss predicted
    input  wire     [WIDTH-1:0]     branch_miss_pc,     // new pc when miss predicted

    // if_id reg
    output reg                      branch_pc_re_out    // branch miss, pc re-assign flag

);

reg                     branch_miss_buf;                // branch buffer
reg     [WIDTH-1:0]     branch_miss_pc_buf;

// reg                     chip_en;
// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         chip_en = 1'b0;
//     end
//     else begin
//         chip_en = 1'b1;
//     end
// end



always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pc_out              <= 32'd0;
        branch_miss_buf     <= 1'b0;
        branch_miss_pc_buf  <= 32'd0;
        branch_pc_re_out    <= 1'b0;
    end
    else begin
        if(ctrl_flush|ctrl_pc_re) begin                 // flush/ctrl pc
            pc_out              <= ctrl_next_pc;
            branch_pc_re_out    <= 1'b0;
        end
        else begin
            if(branch_miss) begin                           // branch miss predict
                if(!ctrl_stall[0]) begin                           // no stall
                    pc_out              <= branch_miss_pc;
                    branch_pc_re_out    <= 1'b1;
                end
                else begin                                      // stall, buffer branch req
                    pc_out              <= pc_out;
                    branch_miss_buf     <= branch_miss;
                    branch_miss_pc_buf  <= branch_miss_pc;
                end
            end
            else begin                                      // no branch miss predict
                if(!ctrl_stall[0]) begin                           // no stall
                    if(branch_miss_buf) begin                       // buffered branch request exist
                        pc_out              <= branch_miss_pc_buf;
                        branch_miss_buf     <= 1'b0;
                        branch_pc_re_out    <= 1'b1;
                    end
                    else begin                                      // no req buffer exist, branch success
                        pc_out              <= branch_predict_pc;
                        branch_pc_re_out    <= 1'b0;
                    end
                end
                else begin                                      // stall
                    pc_out              <= pc_out;
                    branch_pc_re_out    <= 1'b0;
                end
            end
        end
    end
end


endmodule