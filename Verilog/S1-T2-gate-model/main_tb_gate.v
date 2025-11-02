`timescale 1ns / 1ps

module Main_tb;

    // --- Testbench Registers (Inputs) ---
    reg         Clock;
    reg         Insert;
    reg         Serve;
    reg         Reset_Queue;
    reg  [7:0]  Zone;
    reg  [1:0]  Priority;
    reg  [1:0]  Resource_line;

    // --- Testbench Wires (Outputs) ---
    wire        Food_00;
    wire        Shelter_01;
    wire        Evacuation_10;
    wire        Shelter_Full;
    wire        Food_Full;
    wire        Evac_Empty;
    wire        Shelter_Valid;
    wire        Shelter_Boost;
    wire        Food_Valid;
    wire        Food_Boost;
    wire [7:0]  Output_Zone;
    wire [1:0]  Output_Priority;
    
    // --- Clock Generation ---
    parameter CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) Clock = ~Clock;

    // --- Instantiate Device Under Test (DUT) ---
    Main_gate dut (
        .Clock         (Clock),
        .Insert        (Insert),
        .Serve         (Serve),
        .Reset_Queue   (Reset_Queue),
        .Zone          (Zone),
        .Priority      (Priority),
        .Resource_line (Resource_line),

        .Food_00       (Food_00),
        .Shelter_01    (Shelter_01),
        .Evacuation_10 (Evacuation_10),
        .Shelter_Full  (Shelter_Full),
        .Food_Full     (Food_Full),
        .Evac_Empty    (Evac_Empty),
        .Shelter_Valid (Shelter_Valid),
        .Shelter_Boost (Shelter_Boost),
        .Food_Valid    (Food_Valid),
        .Food_Boost    (Food_Boost),
        .Output_Zone   (Output_Zone),
        .Output_Priority (Output_Priority)
    );
    
    // --- Helper Task for Cool Display ---
    task print_state;
        input [50*8-1:0] state_title; 
        begin
            $display("----------------------------------------------------------------------------------");
            $display("  STATE: %s  (Time: %0t ns)", state_title, $time);
            $display("----------------------------------------------------------------------------------");
            $display("  INPUTS:");
            $display("    Insert: %b   Serve: %b   Reset: %b   Resource: %s", 
                     Insert, Serve, Reset_Queue, 
                     (Resource_line == 2'b00) ? "Food" : 
                     (Resource_line == 2'b01) ? "Shelter" :
                     (Resource_line == 2'b10) ? "Evac" : "N/A");
            $display("    Data In -> Zone: 0b%8b, Prio: 0b%2b", (Insert ? Zone : 8'bzzzzzzzz), (Insert ? Priority : 2'bzz));
            $display("");
            $display("  INTERNAL QUEUE STATE:");
            $display("    SHELTER Q (Priority): Full: %b, Valid(Winner): %b, Boost(Winner): %b", Shelter_Full, Shelter_Valid, Shelter_Boost);
            $display("    FOOD Q    (Priority): Full: %b, Valid(Winner): %b, Boost(Winner): %b", Food_Full, Food_Valid, Food_Boost);
            $display("    EVAC Q    (FIFO):     Empty: %b", Evac_Empty);
            $display("");
            $display("  FINAL MUX OUTPUT (Selected by Evac Q 'Empty' signal):");
            $display("    >>> Output Zone: 0b%8b   Output Prio: 0b%2b <<<", Output_Zone, Output_Priority);
            $display("----------------------------------------------------------------------------------\n");
        end
    endtask
    
    // Task to wait for one clock cycle
    task wait_one_cycle;
        begin
            #(CLK_PERIOD);
        end
    endtask


    // --- Test Sequence ---
    initial begin
        // 1. Initialize
        $display("\n\n##################################################################");
        $display("###      DDS MINI PROJECT      ###");
        $display("##################################################################\n");
        Clock         = 0;
        Insert        = 0;
        Serve         = 0;
        Reset_Queue   = 1;
        Zone          = 8'bzzzzzzzz;
        Priority      = 2'b11;
        Resource_line = 2'b01; // Shelter
        
        // 2. Reset
        print_state("--- SYSTEM RESET ---");
        wait_one_cycle;
        Reset_Queue   = 0;
        wait_one_cycle;
        print_state("--- RESET RELEASED (All Qs empty) ---");

        // 3. Insert Shelter Req (Zone 12, Prio 1)
        Insert        = 1;
        Zone          = 8'b00001100; // Zone 12
        Priority      = 2'b01;       // Prio 1
        Resource_line = 2'b01; // Shelter
        print_state("--- INSERT SHELTER (Zone 12, Prio 1) ---");
        wait_one_cycle;
        Insert        = 0;
        print_state("--- POST-INSERT SHELTER (MUX shows Shelter) ---");

        // 4. Insert Food Req (Zone 12, Prio 2)
        Insert        = 1;
        Zone          = 8'b00001100; // Zone 12
        Priority      = 2'b10;       // Prio 2
        Resource_line = 2'b00; // Food
        print_state("--- INSERT FOOD (Zone 12, Prio 2) ---");
        wait_one_cycle;
        Insert        = 0;
        print_state("--- POST-INSERT FOOD (Selector shows Food) ---");

        // 5. Insert Evac Req (Zone 12)
        Insert        = 1;
        Zone          = 8'b00001100; // Zone 12
        Priority      = 2'b01;       // Prio 1
        Resource_line = 2'b10; // Evac
        print_state("--- INSERT EVAC (Zone 12) -> CANCEL OTHERS ---");
        wait_one_cycle;
        Insert        = 0;
        print_state("--- POST-INSERT EVAC (MUX shows Evac, others empty) ---");
        
        // Check if cancellation worked
        if (Shelter_Valid == 0 && Food_Valid == 0 && Evac_Empty == 0) begin
            $display("[SUCCESS] Evac Cancellation for Zone 12 worked!");
        end else begin
            $display("[FAILURE] Evac Cancellation FAILED!");
        end
        
        // 6. Serve the Evac request
        Serve         = 1;
        print_state("--- SERVE EVAC (Zone 12) ---");
        wait_one_cycle;
        Serve         = 0;
        print_state("--- POST-SERVE EVAC (All queues empty) ---");
        
        // 7. Test Shelter vs Food (Food Prio Win)
        Insert        = 1;
        Zone          = 8'b11110000; // Zone 240
        Priority      = 2'b01;       // Prio 1
        Resource_line = 2'b01; // Shelter
        print_state("--- INSERT SHELTER (Zone 240, Prio 1) ---");
        wait_one_cycle;
        
        Insert        = 1;
        Zone          = 8'b00001111; // Zone 15
        Priority      = 2'b10;       // Prio 2
        Resource_line = 2'b00; // Food
        print_state("--- INSERT FOOD (Zone 15, Prio 2) ---");
        wait_one_cycle;
        Insert        = 0;
        print_state("--- POST-INSERT (Food should win on Prio) ---");

        // 8. Serve Food
        Serve         = 1;
        print_state("--- SERVE FOOD (Zone 15) ---");
        wait_one_cycle;
        Serve         = 0;
        print_state("--- POST-SERVE FOOD (MUX switches to Shelter) ---");

        // 9. Serve Shelter
        Serve         = 1;
        print_state("--- SERVE SHELTER (Zone 240) ---");
        wait_one_cycle;
        Serve         = 0;
        print_state("--- POST-SERVE SHELTER (All queues empty) ---");
        
        // 10. Final Check and End Simulation
        if (Evac_Empty == 1 && Shelter_Valid == 0 && Food_Valid == 0) begin
            $display("\n[SUCCESS] All tests passed!");
        end else begin
            $display("\n[FAILURE] Queues are not empty at end of test!");
        end
        $display("##################################################################");
        $display("###                      TESTBENCH END                       ###");
        $display("##################################################################\n");
        $finish;
    end

endmodule
