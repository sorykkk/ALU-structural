//parallel_adder -> should be changed to CSkA

// module parallel_adder #(parameter WIDTH=32)(
//     input  wire [WIDTH:0] a, 
//     input  wire [WIDTH:0] b,
//     input                 cin,
//     input                 load,
//     output reg  [WIDTH:0] sum,
//     output reg            cout
// );
//     always @* begin
//         if(load) {cout, sum} = a+b+cin;
//     end
// endmodule

module FA1 (
    output reg sum,
    output reg cout,
    input a,
    input b,
    input cin
);
  
  always @* begin
      sum = a ^ b ^ cin;
      cout = (a & b) | (b & cin) | (cin & a);
  end

endmodule

module MUX2to1_w11 (         //Mux 2to1 for 1 bit
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

module MUX2to1_w41 (         //Mux 2to1 for 4 bits
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

module RCA41 #(parameter WIDTH=3)(               // Ripple Carry Adder with 4 bits
    input [WIDTH:0] a,
    b,
    input cin,
    output [WIDTH:0] sum,
    output cout
);
  wire [WIDTH-1:0] c;

  FA1 fa0 ( .a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .cout(c[0]));
  FA1 fa1 ( .a(a[1]), .b(b[1]), .cin(c[0]), .sum(sum[1]), .cout(c[1]));
  FA1 fa2 ( .a(a[2]), .b(b[2]), .cin(c[1]), .sum(sum[2]), .cout(c[2]));
  FA1 fa3 ( .a(a[3]), .b(b[3]), .cin(c[2]), .sum(sum[3]), .cout(cout));

endmodule


module parallel_adder #(parameter WIDTH=32) (
    input [WIDTH:0] a,
    input [WIDTH:0] b,
    input cin,
    output [WIDTH:0] sum,
    output cout
);

  wire [WIDTH:0] sum0, sum1;
  wire [7:0] c;
  wire [7:0] cout0, cout1;

  RCA41 rca0_0 ( .sum(sum0[3:0]), .cout(cout0[0]), .a(a[3:0]), .b(b[3:0]), .cin(1'b0) );
  RCA41 rca0_1 ( .sum(sum1[3:0]), .cout(cout1[0]), .a(a[3:0]), .b(b[3:0]), .cin(1'b1));
  MUX2to1_w41 mux1_sum ( .y (sum[3:0]), .i0(sum0[3:0]), .i1(sum1[3:0]), .s (cin) );
  MUX2to1_w11 mux1_cout ( .y (c[0]), .i0(cout0[0]), .i1(cout1[0]), .s (cin) );


  RCA41 rca_other_0[6:1](.sum(sum0[27:4]), .cout(cout0[6:1]), .a(a[27:4]), .b(b[27:4]), .cin(1'b0));
  RCA41 rca_other_1[6:1](.sum(sum1[27:4]), .cout(cout1[6:1]), .a(a[27:4]), .b(b[27:4]), .cin(1'b1) );
  MUX2to1_w41 mux_other_sum[6:1](.y(sum[27:4]), .i0(sum0[27:4]), .i1(sum1[27:4]), .s(c[5:0]));
  MUX2to1_w11 mux_other_cout[6:1](.y(c[6:1]), .i0(cout0[6:1]), .i1(cout1[6:1]), .s(c[5:0]));

  RCA41 rca7_0 (.sum(sum0[31:28]), .cout(cout0[7]), .a(a[31:28]), .b(b[31:28]), .cin(1'b0));
  RCA41 rca7_1 ( .sum(sum1[31:28]), .cout(cout1[7]), .a(a[31:28]), .b(b[31:28]), .cin(1'b1));
  MUX2to1_w41 mux6543210_sum ( .y (sum[31:28]), .i0(sum0[31:28]), .i1(sum1[31:28]), .s (c[6]) );
  MUX2to1_w11 mux6543210_cout ( .y (c[7]), .i0(cout0[7]), .i1(cout1[7]), .s (c[6]) );

  FA1 sign (.a(a[32]), .b(b[32]), .cin(c[7]), .sum(sum[32]), .cout(cout));

endmodule
