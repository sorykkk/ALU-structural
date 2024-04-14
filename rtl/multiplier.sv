module mult_control_unit(
    input            clk, rst_b,
    input            bgn,
    input            cnt,
    input  wire[2:0] q_0,
    output reg       fin,
    output reg       c0, c2, c3, c4, c5, c6, c7
);
    typedef enum bit[3:0] {
            START = 4'b0000,
            S0    = 4'b0001,
            S2    = 4'b0010,
            S3    = 4'b0011,
            S4    = 4'b0100,
            S5    = 4'b0101,
            S6    = 4'b0110,
            S7    = 4'b0111,
            SC    = 4'b1000,
            S8    = 4'b1001,
            S9    = 4'b1010,
            STOP  = 4'b1011
    }state_e;

    state_e state;
    state_e next;

    always @(posedge clk, negedge rst_b) begin
        if(!rst_b) state <= START;
        else       state <= next;
    end

    always @* begin
        next = START;
        case(state)
            START : if(!bgn)                  next = START;
                    else                      
                    begin 
                                              next = S0;
                                              c0 = 1'b1; //activate read of ibus based on next state
                                                        //to make it read with one clock faster, like simple operation
                    end

            S0    :                           next = SC;

            SC    :  if     (q_0 == 3'b010 || 
                             q_0 == 3'b001)   next = S2;
                     else if(q_0 == 3'b101 || 
                             q_0 == 3'b110)   next = S3;
                     else if(q_0 == 3'b011)   next = S4;
                     else if(q_0 == 3'b100)   next = S5;
                     else if(q_0 == 3'b000 || 
                             q_0 == 3'b111)   next = S6;
                  
            S2    :                           next = S6;
            S3    :                           next = S6;
            S4    :                           next = S6;
            S5    :                           next = S6;

            S6    : if(!cnt)                  next = S7;
                    else                      next = S8;

            S7    :                           next = SC;
            S8    :                           next = S9;
            S9    :                           next = START;
        endcase
    end

    always @(posedge clk, negedge rst_b) begin
        {c0, c2, c3, c4, c5, c6, c7, fin} <= 8'b0;
        case(next)
            S2   :  c2           <= 1'b1;
            S3   :  {c2, c3}     <= 2'b11;
            S4   :  {c2, c4}     <= 2'b11;
            S5   :  {c2, c3, c4} <= 3'b111;
            S6   :  c5           <= 1'b1;
            S7   :  c6           <= 1'b1;
            S8   :  {c7, fin}    <= 2'b11;
        endcase
    end
endmodule

module mult_reg_a #(parameter WIDTH=32)(
    input                   clk, rst_b, 
    input                   clr, ld_obus,
    input                   ld_sum,
    input                   sh_r,
    input                   sh_i,
    input  wire [WIDTH:0]   sum,
    output reg  [WIDTH-1:0] obus,
    output reg  [WIDTH:0]   a
);

    always @(posedge clk, negedge rst_b) begin
        if(!rst_b || clr) 
            a <= {(WIDTH+1){1'b0}};
        else if(sh_r)
            a <= {{2{sh_i}}, a[WIDTH:2]};
        else if(ld_sum) 
            a <= sum;
    end

    always @*
        obus = (ld_obus)? a[WIDTH-1:0]: {WIDTH{1'bz}};
endmodule

module mult_counter #(parameter WIDTH=8)(
    input                 clk, rst_b, ld, clr,
    output reg[WIDTH-1:0] out
);

    always @(posedge clk, negedge rst_b) begin
        if(!rst_b || clr) out <= {WIDTH{1'b0}};
        else if(ld)       out <= out+1;
    end
endmodule


module mult_reg_q #(parameter WIDTH=32) (
    input                    clk, rst_b,
    input                    ld_ibus, ld_obus,
    input                    sh_r,
    input  wire [1:0]        sh_i,
    input  wire [WIDTH-1:0]  ibus,
    output reg  [WIDTH-1:0]  obus,
    output reg  [WIDTH-1:-1] q
);

    always @(posedge clk, negedge rst_b) begin
        if(!rst_b) 
            q            <= {(WIDTH+1){1'b0}};
        else if(ld_ibus) 
            q[WIDTH-1:0] <= ibus;
        else if(sh_r) begin
            q            <= {sh_i, q[WIDTH-1:1]};
        end
    end

    always @* 
        obus = (ld_obus)?q[WIDTH-1:0]:{WIDTH{1'bz}};

endmodule

module mult_reg_m #(parameter WIDTH=32)(
    input                   clk, rst_b, ld_ibus,
    input  wire [WIDTH-1:0] ibus,
    output reg  [WIDTH-1:0] m
);
    always @(posedge clk, negedge rst_b) begin
        if(!rst_b)       m <= {WIDTH{1'b0}};
        else if(ld_ibus) m <= ibus;
    end

endmodule

module mult #(parameter WIDTH=32)(
    input                  clk, rst_b,
    input                  bgn,
    input  reg [WIDTH-1:0] ibusA, ibusB,
    output wire[WIDTH-1:0] obusA, obusB,
    output reg             fin
);

    reg[WIDTH:0]             A;
    reg[WIDTH-1:-1]          Q;
    reg[WIDTH-1:0]           M;
    reg[WIDTH:0]             INV;
    reg[$clog2(WIDTH/2)-1:0] cnt;

    reg is_cnt,
        c0, c1, c2, c3, c4, c5, c6, c7, c8;

    wire [WIDTH:0] sum;
    assign INV = ((c4)? {M[WIDTH-1:0], 1'b0 } : {M[WIDTH-1], M[WIDTH-1:0]}) ^ {(WIDTH+1){c3}};
    parallel_adder #(WIDTH) adder_inst(.cin(c3), .a(INV), .b(A), .sum, .cout());
    
    mult_reg_m #(WIDTH) m_reg (.clk, .rst_b, .ld_ibus(c0), .ibus(ibusA), .m(M));
    mult_reg_a #(WIDTH) a_reg (.clk, .rst_b, .clr(c0),     
                               .ld_sum(c2),  .sum(sum), 
                               .sh_r(c5),    .sh_i(A[WIDTH]), 
                               .ld_obus(c7), .obus(obusA), 
                               .a(A));

    mult_reg_q #(WIDTH) q_reg (.clk, .rst_b, 
                               .ld_ibus(c0), .ibus(ibusB),        
                               .sh_r(c5),    .sh_i(A[1:0]), 
                               .ld_obus(c7), .obus(obusB), //c8       
                               .q(Q));
    
    // complement #(WIDTH) cmpl_inst(.m(M), .c4(c4), .c3(c3), .m_out(M_OUT));
    
    mult_counter #($clog2(WIDTH/2))  cnt_inst(.clk, .rst_b, .ld(c6), .out(cnt), .clr(c0));
    assign is_cnt = &cnt;

    mult_control_unit cntrl_inst(.clk, .rst_b, 
                                 .bgn, .c0, .c2, 
                                 .c3,  .c4, .c5, .c6, 
                                 .c7,  .fin,.q_0(Q[1:-1]), 
                                 .cnt(is_cnt));
endmodule

// module tb;
//     localparam WIDTH=32;
//     reg            clk, rst_b, bgn, fin;
//     reg[3:0]       opcode;
//     reg[WIDTH-1:0] ibus;
//     reg[WIDTH-1:0] obus;

//     // alu alu_inst (.clk, .rst_b, .opcode, .ibus, .obus);
//     localparam CLK_PERIOD = 100,
//                CLK_CYCLES = 1000,
//                RST_PULSE  = 25;
    
//     localparam X = 32'b00000000000000000000000001100101,// 101
//                Y = 32'b00000000000000000000000000111111;// 63

//     initial begin
//         clk = 1'd0;
//         repeat (CLK_CYCLES*2) #(CLK_PERIOD) clk = ~clk;
//     end

// mult mul_unit(.clk, .rst_b, .bgn, .ibus, .obus, .fin);
//     initial begin 
//         rst_b = 1'd0;
//         #(RST_PULSE);
//         rst_b = 1'd1;
//     end

//     initial begin
//         bgn = 1'b0;
//         #(RST_PULSE);
//         bgn = 1'b1;
//     end

//     initial begin 
//         ibus = 0;
//         #200;
//         ibus = X;
//         #200;
//         ibus = Y;
//     end


// endmodule
