module Full_Subtractor (
    input A,
    input B,
    input Cin,
    output Diff,
    output Borrow
);

    assign Diff = A ^ B ^ Cin;;
    assign Borrow = (~A & B) | ((~A | B) & Cin);

endmodule


module BCD_sub #(parameter WIDTH=32) (
  input [WIDTH-1:0] x,
  input [WIDTH-1:0] y,
  output [WIDTH-1:0] diff,
    output borrow
);

  wire [WIDTH-1:0]bar;
  wire [WIDTH-1:0]con;

  Full_Subtractor subtr_0 (.A(x[0]), .B(y[0]), .Cin(1'b0), .Diff(diff[0]), .Borrow(bar[0]));
    // Full_Subtractor subtr_2(.A(x[1]), .B(y[1]), .Cin(bar[0]), .Diff(diff[1]), .Borrow(bar[1]));
    // Full_Subtractor subtr_3(.A(x[2]), .B(y[2]), .Cin(bar[1]), .Diff(diff[2]), .Borrow(bar[2]));
    // Full_Subtractor subtr_4(.A(x[3]), .B(y[3]), .Cin(bar[2]), .Diff(diff[3]), .Borrow(bar[3]));
    // Full_Subtractor subtr_5(.A(x[4]), .B(y[4]), .Cin(bar[3]), .Diff(diff[4]), .Borrow(bar[4]));
    // Full_Subtractor subtr_6(.A(x[5]), .B(y[5]), .Cin(bar[4]), .Diff(diff[5]), .Borrow(bar[5]));
    // Full_Subtractor subtr_7(.A(x[6]), .B(y[6]), .Cin(bar[5]), .Diff(diff[6]), .Borrow(bar[6]));
    // Full_Subtractor subtr_8(.A(x[7]), .B(y[7]), .Cin(bar[6]), .Diff(diff[7]), .Borrow(bar[7]));

    genvar i;
    generate
      for (i = 1; i < WIDTH; i = i + 1) begin
        Full_Subtractor subtr ( .A(x[i]), .B(y[i]), .Cin(bar[i-1]), .Diff(diff[i]), .Borrow(bar[i]) );
        end
    endgenerate

    assign borrow = |bar;



endmodule