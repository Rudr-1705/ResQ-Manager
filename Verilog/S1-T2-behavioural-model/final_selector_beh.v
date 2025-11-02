/**
 * Module: Final_Selector_behavioral

 * Logic:
 * 1. Check Valid
 * 2. Check Boost (Boosted wins)
 * 3. Check Priority (Higher prio wins)
 * 4. Tie-breaker: Shelter wins
 */
module Final_Selector_behavioral (
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
    output reg         Out_Valid,
    output reg         Out_Boost,
    output reg [1:0]   Out_Priority,
    output reg [7:0]   Out_Zone,
    
    // Output to Serve Logic
    output reg         Select_Shelter // 1 = Serve Shelter, 0 = Serve Food
);

    always @(*) begin
        // --- Rule 1: Check Validity ---
        if (Shelter_Valid && !Food_Valid) begin
            // Only Shelter is valid
            Select_Shelter = 1'b1;
            Out_Valid      = 1'b1;
            Out_Boost      = Shelter_Boost;
            Out_Priority   = Shelter_Priority;
            Out_Zone       = Shelter_Zone;
        end
        else if (!Shelter_Valid && Food_Valid) begin
            // Only Food is valid
            Select_Shelter = 1'b0;
            Out_Valid      = 1'b1;
            Out_Boost      = Food_Boost;
            Out_Priority   = Food_Priority;
            Out_Zone       = Food_Zone;
        end
        else if (!Shelter_Valid && !Food_Valid) begin
            // Both are invalid
            Select_Shelter = 1'b1; // Default to Shelter
            Out_Valid      = 1'b0;
            Out_Boost      = 1'b0;
            Out_Priority   = 2'b00;
            Out_Zone       = 8'h00;
        end
        else begin
            // Both are valid, proceed to rules
            Out_Valid = 1'b1;
            
            // --- Rule 2: Check Boost ---
            if (Shelter_Boost && !Food_Boost) begin
                // Shelter is boosted, Food is not
                Select_Shelter = 1'b1;
                Out_Boost      = Shelter_Boost;
                Out_Priority   = Shelter_Priority;
                Out_Zone       = Shelter_Zone;
            end
            else if (!Shelter_Boost && Food_Boost) begin
                // Food is boosted, Shelter is not
                Select_Shelter = 1'b0;
                Out_Boost      = Food_Boost;
                Out_Priority   = Food_Priority;
                Out_Zone       = Food_Zone;
            end
            else begin
                // Boost is tied (both 1 or both 0)
                // --- Rule 3: Check Priority ---
                if (Shelter_Priority > Food_Priority) begin
                    // Shelter has higher priority
                    Select_Shelter = 1'b1;
                    Out_Boost      = Shelter_Boost;
                    Out_Priority   = Shelter_Priority;
                    Out_Zone       = Shelter_Zone;
                end
                else if (Food_Priority > Shelter_Priority) begin
                    // Food has higher priority
                    Select_Shelter = 1'b0;
                    Out_Boost      = Food_Boost;
                    Out_Priority   = Food_Priority;
                    Out_Zone       = Food_Zone;
                end
                else begin
                    // Priority is also tied
                    // --- Rule 4: Final Tie-Breaker ---
                    // Shelter wins by default
                    Select_Shelter = 1'b1;
                    Out_Boost      = Shelter_Boost;
                    Out_Priority   = Shelter_Priority;
                    Out_Zone       = Shelter_Zone;
                end
            end
        end
    end

endmodule

