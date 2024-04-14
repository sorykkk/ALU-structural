module FA (
    output reg sum,
    output reg cout,
    input a,
    input b,
    input cin
);
  
  assign sum = a ^ b ^ cin;
  assign cout = (a & b) | (b & cin) | (cin & a);

endmodule

module MUX2to1_w1 (         //Mux 2to1 for 1 bit
    output reg y,
    input i0,
    i1,
    s
);
  always @(i0, i1, s) begin
    if (s == 1'b0) 
        y = i0;
    else 
        y = i1;
  end
endmodule

module MUX2to1_w4 (         //Mux 2to1 for 4 bits
    output reg [3:0] y,
    input [3:0] i0,
    i1,
    input s
);

  always @(i0, i1, s) begin
    if (s == 1'b0) begin
      y = i0;  
    end else begin
      y = i1;  
    end
  end
endmodule

module RCA4 #(parameter WIDTH=4)(               // Ripple Carry Adder with 4 bits
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
    input cin,
  output [WIDTH-1:0] sum,
    output reg cout
);
  wire [WIDTH-1:0] c;

  FA fa0 ( .a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .cout(c[0]));
  FA fa1 ( .a(a[1]), .b(b[1]), .cin(c[0]), .sum(sum[1]), .cout(c[1]));
  FA fa2 ( .a(a[2]), .b(b[2]), .cin(c[1]), .sum(sum[2]), .cout(c[2]));
  FA fa3 ( .a(a[3]), .b(b[3]), .cin(c[2]), .sum(sum[3]), .cout(c[3]));
	always @ * begin
   cout=c[3];
  end
  
endmodule

module CSelA #(parameter WIDTH=32)(
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
    input cin,
  output reg [WIDTH-1:0] sum,
    output reg cout,
    output reg overflow
);

  wire [WIDTH-1:0] sum0, sum1;
  wire [7:0] c;
  wire [7:0] cout0, cout1;
  reg [WIDTH-1:0] result;
  wire [WIDTH-1:0] tmp;

  RCA4 rca0_0 (.sum(sum0[3:0]), .cout(cout0[0]), .a(a[3:0]), .b(b[3:0]), .cin(1'b0));
  RCA4 rca0_1 (.sum(sum1[3:0]), .cout(cout1[0]), .a(a[3:0]), .b(b[3:0]), .cin(1'b1));
  MUX2to1_w4 mux1_sum (.y(tmp[3:0]), .i0(sum0[3:0]), .i1(sum1[3:0]), .s(cin));
  MUX2to1_w1 mux1_cout (.y(c[0]), .i0(cout0[0]), .i1(cout1[0]), .s(cin));

  RCA4 rca_other_0[6:1] (.sum(sum0[27:4]), .cout(cout0[6:1]), .a(a[27:4]), .b(b[27:4]), .cin(1'b0));
  RCA4 rca_other_1[6:1] (.sum(sum1[27:4]), .cout(cout1[6:1]), .a(a[27:4]), .b(b[27:4]), .cin(1'b1));
  MUX2to1_w4 mux_other_sum[6:1] (.y(tmp[27:4]), .i0(sum0[27:4]), .i1(sum1[27:4]), .s(c[5:0]));
  MUX2to1_w1 mux_other_cout[6:1] (.y(c[6:1]), .i0(cout0[6:1]), .i1(cout1[6:1]), .s(c[5:0]));

  RCA4 rca7_0 (.sum(sum0[31:28]), .cout(cout0[7]), .a(a[31:28]), .b(b[31:28]), .cin(1'b0));
  RCA4 rca7_1 (.sum(sum1[31:28]), .cout(cout1[7]), .a(a[31:28]), .b(b[31:28]), .cin(1'b1));
  MUX2to1_w4 mux6543210_sum (.y(tmp[31:28]), .i0(sum0[31:28]), .i1(sum1[31:28]), .s(c[6]));
  MUX2to1_w1 mux6543210_cout (.y(c[7]), .i0(cout0[7]), .i1(cout1[7]), .s(c[6]));

  // Detectăm overflow-ul
always @* begin
    // Verificam daca depășirea sau underflow-ul au loc
  overflow = (a[WIDTH-1] & b[WIDTH-1] & ~tmp[WIDTH-1]) | (~a[WIDTH-1] & ~b[WIDTH-1] & tmp[WIDTH-1]);

    // Tratam cazurile de depasire si underflow
    if (overflow) begin
      if (!tmp[WIDTH-1] && (a[WIDTH-1]==1 && b[WIDTH-1]==1)) begin
            // Realizam complementul lui doi al rezultatului in cazul de underflow
            sum = ~tmp + 1'b1;
            cout = 1; // Setam carry-out pentru cazul de carry pe bitul semnificativ
      end else if (tmp[WIDTH-1] && (a[WIDTH-1]==0 && b[WIDTH-1]==0))  begin
            // Realizam complementul lui doi al rezultatului in cazul de overflow
            sum = ~tmp;
            cout = 0;
        end
    end else begin
        // in caz contrar, rezultatul este neschimbat
        sum = tmp;
        cout = c[7]; // Carry-out este ultimul carry generat de adunare
    end
end



endmodule