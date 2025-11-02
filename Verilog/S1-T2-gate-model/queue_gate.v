/**
 * Module: Evac_Queue_gate
 */
module Evac_Queue_gate (
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

    // --- Wires ---
    wire [7:0] zone_reg_0, zone_reg_1, zone_reg_2, zone_reg_3;
    wire [1:0] prio_reg_0, prio_reg_1, prio_reg_2, prio_reg_3;
    
    wire [7:0] item_count;
    wire [1:0] head_count;
    wire [1:0] tail_count;
    
    wire [3:0] write_enable_vec;
    wire rst_n; // Active-low reset
    
    wire item_cnt_up, item_cnt_down;
    wire not_serve, not_insert, not_empty;
    
    
    // --- Logic ---

    // 1. Create active-low reset
    not rst_gate (rst_n, Reset);
    
    // 2. Counters
    
    // Item Counter logic
    not not_serve_gate (not_serve, Serve);
    not not_insert_gate (not_insert, Insert);
    not not_empty_gate (not_empty, Empty);
    
    and item_up_and (item_cnt_up, Insert, not_serve);
    and item_down_and (item_cnt_down, not_insert, Serve, not_empty);
    
    counter_8bit_rst item_counter (
        .clk(Main_Clock),
        .rst_n(rst_n), // Use active-low reset
        .en_up(item_cnt_up),
        .en_down(item_cnt_down),
        .q(item_count)
    );
    
    // Head Counter
    counter_2bit_rst head_counter (
        .clk(Main_Clock),
        .rst_n(rst_n),
        .en(Insert),
        .q(head_count)
    );

    // Tail Counter
    wire tail_en;
    and tail_en_and (tail_en, Serve, not_empty);
    counter_2bit_rst tail_counter (
        .clk(Main_Clock),
        .rst_n(rst_n),
        .en(tail_en),
        .q(tail_count)
    );

    // 3. Write Logic
    
    // 2-to-4 Decoder for write enable
    decoder_2to4 write_decoder (
        .in(head_count),
        .out(write_enable_vec)
    );
    
    // Registers (Enable logic: Insert AND decoded address)
    wire en0, en1, en2, en3;
    and reg_en0 (en0, Insert, write_enable_vec[0]);
    and reg_en1 (en1, Insert, write_enable_vec[1]);
    and reg_en2 (en2, Insert, write_enable_vec[2]);
    and reg_en3 (en3, Insert, write_enable_vec[3]);
    
    register_8bit_rst zone_reg0 (.clk(Main_Clock), .rst_n(rst_n), .en(en0), .d(Zone), .q(zone_reg_0));
    register_8bit_rst zone_reg1 (.clk(Main_Clock), .rst_n(rst_n), .en(en1), .d(Zone), .q(zone_reg_1));
    register_8bit_rst zone_reg2 (.clk(Main_Clock), .rst_n(rst_n), .en(en2), .d(Zone), .q(zone_reg_2));
    register_8bit_rst zone_reg3 (.clk(Main_Clock), .rst_n(rst_n), .en(en3), .d(Zone), .q(zone_reg_3));
    
    register_2bit_rst prio_reg0 (.clk(Main_Clock), .rst_n(rst_n), .en(en0), .d(Priority), .q(prio_reg_0));
    register_2bit_rst prio_reg1 (.clk(Main_Clock), .rst_n(rst_n), .en(en1), .d(Priority), .q(prio_reg_1));
    register_2bit_rst prio_reg2 (.clk(Main_Clock), .rst_n(rst_n), .en(en2), .d(Priority), .q(prio_reg_2));
    register_2bit_rst prio_reg3 (.clk(Main_Clock), .rst_n(rst_n), .en(en3), .d(Priority), .q(prio_reg_3));
    
    // 4. Output Logic (Serving)
    
    // 4-to-1 MUX for Zone output
    mux_4to1_8bit zone_mux (
        .in0(zone_reg_0),
        .in1(zone_reg_1),
        .in2(zone_reg_2),
        .in3(zone_reg_3),
        .sel(tail_count),
        .out(Output_Zone)
    );
    
    // 4-to-1 MUX for Priority output
    mux_4to1_2bit prio_mux (
        .in0(prio_reg_0),
        .in1(prio_reg_1),
        .in2(prio_reg_2),
        .in3(prio_reg_3),
        .sel(tail_count),
        .out(Output_Priority)
    );

    // 5. Empty Flag Logic
    wire [7:0] zero = 8'b0;
    wire gt, eq, lt;
    comparator_8bit empty_comp (
        .a(item_count),
        .b(zero),
        .gt(gt),
        .eq(eq),
        .lt(lt)
    );
    assign Empty = eq;

endmodule
