
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
    
    localparam
  			   X = 32'b11111111111111111111111110011011,// -101
               Y = 32'b00000000000000000000000000000011;//+63
    
            //    X = 32'b00000000000000000000000001100101,// +101
            //    Y = 32'b00000000000000000000000000111111;// +63

//                X = 32'b11111111111111111111111110011011,// -101
//                Y = 32'b11111111111111111111111111000001;// -63

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
        opcode = 4'b0000; //NOP
        #(RST_PULSE);
        #(2*CLK_PERIOD-RST_PULSE);

        opcode = 4'b0011; //ADD
        @(negedge fin);
        
      	opcode = 4'b0100;//SUB
        @(negedge fin);

        opcode = 4'b1011;//DIV
        @(negedge fin);

        opcode = 4'b1010;//MUL
        @(negedge fin);
      
        opcode = 4'b0101;//SHR
        @(negedge fin);
      
        opcode = 4'b0110; //SHL
        @(negedge fin);

        opcode = 4'b0111;//AND
        @(negedge fin);

        opcode = 4'b1000;//OR
        @(negedge fin);
      
        opcode = 4'b1001;//NEG
        @(negedge fin);

        $finish();
    end

   initial begin
    ibus = 0;

    repeat (15) begin
        #(2*CLK_PERIOD);
        ibus = X;
        #(2*CLK_PERIOD);
        ibus = Y;
        @(negedge fin);
    end
end

    
  initial begin
  $dumpfile("dump.vcd");
  $dumpvars;
   #1200000;
    $finish;
end
endmodule

