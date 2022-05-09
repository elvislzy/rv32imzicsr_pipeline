// -----------------------------------------------------------------
// Filename: param_def.v                                             
// 
// Company: 
// Description:                                                     
// 
// 
//                                                                  
// Author: Elvis.Lu<lzyelvis@gmail.com>                            
// Create Date: 04/11/2022                                           
// Comments:                                                        
// 
// -----------------------------------------------------------------
`define NOP                32'h0000_0013     // addi x0, x0, 0

// opcode
`define OPCODE_LUI         7'b0110111   
`define OPCODE_AUIPC       7'b0010111   
`define OPCODE_JAL         7'b1101111   
`define OPCODE_JALR        7'b1100111   

`define OPCODE_BRANCH      7'b1100011   
`define OPCODE_LTYPE       7'b0000011   
`define OPCODE_STYPE       7'b0100011   
`define OPCODE_ITYPE       7'b0010011   
`define OPCODE_RTYPE       7'b0110011   
`define OPCODE_FENCE       7'b0001111   
`define OPCODE_CSR         7'b1110011  

// funct3
`define FUNCT3_BEQ                3'b000
`define FUNCT3_BNE                3'b001
`define FUNCT3_BLT                3'b100
`define FUNCT3_BGE                3'b101
`define FUNCT3_BLTU               3'b110
`define FUNCT3_BGEU               3'b111

`define FUNCT3_LB                 3'b000
`define FUNCT3_LH                 3'b001
`define FUNCT3_LW                 3'b010
`define FUNCT3_LBU                3'b100
`define FUNCT3_LHU                3'b101

`define FUNCT3_SB                 3'b000
`define FUNCT3_SH                 3'b001
`define FUNCT3_SW                 3'b010

`define FUNCT3_ADDI               3'b000
`define FUNCT3_SLTI               3'b010
`define FUNCT3_SLTIU              3'b011
`define FUNCT3_XORI               3'b100
`define FUNCT3_ORI                3'b110
`define FUNCT3_ANDI               3'b111

`define FUNCT3_SLLI               3'b001  
`define FUNCT3_SRLI_SRAI          3'b101  

`define FUNCT3_ADD_SUB            3'b000  
`define FUNCT3_SLL                3'b001  
`define FUNCT3_SLT                3'b010  
`define FUNCT3_SLTU               3'b011  
`define FUNCT3_XOR                3'b100  
`define FUNCT3_SRL_SRA            3'b101  
`define FUNCT3_OR                 3'b110  
`define FUNCT3_AND                3'b111  

`define FUNCT3_MUL                3'b000  
`define FUNCT3_MULH               3'b001
`define FUNCT3_MULHSU             3'b010
`define FUNCT3_MULHU              3'b011
`define FUNCT3_DIV                3'b100
`define FUNCT3_DIVU               3'b101
`define FUNCT3_REM                3'b110
`define FUNCT3_REMU               3'b111

`define FUNCT3_CSRRW              3'b001
`define FUNCT3_CSRRS              3'b010
`define FUNCT3_CSRRC              3'b011
`define FUNCT3_CSRRWI             3'b101
`define FUNCT3_CSRRSI             3'b110
`define FUNCT3_CSRRCI             3'b111
`define FUNCT3_CSR_SPECIAL        3'b000

`define FUNCT3_FENCE              3'b000
`define FUNCT3_FENCE_I            3'b001

// instruction define
`define INST_NOP            6'D0
`define INST_LUI            6'D1
`define INST_AUIPC          6'D2
`define INST_JAL            6'D3
`define INST_JALR           6'D4

`define INST_BEQ            6'D5
`define INST_BNE            6'D6
`define INST_BGE            6'D7
`define INST_BGEU           6'D8
`define INST_BLT            6'D9
`define INST_BLTU           6'D10

`define INST_LB             6'D11
`define INST_LBU            6'D12
`define INST_LH             6'D13
`define INST_LHU            6'D14
`define INST_LW             6'D15

`define INST_SB             6'D16
`define INST_SH             6'D17
`define INST_SW             6'D18

`define INST_ADDI           6'D19
`define INST_SLTI           6'D20
`define INST_SLTIU          6'D21
`define INST_ANDI           6'D22
`define INST_ORI            6'D23
`define INST_XORI           6'D24
`define INST_SLLI           6'D25
`define INST_SRLI           6'D26
`define INST_SRAI           6'D27

`define INST_ADD            6'D28
`define INST_SUB            6'D29
`define INST_AND            6'D30
`define INST_OR             6'D31
`define INST_XOR            6'D32
`define INST_SLL            6'D33
`define INST_SRL            6'D34
`define INST_SRA            6'D35
`define INST_SLT            6'D36
`define INST_SLTU           6'D37
`define INST_MUL            6'D38
`define INST_MULH           6'D39
`define INST_MULHU          6'D40
`define INST_MULHSU         6'D41
`define INST_DIV            6'D42
`define INST_DIVU           6'D43
`define INST_REM            6'D44
`define INST_REMU           6'D45

`define INST_CSRRW          6'D46
`define INST_CSRRWI         6'D47
`define INST_CSRRS          6'D48
`define INST_CSRRSI         6'D49
`define INST_CSRRC          6'D50
`define INST_CSRRCI         6'D51

`define INST_ECALL          6'D52
`define INST_MRET           6'D53

// ex result select
`define EX_SEL_NOP          3'B000
`define EX_SEL_ALU          3'B001
`define EX_SEL_MUL          3'B010
`define EX_SEL_DIV          3'B011
`define EX_SEL_CSR          3'B100
`define EX_SEL_JUMP         3'B101





