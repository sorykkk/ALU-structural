module div_control_unit(
    input            clk, rst_b,
    input            bgn,
    input            cnt1, cnt2,
    input  wire[2:0] a_0,
    input            m_n, a_n,
    output reg       c0, c2, c3, c4, c5, c6, c7, 
                     c8, c9, c10, c11, c12, fin
);
    typedef enum bit[4:0] 
    {
        START = 5'b00000,
        S0    = 5'b00001,
        SM    = 5'b00010,
        S2    = 5'b00011,
        SA    = 5'b00100,
        S3    = 5'b00101,
        S4    = 5'b00110,
        S5    = 5'b00111,
        S6    = 5'b01000,
        S7    = 5'b01001,
        S8    = 5'b01010,
        SAN   = 5'b01011,
        S9    = 5'b01100,
        S10   = 5'b01101,
        SC    = 5'b01110,
        S11   = 5'b01111,
        S12   = 5'b10000,
        S13   = 5'b10001,
        STOP  = 5'b10010
    } state_e;

    state_e state, next;

    always @(posedge clk, negedge rst_b) begin
        if(!rst_b) state <= START;
        else       state <= next;
    end

    always @* begin
        next = START;
        case(state) 
            START      : if(!bgn)                 next = START;
                         else                     
                         begin 
                                                  next = S0; 
                                                  c0 = 1'b1; // read first ibus based on next state, because we want to read it one clock earlier
                                                             // so it will be like an simple operation will do
                         end

            S0         :                          next = SM; 

            SM         : if(!m_n)                 next = S2;
                         else                     next = SA;

            S2         :                          next = SM;

            SA         : if     (a_0 == 3'b000 || 
                                 a_0 == 3'b111)   next = S3;
                         else if(a_0 == 3'b001 || 
                                 a_0 == 3'b010 || 
                                 a_0 == 3'b011)   next = S4;
                         else if(a_0 == 3'b100 || 
                                 a_0 == 3'b101 || 
                                 a_0 == 3'b110)   next = S5;

            S4         :                          next = S6;
            S5         :                          next = S7;

            S3, S6, S7 : if(!cnt1)                next = S8;
                         else                     next = SAN;
            
            SAN        : if(a_n)                  next = S9;
                         else                     next = S10;

            S8         :                          next = SA;
            S9         :                          next = S10;
            S10        :                          next = SC;

            SC         : if(!cnt2)                next = S11;
                         else                     next = S12;

            S11        :                          next = SC;
            S12        :                          next = START;
            S13        :                          next = START;
        endcase
    end

    always @(posedge clk, negedge rst_b) begin
        { c0, c2, c3, c4, c5, c6, c7,
          c8, c9, c10, c11, c12, fin } <= 13'b0;

        case(next)
            S2   : c2            <= 1'b1;
            S3   : c5            <= 1'b1;
            S4   : {c3, c5}      <= 2'b11;
            S5   : {c4, c5}      <= 2'b11;
            S6   : {c6, c7}      <= 2'b11;
            S7   : c6            <= 1'b1;
            S8   : c8            <= 1'b1;
            S9   : {c9, c6}      <= 2'b11;
            S10  : {c6, c7, c10} <= 3'b111;
            S11  : c11           <= 1'b1;
            S12  : {c12, fin}    <= 2'b11;
        endcase
    end
endmodule

module div_reg_a #(parameter WIDTH=32)(
    input                   clk, rst_b, clr,
    input                   shr, shl, shl_i,
    input                   ld_sum, ld_obus,
    input  wire [WIDTH:0]   sum,
    output reg  [WIDTH-1:0] obus,
    output reg  [WIDTH:0]   a
);
    always @(posedge clk, negedge rst_b) begin
        if(!rst_b || clr) a <= {(WIDTH+1){1'b0}};
        else if(shr)      a <= {1'b0, a[WIDTH:1]};
        else if(shl)      a <= {a[WIDTH-1:0], shl_i};
        else if(ld_sum)   a <= sum;
    end

    always @*
        obus = (ld_obus)? a[WIDTH-1:0] : {WIDTH{1'bz}};
endmodule

module div_reg_q #(parameter WIDTH=32)(
    input                   clk, rst_b,
    input                   ld_ibus, ld_obus, ld_sum,
    input                   shl, shl_i,
    input                   sgnq, sgnm,
    input  wire [WIDTH-1:0] sum,
    input  wire [WIDTH-1:0] ibus,
    output reg  [WIDTH-1:0] obus,
    output reg  [WIDTH-1:0] q,
    output reg              sgn
);

    always @(posedge clk, negedge rst_b) begin
        if(!rst_b)       q <= {(WIDTH+1){1'b0}};
        else if(ld_ibus) begin 
            q   <= (ibus ^ {(WIDTH+1){ibus[WIDTH-1]}}) + ibus[WIDTH-1];
            sgn <= ibus[WIDTH-1];
        end
        else if(shl)     q <= {q[WIDTH-2:0], shl_i};
        else if(ld_sum)  q <= sum;
    end

    always @*
            obus = (ld_obus)? ((q[WIDTH-1:0] ^ {WIDTH{sgnq^sgnm}}) + (sgnq^sgnm)) : {WIDTH{1'bz}};

endmodule

module div_reg_q_prim #(parameter WIDTH=32)(
    input                  clk, rst_b, clr,
    input                  shl, shl_i, inc,
    output reg [WIDTH-1:0] q_p
);

    always @(posedge clk, negedge rst_b) begin 
        if(!rst_b || clr) q_p <= {WIDTH{1'b0}};
        else if(shl)      q_p <= {q_p[WIDTH-2:0], shl_i};
        else if(inc)      q_p <= q_p+1;
    end

endmodule

module div_reg_m #(parameter WIDTH=32)(
    input                   clk, rst_b, ld_ibus,
    input                   shl,
    input  wire [WIDTH-1:0] ibus,
    output reg  [WIDTH-1:0] m,
    output reg              sgn
);

    always @(posedge clk, negedge rst_b) begin
        if(!rst_b)       m <= {WIDTH{1'b0}};
        else if(ld_ibus) begin 
            m   <= (ibus ^ {(WIDTH+1){ibus[WIDTH-1]}}) + ibus[WIDTH-1];
            sgn <= ibus[WIDTH-1];
        end
        else if(shl)     m <= {m[WIDTH-2:0], 1'b0};
    end

endmodule

module div_counter #(parameter WIDTH=5)(
    input                  clk, rst_b, up, down, clr,
    output reg [WIDTH-1:0] cnt
);

    always @(posedge clk, negedge rst_b) begin
        if(!rst_b || clr) cnt <= {WIDTH{1'b0}};
        else if(up)       cnt <= cnt+1;
        else if(down)     cnt <= cnt-1;
    end

endmodule

module div #(parameter WIDTH = 32)(
    input                  clk, rst_b,
    input                  bgn,
    input  reg [WIDTH-1:0] ibusA, ibusB,
    output wire[WIDTH-1:0] obusA, obusB,
    output reg             fin
);

    reg[WIDTH:0]           A;
    reg[WIDTH-1:0]         Q;
    reg[WIDTH-1:0]         QP;
    reg[WIDTH-1:0]         M;
    reg[$clog2(WIDTH)-1:0] cnt1, cnt2;

    reg is_cnt1, is_cnt2, fm, fq,
        c0, c2, c3,  c4,  c5,  c6, 
        c7, c8, c9, c10, c11, c12;

    //Blocul de countere
    assign is_cnt1 = &cnt1;
    assign is_cnt2 = |cnt2;
    div_counter #($clog2(WIDTH)) cnt1_inst(.clk, .rst_b, .up(c8), .down(1'b0), 
                                       .clr(c0), .cnt(cnt1));
    div_counter #($clog2(WIDTH)) cnt2_inst(.clk, .rst_b, .up(c2), .down(c11),  
                                       .clr(c0), .cnt(cnt2));

    //Blocul de control unit
    div_control_unit cntrl(.clk, .rst_b, 
                           .cnt1(is_cnt1), .cnt2(~is_cnt2), 
                           .a_0(A[WIDTH:WIDTH-2]), 
                           .m_n(M[WIDTH-1]), .a_n(A[WIDTH]), 
                           .bgn, .fin,
                           .c0,  .c2, .c3,  .c4,  .c5,  .c6, 
                           .c7,  .c8, .c9, .c10, .c11, .c12);

    //Blocul de sumator
    wire[WIDTH:0] sum;
    reg [WIDTH:0] SUM_A;
    reg [WIDTH:0] SUM_B;
    assign SUM_A = (c10) ? {1'b0, Q}  : {A};
    assign SUM_B = ((c10) ? {1'b0, QP} : {1'b0, M}) ^ {(WIDTH+1){c7}};
    parallel_adder #(WIDTH) adder_inst(.cin(c7), .a(SUM_A), .b(SUM_B), 
                                       .sum(sum), .cout());

    //Blocul cu registri
    div_reg_m #(WIDTH) m_reg (.clk, .rst_b, .ld_ibus(c0), .shl(c2), .ibus(ibusB), .m(M), .sgn(fm));
    div_reg_q_prim #(WIDTH) qp_reg (.clk, .rst_b, .clr(c0), .shl(c4|c5), 
                                    .shl_i(c4), .inc(c9), .q_p(QP));
    
    
    reg shl;
    assign shli = (c2) ? M[WIDTH-1] : c3;

    div_reg_q #(WIDTH) q_reg (.clk, .rst_b, .ld_ibus(c0), .ld_obus(c12), .ibus(ibusA),
                              .ld_sum(c6&c10), .sum(sum[WIDTH-1:0]), 
                              .obus(obusA), .q(Q), .shl(c2|c5), .shl_i(shli), .sgn(fq), .sgnq(fq), .sgnm(fm));
    div_reg_a #(WIDTH) a_reg (.clk, .rst_b, .clr(c0), 
                              .shr(c11), .shl(c2|c5), .shl_i(Q[WIDTH-1]), 
                              .ld_sum(c6&~c10), .ld_obus(c12), .sum(sum), .obus(obusB), .a(A));//c13

endmodule 

