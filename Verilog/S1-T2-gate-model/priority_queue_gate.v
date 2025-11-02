// ============================================================================
// MODULE: priority_Queue_gate
// ============================================================================

// ----------------------------------------------------------------------------
// MODULE: Request Register (Gate Level)
// ----------------------------------------------------------------------------
module request_register_complex_gate (
    input wire clk,
    input wire rst_n,
    input wire write_en,
    input wire [7:0] zone_id_in,
    input wire [1:0] priority_in,
    input wire increment_wait,
    input wire set_boost,
    input wire clear,
    output wire [7:0] zone_id_out,
    output wire [1:0] priority_out,
    output wire [7:0] waiting_time_out,
    output wire valid_out,
    output wire boost_out
);

    // Internal wires
    wire [7:0] zone_id_reg;
    wire [1:0] priority_reg;
    wire [7:0] wait_time_reg;
    wire valid_reg;
    wire boost_reg;
    
    wire [7:0] wait_time_plus_one;
    wire [7:0] wait_time_mux1_out;
    wire [7:0] wait_time_mux2_out;
    wire increment_condition;
    
    wire valid_or_out;
    wire valid_and_out;
    wire not_clear;
    
    wire boost_or_out;
    wire boost_and_out;
    
    // Zone ID Register - clears to 0 on clear signal
    wire en_zone;
    wire [7:0] zone_id_mux_out;
    or zone_en_or (en_zone, write_en, clear);
    mux_2to1_8bit zone_clear_mux (
        .in0(zone_id_in),
        .in1(8'd0),
        .sel(clear),
        .out(zone_id_mux_out)
    );
    
    register_8bit_rst zone_id_register (
        .clk(clk),
        .rst_n(rst_n),
        .en(en_zone),
        .d(zone_id_mux_out),
        .q(zone_id_reg)
    );
    
    // Priority Register - clears to 0 on clear signal
    wire en_pri;
    wire [1:0] priority_mux_out;
    or pri_en_or (en_pri, write_en, clear);
    mux_2to1_2bit priority_clear_mux (
        .in0(priority_in),
        .in1(2'd0),
        .sel(clear),
        .out(priority_mux_out)
    );
    
    register_2bit_rst priority_register (
        .clk(clk),
        .rst_n(rst_n),
        .en(en_pri),
        .d(priority_mux_out),
        .q(priority_reg)
    );
    
    // Waiting Time Logic
    adder_8bit wait_adder (
        .a(wait_time_reg),
        .b(8'd1),
        .sum(wait_time_plus_one)
    );
    
    and increment_and (increment_condition, increment_wait, valid_reg);
    
    mux_2to1_8bit wait_mux1 (
        .in0(wait_time_reg),
        .in1(wait_time_plus_one),
        .sel(increment_condition),
        .out(wait_time_mux1_out)
    );
    
    wire wait_write_or_clear;
    or wait_or (wait_write_or_clear, write_en, clear);
    
    mux_2to1_8bit wait_mux2 (
        .in0(wait_time_mux1_out),
        .in1(8'd0),
        .sel(wait_write_or_clear),
        .out(wait_time_mux2_out)
    );
    
    register_8bit_rst wait_time_register (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(wait_time_mux2_out),
        .q(wait_time_reg)
    );
    
    // Valid Bit Logic
    or valid_or (valid_or_out, write_en, valid_reg);
    not not_clear_gate (not_clear, clear);
    and valid_and (valid_and_out, valid_or_out, not_clear);
    
    dff_rst valid_ff (
        .clk(clk),
        .rst_n(rst_n),
        .d(valid_and_out),
        .q(valid_reg)
    );
    
    // Boost Flag Logic
    or boost_or (boost_or_out, set_boost, boost_reg);
    and boost_and (boost_and_out, boost_or_out, not_clear);
    
    dff_rst boost_ff (
        .clk(clk),
        .rst_n(rst_n),
        .d(boost_and_out),
        .q(boost_reg)
    );
    
    // Outputs
    assign zone_id_out = zone_id_reg;
    assign priority_out = priority_reg;
    assign waiting_time_out = wait_time_reg;
    assign valid_out = valid_reg;
    assign boost_out = boost_reg;

endmodule

// ----------------------------------------------------------------------------
// MODULE: Threshold Comparator (Gate Level)
// ----------------------------------------------------------------------------
module threshold_comparator_complex_gate (
    input wire [7:0] waiting_time,
    input wire [7:0] threshold,
    input wire valid,
    output wire should_boost
);

    wire a_gt_b, a_eq_b;
    wire a_ge_b;
    
    comparator_8bit comp (
        .a(waiting_time),
        .b(threshold),
        .gt(a_gt_b),
        .eq(a_eq_b),
        .lt()
    );
    
    or ge_or (a_ge_b, a_gt_b, a_eq_b);
    and boost_and (should_boost, a_ge_b, valid);

endmodule

// ----------------------------------------------------------------------------
// MODULE: Priority Encoder 2-to-1 (Gate Level)
// ----------------------------------------------------------------------------
module priority_encoder_2to1_complex_gate (
    input  wire [7:0] a_zone_id,
    input  wire [1:0] a_priority,
    input  wire [7:0] a_waiting_time,
    input  wire       a_boost,
    input  wire       a_valid,

    input  wire [7:0] b_zone_id,
    input  wire [1:0] b_priority,
    input  wire [7:0] b_waiting_time,
    input  wire       b_boost,
    input  wire       b_valid,

    output wire [7:0] out_zone_id,
    output wire [1:0] out_priority,
    output wire [7:0] out_waiting_time,
    output wire       out_boost,
    output wire       out_valid,
    output wire       select_a
);

    // Valid-only cases
    wire not_b_valid, not_a_valid;
    wire a_only, b_only, both_valid;
    
    not not_b (not_b_valid, b_valid);
    not not_a (not_a_valid, a_valid);
    
    and a_only_and (a_only, a_valid, not_b_valid);
    and b_only_and (b_only, not_a_valid, b_valid);
    and both_and (both_valid, a_valid, b_valid);

    // Boost comparison
    wire not_b_boost, not_a_boost;
    wire a_boost_only, b_boost_only, boost_equal;
    
    not not_b_bst (not_b_boost, b_boost);
    not not_a_bst (not_a_boost, a_boost);
    
    and a_bst_only (a_boost_only, a_boost, not_b_boost);
    and b_bst_only (b_boost_only, not_a_boost, b_boost);
    
    wire boost_xor;
    xor bst_xor (boost_xor, a_boost, b_boost);
    not bst_eq (boost_equal, boost_xor);

    // Priority comparison
    wire a_pri_gt, a_pri_eq, a_pri_lt;
    comparator_2bit pri_comp (
        .a(a_priority),
        .b(b_priority),
        .gt(a_pri_gt),
        .eq(a_pri_eq),
        .lt(a_pri_lt)
    );

    // Waiting time comparison (use >= for FIFO consistency)
    wire a_wait_gt, a_wait_eq;
    wire a_wait_ge;
    comparator_8bit wait_comp (
        .a(a_waiting_time),
        .b(b_waiting_time),
        .gt(a_wait_gt),
        .eq(a_wait_eq),
        .lt()
    );
    or wait_ge_or (a_wait_ge, a_wait_gt, a_wait_eq);

    // Build selection logic step by step
    wire cond1, cond2, cond3, cond4;
    wire cond12, cond123, cond1234;
    
    // cond1: a_only
    assign cond1 = a_only;
    
    // cond2: both_valid & a_boost_only
    and cond2_and (cond2, both_valid, a_boost_only);
    
    // cond3: both_valid & boost_equal & a_pri_gt
    wire cond3_temp;
    and3 cond3_and (cond3_temp, both_valid, boost_equal, a_pri_gt);
    assign cond3 = cond3_temp;
    
    // cond4: both_valid & boost_equal & a_pri_eq & a_wait_ge
    wire cond4_temp1;
    and3 cond4_and1 (cond4_temp1, both_valid, boost_equal, a_pri_eq);
    and cond4_and2 (cond4, cond4_temp1, a_wait_ge);
    
    // Combine conditions with OR
    or or1 (cond12, cond1, cond2);
    or or2 (cond123, cond12, cond3);
    or or3 (cond1234, cond123, cond4);
    
    assign select_a = cond1234;

    // Outputs
    mux_2to1_8bit zone_mux (.in0(b_zone_id), .in1(a_zone_id), .sel(select_a), .out(out_zone_id));
    mux_2to1_2bit pri_mux (.in0(b_priority), .in1(a_priority), .sel(select_a), .out(out_priority));
    mux_2to1_8bit wait_mux (.in0(b_waiting_time), .in1(a_waiting_time), .sel(select_a), .out(out_waiting_time));
    mux_2to1_1bit boost_mux (.in0(b_boost), .in1(a_boost), .sel(select_a), .out(out_boost));
    mux_2to1_1bit valid_mux (.in0(b_valid), .in1(a_valid), .sel(select_a), .out(out_valid));

endmodule

// ----------------------------------------------------------------------------
// MODULE: Serve Decoder (Gate Level)
// ----------------------------------------------------------------------------
module serve_decoder_complex_gate (
    input wire serve,
    input wire [1:0] selected_index,
    output wire serve_0,
    output wire serve_1,
    output wire serve_2,
    output wire serve_3
);

    wire index_0, index_1;
    wire not_index_0, not_index_1;
    
    assign index_0 = selected_index[0];
    assign index_1 = selected_index[1];
    
    not not0 (not_index_0, index_0);
    not not1 (not_index_1, index_1);
    
    and3 and_serve0 (serve_0, not_index_1, not_index_0, serve);
    and3 and_serve1 (serve_1, not_index_1, index_0, serve);
    and3 and_serve2 (serve_2, index_1, not_index_0, serve);
    and3 and_serve3 (serve_3, index_1, index_0, serve);

endmodule

// ----------------------------------------------------------------------------
// MODULE: Queue Storage (Gate Level)
// ----------------------------------------------------------------------------
module queue_storage_complex_gate (
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
    wire write_en_0, write_en_1, write_en_2, write_en_3;
    wire slot0_empty, slot1_empty, slot2_empty, slot3_empty;
    
    // Serve signals
    wire serve_0, serve_1, serve_2, serve_3;
    
    // Cancel signals
    wire cancel_0, cancel_1, cancel_2, cancel_3;
    wire zone_match_0, zone_match_1, zone_match_2, zone_match_3;
    wire cancel_and_valid_0, cancel_and_valid_1, cancel_and_valid_2, cancel_and_valid_3;
    
    // Clear signals
    wire clear_0, clear_1, clear_2, clear_3;
    
    // Boost signals
    wire should_boost_0, should_boost_1, should_boost_2, should_boost_3;
    
    // Write enable logic
    not not_valid0 (slot0_empty, entry0_valid);
    not not_valid1 (slot1_empty, entry1_valid);
    not not_valid2 (slot2_empty, entry2_valid);
    not not_valid3 (slot3_empty, entry3_valid);
    
    and write_and0 (write_en_0, insert, slot0_empty);
    and3 write_and1 (write_en_1, insert, entry0_valid, slot1_empty);
    and4 write_and2 (write_en_2, insert, entry0_valid, entry1_valid, slot2_empty);
    and5 write_and3 (write_en_3, insert, entry0_valid, entry1_valid, entry2_valid, slot3_empty);
    
    // Serve decoder
    serve_decoder_complex_gate serve_dec (
        .serve(serve),
        .selected_index(selected_index),
        .serve_0(serve_0),
        .serve_1(serve_1),
        .serve_2(serve_2),
        .serve_3(serve_3)
    );
    
    // Cancel logic for each entry (only cancel valid entries)
    comparator_8bit cancel_comp0 (
        .a(entry0_zone_id),
        .b(cancel_zone),
        .gt(),
        .eq(zone_match_0),
        .lt()
    );
    and3 cancel_match0 (cancel_and_valid_0, zone_match_0, cancel_en, entry0_valid);
    or clear_or0 (clear_0, serve_0, cancel_and_valid_0);
    
    comparator_8bit cancel_comp1 (
        .a(entry1_zone_id),
        .b(cancel_zone),
        .gt(),
        .eq(zone_match_1),
        .lt()
    );
    and3 cancel_match1 (cancel_and_valid_1, zone_match_1, cancel_en, entry1_valid);
    or clear_or1 (clear_1, serve_1, cancel_and_valid_1);
    
    comparator_8bit cancel_comp2 (
        .a(entry2_zone_id),
        .b(cancel_zone),
        .gt(),
        .eq(zone_match_2),
        .lt()
    );
    and3 cancel_match2 (cancel_and_valid_2, zone_match_2, cancel_en, entry2_valid);
    or clear_or2 (clear_2, serve_2, cancel_and_valid_2);
    
    comparator_8bit cancel_comp3 (
        .a(entry3_zone_id),
        .b(cancel_zone),
        .gt(),
        .eq(zone_match_3),
        .lt()
    );
    and3 cancel_match3 (cancel_and_valid_3, zone_match_3, cancel_en, entry3_valid);
    or clear_or3 (clear_3, serve_3, cancel_and_valid_3);
    
    // Request registers
    request_register_complex_gate reg0 (
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
    
    request_register_complex_gate reg1 (
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
    
    request_register_complex_gate reg2 (
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
    
    request_register_complex_gate reg3 (
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
    threshold_comparator_complex_gate comp0 (
        .waiting_time(entry0_waiting_time),
        .threshold(threshold),
        .valid(entry0_valid),
        .should_boost(should_boost_0)
    );
    
    threshold_comparator_complex_gate comp1 (
        .waiting_time(entry1_waiting_time),
        .threshold(threshold),
        .valid(entry1_valid),
        .should_boost(should_boost_1)
    );
    
    threshold_comparator_complex_gate comp2 (
        .waiting_time(entry2_waiting_time),
        .threshold(threshold),
        .valid(entry2_valid),
        .should_boost(should_boost_2)
    );
    
    threshold_comparator_complex_gate comp3 (
        .waiting_time(entry3_waiting_time),
        .threshold(threshold),
        .valid(entry3_valid),
        .should_boost(should_boost_3)
    );
    
    // Queue full signal
    and4 queue_full_and (queue_full, entry0_valid, entry1_valid, entry2_valid, entry3_valid);

endmodule

// ----------------------------------------------------------------------------
// MODULE: Priority Selector Tree (Gate Level)
// ----------------------------------------------------------------------------
module priority_selector_tree_complex_gate (
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
    wire select_01_a, select_23_a;
    
    wire select_final_a;
    wire [1:0] index_01, index_23;
    
    // First level comparisons
    priority_encoder_2to1_complex_gate comp_01 (
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
    
    priority_encoder_2to1_complex_gate comp_23 (
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
    priority_encoder_2to1_complex_gate comp_final (
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
    mux_2to1_2bit index_01_mux (
        .in0(2'b01),
        .in1(2'b00),
        .sel(select_01_a),
        .out(index_01)
    );
    
    mux_2to1_2bit index_23_mux (
        .in0(2'b11),
        .in1(2'b10),
        .sel(select_23_a),
        .out(index_23)
    );
    
    mux_2to1_2bit index_final_mux (
        .in0(index_23),
        .in1(index_01),
        .sel(select_final_a),
        .out(selected_index)
    );

endmodule

// ----------------------------------------------------------------------------
// MODULE: Complex Priority Queue (Top Level)
// ----------------------------------------------------------------------------
module priority_Queue_gate (
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
    
    queue_storage_complex_gate queue (
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
    
    priority_selector_tree_complex_gate selector (
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
