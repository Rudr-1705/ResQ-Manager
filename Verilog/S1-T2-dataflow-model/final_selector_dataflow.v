/**
 * Module: Final_Selector_dataflow
 * * Dataflow implementation of the Final Selector
 * * Implements: Boost > Priority > Shelter-tiebreak
 */
module Final_Selector_dataflow (
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

    // --- Wire Declarations ---
    wire shelter_only, food_only, both_valid;
    wire shelter_boost_only, food_boost_only, boost_equal;
    wire shelter_pri_gt, food_pri_gt, prio_equal;

    // --- Dataflow Logic ---
    
    // Rule 1: Check Validity
    assign shelter_only = Shelter_Valid & ~Food_Valid;
    assign food_only = ~Shelter_Valid & Food_Valid;
    assign both_valid = Shelter_Valid & Food_Valid;
    
    // Rule 2: Check Boost
    assign shelter_boost_only = Shelter_Boost & ~Food_Boost;
    assign food_boost_only = ~Shelter_Boost & Food_Boost;
    assign boost_equal = (Shelter_Boost == Food_Boost); // Both 1 or both 0
    
    // Rule 3: Check Priority
    assign shelter_pri_gt = (Shelter_Priority > Food_Priority);
    assign food_pri_gt = (Food_Priority > Shelter_Priority);
    assign prio_equal = (Shelter_Priority == Food_Priority);
    
    // Rule 4: Final Selection Logic
    // Shelter wins if:
    // 1. It's the only one valid.
    // 2. Both are valid AND it's the only one boosted.
    // 3. Both are valid AND boost is tied AND its priority is higher.
    // 4. Both are valid AND boost is tied AND priority is tied (Shelter wins tie-break).
    assign Select_Shelter = shelter_only |
                            (both_valid & shelter_boost_only) |
                            (both_valid & boost_equal & shelter_pri_gt) |
                            (both_valid & boost_equal & prio_equal);
                            
    // --- Output Assignments ---
    
    // The winner's signals are passed to the output
    assign Out_Valid    = Shelter_Valid | Food_Valid;
    assign Out_Zone     = Select_Shelter ? Shelter_Zone : Food_Zone;
    assign Out_Priority = Select_Shelter ? Shelter_Priority : Food_Priority;
    assign Out_Boost    = Select_Shelter ? Shelter_Boost : Food_Boost;

endmodule
