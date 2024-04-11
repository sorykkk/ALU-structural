//parallel_adder -> should be changed to CSkA

module parallel_adder #(parameter WIDTH=32)(
    input  wire [WIDTH:0] a, 
    input  wire [WIDTH:0] b,
    input                 cin,
    input                 load,
    output reg  [WIDTH:0] sum,
    output reg            cout
);
    always @* begin
        if(load) {cout, sum} = a+b+cin;
    end
endmodule
