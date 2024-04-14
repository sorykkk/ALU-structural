module NOT_gate #(parameter WIDTH=32)(
  input [WIDTH-1:0] A,   
  output reg [WIDTH-1:0] out
);
  assign out = ~A;
endmodule
