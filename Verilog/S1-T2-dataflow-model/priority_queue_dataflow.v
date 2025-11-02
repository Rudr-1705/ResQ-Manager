// ============================================================================
// MODULE: priority_queue_dataflow
// ============================================================================

// ----------------------------------------------------------------------------
// MODULE: Request Register (Dataflow)
// ----------------------------------------------------------------------------
module request_register_dataflow (
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

    wire [7:0] next_zone_id;
    wire [1:0] next_priority;
    wire [7:0] next_waiting_time;
    wire next_valid;
    wire next_boost;
    
    // Zone ID and Priority logic
    assign next_zone_id = clear ? 8'd0 : (write_en ? zone_id_in : zone_id_out);
    assign next_priority = clear ? 2'd0 : (write_en ? priority_in : priority_out);
    
    // Waiting time logic
    assign next_waiting_time = clear ? 8'd0 :
                               (write_en ? 8'd0 :
                               (increment_wait & valid_out) ? waiting_time_out + 8'd1 :
                               waiting_time_out);
    
    // Valid bit logic
    assign next_valid = (write_en | valid_out) & ~clear;
    
    // Boost flag logic
    assign next_boost = (set_boost | boost_out) & ~clear;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            zone_id_out <= 8'd0;
            priority_out <= 2'd0;
            waiting_time_out <= 8'd0;
            valid_out <= 1'b0;
            boost_out <= 1'b0;
        end
        else begin
            zone_id_out <= next_zone_id;
            priority_out <= next_priority;
            waiting_time_out <= next_waiting_time;
            valid_out <= next_valid;
            boost_out <= next_boost;
        end
    end

endmodule

// ----------------------------------------------------------------------------
// MODULE: Threshold Comparator (Dataflow)
// ----------------------------------------------------------------------------
module threshold_comparator_dataflow (
    input wire [7:0] waiting_time,
    input wire [7:0] threshold,
    input wire valid,
    output wire should_boost
);

    assign should_boost = (waiting_time >= threshold) & valid;

endmodule

// ----------------------------------------------------------------------------
// MODULE: Priority Encoder 2-to-1 (Dataflow)
// ----------------------------------------------------------------------------
module priority_encoder_2to1_dataflow (
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
    
    output wire [7:0] out_zone_id,
    output wire [1:0] out_priority,
    output wire [7:0] out_waiting_time,
    output wire out_boost,
    output wire out_valid,
    output wire select_a
);

    wire a_only, b_only, both_valid;
    wire a_boost_only, b_boost_only, boost_equal;
    wire a_pri_higher, pri_equal, a_older;
    
    // Valid comparison
    assign a_only = a_valid & ~b_valid;
    assign b_only = b_valid & ~a_valid;
    assign both_valid = a_valid & b_valid;
    
    // Boost comparison
    assign a_boost_only = a_boost & ~b_boost;
    assign b_boost_only = b_boost & ~a_boost;
    assign boost_equal = (a_boost == b_boost);
    
    // Priority comparison
    assign a_pri_higher = (a_priority > b_priority);
    assign pri_equal = (a_priority == b_priority);
    
    // Waiting time comparison (older = higher waiting time, use >= for consistency)
    assign a_older = (a_waiting_time >= b_waiting_time);
    
    // Selection logic
    assign select_a = a_only |
                      (both_valid & a_boost_only) |
                      (both_valid & boost_equal & a_pri_higher) |
                      (both_valid & boost_equal & pri_equal & a_older);
    
    // Output multiplexing
    assign out_zone_id = select_a ? a_zone_id : b_zone_id;
    assign out_priority = select_a ? a_priority : b_priority;
    assign out_waiting_time = select_a ? a_waiting_time : b_waiting_time;
    assign out_boost = select_a ? a_boost : b_boost;
    assign out_valid = select_a ? a_valid : b_valid;

endmodule

// ----------------------------------------------------------------------------
// MODULE: Serve Decoder (Dataflow)
// ----------------------------------------------------------------------------
module serve_decoder_dataflow (
    input wire serve,
    input wire [1:0] selected_index,
    output wire serve_0,
    output wire serve_1,
    output wire serve_2,
    output wire serve_3
);

    assign serve_0 = (selected_index == 2'b00) & serve;
    assign serve_1 = (selected_index == 2'b01) & serve;
    assign serve_2 = (selected_index == 2'b10) & serve;
    assign serve_3 = (selected_index == 2'b11) & serve;

endmodule

// ----------------------------------------------------------------------------
// MODULE: Queue Storage (Dataflow)
// ----------------------------------------------------------------------------
module queue_storage_dataflow (
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
    
    // Serve signals
    wire serve_0, serve_1, serve_2, serve_3;
    
    // Cancel signals
    wire cancel_0, cancel_1, cancel_2, cancel_3;
    
    // Clear signals
    wire clear_0, clear_1, clear_2, clear_3;
    
    // Boost signals
    wire should_boost_0, should_boost_1, should_boost_2, should_boost_3;
    
    // Write enable logic (priority: slot 0 first)
    assign write_en_0 = insert & ~entry0_valid;
    assign write_en_1 = insert & entry0_valid & ~entry1_valid;
    assign write_en_2 = insert & entry0_valid & entry1_valid & ~entry2_valid;
    assign write_en_3 = insert & entry0_valid & entry1_valid & entry2_valid & ~entry3_valid;
    
    // Serve decoder
    serve_decoder_dataflow serve_dec (
        .serve(serve),
        .selected_index(selected_index),
        .serve_0(serve_0),
        .serve_1(serve_1),
        .serve_2(serve_2),
        .serve_3(serve_3)
    );
    
    // Cancel logic (only cancel valid entries)
    assign cancel_0 = (entry0_zone_id == cancel_zone) & cancel_en & entry0_valid;
    assign cancel_1 = (entry1_zone_id == cancel_zone) & cancel_en & entry1_valid;
    assign cancel_2 = (entry2_zone_id == cancel_zone) & cancel_en & entry2_valid;
    assign cancel_3 = (entry3_zone_id == cancel_zone) & cancel_en & entry3_valid;
    
    // Clear signals (serve or cancel)
    assign clear_0 = serve_0 | cancel_0;
    assign clear_1 = serve_1 | cancel_1;
    assign clear_2 = serve_2 | cancel_2;
    assign clear_3 = serve_3 | cancel_3;
    
    // Request registers
    request_register_dataflow reg0 (
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
    
    request_register_dataflow reg1 (
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
    
    request_register_dataflow reg2 (
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
    
    request_register_dataflow reg3 (
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
    threshold_comparator_dataflow comp0 (
        .waiting_time(entry0_waiting_time),
        .threshold(threshold),
        .valid(entry0_valid),
        .should_boost(should_boost_0)
    );
    
    threshold_comparator_dataflow comp1 (
        .waiting_time(entry1_waiting_time),
        .threshold(threshold),
        .valid(entry1_valid),
        .should_boost(should_boost_1)
    );
    
    threshold_comparator_dataflow comp2 (
        .waiting_time(entry2_waiting_time),
        .threshold(threshold),
        .valid(entry2_valid),
        .should_boost(should_boost_2)
    );
    
    threshold_comparator_dataflow comp3 (
        .waiting_time(entry3_waiting_time),
        .threshold(threshold),
        .valid(entry3_valid),
        .should_boost(should_boost_3)
    );
    
    // Queue full signal
    assign queue_full = entry0_valid & entry1_valid & entry2_valid & entry3_valid;

endmodule

// ----------------------------------------------------------------------------
// MODULE: Priority Selector Tree (Dataflow)
// ----------------------------------------------------------------------------
module priority_selector_tree_dataflow (
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
    
    // First level: compare 0 vs 1
    priority_encoder_2to1_dataflow comp_01 (
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
    
    // First level: compare 2 vs 3
    priority_encoder_2to1_dataflow comp_23 (
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
    
    // Final level: compare winners
    priority_encoder_2to1_dataflow comp_final (
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
    wire [1:0] index_01, index_23;
    
    assign index_01 = select_01_a ? 2'b00 : 2'b01;
    assign index_23 = select_23_a ? 2'b10 : 2'b11;
    assign selected_index = select_final_a ? index_01 : index_23;

endmodule

module priority_queue_dataflow (
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
    
    queue_storage_dataflow queue (
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
    
    priority_selector_tree_dataflow selector (
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
