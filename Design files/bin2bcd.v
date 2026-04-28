// ============================================================
// bin2bcd.v
// Double-Dabble (shift-and-add-3) binary to BCD converter
// Converts 14-bit binary (0-9999) to four BCD digits
// ============================================================

module bin2bcd
    (
        input  wire        clk,
        input  wire        reset,
        input  wire        start,
        input  wire [13:0] bin,       // 14-bit binary input (max 9999)
        output reg         ready,
        output reg         done_tick,
        output reg  [3:0]  bcd3,      // thousands
        output reg  [3:0]  bcd2,      // hundreds
        output reg  [3:0]  bcd1,      // tens
        output reg  [3:0]  bcd0       // ones
    );

    // FSM states
    localparam [1:0]
        idle  = 2'b00,
        op    = 2'b01,
        done  = 2'b10;

    reg [1:0]  state_reg,  state_next;
    reg [13:0] bin_reg,    bin_next;
    reg [3:0]  bcd3_reg,   bcd3_next;
    reg [3:0]  bcd2_reg,   bcd2_next;
    reg [3:0]  bcd1_reg,   bcd1_next;
    reg [3:0]  bcd0_reg,   bcd0_next;
    reg [3:0]  n_reg,      n_next;    // shift count (0-13)

    // State register
    always @(posedge clk, posedge reset)
        if (reset)
            state_reg <= idle;
        else
            state_reg <= state_next;

    // Data registers
    always @(posedge clk, posedge reset)
        if (reset)
          begin
              bin_reg  <= 14'd0;
              bcd3_reg <= 4'd0;
              bcd2_reg <= 4'd0;
              bcd1_reg <= 4'd0;
              bcd0_reg <= 4'd0;
              n_reg    <= 4'd0;
          end
        else
          begin
              bin_reg  <= bin_next;
              bcd3_reg <= bcd3_next;
              bcd2_reg <= bcd2_next;
              bcd1_reg <= bcd1_next;
              bcd0_reg <= bcd0_next;
              n_reg    <= n_next;
          end

    // Next-state & output logic
    always @*
    begin
        // defaults
        state_next = state_reg;
        bin_next   = bin_reg;
        bcd3_next  = bcd3_reg;
        bcd2_next  = bcd2_reg;
        bcd1_next  = bcd1_reg;
        bcd0_next  = bcd0_reg;
        n_next     = n_reg;
        ready      = 1'b0;
        done_tick  = 1'b0;

        case (state_reg)

            idle:
            begin
                ready = 1'b1;
                if (start)
                  begin
                      state_next = op;
                      bcd3_next  = 4'd0;
                      bcd2_next  = 4'd0;
                      bcd1_next  = 4'd0;
                      bcd0_next  = 4'd0;
                      bin_next   = bin;
                      n_next     = 4'd0;
                  end
            end

            op:
            begin
                // Add-3 step (if any BCD digit >= 5, add 3 before shifting)
                bcd3_next = (bcd3_reg >= 4'd5) ? bcd3_reg + 4'd3 : bcd3_reg;
                bcd2_next = (bcd2_reg >= 4'd5) ? bcd2_reg + 4'd3 : bcd2_reg;
                bcd1_next = (bcd1_reg >= 4'd5) ? bcd1_reg + 4'd3 : bcd1_reg;
                bcd0_next = (bcd0_reg >= 4'd5) ? bcd0_reg + 4'd3 : bcd0_reg;

                // We need two-cycle operation: add-3 then shift.
                // Use a simpler combinational add-3 inline with shift:
                // Actually let's keep it one-cycle per bit with combined logic.
                // Recompute with corrected values before shifting:
                bcd3_next = {bcd3_next[2:0], bcd2_next[3]};
                bcd2_next = {bcd2_next[2:0], bcd1_next[3]};
                bcd1_next = {bcd1_next[2:0], bcd0_next[3]};
                bcd0_next = {bcd0_next[2:0], bin_reg[13]};
                bin_next  = {bin_reg[12:0], 1'b0};
                n_next    = n_reg + 4'd1;

                if (n_reg == 4'd13)
                    state_next = done;
            end

            done:
            begin
                done_tick  = 1'b1;
                state_next = idle;
            end

            default: state_next = idle;

        endcase
    end

    // Output assignments
    always @(posedge clk, posedge reset)
        if (reset)
          begin
              bcd3 <= 4'd0;
              bcd2 <= 4'd0;
              bcd1 <= 4'd0;
              bcd0 <= 4'd0;
          end
        else if (done_tick)
          begin
              bcd3 <= bcd3_reg;
              bcd2 <= bcd2_reg;
              bcd1 <= bcd1_reg;
              bcd0 <= bcd0_reg;
          end

endmodule