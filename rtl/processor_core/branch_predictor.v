// -----------------------------------------------------------------
// Filename: branch_predictor.v                                             
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


module branch_predictor #(parameter WIDTH=32, parameter BTB_ENTRIES=32, parameter PHT_ENTRIES=32, parameter RAS_ENTRIES=8)
(
    input  wire                     clk,
    input  wire                     rst_n,

    // ex
    input  wire     [WIDTH-1:0]     branch_ex_pc,           // current pc in ex
    input  wire                     branch_ex_req,          // branch request from ex
    input  wire                     branch_ex_taken,        // branch taken 
    input  wire                     branch_ex_jump,         // jump type
    input  wire                     branch_ex_call,         // call type
    input  wire                     branch_ex_ret,          // return type
    input  wire     [WIDTH-1:0]     branch_ex_next_pc,      // true next pc
    input  wire                     branch_miss,            // branch missprediction

    // if
    input  wire     [WIDTH-1:0]     pc_in,                  // current pc in if
    output wire     [WIDTH-1:0]     branch_predict_pc_out,  // predicted pc
    output wire                     branch_taken_out,       // predicted branch taken

    // ctrl
    input  wire                     ctrl_stall              // stall signal from ctrl

);

localparam  PHT_WIDTH = $clog2(PHT_ENTRIES);
localparam  BTB_WIDTH = $clog2(BTB_ENTRIES);
localparam  RAS_WIDTH = $clog2(RAS_ENTRIES);

///////////////////////////////////////////////////////////////
// PHT, pattern history table, two-bit predictor
// strongly not taken(00)--weakly not taken(01)
// weakly taken(10)--strongly taken(11)
///////////////////////////////////////////////////////////////

reg     [1:0]   bht_table   [PHT_ENTRIES-1:0];

// update bht
wire    [PHT_WIDTH-1:0] bht_w_addr = branch_ex_pc[PHT_WIDTH-1+2:2];     // use[6:2] 5bit as index

integer i;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<PHT_ENTRIES;i=i+1) begin
            bht_table[i]    <= 2'b11;           // initialize strongly taken(11)
        end
    end
    else begin
        if(branch_ex_req) begin
            if((branch_ex_taken) && (bht_table[bht_w_addr]<2'd3)) begin // if taken, +1 if predictor != strongly taken(11)
                bht_table[bht_w_addr]   <= bht_table[bht_w_addr] + 1'b1;
            end
            else if((!branch_ex_taken) && (bht_table[bht_w_addr]>2'd0))begin // if not taken, -1 if predictor != strongly not taken(00)
                bht_table[bht_w_addr]   <= bht_table[bht_w_addr] - 1'b1;
            end
        end
    end
end

// lookup bht
wire    [PHT_WIDTH-1:0] bht_r_addr = pc_in[PHT_WIDTH-1+2:2];

wire    bht_pred_taken = bht_table[bht_r_addr] >= 2'd2;

///////////////////////////////////////////////////////////////
// BTB, branch target buffer, two-bit predictor
// | valid | pc | is_call | is_ret | is_jump | target_pc |
// 1. jump, call    --> btb_pred_pc
// 2. branch        --> bht_pred_taken? btb_pred_pc : pc + 4
// 3. ret           --> ras_pred_pc 
///////////////////////////////////////////////////////////////
// define btb tables
reg                     btb_valid_table[BTB_ENTRIES-1:0];
reg     [WIDTH-1:0]     btb_pc_table[BTB_ENTRIES-1:0];
reg                     btb_is_call_table[BTB_ENTRIES-1:0];
reg                     btb_is_ret_table[BTB_ENTRIES-1:0];
reg                     btb_is_jump_table[BTB_ENTRIES-1:0];
reg     [WIDTH-1:0]     btb_target_pc_table[BTB_ENTRIES-1:0];

// ------------
// update btb
// ------------
reg     [BTB_WIDTH-1:0] btb_w_addr;
wire    [BTB_WIDTH-1:0] btb_new_addr;
reg                     btb_hit;
reg                     btb_new_req;

// arrange new btb address
reg     [BTB_WIDTH-1:0] cnt;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt     <= 'd0;
    end
    else if(btb_new_req) begin
        cnt     <= cnt + 1'b1;
    end
end
assign btb_new_addr = cnt;

// match
integer j;
always @(*) begin
    btb_w_addr      = 'd0;
    btb_hit         = 1'b0;
    btb_new_req     = 1'b0;

    if(branch_ex_req && branch_ex_taken) begin      // match btb if branch
        for(j=0;j<BTB_ENTRIES;j=j+1) begin
            if((btb_pc_table[j]==branch_ex_pc) && btb_valid_table[j]) begin
                btb_hit     = 1'b1;
                btb_w_addr  = j;
            end
        end
        btb_new_req     = ~btb_hit;
    end
end

// write
integer k;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(k=0;k<BTB_ENTRIES;k=k+1) begin
            btb_valid_table[k]      <= 'd0;
            btb_pc_table[k]         <= 'd0;
            btb_is_call_table[k]    <= 'd0;
            btb_is_jump_table[k]    <= 'd0;
            btb_is_ret_table[k]     <= 'd0;
            btb_target_pc_table[k]  <= 'd0;
        end
    end
    else begin
        if(branch_ex_req && branch_ex_taken) begin      // update btb if branch
            if(btb_hit) begin                           // update exist addr if hit
                btb_pc_table[btb_w_addr]            <= branch_ex_pc;
                btb_is_call_table[btb_w_addr]       <= branch_ex_call;
                btb_is_jump_table[btb_w_addr]       <= branch_ex_jump;
                btb_is_ret_table[btb_w_addr]        <= branch_ex_ret;
                btb_target_pc_table[btb_w_addr]     <= branch_ex_next_pc;
            end
            else begin                                  // update to new addr
                btb_valid_table[btb_new_addr]       <= 1'b1;                       
                btb_pc_table[btb_new_addr]          <= branch_ex_pc;
                btb_is_call_table[btb_new_addr]     <= branch_ex_call;
                btb_is_jump_table[btb_new_addr]     <= branch_ex_jump;
                btb_is_ret_table[btb_new_addr]      <= branch_ex_ret;
                btb_target_pc_table[btb_new_addr]   <= branch_ex_next_pc;
            end
        end
    end
end


// -----------
// lookup btb
// -----------
reg     [BTB_WIDTH-1:0]     btb_r_addr;
reg                         btb_match;
reg                         btb_call;
reg                         btb_jump;
reg                         btb_ret;
reg     [WIDTH-1:0]         btb_target_pc;

integer p;

always @(*) begin
    btb_match       = 1'b0;
    btb_call        = 1'b0;
    btb_jump        = 1'b0;
    btb_ret         = 1'b0;
    btb_target_pc   = pc_in + 32'd4;
    btb_r_addr      = 'd0;

    for(p=0;p<BTB_ENTRIES;p=p+1) begin
        if(btb_pc_table[p]==pc_in && btb_valid_table[p]) begin
            btb_match               = 1'b1;
            btb_call                = btb_is_call_table[p];
            btb_jump                = btb_is_jump_table[p];
            btb_ret                 = btb_is_ret_table[p];
            btb_target_pc           = btb_target_pc_table[p];
            btb_r_addr              = p; 
        end
    end
end


///////////////////////////////////////////////////////////////
// RAS, Return address stack
// 
// 
///////////////////////////////////////////////////////////////




///////////////////////////////////////////////////////////////
// out
///////////////////////////////////////////////////////////////
assign branch_taken_out = (btb_match & (btb_call|btb_jump|btb_ret|bht_pred_taken)) ? 1'b1 : 1'b0;
assign branch_predict_pc_out = (btb_match & (btb_call|btb_jump|btb_ret|bht_pred_taken)) ? btb_target_pc : pc_in + 32'd4;







endmodule