/**
 * Module: Evac_Queue_dataflow
 */
module Evac_Queue_dataflow (
    // Inputs
    input wire         Main_Clock,
    input wire         Insert,
    input wire         Serve,
    input wire         Reset,
    input wire         Clear,
    input wire [7:0]   Zone,
    input wire [1:0]   Priority,

    // Outputs
    output wire [7:0]  Output_Zone,
    output wire [1:0]  Output_Priority,
    output wire        Empty
);

    // --- Registers ---
    reg [7:0] zone_reg_0, zone_reg_1, zone_reg_2, zone_reg_3;
    reg [1:0] prio_reg_0, prio_reg_1, prio_reg_2, prio_reg_3;
    reg [7:0] item_counter;
    reg [1:0] head_counter;
    reg [1:0] tail_counter;
    
    // --- Wires (Internal Logic) ---
    wire [3:0] write_enable;
    wire item_cnt_up, item_cnt_down;
    wire tail_en;
    wire rst_n = ~Reset; // Active-low reset for registers
    
    // --- Dataflow Logic ---

    // 1. Counter Control Logic
    assign Empty = (item_counter == 8'd0);
    assign item_cnt_up = Insert & ~Serve;
    assign item_cnt_down = ~Insert & Serve & ~Empty;
    assign tail_en = Serve & ~Empty;

    // 2. Decoder
    assign write_enable = (head_counter == 2'b00) ? 4'b0001 :
                          (head_counter == 2'b01) ? 4'b0010 :
                          (head_counter == 2'b10) ? 4'b0100 :
                          (head_counter == 2'b11) ? 4'b1000 :
                          4'b0000;

    // 3. Output MUXes
    assign Output_Zone = (tail_counter == 2'b00) ? zone_reg_0 :
                         (tail_counter == 2'b01) ? zone_reg_1 :
                         (tail_counter == 2'b10) ? zone_reg_2 :
                         zone_reg_3;
                         
    assign Output_Priority = (tail_counter == 2'b00) ? prio_reg_0 :
                             (tail_counter == 2'b01) ? prio_reg_1 :
                             (tail_counter == 2'b10) ? prio_reg_2 :
                             prio_reg_3;

    // --- Sequential Logic (Registers) ---

    // Counters
    always @(posedge Main_Clock or posedge Clear or posedge Reset) begin
        if (Clear || Reset) begin
            item_counter <= 8'd0;
            head_counter <= 2'd0;
            tail_counter <= 2'd0;
        end else begin
            // Item Counter
            if (item_cnt_up)
                item_counter <= item_counter + 1;
            else if (item_cnt_down)
                item_counter <= item_counter - 1;
            
            // Head Counter
            if (Insert)
                head_counter <= head_counter + 1;
                
            // Tail Counter
            if (tail_en)
                tail_counter <= tail_counter + 1;
        end
    end
    
    // Storage Registers
    always @(posedge Main_Clock or negedge rst_n) begin
        if (!rst_n) begin
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

endmodule
