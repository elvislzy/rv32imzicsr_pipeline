// -----------------------------------------------------------------
// Filename: ctrl.v                                             
// 
// Company: 
// Description:                                                     
// 
// 
//                                                                  
// Author: Elvis.Lu<lzyelvis@gmail.com>                            
// Create Date: 04/16/2022                                           
// Comments:                                                        
// 
// -----------------------------------------------------------------


module ctrl     #(parameter WIDTH=32)
(
    input  wire                         clk,
    input  wire                         rst_n,
   
    // stall request--------------------------------------
    input  wire                         stall_req_if,
    input  wire                         stall_req_id,
    input  wire                         stall_req_ex,
    input  wire                         stall_req_mem,

    // mem------------------------------------------------
    input  wire     [WIDTH-1:0]         pc,
    input  wire     [WIDTH-1:0]         inst,
    input  wire     [WIDTH-1:0]         exception,

    // if-------------------------------------------------
    input  wire     [WIDTH-1:0]         if_pc,

    // csr------------------------------------------------
    input  wire                         mstatus_mie,

    input  wire                         mie_sw,
    input  wire                         mie_timer,
    input  wire                         mie_external,

    input  wire     [WIDTH-1:0]         mtvec,

    input  wire     [WIDTH-1:0]         epc,

    input  wire                         mip_sw,
    input  wire                         mip_timer,
    input  wire                         mip_external,

    // to csr---------------------------------------------
    output reg                          mstatus_mie_set_out,
    output reg                          mstatus_mie_clear_out,

    output reg                          mepc_update_out,
    output wire     [WIDTH-1:0]         mepc_out,

    output reg                          mtval_update_out,
    output reg      [WIDTH-1:0]         mtval_out,

    output reg                          trap_type_out,      // 'b1 interrrupt, 1'b0 exception
    output reg                          mcause_update_out,
    output reg      [3:0]               mcause_out,


    // ctrl out-------------------------------------------
    output reg      [4:0]               ctrl_stall_out,
    output reg                          ctrl_pc_re_out,
    output reg                          ctrl_flush_out,
    output reg      [WIDTH-1:0]         ctrl_next_pc_out

);

//-----------------------------------------------------------------------------------------
// stall control
//-----------------------------------------------------------------------------------------
always @(*) begin
    if(!rst_n) begin
        ctrl_stall_out  = 5'd0;
    end
    else if(stall_req_if) begin
        ctrl_stall_out  = 5'b00011;
    end
    else if(stall_req_id) begin
        ctrl_stall_out  = 5'b00111;
    end
    else if(stall_req_ex) begin
        ctrl_stall_out  = 5'b01111;
    end
    else if(stall_req_mem) begin
        ctrl_stall_out  = 5'b11111;
    end
    else begin
        ctrl_stall_out  = 5'b00000;
    end
end


//-----------------------------------------------------------------------------------------
// exception
// exception = {25'b0 ,misaligned_load, misaligned_store, illegal_inst, misaligned_inst, ebreak, ecall, mret}
//-----------------------------------------------------------------------------------------

wire    mret                = exception[0];
wire    ecall               = exception[1];
wire    ebreak              = exception[2];
wire    misaligned_inst     = exception[3];
wire    illegal_inst        = exception[4];
wire    misaligned_store    = exception[5];
wire    misaligned_load     = exception[6];


wire    exception_taken     = mret || misaligned_inst || illegal_inst || misaligned_load || misaligned_store;

//-----------------------------------------------------------------------------------------
// interrupt
//-----------------------------------------------------------------------------------------
// interrupt enable & pending
wire    ip_sw       = mie_sw & mip_sw;
wire    ip_timer    = mie_timer & mip_timer;
wire    ip_external = mie_external & mip_external;

wire    interrupt_taken = mstatus_mie & (ip_sw | ip_timer | ip_external);

assign  mepc_out    = if_pc;

// trap
wire    trap_taken      = exception_taken | interrupt_taken;

//-----------------------------------------------------------------------------------------
// mtvec
// base: mtvec[31:2]
// mode: mtvec[1:0]
// Value    Name        Description 
//   0     Direct     All traps set pc to BASE. 
//   1    Vectored    Asynchronous interrupts set pc to BASE+4×cause, exceptions set pc to BASE.
//-----------------------------------------------------------------------------------------
wire    [1:0]           mtvec_mode  = mtvec[1:0];
wire    [WIDTH-1:2]     mtvec_base  = mtvec[WIDTH-1:2];

wire    [WIDTH-1:0]     vectored_addr   = trap_type_out ? {mtvec_base,2'b00} + {26'b0, mcause_out, 2'b00}
                                        : {mtvec_base, 2'b00};
wire    [WIDTH-1:0]     trap_addr       = mtvec_mode[0] ? {mtvec_base, 2'b00} : vectored_addr;



// fsm
reg     [1:0]   state;
reg     [1:0]   state_next;

localparam IDLE         = 2'b00;
localparam OPERATING    = 2'b01;
localparam TRAP         = 2'b10;
localparam RETURN       = 2'b11;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state       <= IDLE;
    end
    else begin
        state       <= state_next;
    end
end

always @(*) begin
    case(state)
        IDLE: begin
            state_next      <= OPERATING;
        end
        OPERATING: begin
            if(trap_taken) begin
                state_next  <= TRAP;
            end
            else if(mret) begin
                state_next  <= RETURN;
            end
            else begin
                state_next  <= OPERATING;
            end
        end
        TRAP: begin
            state_next      <= OPERATING;
        end
        RETURN: begin
            state_next      <= OPERATING;
        end
        default: begin
            state_next      <= OPERATING;
        end
    endcase
end

always @(*) begin
    ctrl_flush_out           = 1'b0;
    ctrl_next_pc_out         = 'd0;
    ctrl_pc_re_out           = 1'b0;
           
    mepc_update_out          = 1'b0;
    mcause_update_out        = 1'b0;
    mstatus_mie_set_out      = 1'b0;
    mstatus_mie_clear_out    = 1'b0;
    case(state)
        IDLE: begin
           ctrl_flush_out           = 1'b0;
           ctrl_next_pc_out         = 'd0;
           ctrl_pc_re_out           = 1'b0;
           
           mepc_update_out          = 1'b0;
           mcause_update_out        = 1'b0;
           mstatus_mie_set_out      = 1'b0;
           mstatus_mie_clear_out    = 1'b0;
        end
        OPERATING: begin
            ctrl_flush_out           = 1'b0;
            ctrl_next_pc_out         = 'd0;
            ctrl_pc_re_out           = 1'b0;
            
            mepc_update_out          = 1'b0;
            mcause_update_out        = 1'b0;
            mstatus_mie_set_out      = 1'b0;
            mstatus_mie_clear_out    = 1'b0;
        end
        TRAP: begin
            if(interrupt_taken) begin
                ctrl_flush_out  = 1'b0;
                ctrl_pc_re_out  = 1'b1;
            end
            else begin                      // if exception, flush the pipeline
                ctrl_flush_out  = 1'b1;
                ctrl_pc_re_out  = 1'b0;
            end
            ctrl_next_pc_out        = trap_addr;
            mepc_update_out         = 1'b1;     // update current pc
            mcause_update_out       = 1'b1;     // update trap cause
            mstatus_mie_clear_out   = 1'b1;     // clear mie, disable interrupt when trap
            mstatus_mie_set_out     = 1'b0;
        end
        RETURN: begin
            ctrl_flush_out          = 1'b1;     // flush pipeline
            ctrl_pc_re_out          = 1'b0;
            ctrl_next_pc_out        = epc;      // return pc to location before trap happen

            mepc_update_out         = 1'b0;
            mcause_update_out       = 1'b0;
            mstatus_mie_clear_out   = 1'b0;
            mstatus_mie_set_out     = 1'b1;     // enable interrupt after trap return
         
        end
        default: begin

        end
    endcase
end



//-----------------------------------------------------------------------------------------
// update mcause and mtval
// The Exception Code field contains a code identifying the last exception or interrupt.
// exception codes: mcause[3:0]
// Interrupt    Exception Code                  Description
//    1               3                 Machine software interrupt
//    1               7                 Machine timer interrupt   
//    1               11                Machine external interrupt   
//    0               0                 Instruction address misaligned
//    0               2                 Illegal instruction
//    0               3                 Breakpoint   
//    0               4                 Load address misaligned
//    0               6                 Store/AMO address misaligned
//    0               11                Environment call from M-mode
//-----------------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mcause_out          <= 4'd0;
        trap_type_out       <= 1'b0;
        mtval_update_out    <= 1'b0;
        mtval_out           <= 'd0;
    end
    // interrupt
    else if(state==OPERATING) begin
        if(mstatus_mie & ip_sw) begin
            trap_type_out   <= 1'b1;
            mcause_out      <= 4'd3;
        end
        else if(mstatus_mie & ip_timer) begin
            trap_type_out   <= 1'b1;
            mcause_out      <= 4'd7;
        end
        else if(mstatus_mie & ip_external) begin
            trap_type_out   <= 1'b1;
            mcause_out      <= 4'd11;
        end

        // exception
        else if(misaligned_inst) begin
            trap_type_out       <= 1'b0;
            mcause_out          <= 4'd0;

            mtval_update_out    <= 1'b1;
            mtval_out           <= pc;
        end
        else if(illegal_inst) begin
            trap_type_out       <= 1'b0;
            mcause_out          <= 4'd2;

            mtval_update_out    <= 1'b1;
            mtval_out           <= inst;
        end
        else if(ebreak) begin
            trap_type_out       <= 1'b0;
            mcause_out          <= 4'd3;

            mtval_update_out    <= 1'b1;
            mtval_out           <= pc;
        end
        else if(misaligned_load) begin
            trap_type_out       <= 1'b0;
            mcause_out          <= 4'd4;

            mtval_update_out    <= 1'b1;
            mtval_out           <= pc;
        end
        else if(misaligned_store) begin
            trap_type_out       <= 1'b0;
            mcause_out          <= 4'd6;

            mtval_update_out    <= 1'b1;
            mtval_out           <= pc;
        end
        else if(ecall) begin
            trap_type_out       <= 1'b0;
            mcause_out          <= 4'd11;

        end
    end
end


endmodule