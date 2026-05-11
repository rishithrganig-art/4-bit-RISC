module alu (
    input [3:0] a,
    input [3:0] b,
    input [1:0] op,
    output reg [3:0] result
);
    always @(*) begin
        case (op)
            2'b00: result = a + b;   
            2'b01: result = a - b;   
            2'b10: result = a & b;   
            2'b11: result = a | b;   
            default: result = 4'b0000;
        endcase
    end
endmodule

//Instruction Memory ROM
module instr_mem (
    input [3:0] addr,
    output reg [7:0] data
);
    always @(*) begin
        case(addr)
          
            4'd0: data = {4'b0011, 4'd5};  // LDI 5 
            4'd1: data = {4'b0010, 4'd10}; // STA 10 
            4'd2: data = {4'b0011, 4'd3};  // LDI 3 
            4'd3: data = {4'b0100, 4'd10}; // ADD 10 
            4'd4: data = {4'b0010, 4'd11}; // STA 11 
            4'd5: data = {4'b1111, 4'd0};  // HLT 
            default: data = 8'b0000_0000;  // NOP
        endcase
    end
endmodule

//Data Memory
module data_mem (
    input clk,
    input we,
    input [3:0] addr,
    input [3:0] data_in,
    output [3:0] data_out
);
    reg [3:0] memory [0:15];
    integer i;
    
  
    initial begin
        for(i = 0; i < 16; i = i + 1) memory[i] = 4'b0000;
    end

    assign data_out = memory[addr]; 

    always @(posedge clk) begin
        if (we) memory[addr] <= data_in;
    end
endmodule

//cpu core
module cpu_4bit (
    input clk,
    input reset,
    output reg [3:0] acc, 
    output reg halt
);
 
    localparam LDA = 4'b0001;
    localparam STA = 4'b0010;
    localparam LDI = 4'b0011;
    localparam ADD = 4'b0100;
    localparam SUB = 4'b0101;
    localparam AND = 4'b0110;
    localparam JMP = 4'b0111;
    localparam HLT = 4'b1111;

    // FSM States
    localparam FETCH   = 1'b0;
    localparam EXECUTE = 1'b1;

    reg [3:0] pc;
    reg [7:0] ir;
    reg state;

    wire [7:0] i_data;
    wire [3:0] d_addr = ir[3:0]; 
    wire [3:0] d_data_in;
    reg  [3:0] d_data_out;
    reg  d_we;

    wire [3:0] alu_result;
    reg  [1:0] alu_op;

    instr_mem ROM (.addr(pc), .data(i_data));
    data_mem  RAM (.clk(clk), .we(d_we), .addr(d_addr), .data_in(d_data_out), .data_out(d_data_in));
    
    wire [3:0] alu_a = acc;
    wire [3:0] alu_b = d_data_in;
    alu       ALU (.a(alu_a), .b(alu_b), .op(alu_op), .result(alu_result));

    always @(*) begin
        case(ir[7:4])
            SUB: alu_op = 2'b01;
            AND: alu_op = 2'b10;
            default: alu_op = 2'b00; 
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 0;
            acc <= 0;
            ir <= 0;
            state <= FETCH;
            halt <= 0;
            d_we <= 0;
        end else if (!halt) begin
            if (state == FETCH) begin
                ir <= i_data;      
                pc <= pc + 1;      
                d_we <= 0;         
                state <= EXECUTE;  
            end else begin
                state <= FETCH;    
                case (ir[7:4])
                    LDA: acc <= d_data_in;
                    STA: begin
                        d_data_out <= acc;
                        d_we <= 1;
                    end
                    LDI: acc <= ir[3:0];
                    ADD: acc <= alu_result;
                    SUB: acc <= alu_result;
                    AND: acc <= alu_result;
                    JMP: pc <= ir[3:0];
                    HLT: halt <= 1;
                endcase
            end
end else begin
            d_we <= 0;
        end
    end
endmodule
