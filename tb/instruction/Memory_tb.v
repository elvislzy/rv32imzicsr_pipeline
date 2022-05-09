`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/16 15:36:38
// Design Name: 
// Module Name: Memory_tb
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


module Memory_tb;
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
reg [31:0] data0 = 32'b0000_1111_0000_0000_0000_0000_1111_1111;     //LB
reg [31:0] data1 = 32'b0000_1111_0000_0000_1111_1111_1111_1111;     //LH    
reg [31:0] data2 = 32'b1000_0000_1111_1111_1111_1111_1111_1111;     //Lw    

initial begin
    #1;
    processor.u_ram.ram_mem[0] = data0;
    processor.u_ram.ram_mem[1] = data1;
    processor.u_ram.ram_mem[2] = data2;
end


//Instruction Memory Initialisation

initial begin
    #1;
    //initial
    //lui test
    processor.u_rom.rom_mem[0] = {32'b10000000000000000000_00001_0110111};           // lui  x1, imm 
    //load data from data memory to registor file
    //load test
    processor.u_rom.rom_mem[1] = {32'b000000000000_00000_000_00010_0000011};       // lb   x2,x0(0) data memory address start at 0x00000000
    processor.u_rom.rom_mem[2] = {32'b000000000000_00000_100_00011_0000011};       // lbu  x3,x0(0) 
    processor.u_rom.rom_mem[3] = {32'b000000000100_00000_001_00100_0000011};       // lh   x4,x0(4) 
    processor.u_rom.rom_mem[4] = {32'b000000000100_00000_101_00101_0000011};       // lhu  x5,x0(4)
    processor.u_rom.rom_mem[5] = {32'b000000001000_00000_010_00110_0000011};       // lw   x6,x0(8)

    processor.u_rom.rom_mem[6] = {32'b0000000_00110_00000_000_01100_0100011};       // sb   x6,x0(12)
    processor.u_rom.rom_mem[7] = {32'b0000000_00110_00000_001_10000_0100011};       // sh   x6,x0(16)
    processor.u_rom.rom_mem[8] = {32'b0000000_00110_00000_010_10100_0100011};       // sw   x6,x0(20)

end


//Verify
initial begin   
    #100;
    //LOAD
    if(r2 != {{24{data0[7]}},data0[7:0]} )    $fatal("Test case 'LB' failed"); 
    if(r3 != {{24{1'b0}},data0[7:0]} )        $fatal("Test case 'LBU' failed"); 
    if(r4 != {{16{data1[7]}},data1[15:0]} )   $fatal("Test case 'LH' failed"); 
    if(r5 != {{16{1'b0}},data1[15:0]} )       $fatal("Test case 'LHU' failed"); 
    //SAVE
    if(processor.u_ram.ram_mem[3] != {{24{1'b0}},data2[7:0]})     $fatal("Test case 'SB' failed"); 
    if(processor.u_ram.ram_mem[4] != {{16{1'b0}},data2[15:0]})    $fatal("Test case 'SH' failed"); 
    if(processor.u_ram.ram_mem[5] != data2)                     $fatal("Test case 'SW' failed"); 
 
    #10
    $display("Memory Test cases passed");
    $finish;
end

//Monitor
initial begin
    //print N numbers
    $monitor ("R7: %4d, R8: %4d, R9: %4d", processor.u_core_top.u_regfile.regfile[7], processor.u_core_top.u_regfile.regfile[8], processor.u_core_top.u_regfile.regfile[9]); 
    
end

endmodule
    