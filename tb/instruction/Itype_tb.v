`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/03 15:37:10
// Design Name: 
// Module Name: Itype_tb
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


module Itype_tb;
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


//Instruction Memory Initialisation
reg [31:0] operand1 = 32'b000000110010;
reg [31:0] operand2 = 32'b100000010100;
reg [11:0] imm = 11'b000000000011; //3
initial begin
    //initiallize registor value
    processor.u_rom.rom_mem[0] = {operand1[11:0],20'b00001_000_00001_0010011};         // addi x1,x1,50
    processor.u_rom.rom_mem[1] = {operand2[11:0],20'b00001_000_00010_0010011};         // addi x2,x1,-2028
    //I-type insruction
    processor.u_rom.rom_mem[2] = {operand2[11:0],20'b00001_010_00011_0010011};         // slti x3,x1,-2028
    processor.u_rom.rom_mem[3] = {operand2[11:0],20'b00001_011_00100_0010011};         // sltiu x4,x1,-2028
    processor.u_rom.rom_mem[4] = {operand2[11:0],20'b00001_100_00101_0010011};         // xori x5,x1,-2028
    processor.u_rom.rom_mem[5] = {operand2[11:0],20'b00001_110_00110_0010011};         // ori x6,x1,-2028
    processor.u_rom.rom_mem[6] = {operand2[11:0],20'b00001_111_00111_0010011};         // andi x7,x1,-2028
    processor.u_rom.rom_mem[7] = {7'b0000000,imm[4:0],20'b00010_001_01000_0010011};    // slli x8,x2,3
    processor.u_rom.rom_mem[8] = {7'b0000000,imm[4:0],20'b00010_101_01001_0010011};    // srli x9,x2,3
    processor.u_rom.rom_mem[9] = {7'b0100000,imm[4:0],20'b00010_101_01010_0010011};    // srai x10,x2,3

end


//Verify
wire [31:0] signed_op1 = {{20{operand1[11]}},operand1[11:0]};
wire [31:0] signed_op2 = {{20{operand2[11]}},operand2[11:0]};
wire [31:0] sum = signed_op1 + signed_op2;

initial begin   
    #100;
    if(r2 != signed_op1 + signed_op2)                   $fatal("Test case 'addi' failed");
    if(r8 != sum << imm[4:0])                           $fatal("Test case 'slli' failed");
    if(r3 != $signed(signed_op1) < $signed(signed_op2)) $fatal("Test case 'slti' failed");
    if(r4 != signed_op1 < signed_op2)                   $fatal("Test case 'sltiu' failed");
    if(r5 != (signed_op1 ^ signed_op2))                 $fatal("Test case 'xori' failed");
    if(r9 != sum >> imm[4:0])                           $fatal("Test case 'srli' failed");
    if(r10!= sum >>> imm[4:0])                          $fatal("Test case 'srai' failed");
    if(r6 != (signed_op1 | signed_op2))                 $fatal("Test case 'ori' failed");
    if(r7 != (signed_op1 & signed_op2))                 $fatal("Test case 'andi' failed");
    #10
    $display("Itype Test case passed");
    $finish;
end


//Monitor
initial begin
    $monitor ("R1: %4d, R2: %4d, R3: %4d", processor.u_core_top.u_regfile.regfile[1], processor.u_core_top.u_regfile.regfile[2], processor.u_core_top.u_regfile.regfile[3]); 
    
end

endmodule