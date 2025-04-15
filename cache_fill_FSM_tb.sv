module cache_tb();


    logic clk, rst_n;
    logic miss_detected;                // active high when tag match logic detects a miss
    logic [15:0] miss_address;          // address that missed the cache

    logic [15:0] memory_data;           // data returned by memory (after delay)
    logic memory_data_valid;            // active high indicates valid data returning on memory bus

    logic fsm_busy;                    // asserted while FSM is busy handling the miss (can be used as pipeline stall signal)
    logic write_data_array;            // write enable to cache data array to signal when filling with memory_data
    logic write_tag_array;             // write enable to cache tag array to signal when all words are filled in to data array
    logic [15:0] memory_address;       // address to read from memory

    //DUT declaration
    cache_fill_FSM dut (
    .clk              (clk),
    .rst_n            (rst_n),
    .miss_detected    (miss_detected),
    .miss_address     (miss_address),
    .memory_data      (memory_data),
    .memory_data_valid(memory_data_valid),
    .fsm_busy         (fsm_busy),
    .write_data_array (write_data_array),
    .write_tag_array  (write_tag_array),
    .memory_address   (memory_address)
);

    //testbench will just use personal inspection to ensure it works
    initial begin
         clk = 0; 
         rst = 0;   //active high reset signal
         miss_detected = 0; 
         miss_address = 16'h3B04; 

         @(posedge clk); 
         miss_detected = 1; 
         @(posedge clk);
         miss_detected = 0; 


         @(negedge fsm_busy); 
         $stop(); 


         repeat (5) @(posedge clk);

         miss_address = 16'h02C8; 

        @(posedge clk); 
         miss_detected = 1; 
         @(posedge clk);
         miss_detected = 0;

         @(negedge fsm_busy); 
         $stop();
         //check for outputting correct memory blocks
         //check it does it for correct number of cycles
         //check fsm busy is high for correct amount
    end

    always begin 
        clk = #5 ~clk; 
    end


endmodule
