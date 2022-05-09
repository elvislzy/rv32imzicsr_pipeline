`timescale 1ns / 1ps
//`timescale 100ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/08 01:58:32
// Design Name: 
// Module Name: Jtype_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Jtype_tb;

parameter f = 500;                   //Mhz
parameter PERIOD = 1/(f*0.001);

reg clk = 0;
reg rst_n = 0;

soc_top  processor (
    .clk                     ( clk     ),
    .rst_n                   ( rst_n   )
);

wire        core_clk = processor.u_core_top.clk;
wire        core_rstn= processor.u_core_top.rst_n;

wire [31:0] rom_d = processor.rom_data;
wire [31:0] rom_addr = processor.rom_addr;
wire [31:0] ram_d = processor.ram_data;

wire [31:0] dout_ram = processor.core_ram_data;
wire [31:0] ram_addr = processor.ram_addr;
wire [3:0]  ram_sel = processor.ram_sel;
wire        ram_ce  = processor.ram_ce;
wire        ram_we  = processor.ram_we;

// if
wire [31:0] if_pc = processor.u_core_top.if_pc;
wire [31:0] if_inst = processor.u_core_top.rom_data; 
wire [31:0] branch_pc = processor.u_core_top.branch_predict_pc;

// if_id
// wire [31:0] ifid_inst_in = processor.u_core_top.u_if_id.inst;
wire [31:0] ifid_inst = processor.u_core_top.u_if_id.inst_out;

// id


// id_ex
wire [31:0] idex_inst = processor.u_core_top.u_id_ex.inst_out;

// ex
wire [5:0]  ex_decode = processor.u_core_top.u_ex.inst_decode;
wire [3:0]  ex_aluop = processor.u_core_top.u_ex.aluop;
wire [31:0] ex_rs1  = processor.u_core_top.u_ex.rs1_data;
wire [31:0] ex_rs2  = processor.u_core_top.u_ex.rs2_data;
wire [31:0] op1 = processor.u_core_top.u_ex.operand1; 
wire [31:0] op2 = processor.u_core_top.u_ex.operand2; 
wire [31:0] ex_rd_data = processor.u_core_top.ex_rd_wdata; 

// mem
wire [31:0] mem_rd_data = processor.u_core_top.u_mem.rd_wdata_out;

// wb
wire [31:0] r0 = processor.u_core_top.u_regfile.regfile[0]; 
wire [31:0] r1 = processor.u_core_top.u_regfile.regfile[1]; 
wire [31:0] r2 = processor.u_core_top.u_regfile.regfile[2];  
wire [31:0] r3 = processor.u_core_top.u_regfile.regfile[3]; 
wire [31:0] r4 = processor.u_core_top.u_regfile.regfile[4]; 
wire [31:0] r5 = processor.u_core_top.u_regfile.regfile[5]; 
wire [31:0] r6 = processor.u_core_top.u_regfile.regfile[6];  
wire [31:0] r7 = processor.u_core_top.u_regfile.regfile[7]; 
wire [31:0] r8 = processor.u_core_top.u_regfile.regfile[8]; 
wire [31:0] r9 = processor.u_core_top.u_regfile.regfile[9]; 
wire [31:0] r10 = processor.u_core_top.u_regfile.regfile[10]; 
wire [31:0] r11 = processor.u_core_top.u_regfile.regfile[11];  
wire [31:0] r12 = processor.u_core_top.u_regfile.regfile[12]; 



//Rst
initial begin
    #5 
    rst_n = 1;
end 

//clk
initial begin
    forever #(PERIOD/2)  clk=~clk;
end

integer i,k=0;

initial begin
    for(i=0;i<1024;i=i+1) begin
        processor.u_rom.rom_mem[i] = 32'h00000073;
    end
end

initial begin
    for(k=0;k<2048;k=k+1) begin
        processor.u_ram.ram_mem[k] = 32'd0;
    end
end



//Data Memory Initialisation
reg [31:0] data0 = 32'b1;
reg [31:0] data1 = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
reg [31:0] data2 = 32'h0000_0024;

initial begin
    #1;
    processor.u_ram.ram_mem[0] = data0;
    processor.u_ram.ram_mem[1] = data1;
    processor.u_ram.ram_mem[2] = data2; 
end


//Instruction Memory Initialisation
parameter [31:0] operand1 = 32'b000000110010;
parameter [31:0] operand2 = 32'b000000010100;
parameter [20:0] jimm = 21'b0000000010000;         //+16
parameter [31:0] imm = 32'h1000_0000;
parameter [11:0] simm = 12'd12;

initial begin
    #1;
    //initial
    //lui test
    processor.u_rom.rom_mem[0] = {32'b10000000000000000000_00001_0110111};           // lui  x1, 0x80000000
    //load data from data memory to registor file
    //load test
    processor.u_rom.rom_mem[1] = {32'b000000000000_00000_010_00010_0000011};       // lw x2,x0(0) data memory address start at 0x80000000
    processor.u_rom.rom_mem[2] = {32'b000000000100_00000_010_00011_0000011};       // lw x3,x0(4)
    processor.u_rom.rom_mem[3] = {32'b000000001000_00000_010_00100_0000011};       // lw x4,x0(8)
    
    //r1 0x8000_0000
    //r2 0x0000_0001
    //r3 0xffff_ffff
    //r4 0x0100_0024

    //Jtype test
    processor.u_rom.rom_mem[4] = {{jimm[20],jimm[10:1],jimm[11],jimm[19:12]},12'b00101_1101111};       // jal  x5,16       [4]to[8]    (pc+16=0x0000_0010+16=0x0000_0020)
    processor.u_rom.rom_mem[8] = {jimm[11:0],20'b00100_000_00110_1100111};                             // jalr x6,x4,16    [8]to[13]   (rs1+16=0x0000_0024+16=0x0000_0034)

    processor.u_rom.rom_mem[13] = {imm[31:12],12'b00111_0010111};                                      // auipc x7,imm     ($7 = pc+{imm[31:12], 12'b0})
    processor.u_rom.rom_mem[14] = {32'b000000000001_00000_000_01000_0010011};                          // addi x8,x0,1   
    processor.u_rom.rom_mem[15] = {simm[11:5],13'b01000_00000_010,simm[4:0],7'b0100011};               // sw x8,x0(12)
end


//Verify
initial begin   
    #50;
    if(r5 != 32'h00000010 + 32'h4 )                 $fatal("Test case 'jal' failed");    // $5 == pc+4  = 32'h0000_0014
    if(r6 != 32'h00000020 + 32'h4 )                 $fatal("Test case 'jalr' failed");   // $6 == pc+4  = 32'h0000_0024
    if(r7 != 32'h00000034 + {imm[31:12], 12'b0})    $fatal("Test case 'auipc' failed");  // $7 == pc+imm= 32'h1000_0034
    if(processor.u_ram.ram_mem[3] != 32'd1)         $fatal("Test case 'sw' failed"); 
    #10;
    $display("Jump Test case passed");
    $finish;
end

//Monitor
// initial begin
//     $monitor ("R5: %4d, R6: %4d, R7: %4d", processor.regfile.regfile[5], processor.regfile.regfile[6], processor.regfile.regfile[7]); 
    
// end
initial begin
    $monitor ("D0: %4d, D1: %4d, D1: %4d, D3: %4d", processor.u_ram.ram_mem[0], processor.u_ram.ram_mem[1], processor.u_ram.ram_mem[2], processor.u_ram.ram_mem[3]); 
end

endmodule
    
