typedef enum bit[3:0] {
    //fsm signals
    NOP  = 4'b0000, // no operation
    // for combinatorial modules (all except mult and div)
    // there is necessary 4 clocks (which simulates mult and div)
    RD1  = 4'b0001, // read first number from ibus (for operations except mult and div)
    RD2  = 4'b0010, // read second number from ibus
    //op signals
    ADD  = 4'b0011,
    SUB  = 4'b0100,
    SHR  = 4'b0101,
    SHL  = 4'b0110,
    AND  = 4'b0111,
    OR   = 4'b1000,
    NEG  = 4'b1001,
    MUL  = 4'b1010,
    DIV  = 4'b1011
}op_e;

module alu_control_unit (
    input       clk, rst_b,
    input  op_e opcode,
    output reg  csum, csub, cdiv, cshr, 
                cshl, cand, cor, cmul, cneg,
    output reg  rd1, rd2, nop
);
    op_e state, next;

    always @(posedge clk, negedge rst_b) begin
        if(!rst_b) state <= NOP;
        else       state <= next;
    end

    always @* begin
        next = NOP;
        case(state)
            NOP           : if     (opcode == NOP) begin 
                                                      next = NOP; 
                                                      nop = 1'b1; 
                            end
                            else if(opcode == MUL) begin 
                                                      next = opcode; 
                                                      cmul = 1'b1; 
                            end
                            else if(opcode == DIV) begin                     
                                                      next = opcode;  
                                                      cdiv = 1'b1; 
                            end

                            else begin 
                                                      next = RD1; 
                                                      rd1 = 1'b1; // we activate read first ibus based on next state
                                                                 // to accelerate with one clock read from ibus
                            end

            RD1            : begin 
                                                      next = RD2; 
                                                      rd2 = 1'b1; // we do the same here
                                                                 // so if it is not mult or div operation, then we know it is a simple
                                                                 // one so we can read the values no matter what operation we will perform
                            end                        
            RD2            :                          
                             if    ((opcode >= ADD && 
                                     opcode <= NEG))  next = opcode;
                             else                     next = NOP;

            ADD,
            SUB,
            SHR, SHL, 
            AND, OR,  NEG, 
          	MUL, DIV       :                          next = NOP;                         
            
        endcase

    end

    always @(posedge clk, negedge rst_b) begin
        { cor,  csum, csub, cdiv, cshr, nop,
          cshl, cand, cmul, cneg, rd1, rd2 } <= 12'b0;

        case(next) 
            ADD : csum        <= 1'b1;
            SUB : csub        <= 1'b1;
            SHR : cshr        <= 1'b1;
            SHL : cshl        <= 1'b1;
            AND : cand        <= 1'b1;
            OR  : cor         <= 1'b1;
            NEG : cneg        <= 1'b1;
        endcase
    end
endmodule


module alu #(parameter WIDTH=32)(
    input                  clk, rst_b,
    input  wire[WIDTH-1:0] ibus,
    input  op_e            opcode,
    output reg [WIDTH-1:0] obus,
    output reg             fin
);

    reg csum, csub, cdiv, cshr, nop,
        cshl, cand, cor,  cmul, cneg, rd1, rd2;
    
    reg fmul, alu_fmul, fdiv, alu_fdiv;

    assign fin = (alu_fdiv| alu_fmul | csum | csub | cshr | cshl | cand | cor | cneg | nop);

    reg  [WIDTH-1:0] A, B;
    wire [WIDTH-1:0] RSUM, RSUB, RSHR, RSHL, RAND, 
                     ROR,  RNEG, RM1,  RM2,  RD1, RD2;

    always @(posedge clk) begin
        if(rd1)      A <= ibus;
        else if(rd2) B <= ibus;
    end

    always @(clk, csum, csub, cshr, cshl, fmul, fdiv, cand, cor, cneg) begin

        {alu_fmul, alu_fdiv} = 2'b00;
        case({csum, csub, cshr, cshl, cand, cor, cneg, fmul, fdiv})
            9'b100000000 : obus = RSUM;
            9'b010000000 : obus = RSUB;
            9'b001000000 : obus = RSHR;
            9'b000100000 : obus = RSHL;
            9'b000010000 : obus = RAND;
            9'b000001000 : obus = ROR;
            9'b000000100 : obus = RNEG;
            
            9'b000000001 : begin 
                    obus = RD1;
                    @(posedge clk);
                    obus = RD2;
                    alu_fdiv = 1'b1;
                    @(posedge clk);
            end 
            9'b000000010 : begin 
                    obus = RM1; 
                    @(posedge clk); 
                    obus = RM2; 
                    alu_fmul = 1'b1; 
                    @(posedge clk);
            end
            default : obus = {WIDTH{1'bz}};
        endcase
    end

    alu_control_unit alu_cntrl(.clk,  .rst_b, .opcode, .rd1, .rd2, .nop,
                               .csum, .csub,  .cdiv, .cshr, 
                               .cshl, .cand,  .cor,  .cmul, .cneg);

    mult #(WIDTH) mul_unit(.clk, .rst_b, .bgn(cmul), .ibusA(A), .ibusB(B), .obusA(RM1), .obusB(RM2), .fin(fmul));
    div  #(WIDTH) div_unit(.clk, .rst_b, .bgn(cdiv), .ibusA(A), .ibusB(B), .obusA(RD1), .obusB(RD2), .fin(fdiv));
  	// parallel_adder sum_unit(.a(A), .b(B), .cin(1'b0), .cout(), .sum(S));
  
    CSelA    #(WIDTH) add_unit (.a(A), .b(B), .cin(1'b0), .sum(RSUM), .cout(), .overflow());
    BCD_sub  #(WIDTH) sub_unit (.x(A), .y(B), .borrow(), .diff(RSUB));
    Rshift   #(WIDTH) shr_unit (.data_in(A), .shift_amount(6'd4), .data_out(RSHR));
    Lshift   #(WIDTH) shl_unit (.data_in(A), .shift_amount(6'd4), .data_out(RSHL)); 
    AND_gate #(WIDTH) and_unit (.A(A), .B(B), .Out(RAND));
    OR_gate  #(WIDTH) or_unit  (.A(A), .B(B), .Out(ROR));
    NOT_gate #(WIDTH) neg_unit (.A(A), .out(RNEG));

endmodule


module tb;
    localparam WIDTH=32;

    reg             clk, rst_b, fin;
    op_e            opcode;
    reg [WIDTH-1:0] ibus;
    reg [WIDTH-1:0] obus;

    alu alu_inst (.clk, .rst_b, .opcode, .ibus, .obus, .fin);
    localparam CLK_PERIOD = 100,
               CLK_CYCLES = 1000,
               RST_PULSE  = 25;
    
    localparam X = 32'b11111111111111111111111110011011,//-101
               Y = 32'b00000000000000000000000000111111;//+63
    
            //    X = 32'b00000000000000000000000001100101,// +101
            //    Y = 32'b00000000000000000000000000111111;// +63

            //    X = 32'b11111111111111111111111110011011,// -101
            //    Y = 32'b11111111111111111111111111000001;// -63

    initial begin
        clk = 1'd0;
        forever begin
            #(CLK_PERIOD) clk = ~clk;
        end
    end

    initial begin 
        rst_b = 1'd0;
        #(RST_PULSE);
        rst_b = 1'd1;
    end

    initial begin
        opcode = NOP;
        #(RST_PULSE);
        #(2*CLK_PERIOD-RST_PULSE);

        opcode = ADD;
        @(negedge fin);
        opcode = SHL;
        @(negedge fin);


        opcode = MUL;
        @(negedge fin);

        opcode = DIV;
        @(negedge fin);

        opcode = MUL;
        @(negedge fin);

        opcode = ADD;
        @(negedge fin);

        opcode = SHR;
        @(negedge fin);

        // opcode = AND;
        // @(negedge fin);

        // opcode = OR;
        // @(negedge fin);

        // opcode = NEG;
        // @(negedge fin);

        // opcode = NOP;
        // @(negedge fin);

        // opcode = DIV;
        // @(negedge fin);

        // opcode = DIV;
        // @(negedge fin);

        // opcode = DIV;
        // @(negedge fin);

        $finish();
    end

    initial begin 
        ibus = 0;

        #(2*CLK_PERIOD);
        ibus = X;
        #(2*CLK_PERIOD);
        ibus = Y;
        @(negedge fin);

        #(2*CLK_PERIOD);
        ibus = X;
        #(2*CLK_PERIOD);
        ibus = Y;
        @(negedge fin);

        #(2*CLK_PERIOD);
        ibus = X;
        #(2*CLK_PERIOD);
        ibus = Y;
        @(negedge fin);

        #(2*CLK_PERIOD);
        ibus = X;
        #(2*CLK_PERIOD);
        ibus = Y;
        @(negedge fin);

        #(2*CLK_PERIOD);
        ibus = X;
        #(2*CLK_PERIOD);
        ibus = Y;
        @(negedge fin);

        #(2*CLK_PERIOD);
        ibus = X;
        #(2*CLK_PERIOD);
        ibus = Y;
        @(negedge fin);

        #(2*CLK_PERIOD);
        ibus = X;
        #(2*CLK_PERIOD);
        ibus = Y;
        @(negedge fin);

        // #(2*CLK_PERIOD);
        // ibus = X;
        // #(2*CLK_PERIOD);
        // ibus = Y;
        // @(negedge fin);

        // #(2*CLK_PERIOD);
        // ibus = X;
        // #(2*CLK_PERIOD);
        // ibus = Y;
        // @(negedge fin);

        // #(2*CLK_PERIOD);
        // ibus = X;
        // #(2*CLK_PERIOD);
        // ibus = Y;
        // @(negedge fin);

        // #(2*CLK_PERIOD);
        // ibus = X;
        // #(2*CLK_PERIOD);
        // ibus = Y;
        // @(negedge fin);

        // #(2*CLK_PERIOD);
        // ibus = X;
        // #(2*CLK_PERIOD);
        // ibus = Y;
        // @(negedge fin);

        // #(2*CLK_PERIOD);
        // ibus = X;
        // #(2*CLK_PERIOD);
        // ibus = Y;
        // @(negedge fin);

        // #(2*CLK_PERIOD);
        // ibus = X;
        // #(2*CLK_PERIOD);
        // ibus = Y;
        // @(negedge fin);

    end

endmodule
