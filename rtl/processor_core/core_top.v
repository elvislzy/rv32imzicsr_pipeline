// -----------------------------------------------------------------
// Filename: core_top.v                                             
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


module core_top    #(parameter WIDTH=32)
(
    input  wire                         clk,
    input  wire                         rst_n,

    // rom
    input  wire     [WIDTH-1:0]         rom_data,
    output wire     [WIDTH-1:0]         rom_addr,
    // output wire                         rom_ce,

    // ram
    input  wire     [WIDTH-1:0]         ram_data_in,
    output wire     [WIDTH-1:0]         ram_data_out,
    output wire     [WIDTH-1:0]         ram_addr,
    output wire                         ram_ce,
    output wire     [3:0]               ram_sel,
    output wire                         ram_we,

    // interrupt
    input  wire                         irq_sw,
    input  wire                         irq_timer,
    input  wire                         irq_external

);

// if
wire    [WIDTH-1:0] if_pc;          
wire                if_branch_pc_re;


// branch
wire    [WIDTH-1:0] branch_predict_pc;
wire                branch_taken;     


// if_id
wire    [WIDTH-1:0] if_id_pc;                
wire    [WIDTH-1:0] if_id_inst;              
wire    [WIDTH-1:0] if_id_branch_predict_pc; 
wire                if_id_branch_taken;      
wire                if_id_branch_pc_re;      


// id
wire                id_rs1_re;           
wire                id_rs2_re;           
wire    [4:0]       id_rs1_raddr;        
wire    [4:0]       id_rs2_raddr;        
wire    [WIDTH-1:0] id_pc;               
wire    [WIDTH-1:0] id_inst;             
wire    [WIDTH-1:0] id_imm;              
wire                id_csr_we;           
wire    [11:0]      id_csr_addr;         
wire    [WIDTH-1:0] id_rs1_data;        
wire    [WIDTH-1:0] id_rs2_data;        
wire                id_rd_we;            
wire    [4:0]       id_rd_waddr;         
wire    [5:0]       id_inst_decode;      
wire    [3:0]       id_aluop;            
wire    [2:0]       id_result_sel;       
wire    [WIDTH-1:0] id_branch_predict_pc;
wire                id_branch_taken;     
wire                id_branch_pc_re;     
wire    [WIDTH-1:0] id_exception;        
wire                id_stall_req;        


// id_ex
wire    [WIDTH-1:0] id_ex_pc;               
wire    [WIDTH-1:0] id_ex_inst;             
wire    [WIDTH-1:0] id_ex_imm;              
wire                id_ex_csr_we;           
wire    [11:0]      id_ex_csr_addr;         
wire    [WIDTH-1:0] id_ex_rs1_data;         
wire    [WIDTH-1:0] id_ex_rs2_data;         
wire                id_ex_rd_we;            
wire    [4:0]       id_ex_rd_waddr;          
wire    [5:0]       id_ex_inst_decode;      
wire    [3:0]       id_ex_aluop;            
wire    [2:0]       id_ex_result_sel;       
wire    [WIDTH-1:0] id_ex_branch_predict_pc;
wire                id_ex_branch_taken;     
wire                id_ex_branch_pc_re;     
wire    [WIDTH-1:0] id_ex_exception;        


// ex
wire    [11:0]      ex_csr_raddr;     
wire                ex_csr_we;        
wire    [11:0]      ex_csr_waddr;     
wire    [WIDTH-1:0] ex_csr_wdata;     
wire                ex_branch_req;    
wire                ex_branch_taken;  
wire                ex_branch_jump;   
wire                ex_branch_call;   
wire                ex_branch_ret;    
wire    [WIDTH-1:0] ex_branch_next_pc;
wire                ex_branch_miss;   
wire    [WIDTH-1:0] ex_branch_miss_pc;
wire                ex_branch_pc_re; 
wire                ex_branch_tag; 
wire    [WIDTH-1:0] ex_pc;            
wire    [WIDTH-1:0] ex_inst;          
wire                ex_rd_we;         
wire    [4:0]       ex_rd_waddr;       
wire    [WIDTH-1:0] ex_rd_wdata;      
wire    [5:0]       ex_inst_decode;   
wire    [WIDTH-1:0] ex_mem_addr;      
wire    [WIDTH-1:0] ex_mem_wdata;     
wire                ex_stall_req;     
wire    [WIDTH-1:0] ex_exception;     


// ex_mem
wire    [WIDTH-1:0] ex_mem_pc;         
wire    [WIDTH-1:0] ex_mem_inst;       
wire    [5:0]       ex_mem_inst_decode;
wire                ex_mem_rd_we;      
wire    [4:0]       ex_mem_rd_waddr;    
wire    [WIDTH-1:0] ex_mem_rd_wdata;   
wire    [WIDTH-1:0] ex_mem_mem_addr;   
wire    [WIDTH-1:0] ex_mem_mem_wdata;  
wire                ex_mem_csr_we;     
wire    [11:0]      ex_mem_csr_waddr;  
wire    [WIDTH-1:0] ex_mem_csr_wdata;  
wire    [WIDTH-1:0] ex_mem_exception; 


// mem
wire    [WIDTH-1:0] mem_addr;     
wire                mem_we;       
wire    [3:0]       mem_sel;      
wire    [WIDTH-1:0] mem_wdata;    
wire                mem_ce;       
wire                mem_rd_we;    
wire    [4:0]       mem_rd_waddr;  
wire    [WIDTH-1:0] mem_rd_wdata; 
wire                mem_csr_we;   
wire    [11:0]      mem_csr_waddr;
wire    [WIDTH-1:0] mem_csr_wdata;
wire    [WIDTH-1:0] mem_pc;       
wire    [WIDTH-1:0] mem_inst;     
wire    [WIDTH-1:0] mem_exception;


// mem_wb
wire                mem_wb_rd_we;         
wire    [4:0]       mem_wb_rd_waddr;       
wire    [WIDTH-1:0] mem_wb_rd_wdata;      
wire                mem_wb_csr_we;        
wire    [11:0]      mem_wb_csr_waddr;     
wire    [WIDTH-1:0] mem_wb_csr_wdata;     
wire                mem_wb_inst_processed;


// ctrl
wire                ctrl_mstatus_mie_set;  
wire                ctrl_mstatus_mie_clear;
wire                ctrl_mepc_update;      
wire    [WIDTH-1:0] ctrl_mepc;             
wire                ctrl_mtval_update;     
wire    [WIDTH-1:0] ctrl_mtval;            
wire                ctrl_trap_type;        
wire                ctrl_mcause_update;    
wire    [3:0]       ctrl_mcause;           
wire    [4:0]       ctrl_stall;            
wire                ctrl_pc_re;            
wire                ctrl_flush;            
wire    [WIDTH-1:0] ctrl_next_pc;          


// csr
wire    [WIDTH-1:0] csr_rdata;       
wire                csr_mstatus_mie; 
wire                csr_mie_sw;      
wire                csr_mie_timer;   
wire                csr_mie_external;
wire    [WIDTH-1:0] csr_mtvec;       
wire    [WIDTH-1:0] csr_mepc;        
wire                csr_mip_sw;      
wire                csr_mip_timer;   
wire                csr_mip_external;

// regfile
wire    [WIDTH-1:0] rs1_data;
wire    [WIDTH-1:0] rs2_data;

// Out
assign  rom_addr        = if_pc;
assign  ram_addr        = mem_addr;
assign  ram_data_out    = mem_wdata;
assign  ram_ce          = mem_ce;
assign  ram_we          = mem_we;
assign  ram_sel         = mem_sel;

//------------------------------------------------------------------
// Instantiate
//------------------------------------------------------------------
if_unit  u_if_unit (
    .clk                     ( clk                            ),
    .rst_n                   ( rst_n                          ),
    .ctrl_stall              ( ctrl_stall                     ),
    .ctrl_pc_re              ( ctrl_pc_re                     ),
    .ctrl_flush              ( ctrl_flush                     ),
    .ctrl_next_pc            ( ctrl_next_pc                   ),
    .branch_predict_pc       ( branch_predict_pc              ),
    .branch_taken            ( branch_taken                   ),
    .branch_miss             ( ex_branch_miss                 ),
    .branch_miss_pc          ( ex_branch_miss_pc              ),

    .pc_out                  ( if_pc                          ),
    .branch_pc_re_out        ( if_branch_pc_re                )
);


branch_predictor #(
    .BTB_ENTRIES ( 32 ),
    .PHT_ENTRIES ( 32 ),
    .RAS_ENTRIES ( 8 ))
 u_branch_predictor (
    .clk                     ( clk                                ),
    .rst_n                   ( rst_n                              ),
    .branch_ex_pc            ( ex_pc                              ),
    .branch_ex_req           ( ex_branch_req                      ),
    .branch_ex_taken         ( ex_branch_taken                    ),
    .branch_ex_jump          ( ex_branch_jump                     ),
    .branch_ex_call          ( ex_branch_call                     ),
    .branch_ex_ret           ( ex_branch_ret                      ),
    .branch_ex_next_pc       ( ex_branch_next_pc                  ),
    .branch_miss             ( ex_branch_miss                     ),
    .pc_in                   ( if_pc                              ),
    .ctrl_stall              ( ctrl_stall                         ),

    .branch_predict_pc_out   ( branch_predict_pc                  ),
    .branch_taken_out        ( branch_taken                       )
);

if_id  u_if_id (
    .clk                     ( clk                                ),
    .rst_n                   ( rst_n                              ),
    .inst                    ( rom_data                           ),
    .pc                      ( if_pc                              ),
    .branch_pc_re            ( if_branch_pc_re                    ),
    .branch_taken            ( branch_taken                       ),
    .branch_predict_pc       ( branch_predict_pc                  ),
    .branch_miss             ( ex_branch_miss                     ),
    .ctrl_stall              ( ctrl_stall                         ),
    .ctrl_flush              ( ctrl_flush                         ),
    .ctrl_pc_re              ( ctrl_pc_re                         ),

    .pc_out                  ( if_id_pc                           ),
    .inst_out                ( if_id_inst                         ),
    .branch_predict_pc_out   ( if_id_branch_predict_pc            ),
    .branch_taken_out        ( if_id_branch_taken                 ),
    .branch_pc_re_out        ( if_id_branch_pc_re                 )
);

id  u_id (
    .rst_n                   ( rst_n                              ),
    .pc_in                   ( if_id_pc                           ),
    .inst_in                 ( if_id_inst                         ),
    .branch_predict_pc       ( if_id_branch_predict_pc            ),
    .branch_taken            ( if_id_branch_taken                 ),
    .branch_pc_re            ( if_id_branch_pc_re                 ),
    .rs1_rdata               ( rs1_data                           ),
    .rs2_rdata               ( rs2_data                           ),
    .branch_miss             ( ex_branch_miss                     ),
    .ex_opcode               ( ex_inst[6:0]                       ),
    .ex_rd_we                ( ex_rd_we                           ),
    .ex_rd_waddr             ( ex_rd_waddr                        ),
    .ex_rd_wdata             ( ex_rd_wdata                        ),
    .mem_rd_we               ( mem_rd_we                          ),
    .mem_rd_waddr            ( mem_rd_waddr                       ),
    .mem_rd_wdata            ( mem_rd_wdata                       ),

    .rs1_re_out              ( id_rs1_re                          ),
    .rs2_re_out              ( id_rs2_re                          ),
    .rs1_raddr_out           ( id_rs1_raddr                       ),
    .rs2_raddr_out           ( id_rs2_raddr                       ),
    .pc_out                  ( id_pc                              ),
    .inst_out                ( id_inst                            ),
    .imm_out                 ( id_imm                             ),
    .csr_we_out              ( id_csr_we                          ),
    .csr_addr_out            ( id_csr_addr                        ),
    .rs1_rdata_out           ( id_rs1_data                        ),
    .rs2_rdata_out           ( id_rs2_data                        ),
    .rd_we_out               ( id_rd_we                           ),
    .rd_waddr_out            ( id_rd_waddr                        ),
    .inst_decode_out         ( id_inst_decode                     ),
    .aluop_out               ( id_aluop                           ),
    .result_sel_out          ( id_result_sel                      ),
    .branch_predict_pc_out   ( id_branch_predict_pc               ),
    .branch_taken_out        ( id_branch_taken                    ),
    .branch_pc_re_out        ( id_branch_pc_re                    ),
    .exception_out           ( id_exception                       ),
    .stall_req_out           ( id_stall_req                       )
);

id_ex  u_id_ex (
    .clk                     ( clk                                ),
    .rst_n                   ( rst_n                              ),
    .pc                      ( id_pc                              ),
    .inst                    ( id_inst                            ),
    .imm                     ( id_imm                             ),
    .csr_we                  ( id_csr_we                          ),
    .csr_addr                ( id_csr_addr                        ),
    .rs1_data                ( id_rs1_data                        ),
    .rs2_data                ( id_rs2_data                        ),
    .rd_we                   ( id_rd_we                           ),
    .rd_addr                 ( id_rd_waddr                        ),
    .inst_decode             ( id_inst_decode                     ),
    .aluop                   ( id_aluop                           ),
    .result_sel              ( id_result_sel                      ),
    .branch_predict_pc       ( id_branch_predict_pc               ),
    .branch_taken            ( id_branch_taken                    ),
    .branch_pc_re            ( id_branch_pc_re                    ),
    .branch_miss             ( ex_branch_miss                     ),
    .exception               ( id_exception                       ),
    .ctrl_stall              ( ctrl_stall                         ),
    .ctrl_flush              ( ctrl_flush                         ),

    .pc_out                  ( id_ex_pc                           ),
    .inst_out                ( id_ex_inst                         ),
    .imm_out                 ( id_ex_imm                          ),
    .csr_we_out              ( id_ex_csr_we                       ),
    .csr_addr_out            ( id_ex_csr_addr                     ),
    .rs1_data_out            ( id_ex_rs1_data                     ),
    .rs2_data_out            ( id_ex_rs2_data                     ),
    .rd_we_out               ( id_ex_rd_we                        ),
    .rd_addr_out             ( id_ex_rd_waddr                     ),
    .inst_decode_out         ( id_ex_inst_decode                  ),
    .aluop_out               ( id_ex_aluop                        ),
    .result_sel_out          ( id_ex_result_sel                   ),
    .branch_predict_pc_out   ( id_ex_branch_predict_pc            ),
    .branch_taken_out        ( id_ex_branch_taken                 ),
    .branch_pc_re_out        ( id_ex_branch_pc_re                 ),
    .exception_out           ( id_ex_exception                    )
);

ex  u_ex (
    .clk                     ( clk                                ),
    .rst_n                   ( rst_n                              ),
    .pc                      ( id_ex_pc                           ),
    .inst                    ( id_ex_inst                         ),
    .imm                     ( id_ex_imm                          ),
    .inst_decode             ( id_ex_inst_decode                  ),
    .aluop                   ( id_ex_aluop                        ),
    .result_sel              ( id_ex_result_sel                   ),
    .rs1_data                ( id_ex_rs1_data                     ),
    .rs2_data                ( id_ex_rs2_data                     ),
    .rd_we                   ( id_ex_rd_we                        ),
    .rd_addr                 ( id_ex_rd_waddr                     ),
    .csr_we                  ( id_ex_csr_we                       ),
    .csr_addr                ( id_ex_csr_addr                     ),
    .branch_predict_pc       ( id_ex_branch_predict_pc            ),
    .branch_taken            ( id_ex_branch_taken                 ),
    .branch_pc_re            ( id_ex_branch_pc_re                 ),
    .exception               ( id_ex_exception                    ),
    .mem_csr_we              ( mem_csr_we                         ),
    .mem_csr_waddr           ( mem_csr_waddr                      ),
    .mem_csr_wdata           ( mem_csr_wdata                      ),
    .wb_csr_we               ( mem_wb_csr_we                      ),
    .wb_csr_waddr            ( mem_wb_csr_waddr                   ),
    .wb_csr_wdata            ( mem_wb_csr_wdata                   ),
    .csr_rdata               ( csr_rdata                          ),

    .csr_raddr_out           ( ex_csr_raddr                       ),
    .csr_we_out              ( ex_csr_we                          ),
    .csr_waddr_out           ( ex_csr_waddr                       ),
    .csr_wdata_out           ( ex_csr_wdata                       ),
    .branch_ex_req_out       ( ex_branch_req                      ),
    .branch_ex_taken_out     ( ex_branch_taken                    ),
    .branch_ex_jump_out      ( ex_branch_jump                     ),
    .branch_ex_call_out      ( ex_branch_call                     ),
    .branch_ex_ret_out       ( ex_branch_ret                      ),
    .branch_ex_next_pc_out   ( ex_branch_next_pc                  ),
    .branch_miss_out         ( ex_branch_miss                     ),
    .branch_miss_pc_out      ( ex_branch_miss_pc                  ),
    .branch_pc_re_out        ( ex_branch_pc_re                    ),
    .branch_tag              ( ex_branch_tag                      ),
    .pc_out                  ( ex_pc                              ),
    .inst_out                ( ex_inst                            ),
    .rd_we_out               ( ex_rd_we                           ),
    .rd_addr_out             ( ex_rd_waddr                        ),
    .rd_wdata_out            ( ex_rd_wdata                        ),
    .inst_decode_out         ( ex_inst_decode                     ),
    .mem_addr_out            ( ex_mem_addr                        ),
    .mem_wdata_out           ( ex_mem_wdata                       ),
    .stall_req_out           ( ex_stall_req                       ),
    .exception_out           ( ex_exception                       )
);


ex_mem  u_ex_mem (
    .clk                     ( clk                          ),
    .rst_n                   ( rst_n                        ),
    .ctrl_stall              ( ctrl_stall                   ),
    .ctrl_flush              ( ctrl_flush                   ),
    .pc                      ( ex_pc                        ),
    .inst                    ( ex_inst                      ),
    .inst_decode             ( ex_inst_decode               ),
    .branch_tag              ( ex_branch_tag                ),
    .branch_pc_re            ( ex_branch_pc_re              ),
    .rd_we                   ( ex_rd_we                     ),
    .rd_addr                 ( ex_rd_waddr                  ),
    .rd_wdata                ( ex_rd_wdata                  ),
    .mem_addr                ( ex_mem_addr                  ),
    .mem_wdata               ( ex_mem_wdata                 ),
    .csr_we                  ( ex_csr_we                    ),
    .csr_waddr               ( ex_csr_waddr                 ),
    .csr_wdata               ( ex_csr_wdata                 ),
    .exception               ( ex_exception                 ),

    .pc_out                  ( ex_mem_pc                    ),
    .inst_out                ( ex_mem_inst                  ),
    .inst_decode_out         ( ex_mem_inst_decode           ),
    .rd_we_out               ( ex_mem_rd_we                 ),
    .rd_addr_out             ( ex_mem_rd_waddr              ),
    .rd_wdata_out            ( ex_mem_rd_wdata              ),
    .mem_addr_out            ( ex_mem_mem_addr              ),
    .mem_wdata_out           ( ex_mem_mem_wdata             ),
    .csr_we_out              ( ex_mem_csr_we                ),
    .csr_waddr_out           ( ex_mem_csr_waddr             ),
    .csr_wdata_out           ( ex_mem_csr_wdata             ),
    .exception_out           ( ex_mem_exception             )
);


mem  u_mem (
    .rst_n                   ( rst_n                      ),
    .pc                      ( ex_mem_pc                  ),
    .inst                    ( ex_mem_inst                ),
    .inst_decode             ( ex_mem_inst_decode         ),
    .rd_we                   ( ex_mem_rd_we               ),
    .rd_addr                 ( ex_mem_rd_waddr            ),
    .rd_wdata                ( ex_mem_rd_wdata            ),
    .mem_addr                ( ex_mem_mem_addr            ),
    .mem_wdata               ( ex_mem_mem_wdata           ),
    .csr_we                  ( ex_mem_csr_we              ),
    .csr_waddr               ( ex_mem_csr_waddr           ),
    .csr_wdata               ( ex_mem_csr_wdata           ),
    .exception               ( ex_mem_exception           ),
    .mem_rdata               ( ram_data_in                ),

    .mem_addr_out            ( mem_addr                   ),
    .mem_we_out              ( mem_we                     ),
    .mem_sel_out             ( mem_sel                    ),
    .mem_wdata_out           ( mem_wdata                  ),
    .mem_ce_out              ( mem_ce                     ),
    .rd_we_out               ( mem_rd_we                  ),
    .rd_addr_out             ( mem_rd_waddr               ),
    .rd_wdata_out            ( mem_rd_wdata               ),
    .csr_we_out              ( mem_csr_we                 ),
    .csr_waddr_out           ( mem_csr_waddr              ),
    .csr_wdata_out           ( mem_csr_wdata              ),
    .pc_out                  ( mem_pc                     ),
    .inst_out                ( mem_inst                   ),
    .exception_out           ( mem_exception              )
);


mem_wb  u_mem_wb (
    .clk                     ( clk                         ),
    .rst_n                   ( rst_n                       ),
    .ctrl_stall              ( ctrl_stall                  ),
    .ctrl_flush              ( ctrl_flush                  ),
    .rd_we                   ( mem_rd_we                   ),
    .rd_addr                 ( mem_rd_waddr                ),
    .rd_wdata                ( mem_rd_wdata                ),
    .csr_we                  ( mem_csr_we                  ),
    .csr_waddr               ( mem_csr_waddr               ),
    .csr_wdata               ( mem_csr_wdata               ),

    .rd_we_out               ( mem_wb_rd_we                ),
    .rd_addr_out             ( mem_wb_rd_waddr             ),
    .rd_wdata_out            ( mem_wb_rd_wdata             ),
    .csr_we_out              ( mem_wb_csr_we               ),
    .csr_waddr_out           ( mem_wb_csr_waddr            ),
    .csr_wdata_out           ( mem_wb_csr_wdata            ),
    .inst_processed          ( mem_wb_inst_processed       )
);



ctrl  u_ctrl (
    .clk                     ( clk                                ),
    .rst_n                   ( rst_n                              ),
    .stall_req_if            ( 1'b0                               ),
    .stall_req_id            ( id_stall_req                       ),
    .stall_req_ex            ( ex_stall_req                       ),
    .stall_req_mem           ( 1'b0                               ),
    .pc                      ( mem_pc                             ),
    .inst                    ( mem_inst                           ),
    .exception               ( mem_exception                      ),
    .if_pc                   ( if_pc                              ),
    .mstatus_mie             ( csr_mstatus_mie                    ),
    .mie_sw                  ( csr_mie_sw                         ),
    .mie_timer               ( csr_mie_timer                      ),
    .mie_external            ( csr_mie_external                   ),
    .mtvec                   ( csr_mtvec                          ),
    .epc                     ( csr_mepc                           ),
    .mip_sw                  ( csr_mip_sw                         ),
    .mip_timer               ( csr_mip_timer                      ),
    .mip_external            ( csr_mip_external                   ),

    .mstatus_mie_set_out     ( ctrl_mstatus_mie_set               ),
    .mstatus_mie_clear_out   ( ctrl_mstatus_mie_clear             ),
    .mepc_update_out         ( ctrl_mepc_update                   ),
    .mepc_out                ( ctrl_mepc                          ),
    .mtval_update_out        ( ctrl_mtval_update                  ),
    .mtval_out               ( ctrl_mtval                         ),
    .trap_type_out           ( ctrl_trap_type                     ),
    .mcause_update_out       ( ctrl_mcause_update                 ),
    .mcause_out              ( ctrl_mcause                        ),
    .ctrl_stall_out          ( ctrl_stall                         ),
    .ctrl_pc_re_out          ( ctrl_pc_re                         ),
    .ctrl_flush_out          ( ctrl_flush                         ),
    .ctrl_next_pc_out        ( ctrl_next_pc                       )
);


csr  u_csr (
    .clk                     ( clk                            ),
    .rst_n                   ( rst_n                          ),
    .csr_raddr               ( ex_csr_raddr                   ),
    .csr_we                  ( mem_wb_csr_we                  ),
    .csr_waddr               ( mem_wb_csr_waddr               ),
    .csr_wdata               ( mem_wb_csr_wdata               ),
    .inst_processed          ( mem_wb_inst_processed          ),
    .irq_sw                  ( irq_sw                         ),
    .irq_timer               ( irq_timer                      ),
    .irq_external            ( irq_external                   ),
    .mstatus_mie_set         ( ctrl_mstatus_mie_set           ),
    .mstatus_mie_clear       ( ctrl_mstatus_mie_clear         ),
    .mepc_in                 ( ctrl_mepc                      ),
    .mepc_update             ( ctrl_mepc_update               ),
    .mtval_in                ( ctrl_mtval                     ),
    .mtval_update            ( ctrl_mtval_update              ),
    .trap_type               ( ctrl_trap_type                 ),
    .mcause_in               ( ctrl_mcause                    ),
    .mcause_update           ( ctrl_mcause_update             ),

    .csr_rdata               ( csr_rdata                      ),
    .mstatus_mie             ( csr_mstatus_mie                ),
    .mie_sw                  ( csr_mie_sw                     ),
    .mie_timer               ( csr_mie_timer                  ),
    .mie_external            ( csr_mie_external               ),
    .mtvec                   ( csr_mtvec                      ),
    .mepc                    ( csr_mepc                       ),
    .mip_sw                  ( csr_mip_sw                     ),
    .mip_timer               ( csr_mip_timer                  ),
    .mip_external            ( csr_mip_external               )
);


regfile  u_regfile (
    .clk                     ( clk                ),
    .rst_n                   ( rst_n              ),
    .rd_we                   ( mem_wb_rd_we       ),
    .rd_addr                 ( mem_wb_rd_waddr    ),
    .rs1_re                  ( id_rs1_re          ),
    .rs1_addr                ( id_rs1_raddr       ),
    .rs2_re                  ( id_rs2_re          ),
    .rs2_addr                ( id_rs2_raddr       ),
    .rd_data_in              ( mem_wb_rd_wdata    ),

    .rs1_data                ( rs1_data           ),
    .rs2_data                ( rs2_data           )
);



endmodule