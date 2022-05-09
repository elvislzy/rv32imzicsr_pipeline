# 5-stage-pipline-RV32IMzicsr



## CSR

| Name      | Number | R/W | Descroption                                |
| --------- | ------ | --- | ------------------------------------------ |
| mvendorid | 0xF11  | R   | Vendor ID                                  |
| marchid   | 0xF12  | R   | Architecture ID                            |
| mimpid    | 0xF13  | R   | Implementation ID                          |
| mhartid   | 0xF14  | R   | Hardware thread ID                         |
| mstatus   | 0x300  | RW  | Machine status register                    |
| misa      | 0x301  | R   | ISA and extensions                         |
| mie       | 0x304  | RW  | interrupt enable bits                      |
| mtvec     | 0x305  | RW  | trap-handler base address                  |
| mscratch  | 0x340  | RW  | Scratch register for machine trap handlers |
| mepc      | 0x341  | RW  | exception program counter                  |
| mcause    | 0x342  | R   | trap cause                                 |
| mtval     | 0x343  | RW  | bad address or instruction                 |
| mip       | 0x344  | R   | information on pending interrupts          |
| mcycle    | 0xB00  | R   | cycle counter                              |
| mcycleh   | 0xB80  | R   | Upper 32 bits of mcycle                    |
| minstret  | 0xB02  | R   | instructions-retired counter               |
| minstreth | 0xB82  | R   | Upper 32 bits of minstret                  |
