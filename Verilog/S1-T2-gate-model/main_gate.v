/**
 * Module: Main_gate
 */
module Main_gate (
    // Inputs
    input wire         Clock,
    input wire         Insert,
    input wire         Serve,
    input wire         Reset_Queue,
    input wire [7:0]   Zone,
    input wire [1:0]   Priority,
    input wire [1:0]   Resource_line,

    // Outputs
    output wire        Food_00,
    output wire        Shelter_01,
    output wire        Evacuation_10,
    
    output wire        Shelter_Full,
    output wire        Food_Full,
    output wire        Evac_Empty,
    
    output wire [7:0]  Output_Zone,
    output wire [1:0]  Output_Priority,
    
    output wire        Shelter_Valid,
    output wire        Shelter_Boost,
    output wire        Food_Valid,
    output wire        Food_Boost
);

    // --- Internal Wires ---

    // Decoder Outputs
    wire w_food_req;
    wire w_shelter_req;
    wire w_evac_req;
    wire [3:0] decoder_out;

    // Shelter Q Wires
    wire w_shelter_insert_en;
    wire w_shelter_serve_en;
    wire w_shelter_cancel_en;
    wire [1:0] w_shelter_priority;
    wire [7:0] w_shelter_zone;

    // Food Q Wires
    wire w_food_insert_en;
    wire w_food_serve_en;
    wire w_food_cancel_en;
    wire [1:0] w_food_priority;
    wire [7:0] w_food_zone;
    
    // Evac Q Wires
    wire w_evac_insert_en;
    wire w_evac_serve_en;
    wire [1:0] w_evac_priority;
    wire [7:0] w_evac_zone;

    // Final Selector Wires
    wire w_final_valid;
    wire w_final_boost;
    wire [1:0] w_final_priority;
    wire [7:0] w_final_zone;
    wire w_final_select_shelter; // 1=Shelter, 0=Food
    
    // MUX Control Wires
    wire w_evac_not_empty;
    wire w_rst_n;
    wire [7:0] w_threshold_const = 8'h14; // Default 20 cycles

    // --- Logic Implementation ---

    // 1. Decoder
    decoder_2to4 main_decoder (
        .in(Resource_line),
        .out(decoder_out)
    );
    
    assign Food_00       = decoder_out[0];
    assign Shelter_01    = decoder_out[1];
    assign Evacuation_10 = decoder_out[2];
    
    assign w_food_req    = Food_00;
    assign w_shelter_req = Shelter_01;
    assign w_evac_req    = Evacuation_10;

    // 2. Insertion Routing Logic
    and and_shelter_insert (w_shelter_insert_en, Insert, w_shelter_req);
    and and_food_insert (w_food_insert_en, Insert, w_food_req);
    and and_evac_insert (w_evac_insert_en, Insert, w_evac_req);

    // 3. Cancellation Logic
    assign w_shelter_cancel_en = w_evac_req;
    assign w_food_cancel_en    = w_evac_req;
    
    // 4. MUX and Serve Control Logic (The "Evac-First" Brain)
    not not_evac_empty (w_evac_not_empty, Evac_Empty);

    // The MUX select is controlled by whether the Evac Q has items
    mux_2to1_8bit output_zone_mux (
        .in0(w_final_zone),
        .in1(w_evac_zone),
        .sel(w_evac_not_empty),
        .out(Output_Zone)
    );
    mux_2to1_2bit output_prio_mux (
        .in0(w_final_priority),
        .in1(w_evac_priority),
        .sel(w_evac_not_empty),
        .out(Output_Priority)
    );

    // Route the 'Serve' signal
    and and_evac_serve (w_evac_serve_en, Serve, w_evac_not_empty);
    
    wire not_w_final_select_shelter;
    not not_final_sel (not_w_final_select_shelter, w_final_select_shelter);
    and3 and_shelter_serve (w_shelter_serve_en, Serve, Evac_Empty, w_final_select_shelter);
    and3 and_food_serve (w_food_serve_en, Serve, Evac_Empty, not_w_final_select_shelter);

    // Create active-low reset
    not not_rst (w_rst_n, Reset_Queue);

    // --- Component Instantiation ---

    // 1. Shelter Q (Complex Prio Q)
    priority_Queue_gate_shelter shelter_module_inst (
        .clk           (Clock),
        .rst_n         (w_rst_n),
        .insert        (w_shelter_insert_en),
        .new_zone_id   (Zone),
        .new_priority  (Priority),
        .threshold     (w_threshold_const),
        .serve         (w_shelter_serve_en),
        .cancel_zone   (Zone),
        .cancel_en     (w_shelter_cancel_en),
        
        .to_fsm_zone_id(w_shelter_zone),
        .to_fsm_priority(w_shelter_priority),
        .to_fsm_boost  (Shelter_Boost),
        .to_fsm_valid  (Shelter_Valid),
        .queue_full    (Shelter_Full)
    );

    // 2. Food Q (Complex Prio Q)
    priority_Queue_gate_food food_module_inst (
        .clk           (Clock),
        .rst_n         (w_rst_n),
        .insert        (w_food_insert_en),
        .new_zone_id   (Zone),
        .new_priority  (Priority),
        .threshold     (w_threshold_const),
        .serve         (w_food_serve_en),
        .cancel_zone   (Zone),
        .cancel_en     (w_food_cancel_en),
        
        .to_fsm_zone_id(w_food_zone),
        .to_fsm_priority(w_food_priority),
        .to_fsm_boost  (Food_Boost),
        .to_fsm_valid  (Food_Valid),
        .queue_full    (Food_Full)
    );

    // 3. Evac Q (Simple FIFO)
    Evac_Queue_gate evac_queue_inst (
        .Main_Clock  (Clock),
        .Insert      (w_evac_insert_en),
        .Zone        (Zone),
        .Clear       (Reset_Queue), // Active high clear
        .Reset       (Reset_Queue), // Active high reset
        .Serve       (w_evac_serve_en),
        .Priority    (Priority),

        .Output_Zone   (w_evac_zone),
        .Output_Priority (w_evac_priority),
        .Empty       (Evac_Empty)
    );
    
    // 4. Final Selector (Shelter vs Food)
    Final_Selector_gate final_selector_inst (
        .Shelter_Valid    (Shelter_Valid),
        .Shelter_Boost    (Shelter_Boost),
        .Shelter_Priority (w_shelter_priority),
        .Shelter_Zone     (w_shelter_zone),
    
        .Food_Valid       (Food_Valid),
        .Food_Boost       (Food_Boost),
        .Food_Priority    (w_food_priority),
        .Food_Zone        (w_food_zone),

        .Out_Valid        (w_final_valid),
        .Out_Boost        (w_final_boost),
        .Out_Priority     (w_final_priority),
        .Out_Zone         (w_final_zone),
        
        .Select_Shelter   (w_final_select_shelter)
    );

endmodule
