// -----------------------------------------------------------------
// Filename: id_ex.v                                             
// 
// Company: 
// Description:                                                     
// 
// 
//                                                                  
// Author: Elvis.Lu<lzyelvis@gmail.com>                            
// Create Date: 04/12/2022                                           
// Comments:                                                        
// 
// -----------------------------------------------------------------

`include "param_def.v"

module id_ex    #(parameter WIDTH=32)
(
    input  wire                     clk,
    input  wire                     rst_n,

    // id-----------------------------------------------
    input  wire     [WIDTH-1:0]     pc,
    input  wire     [WIDTH-1:0]     inst,
    input  wire     [WIDTH-1:0]     imm,
    
    // csr
    input  wire                     csr_we,
    input  wire     [11:0]          csr_addr,

    // rs
    input  wire     [WIDTH-1:0]     rs1_data,
    input  wire     [WIDTH-1:0]     rs2_data,
    input  wire                     rd_we,
    input  wire     [4:0]           rd_addr,

    // decode
    input  wire     [5:0]           inst_decode,
    input  wire     [3:0]           aluop,
    input  wire     [2:0]           result_sel,

    // branch
    input  wire     [WIDTH-1:0]     branch_predict_pc,
    input  wire                     branch_taken,
    input  wire                     branch_pc_re,
    input  wire                     branch_miss,

    input  wire     [WIDTH-1:0]     exception,

    // ctrl----------------------------------------------
    input  wire     [4:0]           ctrl_stall,
    input  wire                     ctrl_flush,

    // to ex---------------------------------------------
    output reg      [WIDTH-1:0]     pc_out,
    output reg      [WIDTH-1:0]     inst_out,
    output reg      [WIDTH-1:0]     imm_out,

    // csr
    output reg                      csr_we_out,
    output reg      [11:0]          csr_addr_out,

    // rs
    output reg      [WIDTH-1:0]     rs1_data_out,
    output reg      [WIDTH-1:0]     rs2_data_out,
    output reg                      rd_we_out,
    output reg      [4:0]           rd_addr_out,

    // decode
    output reg      [5:0]           inst_decode_out,
    output reg      [3:0]           aluop_out,
    output reg      [2:0]           result_sel_out,

    // branch
    output reg      [WIDTH-1:0]     branch_predict_pc_out,
    output reg                      branch_taken_out,
    output reg                      branch_pc_re_out,

    
    output reg      [WIDTH-1:0]     exception_out
);


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
       pc_out                   <= 'd0;
       inst_out                 <= `NOP; 
       imm_out                  <= 'd0;
       
       csr_we_out               <= 1'b0;
       csr_addr_out             <= 'd0;
       
       rs1_data_out             <= 'd0;
       rs2_data_out             <= 'd0;
       rd_we_out                <= 1'b0;
       rd_addr_out              <= 'd0;
       
       inst_decode_out          <= `INST_NOP;
       aluop_out                <= 4'b0000;
       result_sel_out           <= `EX_SEL_NOP;
       
       branch_predict_pc_out    <= 'd0;
       branch_taken_out         <= 1'b0;
       branch_pc_re_out         <= 1'b0;
       
       exception_out            <= 'd0;
    
    end
    else begin
        if(ctrl_flush) begin
            pc_out                   <= 'd0;
            inst_out                 <= `NOP; 
            imm_out                  <= 'd0;
       
            csr_we_out               <= 1'b0;
            csr_addr_out             <= 'd0;
       
            rs1_data_out             <= 'd0;
            rs2_data_out             <= 'd0;
            rd_we_out                <= 1'b0;
            rd_addr_out              <= 'd0;
       
            inst_decode_out          <= `INST_NOP;
            aluop_out                <= 4'b0000;
            result_sel_out           <= `EX_SEL_NOP;
       
            branch_predict_pc_out    <= 'd0;
            branch_taken_out         <= 1'b0;
            branch_pc_re_out         <= 1'b0;
       
            exception_out            <= 'd0;

        end
        else begin
            branch_pc_re_out    <= branch_pc_re;
            if(branch_miss) begin
                pc_out                   <= pc;
                inst_out                 <= `NOP; 
                imm_out                  <= 'd0;
       
                csr_we_out               <= 1'b0;
                csr_addr_out             <= 'd0;
       
                rs1_data_out             <= 'd0;
                rs2_data_out             <= 'd0;
                rd_we_out                <= 1'b0;
                rd_addr_out              <= 'd0;
       
                inst_decode_out          <= `INST_NOP;
                aluop_out                <= 4'b0000;
                result_sel_out           <= `EX_SEL_NOP;
       
                branch_predict_pc_out    <= 'd0;
                branch_taken_out         <= 1'b0;
                branch_pc_re_out         <= 1'b0;
       
                exception_out            <= 'd0;
            end
            else begin
                if(ctrl_stall[2]) begin                     // stall id
                    if(!ctrl_stall[3]) begin                    // not stall ex       
                        pc_out                   <= pc_out;
                        inst_out                 <= `NOP; 
                        imm_out                  <= 'd0;
       
                        csr_we_out               <= 1'b0;
                        csr_addr_out             <= 'd0;
       
                        rs1_data_out             <= 'd0;
                        rs2_data_out             <= 'd0;
                        rd_we_out                <= 1'b0;
                        rd_addr_out              <= 'd0;
       
                        inst_decode_out          <= `INST_NOP;
                        aluop_out                <= 4'b0000;
                        result_sel_out           <= `EX_SEL_NOP;
       
                        branch_predict_pc_out    <= 'd0;
                        branch_taken_out         <= 1'b0;
                        branch_pc_re_out         <= 1'b0;
       
                        exception_out            <= 'd0;

                    end
                    else begin                                      // stall ex
                        pc_out                   <= pc_out;
                        inst_out                 <= inst_out; 
                        imm_out                  <= imm_out;
       
                        csr_we_out               <= csr_we_out;
                        csr_addr_out             <= csr_addr_out;
       
                        rs1_data_out             <= rs1_data_out;
                        rs2_data_out             <= rs2_data_out;
                        rd_we_out                <= rd_we_out;
                        rd_addr_out              <= rd_addr_out;
       
                        inst_decode_out          <= inst_decode_out;
                        aluop_out                <= aluop_out;
                        result_sel_out           <= result_sel_out;
       
                        branch_predict_pc_out    <= branch_predict_pc_out;
                        branch_taken_out         <= branch_taken_out;
                        branch_pc_re_out         <= branch_pc_re_out;
       
                        exception_out            <= exception_out;
                    end
                end
                else begin                                          // not stall id and ex
                    pc_out                   <= pc;
                    inst_out                 <= inst; 
                    imm_out                  <= imm;
       
                    csr_we_out               <= csr_we;
                    csr_addr_out             <= csr_addr;
       
                    rs1_data_out             <= rs1_data;
                    rs2_data_out             <= rs2_data;
                    rd_we_out                <= rd_we;
                    rd_addr_out              <= rd_addr;
       
                    inst_decode_out          <= inst_decode;
                    aluop_out                <= aluop;
                    result_sel_out           <= result_sel;
       
                    branch_predict_pc_out    <= branch_predict_pc;
                    branch_taken_out         <= branch_taken;
                    branch_pc_re_out         <= branch_pc_re;
       
                    exception_out            <= exception;
                end
            end
        end
    end
end



endmodule