/**
 * Module: Evac_Queue_behavioral
 */
module Evac_Queue_behavioral (
    // Inputs
    input wire         Main_Clock,
    input wire         Insert,      // Signal to insert data
    input wire         Serve,       // Signal to serve data
    input wire         Reset,       // Resets head/tail counters
    input wire         Clear,       // Clears the item counter
    input wire [7:0]   Zone,        // 8-bit Zone data to insert
    input wire [1:0]   Priority,    // 2-bit Priority data to insert

    // Outputs
    output wire [7:0]  Output_Zone, // 8-bit Zone data from the tail
    output wire [1:0]  Output_Priority, // 2-bit Priority data from the tail
    output wire        Empty        // Flag is high when queue is empty
);

    // 4-element storage for Zone data
    reg [7:0] zone_reg_0;
    reg [7:0] zone_reg_1;
    reg [7:0] zone_reg_2;
    reg [7:0] zone_reg_3;

    // 4-element storage for Priority data
    reg [1:0] prio_reg_0;
    reg [1:0] prio_reg_1;
    reg [1:0] prio_reg_2;
    reg [1:0] prio_reg_3;

    // Counters
    reg [7:0] item_counter; // 8-bit counter for num items
    reg [1:0] head_counter; // 2-bit counter for insertion
    reg [1:0] tail_counter; // 2-bit counter for serving
    
    // Wires for decoding and enables
    wire [3:0] write_enable; // 4-bit write enable from decoder

    // Item counter (tracks if empty/full)
    always @(posedge Main_Clock or posedge Clear) begin
        if (Clear) begin
            item_counter <= 8'd0;
        end else begin
            if (Insert && !Serve) begin // Insert only
                item_counter <= item_counter + 1;
            end else if (!Insert && Serve && !Empty) begin // Serve only
                item_counter <= item_counter - 1;
            end
            // If Insert and Serve happen simultaneously, count stays the same
        end
    end

    // Head (insertion) counter
    always @(posedge Main_Clock or posedge Reset) begin
        if (Reset) begin
            head_counter <= 2'd0;
        end else if (Insert) begin
            head_counter <= head_counter + 1; // Wraps around (0, 1, 2, 3, 0...)
        end
    end

    // Tail (serving) counter
    always @(posedge Main_Clock or posedge Reset) begin
        if (Reset) begin
            tail_counter <= 2'd0;
        end else if (Serve && !Empty) begin // Only increment tail if serving and not empty
            tail_counter <= tail_counter + 1; // Wraps around
        end
    end

    // 2-to-4 Decoder for write enable
    assign write_enable = (head_counter == 2'b00) ? 4'b0001 :
                          (head_counter == 2'b01) ? 4'b0010 :
                          (head_counter == 2'b10) ? 4'b0100 :
                          (head_counter == 2'b11) ? 4'b1000 :
                          4'b0000; // Default

    // Logic for writing data to the registers
    always @(posedge Main_Clock or posedge Reset) begin
        if (Reset) begin
            zone_reg_0 <= 8'd0; prio_reg_0 <= 2'd0;
            zone_reg_1 <= 8'd0; prio_reg_1 <= 2'd0;
            zone_reg_2 <= 8'd0; prio_reg_2 <= 2'd0;
            zone_reg_3 <= 8'd0; prio_reg_3 <= 2'd0;
        end else if (Insert) begin
            if (write_enable[0]) begin
                zone_reg_0 <= Zone;
                prio_reg_0 <= Priority;
            end
            if (write_enable[1]) begin
                zone_reg_1 <= Zone;
                prio_reg_1 <= Priority;
            end
            if (write_enable[2]) begin
                zone_reg_2 <= Zone;
                prio_reg_2 <= Priority;
            end
            if (write_enable[3]) begin
                zone_reg_3 <= Zone;
                prio_reg_3 <= Priority;
            end
        end
    end

    // 4-to-1 MUX for Zone output, selected by tail_counter
    assign Output_Zone = (tail_counter == 2'b00) ? zone_reg_0 :
                         (tail_counter == 2'b01) ? zone_reg_1 :
                         (tail_counter == 2'b10) ? zone_reg_2 :
                         zone_reg_3;

    // 4-to-1 MUX for Priority output, selected by tail_counter
    assign Output_Priority = (tail_counter == 2'b00) ? prio_reg_0 :
                             (tail_counter == 2'b01) ? prio_reg_1 :
                             (tail_counter == 2'b10) ? prio_reg_2 :
                             prio_reg_3;

    // Empty is high if the item counter is zero
    assign Empty = (item_counter == 8'd0);

endmodule

