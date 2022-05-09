`timescale 1ns / 1ps
//`timescale 100ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/06 17:47:12
// Design Name: 
// Module Name: Branch_tb
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


module Branch_tb;
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
reg [31:0] data2 = 32'b1;

initial begin
    #1;
    processor.u_ram.ram_mem[0] = data0;
    processor.u_ram.ram_mem[1] = data1;
    processor.u_ram.ram_mem[2] = data2; 
end


//Instruction Memory Initialisation
parameter [31:0] operand1 = 32'b000000110010;
parameter [31:0] operand2 = 32'b000000010100;
parameter [12:0] imm0 = 13'b0000000001000;         //+8
parameter [12:0] imm1 = 13'b1111111111000;         //-8
parameter [12:0] imm2 = 13'b0000000010000;         //+16
parameter [12:0] imm3 = 13'b0000000011000;         //+24
parameter [12:0] imm4 = 13'b1111111110000;         //-16


initial begin
    //initial
    #1;
    //lui test
    processor.u_rom.rom_mem[0] = {32'b10000000000000000000_00001_0110111};         // lui  x1, imm 
    //load data from data memory to registor file
    //load test
    processor.u_rom.rom_mem[1] = {32'b000000000000_00000_010_00010_0000011};       // lw x2,x0(0) data memory address start at 0x80000000
    processor.u_rom.rom_mem[2] = {32'b000000000100_00000_010_00011_0000011};       // lw x3,x0(4)
    processor.u_rom.rom_mem[3] = {32'b000000001000_00000_010_00100_0000011};       // lw x4,x0(8)
    
    //r1 0x8000_0000
    //r2 0x0000_0001
    //r3 0xffff_ffff
    //r4 0x0000_0001

    //branch test
    //notice                                                  x4     x2
    processor.u_rom.rom_mem[4] = {{imm2[12],imm2[10:5]},13'b00100_00010_000,{imm2[4:1],imm2[11]},7'b1100011};      // beq x2,x4,16     [4]to[8]    (branch+16)
    processor.u_rom.rom_mem[5] = {32'b000000000001_00000_000_00101_0010011};                                       // addi x5,x0,1

    processor.u_rom.rom_mem[6] = {{imm2[12],imm2[10:5]},13'b00001_00010_001,{imm2[4:1],imm2[11]},7'b1100011};      // bne x2,x1,16     [6]to[10]   (branch+16)
    processor.u_rom.rom_mem[7] = {32'b000000000001_00000_000_00101_0010011};                                       // addi x5,x0,1

    processor.u_rom.rom_mem[8] = {{imm1[12],imm1[10:5]},13'b00100_00010_000,{imm1[4:1],imm1[11]},7'b1100011};      // beq x2,x4,-8     [8]to[6]    (branch-8)
    processor.u_rom.rom_mem[9] = {32'b000000000001_00000_000_00101_0010011};                                       // addi x5,x0,1

    processor.u_rom.rom_mem[10] = {{imm0[12],imm0[10:5]},13'b00100_00010_001,{imm0[4:1],imm0[11]},7'b1100011};     // bne x2,x4,8      [10]to[11]   (+4)

    processor.u_rom.rom_mem[11] = {{imm2[12],imm2[10:5]},13'b00010_00001_100,{imm2[4:1],imm2[11]},7'b1100011};     // blt x1,x2,16     [11]to[15]  (branch+16)
    processor.u_rom.rom_mem[12] = {32'b000000000001_00000_000_00101_0010011};                                      // addi x5,x0,1 

    processor.u_rom.rom_mem[13] = {{imm3[12],imm3[10:5]},13'b00001_00010_101,{imm3[4:1],imm3[11]},7'b1100011};     // bge x2,x1,24     [13]to[19]  (branch+24)
    processor.u_rom.rom_mem[14] = {32'b000000000001_00000_000_00101_0010011};                                      // addi x5,x0,1   

    processor.u_rom.rom_mem[15] = {{imm0[12],imm0[10:5]},13'b00011_00010_100,{imm0[4:1],imm0[11]},7'b1100011};     // blt x2,x3,8      [15]to[16]  (+4)

    processor.u_rom.rom_mem[16] = {{imm0[12],imm0[10:5]},13'b00010_00011_101,{imm0[4:1],imm0[11]},7'b1100011};     // bge x3,x2,8      [16]to[17]  (+4)

    processor.u_rom.rom_mem[17] = {{imm4[12],imm4[10:5]},13'b00011_00010_110,{imm4[4:1],imm4[11]},7'b1100011};     // bltu x2,x3,-24   [17]to[13]  (branch-16)
    processor.u_rom.rom_mem[18] = {32'b000000000001_00000_000_00101_0010011};                                      // addi x5,x0,1

    processor.u_rom.rom_mem[19] = {{imm0[12],imm0[10:5]},13'b00010_00011_111,{imm0[4:1],imm0[11]},7'b1100011};     // bgeu x3,x2,8     [19]to[21]  (branch+8)
    processor.u_rom.rom_mem[20] = {32'b000000000001_00000_000_00101_0010011};                                      // addi x5,x0,1

    processor.u_rom.rom_mem[21] = {32'b000000000001_00000_000_00110_0010011};                                      // addi x6,x0,1   

end


//Verify
initial begin   
    #200;
    if(r5 != 32'd0 | r6 != 32'd1) $fatal("Test case failed"); //when $5 == 0, all branch instruction succeed 
    #50;
    $display("Branch Test case passed");
    $finish;
end

//Monitor
initial begin
    //print N numbers
    $monitor ("R2: %4d, R3: %4d, R4: %4d", processor.u_core_top.u_regfile.regfile[2], processor.u_core_top.u_regfile.regfile[3], processor.u_core_top.u_regfile.regfile[4]); 
    
end
initial begin
    $monitor ("D0: %4d, D1: %4d, D1: %4d, D3: %4d", processor.u_ram.ram_mem[0], processor.u_ram.ram_mem[1], processor.u_ram.ram_mem[2], processor.u_ram.ram_mem[3]); 
end

endmodule
