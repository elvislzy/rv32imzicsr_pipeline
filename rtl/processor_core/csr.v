// -----------------------------------------------------------------
// Filename: csr.v                                             
// 
// Company: 
// Description:                                                     
// 
// 
//                                                                  
// Author: Elvis.Lu<lzyelvis@gmail.com>                            
// Create Date: 04/10/2022                                           
// Comments:                                                        
// 
// -----------------------------------------------------------------


module csr  #(parameter WIDTH=32)
(
    input  wire                     clk,
    input  wire                     rst_n,

    // ex
    input  wire     [11:0]          csr_raddr,
    output reg      [WIDTH-1:0]     csr_rdata,

    // wb
    input  wire                     csr_we,
    input  wire     [11:0]          csr_waddr,
    input  wire     [WIDTH-1:0]     csr_wdata,
    
    input  wire                     inst_processed,

    // interrupt request
    input  wire                     irq_sw,
    input  wire                     irq_timer,
    input  wire                     irq_external,

    // ctrl
    input  wire                     mstatus_mie_set,
    input  wire                     mstatus_mie_clear,

    input  wire     [WIDTH-1:0]     mepc_in,
    input  wire                     mepc_update,

    input  wire     [WIDTH-1:0]     mtval_in,
    input  wire                     mtval_update,

    input  wire                     trap_type,          // 1'b1 interrrupt, 1'b0 exception
    input  wire     [3:0]           mcause_in,          // 0-15 bit value, other reserved 
    input  wire                     mcause_update,

    
    output reg                      mstatus_mie,

    output reg                      mie_sw,
    output reg                      mie_timer,
    output reg                      mie_external,

    output reg      [WIDTH-1:0]     mtvec,

    output reg      [WIDTH-1:0]     mepc,

    output reg                      mip_sw,
    output reg                      mip_timer,
    output reg                      mip_external
    
);

// define csr addr
localparam CSR_MVENDORID_ADDR       = 12'hF1;
localparam CSR_MARCHID_ADDR         = 12'hF12;
localparam CSR_MIMPID_ADDR          = 12'hF13;
localparam CSR_MHARTID_ADDR         = 12'hF14;
localparam CSR_MSTATUS_ADDR         = 12'h300;
localparam CSR_MISA_ADDR            = 12'h301;
localparam CSR_MIE_ADDR             = 12'h304;
localparam CSR_MTVEC_ADDR           = 12'h305;
localparam CSR_MSCRATCH_ADDR        = 12'h340;
localparam CSR_MEPC_ADDR            = 12'h341;
localparam CSR_MCAUSE_ADDR          = 12'h342;
localparam CSR_MTVAL_ADDR           = 12'h343;
localparam CSR_MIP_ADDR             = 12'h344;
localparam CSR_CYCLE_ADDR           = 12'hc00;
localparam CSR_CYCLEH_ADDR          = 12'hc80;
localparam CSR_MCYCLE_ADDR          = 12'hB00;
localparam CSR_MCYCLEH_ADDR         = 12'hB80;
localparam CSR_MINSTRET_ADDR        = 12'hB02;
localparam CSR_MINSTRETH_ADDR       = 12'hB82;


// define csr value
localparam CSR_MVENDORID    = 32'b0;
localparam CSR_MARCHID      = 32'b0;
localparam CSR_MIMPID       = 32'b0;
localparam CSR_MHARTID      = 32'b0;
//MISA: [31:30]mxl 2'b01(32 bit), [12]int mul/div, [8]RV32/64/128I
localparam CSR_MISA         = {2'b01,4'b0,26'b00_0000_0000_0001_0001_0000_0000}; 

////////////////////////////////////////////////////////////////////////////////
// csr update
////////////////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------------------------
// mstatus
//-----------------------------------------------------------------------------------------
wire     [WIDTH-1:0]    mstatus;
reg                     mstatus_mpie;

// two-level stack of interrupt-enable bits(mpie, mie)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mstatus_mie     <= 1'b0;
        mstatus_mpie    <= 1'b1;
    end
    else if((csr_waddr==CSR_MSTATUS_ADDR) && csr_we) begin
        mstatus_mie     <= csr_wdata[3];
        mstatus_mpie    <= csr_wdata[7];
    end
    else if(mstatus_mie_clear) begin
        mstatus_mpie    <= mstatus_mie;
        mstatus_mie     <= 1'b0;
    end
    else if(mstatus_mie_set) begin
        mstatus_mie     <= mstatus_mpie;
        mstatus_mpie    <= 1'b1;
    end
end

// mstatus 32 bits: [12:11]MPP(2'b11), [7]MPIE, [3]MIE
assign mstatus  = {19'b0, 2'b11, 3'b0, mstatus_mpie, 3'b0, mstatus_mie, 3'b0};

//-----------------------------------------------------------------------------------------
// mie
// read/write register containing interrupt enable bits.
//-----------------------------------------------------------------------------------------
wire    [WIDTH-1:0] mie;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mie_sw          <= 1'b0;
        mie_timer       <= 1'b0;
        mie_external    <= 1'b0;
    end
    else if((csr_waddr==CSR_MIE_ADDR) && csr_we) begin
        mie_sw          <= csr_wdata[3];
        mie_timer       <= csr_wdata[7];
        mie_external    <= csr_wdata[11];
    end
end

// mie 32 bits: [11]MEIE, [7]MTIE, [3]MSIE
assign mie = {20'b0, mie_external, 3'b0, mie_timer, 3'b0, mie_sw, 3'b0};

//------------------------------------------------------------------------------------------
// mtvec
// base addr + mode
// (1) Direct mode(![0]): all traps cause the pc to be set to the address in the BASE field
// (2) Vector mode([0]) : exceptions pc --> BASE, interrrupts pc --> BASE + 4x cause number
//------------------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mtvec       <= 32'h0000_0001;   // vector mode 
    end
    else if((csr_waddr==CSR_MTVEC_ADDR) && csr_we) begin
        mtvec       <= csr_wdata;
    end
end

//------------------------------------------------------------------------------------------
// mscratch
// used to hold a pointer to a machine-mode hart-local context space 
// and swapped with a user register upon entry to an M-mode trap handler.
//------------------------------------------------------------------------------------------
reg     [WIDTH-1:0] mscratch;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mscratch        <= 32'd0;
    end
    else if((csr_waddr==CSR_MSCRATCH_ADDR) && csr_we) begin
        mscratch        <= csr_wdata;
    end
end

//------------------------------------------------------------------------------------------
// mepc
// Implementation support only IALIGN=32, the two low bits (mepc[1:0]) are always zero.
//------------------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mepc        <= 32'd0;
    end
    else if(mepc_update) begin
        mepc        <= {mepc_in[31:2], 2'b00};
    end
    else if((csr_waddr==CSR_MEPC_ADDR) && csr_we) begin
        mepc        <= {csr_wdata[31:2], 2'b00};
    end    
end

//------------------------------------------------------------------------------------------
// mcause
// When a trap is taken into M-mode, 
// mcause is written with a code indicating the event that caused the trap.
//------------------------------------------------------------------------------------------
reg    [WIDTH-1:0]     mcause;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mcause      <= 32'd0;
    end
    else if(mcause_update) begin
        mcause      <= {trap_type, 27'b0, mcause_in}; // [31]interrupt/exception bit, [3:0] cause number
    end
    else if((csr_waddr==CSR_MCAUSE_ADDR) && csr_we) begin
        mcause      <= csr_wdata;
    end
end

//------------------------------------------------------------------------------------------
// mtval
// When a trap is taken into M-mode, 
// mtval is either set to zero or written with exception-specific information 
// to assist software in handling the trap.
//------------------------------------------------------------------------------------------
reg     [WIDTH-1:0]     mtval;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mtval       <= 32'd0;
    end
    else if(mtval_update) begin
        mtval       <= mtval_in;
    end
    else if((csr_waddr==CSR_MTVAL_ADDR) && csr_we) begin
        mtval       <= csr_wdata;
    end
end

//------------------------------------------------------------------------------------------
// mip
// read/write register containing information on pending interrupts
//------------------------------------------------------------------------------------------
wire    [WIDTH-1:0] mip;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mip_sw          <= 1'b0;
        mip_timer       <= 1'b0;
        mip_external    <= 1'b0;
    end
    else begin
        mip_sw          <= irq_sw;
        mip_timer       <= irq_timer;
        mip_external    <= irq_external;
    end
end

// mip 32 bits: [11]MEIE, [7]MTIE, [3]MSIE
assign mip = {20'b0, mip_external, 3'b0, mip_timer, 3'b0, mip_sw, 3'b0};

//------------------------------------------------------------------------------------------
// mcycle
// counts the number of clock cycles executed by the processor core on which the hart is running.
// 64-bit
//------------------------------------------------------------------------------------------
reg     [2*WIDTH-1:0]   mcycle;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mcycle      <= 'd0;
    end
    else begin
        mcycle      <= mcycle + 1'b1;
    end
end


//------------------------------------------------------------------------------------------
// minstret
// counts the number of instructions the hart has retired.
// 64-bit
//------------------------------------------------------------------------------------------
reg     [2*WIDTH-1:0]   minstret;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        minstret    <= 'd0;
    end
    else if(inst_processed) begin
        minstret    <= minstret + 1'b1;
    end
end



////////////////////////////////////////////////////////////////////////////////
// csr read
////////////////////////////////////////////////////////////////////////////////

always @(*) begin
    // data bypass
    if((csr_waddr==csr_raddr) && csr_we) begin
        csr_rdata   = csr_wdata;
    end
    else begin
        case(csr_raddr)
            CSR_MVENDORID_ADDR:
                csr_rdata   = CSR_MVENDORID;
            CSR_MARCHID_ADDR:
                csr_rdata   = CSR_MARCHID;
            CSR_MIMPID_ADDR:
                csr_rdata   = CSR_MIMPID;
            CSR_MHARTID_ADDR:
                csr_rdata   = CSR_MHARTID;
            CSR_MISA_ADDR:
                csr_rdata   = CSR_MISA;
            CSR_MIE_ADDR:
                csr_rdata   = mie;
            CSR_MTVEC_ADDR:
                csr_rdata   = mtvec;
            CSR_MSCRATCH_ADDR:
                csr_rdata   = mscratch;
            CSR_MEPC_ADDR:
                csr_rdata   = mepc;
            CSR_MCAUSE_ADDR:
                csr_rdata   = mcause;
            CSR_MTVAL_ADDR:
                csr_rdata   = mtval;
            CSR_MIP_ADDR:
                csr_rdata   = mip;
            CSR_MCYCLE_ADDR, CSR_CYCLE_ADDR:
                csr_rdata   = mcycle[WIDTH-1:0];
            CSR_MCYCLEH_ADDR, CSR_CYCLEH_ADDR:
                csr_rdata   = mcycle[2*WIDTH-1:WIDTH];
            CSR_MINSTRET_ADDR:
                csr_rdata   = minstret[WIDTH-1:0];
            CSR_MINSTRETH_ADDR:
                csr_rdata   = minstret[2*WIDTH-1:WIDTH];
            default:
                csr_rdata   =   'd0;
        endcase
    end
end


endmodule