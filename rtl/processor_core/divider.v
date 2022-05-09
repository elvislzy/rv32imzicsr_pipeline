// -----------------------------------------------------------------
// Filename: divider.v                                             
// 
// Company: 
// Description:                                                     
// 
// 
//                                                                  
// Author: Elvis.Lu<lzyelvis@gmail.com>                            
// Create Date: 04/14/2022                                           
// Comments:                                                        
// 
// -----------------------------------------------------------------


module divider #(parameter WIDTH=32, parameter CBIT=5)
(
    input   wire                    clk,
    input   wire                    rst_n,

    input   wire    [WIDTH-1:0]     dividend,
    input   wire    [WIDTH-1:0]     divisor,
    input   wire                    start,
    input   wire                    div_sign,

    output  reg     [WIDTH-1:0]     quotient,
    output  reg     [WIDTH-1:0]     remainder,
    output  wire                    busy

);

    // fsm--------------------------------------------------------
    reg     [1:0]       state;
    reg     [1:0]       state_next;

    localparam DIV_IDLE = 2'B00;
    localparam DIV_CAL  = 2'B01;
    localparam DIV_END  = 2'B10;
    localparam DIV_ZERO = 2'B11;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state       <= 2'b00;
        end
        else begin
            state       <= state_next;
        end
    end

    // decleration------------------------------------------------
    assign              busy = ~(state==DIV_IDLE);
    reg     [CBIT-1:0]  cnt;
    reg     [WIDTH-1:0] dividend_r;
    reg     [WIDTH-1:0] remainder_r;
    reg     [WIDTH-1:0] divisor_r;
    reg                 r_sign;

    wire    [WIDTH-1:0] fixed_remainder = r_sign ? remainder_r + divisor_r : remainder_r;;

    wire    [WIDTH:0]   sub_add = r_sign ? ({remainder_r,dividend_r[31]} + {1'b0,divisor_r}) 
                                         : ({remainder_r,dividend_r[31]} - {1'b0,divisor_r});




    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cnt     <= 'd0;
        end
        else if(state==DIV_CAL) begin
            cnt     <= cnt + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dividend_r      <= 'd0;
            divisor_r       <= 'd0;
            remainder_r     <= 'd0;
            r_sign          <= 'd0;
        end
        else if(state==DIV_IDLE && start) begin
            if(div_sign && dividend[31]) begin
                dividend_r      <= ~dividend + 1'b1;
            end
            else begin
                dividend_r      <= dividend;
            end

            if(div_sign && divisor[31]) begin
                divisor_r       <= ~divisor + 1'b1;
            end
            else begin
                divisor_r       <= divisor;
            end
        end
        else if(state==DIV_CAL) begin
            remainder_r     <= sub_add[31:0];
            r_sign          <= sub_add[32];
            dividend_r      <= {dividend_r[30:0],~sub_add[32]};     // left shift and add lsb
        end
    end



    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            remainder       <= 'd0;
            quotient        <= 'd0;
        end
        else if(state==DIV_END) begin
            remainder       <= (dividend[31] && div_sign) ? (~fixed_remainder + 1'b1) : fixed_remainder;
            quotient        <= ((divisor[31]^dividend[31]) && div_sign) ? (~dividend_r + 1'b1) : dividend_r;
        end
        else if(state==DIV_ZERO) begin
            remainder       <= 'd0;
            quotient        <= 'd0;
        end
    end


    always @(*) begin
        if(!rst_n) begin
            state_next  = DIV_IDLE;
        end
        else begin
            case(state)
                DIV_IDLE: begin
                    if(start) begin
                        if(divisor==0) begin
                            state_next  = DIV_ZERO;
                        end
                        else begin
                            state_next  = DIV_CAL;
                        end
                    end
                    else begin
                        state_next  = DIV_IDLE;
                    end
                end
                DIV_CAL: begin
                    if(cnt==WIDTH-1) begin
                        state_next  = DIV_END;
                    end
                    else begin
                        state_next  = DIV_CAL;
                    end
                end
                DIV_ZERO: begin
                    state_next  = DIV_IDLE;
                end
                DIV_END: begin
                    state_next  = DIV_IDLE;
                end
                default: begin
                    state_next  = DIV_IDLE;
                end
            endcase
        end
    end


endmodule