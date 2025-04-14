module cache_fill_FSM(clk, rst_n, miss_detected, miss_address, fsm_busy, write_data_array,
write_tag_array,memory_address, memory_data, memory_data_valid);


    //DESIGN NOTES: 
    //- check how long each memory access takes, as our counters could be at different values
    //- double check specifications and make sure 
    // - PRETTY SURE ALL OCCURENCES OF 11 NEED TO BE CHANGED TO 32 OR 8 

    input clk, rst_n;
    input miss_detected;                // active high when tag match logic detects a miss
    input [15:0] miss_address;          // address that missed the cache

    input [15:0] memory_data;           // data returned by memory (after delay)
    input memory_data_valid;            // active high indicates valid data returning on memory bus

    output fsm_busy;                    // asserted while FSM is busy handling the miss (can be used as pipeline stall signal)
    output write_data_array;            // write enable to cache data array to signal when filling with memory_data
    output write_tag_array;             // write enable to cache tag array to signal when all words are filled in to data array
    output [15:0] memory_address;       // address to read from memory



    //internal logic signals
    wire state, nxt_state;        //current & next FSM state(0 = IDLE, 1 = WAIT)
    wire busy_out, busy_in;       //fsm_busy FF in/out signals 
    wire bytes_remain;           //high if FSM is busy & there are still bytes to fetch for cache block
    wire [3:0]cnt1_in, cnt1_out, cnt1_sum;  //cnter signals for bytes_remain signal




    


    //each two byte word of data requires 4 cycles to be read from memory
    //we need to grab 8, two byte words. fetching a block will entail minimum 32 cycles 
    //will need some sort of counting unit I believe


    //next state logic
    assign nxt_state = (~state) ? miss_detected ? bytes_remain;
    dff state_ff(.q(state), .d(nxt_state), .wen(1'b1), .clk(clk), .rst(rst));   //state reg      



    //fsm_busy & fsm_busy_ff logic
    assign fsm_busy = nxt_state | busy_out;        //will remain busy if busy_out = 1 or future state projected to be WAIT
    assign busy_in = (~state) ? miss_detected : bytes_remain; 
    dff fsm_busy_ff(.q(busy_out), .d(busy_in), .wen(1'b1), .clk(clk), .rst(rst)); //FF for fsm output signal





    //will need a counter & internal logic for bytes_remain
    //cnt1 counts each rollover(cycle spent within next_state)
    //think this is what we need to count to 4, or however many cycles we need to access memory

    dff cnt1_ff[3:0](.q(cnt1_out), .d(cnt1_in), .wen(nxt_state), .clk(clk), .rst(rst | cnt1_out == 4'b1011)); //only count if nxt_state is WAIT

    addsub_4bit cnt1_adder(.A(cnt1_out), .B(4'b1), .sub(1'b0), .Sum(cnt1_sum), .Ovfl());

    assign cnt1_in = (~state) ?         4'b1 : 
                     (miss_detected) ?  cnt1_sum : 
                                        cnt1_out; 

    assign bytes_remain = (state & ~(cnt1_out == 4'b1011));






    //write to data & tag array logic
    assign write_data_array = state & memory_data_valid; 
    assign write_tag_array = state & cnt1_out == 4'b1011; //why 11, not 8? 





    //will need an additional counter/incrementor
    //for addresses as we fetch different addresses we'll need to incrememnt as 
    //we read from memory, as we will assign memory_address = ???????
    wire [15:0] fill_addr;  //????????

    assign memory_address = 0; 





endmodule

// Gokul's D-flipflop
module dff (q, d, wen, clk, rst);

    output         q; //DFF output
    input          d; //DFF input
    input 	   wen; //Write Enable
    input          clk; //Clock
    input          rst; //Reset (used synchronously)

    reg            state;

    assign q = state;

    always @(posedge clk) begin
      state <= rst ? 0 : (wen ? d : state);
    end
endmodule


/**
* This carry lookahead block generates the carry chain logic of 4 bits of the
* full adder, plus the group generate/propagate signals to pass to a higher
* level carry lookahead block
*
* NOTE: this file was borrowed from my 552 group's phase1 project
*/
module clb_low(A, B, Cin, Cout, Gout, Pout);
// Port declarations
input wire [3:0] A; 
input wire [3:0] B;
input wire Cin;
output wire [2:0] Cout;
output wire Gout;
output wire Pout;

// intermediate signals
wire [3:0] G; // Generate signals between A and B bits
wire [3:0] P; // Propagate signals between A and B bits

assign G = A & B;
assign P = A ^ B;

assign Cout[0] = G[0] | (P[0] & Cin);
assign Cout[1] = G[1] | (P[1]&G[0]) | (P[1]&P[0]&Cin);
assign Cout[2] = G[2] | (P[2]&G[1]) | (P[2]&P[1]&G[0]) | (P[2]&P[1]&P[0]&Cin);

assign Pout = &P;
assign Gout = G[3] | (P[3]&G[2]) | (P[3]&P[2]&G[1]) | (P[3]&P[2]&P[1]&G[0]);
endmodule

module addsub_4bit(A, B, sub, Sum, Ovfl);

    input wire [3:0] A;
    input wire [3:0] B;
    input wire sub;
    output wire [3:0] Sum;
    output wire Ovfl;

    wire [3:0]Cout;
    wire [3:0]B_temp;

    wire xnor1out;
    wire xor1out;

    assign B_temp = (sub) ? ~B : B;

    // if A and B sign bits are the same, but the Sum sign bit is different, overflow occurred.
    xnor xnor1(xnor1out, A[3], B_temp[3]);
    xor xor1(xor1out, A[3], Sum[3]);
    and and1(Ovfl, xnor1out, xor1out);

    full_adder_1bit add4b[0:3](.A(A), .B(B_temp), .Cout(Cout), .Cin({Cout[2:0],sub}), .S(Sum));

endmodule