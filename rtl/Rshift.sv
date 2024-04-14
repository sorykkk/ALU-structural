module Rshift #(parameter WIDTH=32) (
  input [WIDTH-1:0] data_in,       // Input data
    input [5:0] shift_amount,   // Shift amount
  output reg [WIDTH-1:0] data_out  // Output data
);

  reg [WIDTH-1:0] shifted_data;  
integer i;
always @* begin
    shifted_data = data_in;
    for (i = 0; i < shift_amount; i = i + 1) begin
        shifted_data = {shifted_data[31], shifted_data[31:1]};
    end
end

always @* begin
    data_out = shifted_data;
end
endmodule