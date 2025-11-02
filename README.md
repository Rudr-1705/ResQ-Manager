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
      ```
      ```
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
