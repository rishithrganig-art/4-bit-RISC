module tb_processor;
    reg clk;
    reg reset;
    wire [3:0] acc;
    wire halt;

 
cpu_4bit uut (.clk(clk),.reset(reset),.acc(acc),.halt(halt));

initial begin
clk = 0;
forever #5 clk = ~clk; 
end

initial begin
$display("========================================");
$display("   Starting 4-bit CPU Simulation...     ");
$display("========================================");
        

$monitor("Time=%0t | PC=%d | IR=%b | ACC=%d | State=%b | Halt=%b", 
$time, uut.pc, uut.ir, acc, uut.state, halt);

// Reset CPU
reset = 1;
#15; 
reset = 0;
wait(halt == 1);
#10; 

$display("========================================");
$display("Simulation Finished!");
$display("Final ACC Value: %d (Expected: 8)", acc);
$display("Value in RAM[11]: %d (Expected: 8)", uut.RAM.memory[11]);
$display("========================================");
        
$stop; 
    end
endmodule
