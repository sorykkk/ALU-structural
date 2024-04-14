module mux2#(parameter WIDTH=32)(
    output reg [WIDTH-1:0] S,
    input [WIDTH-1:0] A0, A1,
    input sel
);
    wire [WIDTH-1:0] selector;

    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin
            assign selector[i] = sel;
        end
    endgenerate 
    assign S = selector & A1 | (~selector) & A0;
endmodule