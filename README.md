# ResQ-Manager: A Priority-Based Disaster Relief System

<!-- First Section -->
## Team Details
<details>
  <summary>Detail</summary>

  > Semester: 3rd Sem B. Tech. CSE

  > Section: S1

  > Team ID: S1-T2

  > Member-1: Pradyun Diwakar, 241CS141, pradyund.241cs141@nitk.edu.in

  > Member-2: Rudraksh Mahajan, 241CS150, rudrakshmahajan.241cs150@nitk.edu.in

  > Member-3: Tanay Nahta, 241CS159, tanaynahta.241cs159@nitk.edu.in
</details>

<!-- Second Section -->
## Abstract
<details>
  <summary>Detail</summary>
  
  > Disasters such as floods, earthquakes, and cyclones create urgent demands for relief resources like transport vehicles, food packets, and shelter space. Manual allocation of these resources often results in delays, inefficiencies, and unfair distribution. This project, titled ResQ-Manager, proposes a hardware-oriented digital system that manages disaster relief requests using priority-based scheduling and finite state machine (FSM) logic. The system integrates three modules: a Transport Scheduler, a Food Resource Allocator, and a Shelter Availability Checker. Each request is assigned a priority level (Normal, High, Emergency), and the system ensures that higher-priority zones receive resources first while also implementing fairness mechanisms to avoid starvation. The Coordinator FSM orchestrates communication between modules, checks resource availability, and updates outputs through LEDs, seven-segment displays, and optional LCD modules. By combining combinational and sequential logic, this system demonstrates how digital design can be applied to solve real-world problems. The proposed solution highlights concepts of queue management, priority arbitration, and hardware-friendly scheduling algorithms, making it both educational and socially impactful. The final system can be simulated in FPGA/Logisim and later scaled into IoT-enabled prototypes for actual disaster management use.
</details>

## Functional Block Diagram
<details>
  <summary>Detail</summary>

  
</details>

<!-- Third Section -->
## Working
<details>
  <summary>Detail</summary>

  > Explain how your model works with the help of a functional table (compulsory) followed by the flowchart.
</details>

<!-- Fourth Section -->
## Logisim Circuit Diagram
<details>
  <summary>Detail</summary>
    

  > Update a neat logisim circuit diagram
</details>

<!-- Fifth Section -->
## Verilog Code

<details>
    <summary>Verilog Behavioral level code</summary>
      <details>
      <summary>Main FSM Behavioral level code</summary>
      ```
      ```
      </details>
      <details>
      <summary>Shelter Module Behavioral level code</summary>
        
    // SHELTER MODULE - BEHAVIORAL IMPLEMENTATION

    // MODULE: Request Register (Behavioral)
    module request_register_behavioral (
    input wire clk,
    input wire rst_n,
    input wire write_en,
    input wire [7:0] zone_id_in,
    input wire [1:0] priority_in,
    input wire increment_wait,
    input wire set_boost,
    input wire clear,
    output reg [7:0] zone_id_out,
    output reg [1:0] priority_out,
    output reg [7:0] waiting_time_out,
    output reg valid_out,
    output reg boost_out
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            zone_id_out <= 8'd0;
            priority_out <= 2'd0;
            waiting_time_out <= 8'd0;
            valid_out <= 1'b0;
            boost_out <= 1'b0;
        end
        else if (clear) begin
            zone_id_out <= 8'd0;
            priority_out <= 2'd0;
            waiting_time_out <= 8'd0;
            valid_out <= 1'b0;
            boost_out <= 1'b0;
        end
        else begin
            if (write_en) begin
                zone_id_out <= zone_id_in;
                priority_out <= priority_in;
                waiting_time_out <= 8'd0;
                valid_out <= 1'b1;
                boost_out <= 1'b0;
            end
            else begin
                if (increment_wait && valid_out) begin
                    waiting_time_out <= waiting_time_out + 8'd1;
                end
                
                if (set_boost) begin
                    boost_out <= 1'b1;
                end
            end
        end
    end

    endmodule

    // MODULE: Threshold Comparator (Behavioral)
    module threshold_comparator_behavioral (
    input wire [7:0] waiting_time,
    input wire [7:0] threshold,
    input wire valid,
    output reg should_boost
    );

    always @(*) begin
        if (valid && (waiting_time >= threshold))
            should_boost = 1'b1;
        else
            should_boost = 1'b0;
    end

    endmodule

    // MODULE: Priority Encoder 2-to-1 (Behavioral)
    module priority_encoder_2to1_behavioral (
    input wire [7:0] a_zone_id,
    input wire [1:0] a_priority,
    input wire [7:0] a_waiting_time,
    input wire a_boost,
    input wire a_valid,
    
    input wire [7:0] b_zone_id,
    input wire [1:0] b_priority,
    input wire [7:0] b_waiting_time,
    input wire b_boost,
    input wire b_valid,
    
    output reg [7:0] out_zone_id,
    output reg [1:0] out_priority,
    output reg [7:0] out_waiting_time,
    output reg out_boost,
    output reg out_valid,
    output reg select_a
    );

    always @(*) begin
        // Default: select nothing
        select_a = 1'b0;
        out_zone_id = 8'd0;
        out_priority = 2'd0;
        out_waiting_time = 8'd0;
        out_boost = 1'b0;
        out_valid = 1'b0;
        
        // Priority selection logic
        if (!a_valid && !b_valid) begin
            // Both invalid
            select_a = 1'b0;
            out_valid = 1'b0;
        end
        else if (a_valid && !b_valid) begin
            // Only A valid
            select_a = 1'b1;
            out_zone_id = a_zone_id;
            out_priority = a_priority;
            out_waiting_time = a_waiting_time;
            out_boost = a_boost;
            out_valid = 1'b1;
        end
        else if (!a_valid && b_valid) begin
            // Only B valid
            select_a = 1'b0;
            out_zone_id = b_zone_id;
            out_priority = b_priority;
            out_waiting_time = b_waiting_time;
            out_boost = b_boost;
            out_valid = 1'b1;
        end
        else begin
            // Both valid - apply priority rules
            if (a_boost && !b_boost) begin
                // A boosted, B not
                select_a = 1'b1;
                out_zone_id = a_zone_id;
                out_priority = a_priority;
                out_waiting_time = a_waiting_time;
                out_boost = a_boost;
                out_valid = 1'b1;
            end
            else if (!a_boost && b_boost) begin
                // B boosted, A not
                select_a = 1'b0;
                out_zone_id = b_zone_id;
                out_priority = b_priority;
                out_waiting_time = b_waiting_time;
                out_boost = b_boost;
                out_valid = 1'b1;
            end
            else begin
                // Both boosted or both not boosted
                if (a_priority > b_priority) begin
                    // A higher priority
                    select_a = 1'b1;
                    out_zone_id = a_zone_id;
                    out_priority = a_priority;
                    out_waiting_time = a_waiting_time;
                    out_boost = a_boost;
                    out_valid = 1'b1;
                end
                else if (b_priority > a_priority) begin
                    // B higher priority
                    select_a = 1'b0;
                    out_zone_id = b_zone_id;
                    out_priority = b_priority;
                    out_waiting_time = b_waiting_time;
                    out_boost = b_boost;
                    out_valid = 1'b1;
                end
                else begin
                    // Same priority - use FIFO (older = higher waiting time)
                    if (a_waiting_time >= b_waiting_time) begin
                        select_a = 1'b1;
                        out_zone_id = a_zone_id;
                        out_priority = a_priority;
                        out_waiting_time = a_waiting_time;
                        out_boost = a_boost;
                        out_valid = 1'b1;
                    end
                    else begin
                        select_a = 1'b0;
                        out_zone_id = b_zone_id;
                        out_priority = b_priority;
                        out_waiting_time = b_waiting_time;
                        out_boost = b_boost;
                        out_valid = 1'b1;
                    end
                end
            end
        end
    end

    endmodule

    // MODULE: Serve Decoder (Behavioral)
    module serve_decoder_behavioral (
    input wire serve,
    input wire [1:0] selected_index,
    output reg serve_0,
    output reg serve_1,
    output reg serve_2,
    output reg serve_3
    );

    always @(*) begin
        serve_0 = 1'b0;
        serve_1 = 1'b0;
        serve_2 = 1'b0;
        serve_3 = 1'b0;
        
        if (serve) begin
            case (selected_index)
                2'b00: serve_0 = 1'b1;
                2'b01: serve_1 = 1'b1;
                2'b10: serve_2 = 1'b1;
                2'b11: serve_3 = 1'b1;
            endcase
        end
    end

    endmodule

    // MODULE: Queue Storage (Behavioral)
    module queue_storage_behavioral (
    input wire clk,
    input wire rst_n,
    input wire insert,
    input wire [7:0] new_zone_id,
    input wire [1:0] new_priority,
    input wire serve,
    input wire [1:0] selected_index,
    input wire [7:0] cancel_zone,
    input wire cancel_en,
    input wire [7:0] threshold,
    
    output wire [7:0] entry0_zone_id,
    output wire [1:0] entry0_priority,
    output wire [7:0] entry0_waiting_time,
    output wire entry0_boost,
    output wire entry0_valid,
    
    output wire [7:0] entry1_zone_id,
    output wire [1:0] entry1_priority,
    output wire [7:0] entry1_waiting_time,
    output wire entry1_boost,
    output wire entry1_valid,
    
    output wire [7:0] entry2_zone_id,
    output wire [1:0] entry2_priority,
    output wire [7:0] entry2_waiting_time,
    output wire entry2_boost,
    output wire entry2_valid,
    
    output wire [7:0] entry3_zone_id,
    output wire [1:0] entry3_priority,
    output wire [7:0] entry3_waiting_time,
    output wire entry3_boost,
    output wire entry3_valid,
    
    output wire queue_full
    );

    // Write enable signals
    reg write_en_0, write_en_1, write_en_2, write_en_3;
    
    // Serve signals
    wire serve_0, serve_1, serve_2, serve_3;
    
    // Clear signals
    reg clear_0, clear_1, clear_2, clear_3;
    
    // Boost signals
    wire should_boost_0, should_boost_1, should_boost_2, should_boost_3;
    
    // Write enable logic
    always @(*) begin
        write_en_0 = 1'b0;
        write_en_1 = 1'b0;
        write_en_2 = 1'b0;
        write_en_3 = 1'b0;
        
        if (insert) begin
            if (!entry0_valid)
                write_en_0 = 1'b1;
            else if (!entry1_valid)
                write_en_1 = 1'b1;
            else if (!entry2_valid)
                write_en_2 = 1'b1;
            else if (!entry3_valid)
                write_en_3 = 1'b1;
        end
    end
    
    // Serve decoder
    serve_decoder_behavioral serve_dec (
        .serve(serve),
        .selected_index(selected_index),
        .serve_0(serve_0),
        .serve_1(serve_1),
        .serve_2(serve_2),
        .serve_3(serve_3)
    );
    
    // Clear logic (serve or cancel)
    always @(*) begin
        clear_0 = serve_0 | (cancel_en & (entry0_zone_id == cancel_zone) & entry0_valid);
        clear_1 = serve_1 | (cancel_en & (entry1_zone_id == cancel_zone) & entry1_valid);
        clear_2 = serve_2 | (cancel_en & (entry2_zone_id == cancel_zone) & entry2_valid);
        clear_3 = serve_3 | (cancel_en & (entry3_zone_id == cancel_zone) & entry3_valid);
    end
    
    // Request registers
    request_register_behavioral reg0 (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(write_en_0),
        .zone_id_in(new_zone_id),
        .priority_in(new_priority),
        .increment_wait(1'b1),
        .set_boost(should_boost_0),
        .clear(clear_0),
        .zone_id_out(entry0_zone_id),
        .priority_out(entry0_priority),
        .waiting_time_out(entry0_waiting_time),
        .valid_out(entry0_valid),
        .boost_out(entry0_boost)
    );
    
    request_register_behavioral reg1 (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(write_en_1),
        .zone_id_in(new_zone_id),
        .priority_in(new_priority),
        .increment_wait(1'b1),
        .set_boost(should_boost_1),
        .clear(clear_1),
        .zone_id_out(entry1_zone_id),
        .priority_out(entry1_priority),
        .waiting_time_out(entry1_waiting_time),
        .valid_out(entry1_valid),
        .boost_out(entry1_boost)
    );
    
    request_register_behavioral reg2 (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(write_en_2),
        .zone_id_in(new_zone_id),
        .priority_in(new_priority),
        .increment_wait(1'b1),
        .set_boost(should_boost_2),
        .clear(clear_2),
        .zone_id_out(entry2_zone_id),
        .priority_out(entry2_priority),
        .waiting_time_out(entry2_waiting_time),
        .valid_out(entry2_valid),
        .boost_out(entry2_boost)
    );
    
    request_register_behavioral reg3 (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(write_en_3),
        .zone_id_in(new_zone_id),
        .priority_in(new_priority),
        .increment_wait(1'b1),
        .set_boost(should_boost_3),
        .clear(clear_3),
        .zone_id_out(entry3_zone_id),
        .priority_out(entry3_priority),
        .waiting_time_out(entry3_waiting_time),
        .valid_out(entry3_valid),
        .boost_out(entry3_boost)
    );
    
    // Threshold comparators
    threshold_comparator_behavioral comp0 (
        .waiting_time(entry0_waiting_time),
        .threshold(threshold),
        .valid(entry0_valid),
        .should_boost(should_boost_0)
    );
    
    threshold_comparator_behavioral comp1 (
        .waiting_time(entry1_waiting_time),
        .threshold(threshold),
        .valid(entry1_valid),
        .should_boost(should_boost_1)
    );
    
    threshold_comparator_behavioral comp2 (
        .waiting_time(entry2_waiting_time),
        .threshold(threshold),
        .valid(entry2_valid),
        .should_boost(should_boost_2)
    );
    
    threshold_comparator_behavioral comp3 (
        .waiting_time(entry3_waiting_time),
        .threshold(threshold),
        .valid(entry3_valid),
        .should_boost(should_boost_3)
    );
    
    // Queue full signal
    assign queue_full = entry0_valid & entry1_valid & entry2_valid & entry3_valid;

    endmodule

    // MODULE: Priority Selector Tree (Behavioral)
    module priority_selector_tree_behavioral (
    input wire [7:0] entry0_zone_id,
    input wire [1:0] entry0_priority,
    input wire [7:0] entry0_waiting_time,
    input wire entry0_boost,
    input wire entry0_valid,
    
    input wire [7:0] entry1_zone_id,
    input wire [1:0] entry1_priority,
    input wire [7:0] entry1_waiting_time,
    input wire entry1_boost,
    input wire entry1_valid,
    
    input wire [7:0] entry2_zone_id,
    input wire [1:0] entry2_priority,
    input wire [7:0] entry2_waiting_time,
    input wire entry2_boost,
    input wire entry2_valid,
    
    input wire [7:0] entry3_zone_id,
    input wire [1:0] entry3_priority,
    input wire [7:0] entry3_waiting_time,
    input wire entry3_boost,
    input wire entry3_valid,
    
    output wire [7:0] selected_zone_id,
    output wire [1:0] selected_priority,
    output wire [7:0] selected_waiting_time,
    output wire selected_boost,
    output wire selected_valid,
    output wire [1:0] selected_index
    );

    wire [7:0] winner_01_zone, winner_23_zone;
    wire [1:0] winner_01_pri, winner_23_pri;
    wire [7:0] winner_01_wait, winner_23_wait;
    wire winner_01_boost, winner_23_boost;
    wire winner_01_valid, winner_23_valid;
    wire select_01_a, select_23_a, select_final_a;
    
    // First level comparisons
    priority_encoder_2to1_behavioral comp_01 (
        .a_zone_id(entry0_zone_id),
        .a_priority(entry0_priority),
        .a_waiting_time(entry0_waiting_time),
        .a_boost(entry0_boost),
        .a_valid(entry0_valid),
        .b_zone_id(entry1_zone_id),
        .b_priority(entry1_priority),
        .b_waiting_time(entry1_waiting_time),
        .b_boost(entry1_boost),
        .b_valid(entry1_valid),
        .out_zone_id(winner_01_zone),
        .out_priority(winner_01_pri),
        .out_waiting_time(winner_01_wait),
        .out_boost(winner_01_boost),
        .out_valid(winner_01_valid),
        .select_a(select_01_a)
    );
    
    priority_encoder_2to1_behavioral comp_23 (
        .a_zone_id(entry2_zone_id),
        .a_priority(entry2_priority),
        .a_waiting_time(entry2_waiting_time),
        .a_boost(entry2_boost),
        .a_valid(entry2_valid),
        .b_zone_id(entry3_zone_id),
        .b_priority(entry3_priority),
        .b_waiting_time(entry3_waiting_time),
        .b_boost(entry3_boost),
        .b_valid(entry3_valid),
        .out_zone_id(winner_23_zone),
        .out_priority(winner_23_pri),
        .out_waiting_time(winner_23_wait),
        .out_boost(winner_23_boost),
        .out_valid(winner_23_valid),
        .select_a(select_23_a)
    );
    
    // Final comparison
    priority_encoder_2to1_behavioral comp_final (
        .a_zone_id(winner_01_zone),
        .a_priority(winner_01_pri),
        .a_waiting_time(winner_01_wait),
        .a_boost(winner_01_boost),
        .a_valid(winner_01_valid),
        .b_zone_id(winner_23_zone),
        .b_priority(winner_23_pri),
        .b_waiting_time(winner_23_wait),
        .b_boost(winner_23_boost),
        .b_valid(winner_23_valid),
        .out_zone_id(selected_zone_id),
        .out_priority(selected_priority),
        .out_waiting_time(selected_waiting_time),
        .out_boost(selected_boost),
        .out_valid(selected_valid),
        .select_a(select_final_a)
    );
    
    // Index tracking
    reg [1:0] index_01, index_23;
    
    always @(*) begin
        if (select_01_a)
            index_01 = 2'b00;
        else
            index_01 = 2'b01;
            
        if (select_23_a)
            index_23 = 2'b10;
        else
            index_23 = 2'b11;
    end
    
    assign selected_index = select_final_a ? index_01 : index_23;

    endmodule

    // MODULE: Shelter Module Top Level (Behavioral)
    module shelter_module_behavioral (
    input wire clk,
    input wire rst_n,
    input wire insert,
    input wire [7:0] new_zone_id,
    input wire [1:0] new_priority,
    input wire [7:0] threshold,
    input wire serve,
    input wire [7:0] cancel_zone,
    input wire cancel_en,
    
    output wire [7:0] to_fsm_zone_id,
    output wire [1:0] to_fsm_priority,
    output wire to_fsm_boost,
    output wire to_fsm_valid,
    output wire queue_full
    );

    wire [7:0] entry0_zone_id, entry1_zone_id, entry2_zone_id, entry3_zone_id;
    wire [1:0] entry0_priority, entry1_priority, entry2_priority, entry3_priority;
    wire [7:0] entry0_waiting_time, entry1_waiting_time, entry2_waiting_time, entry3_waiting_time;
    wire entry0_boost, entry1_boost, entry2_boost, entry3_boost;
    wire entry0_valid, entry1_valid, entry2_valid, entry3_valid;
    wire [1:0] selected_index;
    wire [7:0] selected_waiting_time;
    
    queue_storage_behavioral queue (
        .clk(clk),
        .rst_n(rst_n),
        .insert(insert),
        .new_zone_id(new_zone_id),
        .new_priority(new_priority),
        .serve(serve),
        .selected_index(selected_index),
        .cancel_zone(cancel_zone),
        .cancel_en(cancel_en),
        .threshold(threshold),
        .entry0_zone_id(entry0_zone_id),
        .entry0_priority(entry0_priority),
        .entry0_waiting_time(entry0_waiting_time),
        .entry0_boost(entry0_boost),
        .entry0_valid(entry0_valid),
        .entry1_zone_id(entry1_zone_id),
        .entry1_priority(entry1_priority),
        .entry1_waiting_time(entry1_waiting_time),
        .entry1_boost(entry1_boost),
        .entry1_valid(entry1_valid),
        .entry2_zone_id(entry2_zone_id),
        .entry2_priority(entry2_priority),
        .entry2_waiting_time(entry2_waiting_time),
        .entry2_boost(entry2_boost),
        .entry2_valid(entry2_valid),
        .entry3_zone_id(entry3_zone_id),
        .entry3_priority(entry3_priority),
        .entry3_waiting_time(entry3_waiting_time),
        .entry3_boost(entry3_boost),
        .entry3_valid(entry3_valid),
        .queue_full(queue_full)
    );
    
    priority_selector_tree_behavioral selector (
        .entry0_zone_id(entry0_zone_id),
        .entry0_priority(entry0_priority),
        .entry0_waiting_time(entry0_waiting_time),
        .entry0_boost(entry0_boost),
        .entry0_valid(entry0_valid),
        .entry1_zone_id(entry1_zone_id),
        .entry1_priority(entry1_priority),
        .entry1_waiting_time(entry1_waiting_time),
        .entry1_boost(entry1_boost),
        .entry1_valid(entry1_valid),
        .entry2_zone_id(entry2_zone_id),
        .entry2_priority(entry2_priority),
        .entry2_waiting_time(entry2_waiting_time),
        .entry2_boost(entry2_boost),
        .entry2_valid(entry2_valid),
        .entry3_zone_id(entry3_zone_id),
        .entry3_priority(entry3_priority),
        .entry3_waiting_time(entry3_waiting_time),
        .entry3_boost(entry3_boost),
        .entry3_valid(entry3_valid),
        .selected_zone_id(to_fsm_zone_id),
        .selected_priority(to_fsm_priority),
        .selected_waiting_time(selected_waiting_time),
        .selected_boost(to_fsm_boost),
        .selected_valid(to_fsm_valid),
        .selected_index(selected_index)
    );

    endmodule
   </details>
      <details>
      <summary>Food Module Behavioral level code</summary>
        
     module food_allocator_behavioral #(
    parameter QUEUE_DEPTH = 8,           // Maximum number of pending requests
    parameter ZONE_ID_WIDTH = 4,         // Bits for zone identification
    parameter PEOPLE_WIDTH = 8,          // Bits for number of people
    parameter PRIORITY_WIDTH = 2,        // 2 bits: 00=Normal, 01=High, 10=Emergency
    parameter WAIT_TIME_WIDTH = 8,       // Counter width for waiting time
    parameter STARVATION_THRESHOLD = 10  // Cycles before boost
    
    )(
    input wire clk,
    input wire reset,
    
    // New request interface
    input wire new_request,
    input wire [ZONE_ID_WIDTH-1:0] zone_id_in,
    input wire [PRIORITY_WIDTH-1:0] priority_in,
    input wire [PEOPLE_WIDTH-1:0] num_people_in,
    
    // FSM acknowledgment interface
    input wire fsm_ack,
    
    // Cancellation interface (for evacuation)
    input wire cancel_request,
    input wire [ZONE_ID_WIDTH-1:0] cancel_zone_id,
    
    // Output to Coordinator FSM
    output reg valid_request,
    output reg [ZONE_ID_WIDTH-1:0] zone_id_out,
    output reg [PRIORITY_WIDTH-1:0] priority_out,
    output reg [PEOPLE_WIDTH-1:0] num_people_out,
    output reg boost_flag_out,
    
    // Status outputs
    output reg [3:0] queue_occupancy,
    output reg queue_full,
    output reg queue_empty
    );

    // Priority encoding
    localparam PRIORITY_NORMAL = 2'b00;
    localparam PRIORITY_HIGH = 2'b01;
    localparam PRIORITY_EMERGENCY = 2'b10;
    
    // Queue storage structures
    reg [ZONE_ID_WIDTH-1:0] queue_zone_id [0:QUEUE_DEPTH-1];
    reg [PRIORITY_WIDTH-1:0] queue_priority [0:QUEUE_DEPTH-1];
    reg [PEOPLE_WIDTH-1:0] queue_num_people [0:QUEUE_DEPTH-1];
    reg [WAIT_TIME_WIDTH-1:0] queue_wait_time [0:QUEUE_DEPTH-1];
    reg queue_boost_flag [0:QUEUE_DEPTH-1];
    reg queue_valid [0:QUEUE_DEPTH-1];
    
    // Internal variables
    integer i, j;
    reg [3:0] selected_index;
    reg found_request;
    
    // Queue management
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize all queue entries
            for (i = 0; i < QUEUE_DEPTH; i = i + 1) begin
                queue_zone_id[i] <= 0;
                queue_priority[i] <= 0;
                queue_num_people[i] <= 0;
                queue_wait_time[i] <= 0;
                queue_boost_flag[i] <= 0;
                queue_valid[i] <= 0;
            end
            valid_request <= 0;
            zone_id_out <= 0;
            priority_out <= 0;
            num_people_out <= 0;
            boost_flag_out <= 0;
            queue_occupancy <= 0;
        end
        else begin
            // Handle new request insertion
            if (new_request && !queue_full) begin
                // Find first empty slot
                for (i = 0; i < QUEUE_DEPTH; i = i + 1) begin
                    if (!queue_valid[i]) begin
                        queue_zone_id[i] <= zone_id_in;
                        queue_priority[i] <= priority_in;
                        queue_num_people[i] <= num_people_in;
                        queue_wait_time[i] <= 0;
                        queue_boost_flag[i] <= 0;
                        queue_valid[i] <= 1;
                        i = QUEUE_DEPTH; // Exit loop
                    end
                end
            end
            
            // Handle cancellation requests
            if (cancel_request) begin
                for (i = 0; i < QUEUE_DEPTH; i = i + 1) begin
                    if (queue_valid[i] && queue_zone_id[i] == cancel_zone_id) begin
                        queue_valid[i] <= 0;
                    end
                end
            end
            
            // Handle FSM acknowledgment (remove served request)
            if (fsm_ack && valid_request) begin
                queue_valid[selected_index] <= 0;
            end
            
            // Increment waiting times and check for boost
            for (i = 0; i < QUEUE_DEPTH; i = i + 1) begin
                if (queue_valid[i]) begin
                    queue_wait_time[i] <= queue_wait_time[i] + 1;
                    if (queue_wait_time[i] >= STARVATION_THRESHOLD) begin
                        queue_boost_flag[i] <= 1;
                    end
                end
            end
            
            // Select highest priority request
            found_request = 0;
            selected_index = 0;
            valid_request <= 0;
            
            // Priority selection logic:
            // 1. Boosted requests (oldest first)
            // 2. Emergency requests
            // 3. High priority requests
            // 4. Normal priority requests
            
            for (i = 0; i < QUEUE_DEPTH; i = i + 1) begin
                if (queue_valid[i] && !found_request) begin
                    if (queue_boost_flag[i]) begin
                        selected_index = i;
                        found_request = 1;
                    end
                end
            end
            
            if (!found_request) begin
                for (i = 0; i < QUEUE_DEPTH; i = i + 1) begin
                    if (queue_valid[i] && queue_priority[i] == PRIORITY_EMERGENCY) begin
                        selected_index = i;
                        found_request = 1;
                        i = QUEUE_DEPTH; // Exit loop
                    end
                end
            end
            
            if (!found_request) begin
                for (i = 0; i < QUEUE_DEPTH; i = i + 1) begin
                    if (queue_valid[i] && queue_priority[i] == PRIORITY_HIGH) begin
                        selected_index = i;
                        found_request = 1;
                        i = QUEUE_DEPTH; // Exit loop
                    end
                end
            end
            
            if (!found_request) begin
                for (i = 0; i < QUEUE_DEPTH; i = i + 1) begin
                    if (queue_valid[i] && queue_priority[i] == PRIORITY_NORMAL) begin
                        selected_index = i;
                        found_request = 1;
                        i = QUEUE_DEPTH; // Exit loop
                    end
                end
            end
            
            // Output selected request
            if (found_request) begin
                valid_request <= 1;
                zone_id_out <= queue_zone_id[selected_index];
                priority_out <= queue_priority[selected_index];
                num_people_out <= queue_num_people[selected_index];
                boost_flag_out <= queue_boost_flag[selected_index];
            end
        end
    end
    
    // Calculate queue occupancy
    always @(*) begin
        queue_occupancy = 0;
        for (i = 0; i < QUEUE_DEPTH; i = i + 1) begin
            if (queue_valid[i]) begin
                queue_occupancy = queue_occupancy + 1;
            end
        end
        queue_full = (queue_occupancy == QUEUE_DEPTH);
        queue_empty = (queue_occupancy == 0);
    end

    endmodule
      </details>
      
</details>
<details>
    <summary>Verilog Dataflow level code</summary>
      <details>
      <summary>Main FSM Dataflow level code</summary>
      ```
      ```
      </details>
      <details>
      <summary>Shelter Module Dataflow level code</summary>
      ```
      ```
      </details>
      <details>
      <summary>Food Module Dataflow level code</summary>
      ```
      ```
      </details>
</details>
<details>
    <summary>Verilog Gate level code</summary>
      <details>
      <summary>Main FSM Gate level code</summary>
      ```
      ```
      </details>
      <details>
      <summary>Shelter Module Gate level code</summary>
      ```
      ```
      </details>
      <details>
      <summary>Food Module Gate level code</summary>
      ```
      ```
      </details>
</details>
<details>
    <summary>TestBench</summary>
      <details>
      <summary>Main FSM TestBench</summary>
      ```
      ```
      </details>
      <details>
      <summary>Shelter Module TestBench</summary>
       ```
       ```
      </details>
      <details>
      <summary>Food Module TestBench</summary>
       ```
       ```
      </details>
</details>

## References
<details>
  <summary>Detail</summary>
  
> 1. Morris Mano, ”Digital Design,” Pearson Education, 5th Edition, 2013.
> 2. Andrew S. Tanenbaum, ”Structured Computer Organization,” Pearson, 6th Edition, 2013.
> 3. FPGA4Student, ”Design of Priority Encoder and FSM in Verilog,” 2020, available online.
> 4. IEEE Xplore, ”Priority-based Scheduling Algorithms for Disaster Resource Management,” 2019.
   
</details>
