`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/03 02:21:48
// Design Name: 
// Module Name: add_tb
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

module Rtype_tb;
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

initial begin
    #1;
    processor.u_rom.rom_mem[0] = {operand1[11:0],20'b00001_000_00001_0010011}; // addi x1,x1,50
    processor.u_rom.rom_mem[1] = {operand2[11:0],20'b00010_000_00010_0010011}; // addi x2,x2,-2028
    processor.u_rom.rom_mem[2] = 32'b0000000_00010_00001_000_00011_0110011;    // add x3,x1,x2
    processor.u_rom.rom_mem[3] = 32'b0100000_00010_00001_000_00100_0110011;    // sub x4,x1,x2
    processor.u_rom.rom_mem[4] = 32'b0000000_00010_00001_001_00101_0110011;    // sll x5,x1,x2  
    processor.u_rom.rom_mem[5] = 32'b0000000_00010_00001_010_00110_0110011;    // slt x6,x1,x2  
    processor.u_rom.rom_mem[6] = 32'b0000000_00010_00001_011_00111_0110011;    // sltu x7,x1,x2  
    processor.u_rom.rom_mem[7] = 32'b0000000_00010_00001_100_01000_0110011;    // xor x8,x1,x2 
    processor.u_rom.rom_mem[8] = 32'b0000000_00010_00001_101_01001_0110011;    // srl x9,x1,4 
    processor.u_rom.rom_mem[9] = 32'b0100000_00010_00001_101_01010_0110011;    // sra x10,x1,x2 
    processor.u_rom.rom_mem[10]= 32'b0000000_00010_00001_110_01011_0110011;    // or x11,x1,x2 
    processor.u_rom.rom_mem[11]= 32'b0000000_00010_00001_111_01100_0110011;    // and x12,x1,x2 

end


//Verify
wire [31:0] signed_op1 = {{20{operand1[11]}},operand1[11:0]};
wire [31:0] signed_op2 = {{20{operand2[11]}},operand2[11:0]};

initial begin   
    #100;
    if(r3 != signed_op1 + signed_op2)                       $fatal("Test case 'add' failed");
    if(r4 != signed_op1 - signed_op2)                       $fatal("Test case 'sub' failed");
    if(r5 != signed_op1 << signed_op2[4:0])                 $fatal("Test case 'sll' failed");
    if(r6 != $signed(signed_op1) < $signed(signed_op2))     $fatal("Test case 'slt' failed");
    if(r7 != signed_op1 < signed_op2)                       $fatal("Test case 'sltu' failed");
    if(r8 != (signed_op1 ^ signed_op2))                     $fatal("Test case 'xor' failed");
    if(r9 != signed_op1 >> signed_op2[4:0])                 $fatal("Test case 'srl' failed");
    if(r10!= ($signed(signed_op1)) >>> signed_op2[4:0])     $fatal("Test case 'sra' failed");
    if(r11!= (signed_op1 | signed_op2))                     $fatal("Test case 'or' failed");
    if(r12!= (signed_op1 & signed_op2))                     $fatal("Test case 'and' failed");
    #10;
    $display("Rtype Test case passed");
    $finish;
end


//Monitor
initial begin
    $monitor ("R1: %4d, R2: %4d, R3: %4d", processor.u_core_top.u_regfile.regfile[1], processor.u_core_top.u_regfile.regfile[2], processor.u_core_top.u_regfile.regfile[3]); 
    
end

endmodule