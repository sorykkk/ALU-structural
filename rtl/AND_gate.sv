module AND_gate #(parameter WIDTH=32)(
  input [WIDTH-1:0] A,  
  input [WIDTH-1:0] B, 
  output [WIDTH-1:0] Out 
);

assign Out = A & B;

endmodule
