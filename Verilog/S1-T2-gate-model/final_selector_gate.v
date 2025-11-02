/**
 * Module: Final_Selector_gate
 * * Gate-level implementation of the Final Selector
 * * Implements: Boost > Priority > Shelter-tiebreak
 */
module Final_Selector_gate (
    // Inputs from Shelter Module
    input wire         Shelter_Valid,
    input wire         Shelter_Boost,
    input wire [1:0]   Shelter_Priority,
    input wire [7:0]   Shelter_Zone,
    
    // Inputs from Food Module
    input wire         Food_Valid,
    input wire         Food_Boost,
    input wire [1:0]   Food_Priority,
    input wire [7:0]   Food_Zone,

    // Outputs to Main MUX
    output wire        Out_Valid,
    output wire        Out_Boost,
    output wire [1:0]  Out_Priority,
    output wire [7:0]  Out_Zone,
    
    // Output to Serve Logic
    output wire        Select_Shelter // 1 = Serve Shelter, 0 = Serve Food
);

    // --- Wires ---
    wire not_shelter_valid, not_food_valid;
    wire shelter_only, food_only, both_valid;
    
    wire not_shelter_boost, not_food_boost;
    wire shelter_boost_only, food_boost_only, boost_equal;
    
    wire shelter_pri_gt, prio_equal;
    
    wire select_shelter_cond1; // shelter_only
    wire select_shelter_cond2; // both_valid & shelter_boost_only
    wire select_shelter_cond3; // both_valid & boost_equal & shelter_pri_gt
    wire select_shelter_cond4; // both_valid & boost_equal & prio_equal
    
    wire temp1, temp2;
    
    // --- Logic Implementation ---

    // Rule 1: Check Validity
    not n_sv (not_shelter_valid, Shelter_Valid);
    not n_fv (not_food_valid, Food_Valid);
    
    and and_shelter_only (shelter_only, Shelter_Valid, not_food_valid);
    and and_food_only (food_only, not_shelter_valid, Food_Valid);
    and and_both_valid (both_valid, Shelter_Valid, Food_Valid);
    
    // Rule 2: Check Boost
    not n_sb (not_shelter_boost, Shelter_Boost);
    not n_fb (not_food_boost, Food_Boost);
    
    and and_shelter_boost (shelter_boost_only, Shelter_Boost, not_food_boost);
    and and_food_boost (food_boost_only, Food_Boost, not_shelter_boost);
    
    wire boost_xor;
    xor xor_boost (boost_xor, Shelter_Boost, Food_Boost);
    not not_boost_xor (boost_equal, boost_xor); // boost_equal is XNOR

    // Rule 3: Check Priority
    comparator_2bit pri_comp (
        .a(Shelter_Priority),
        .b(Food_Priority),
        .gt(shelter_pri_gt),
        .eq(prio_equal),
        .lt() // Not needed
    );

    // Combine rules to create final Select_Shelter signal
    // Select_Shelter is true if:
    // 1. shelter_only
    // OR
    // 2. both_valid AND shelter_boost_only
    // OR
    // 3. both_valid AND boost_equal AND shelter_pri_gt
    // OR
    // 4. both_valid AND boost_equal AND prio_equal (Shelter wins tie)

    assign select_shelter_cond1 = shelter_only;
    and and_cond2 (select_shelter_cond2, both_valid, shelter_boost_only);
    and3 and_cond3 (select_shelter_cond3, both_valid, boost_equal, shelter_pri_gt);
    and3 and_cond4 (select_shelter_cond4, both_valid, boost_equal, prio_equal);
    
    or or_s1 (temp1, select_shelter_cond1, select_shelter_cond2);
    or or_s2 (temp2, select_shelter_cond3, select_shelter_cond4);
    or or_s_final (Select_Shelter, temp1, temp2);

    // --- Output MUXes ---
    mux_2to1_1bit valid_mux (.in0(Food_Valid), .in1(Shelter_Valid), .sel(Select_Shelter), .out(Out_Valid));
    mux_2to1_1bit boost_mux (.in0(Food_Boost), .in1(Shelter_Boost), .sel(Select_Shelter), .out(Out_Boost));
    mux_2to1_2bit prio_mux  (.in0(Food_Priority), .in1(Shelter_Priority), .sel(Select_Shelter), .out(Out_Priority));
    mux_2to1_8bit zone_mux  (.in0(Food_Zone), .in1(Shelter_Zone), .sel(Select_Shelter), .out(Out_Zone));

endmodule
