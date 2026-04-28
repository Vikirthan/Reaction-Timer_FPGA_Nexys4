module reactionTimer
    (
      input wire clk,
      input wire clear, start, stop,
      output wire led,
      output wire [3:0] an,
      output wire [7:0] sseg
    );

    // ---------------------------------------------------------------
    // Internal signals
    // ---------------------------------------------------------------

    // Free-running random counter: wraps 15 -> 50
    reg  [5:0]  random_counter_reg;
    wire [5:0]  random_counter_next;

    // Millisecond tick counter
    // Nexys 4 clock = 100 MHz  =>  1 ms = 100,000 cycles
    reg  [16:0] ms_counter_reg;
    wire [16:0] ms_counter_next;

    // Reaction timer: counts elapsed ms (0 - 9999)
    reg  [13:0] reaction_timer_reg;
    wire [13:0] reaction_timer_next;

    // Countdown timer: counts down clock cycles
    // Max value = 50 * 10,000,000 = 500,000,000  -> needs 29 bits
    reg  [29:0] countdown_timer_reg;
    wire [29:0] countdown_timer_next;

    wire ms_tick;          // pulses for 1 cycle every 1 ms
    reg  ms_go;            // enable ms_counter
    wire countdown_done;   // asserted when countdown_timer == 0
    reg  countdown_go;     // enable countdown_timer decrement

    reg [1:0] state_reg, state_next;

    reg  bin2bcd_start;
    wire [3:0] bcd3, bcd2, bcd1, bcd0;

    reg  led_state;

    // ---------------------------------------------------------------
    // Register bank (synchronous reset)
    // ---------------------------------------------------------------
    always @(posedge clk, posedge clear)
        if (clear)
          begin
              random_counter_reg  <= 6'd0;
              ms_counter_reg      <= 17'd0;
              reaction_timer_reg  <= 14'd0;
              countdown_timer_reg <= 30'd0;
          end
        else
          begin
              random_counter_reg  <= random_counter_next;
              ms_counter_reg      <= ms_counter_next;
              reaction_timer_reg  <= reaction_timer_next;
              countdown_timer_reg <= countdown_timer_next;
          end

    // ---------------------------------------------------------------
    // Random counter: free-runs 15 -> 50 continuously
    // Gives a random-ish count whenever 'start' is pressed
    // ---------------------------------------------------------------
    assign random_counter_next =
        (random_counter_reg < 6'd50) ? random_counter_reg + 1'b1 : 6'd15;

    // ---------------------------------------------------------------
    // ms counter: counts 0 -> 99,999 then wraps (= 1 ms at 100 MHz)
    // Only runs when ms_go is asserted
    // ---------------------------------------------------------------
    assign ms_counter_next =
        (ms_go && ms_counter_reg < 17'd99999) ? ms_counter_reg + 1'b1 :
        (ms_counter_reg == 17'd99999)          ? 17'd0                  :
                                                  ms_counter_reg;

    assign ms_tick = (ms_counter_reg == 17'd99999) ? 1'b1 : 1'b0;

    // ---------------------------------------------------------------
    // Reaction timer: increments once per ms_tick, up to 9999
    // ---------------------------------------------------------------
    assign reaction_timer_next =
        (ms_tick && reaction_timer_reg < 14'd9999) ? reaction_timer_reg + 1'b1
                                                   : reaction_timer_reg;

    // ---------------------------------------------------------------
    // Countdown timer
    //   - Loaded with (random_counter * 10,000,000) when FSM enters
    //     the 'load' state (start was just pressed AND timer is 0)
    //   - Decrements every clock when countdown_go is asserted
    // ---------------------------------------------------------------
    assign countdown_timer_next =
        // Load: only when FSM is transitioning into load (timer still 0)
        (start && countdown_timer_reg == 30'd0)
            ? ({24'd0, random_counter_reg} * 30'd10_000_000)
        // Decrement while counting down
        : (countdown_go && countdown_timer_reg > 30'd0)
            ? countdown_timer_reg - 1'b1
        : countdown_timer_reg;

    assign countdown_done = (countdown_timer_reg == 30'd0) ? 1'b1 : 1'b0;

    // ---------------------------------------------------------------
    // FSM state register
    // ---------------------------------------------------------------
    localparam [1:0]
        idle   = 2'b00,   // waiting for 'start'
        load   = 2'b01,   // counting down random delay
        timing = 2'b10,   // LED on, measuring reaction
        w2c    = 2'b11;   // result displayed, waiting for 'clear'

    always @(posedge clk, posedge clear)
        if (clear)
            state_reg <= idle;
        else
            state_reg <= state_next;

    // ---------------------------------------------------------------
    // FSM combinational logic
    // ---------------------------------------------------------------
    always @*
    begin
        // defaults
        state_next    = state_reg;
        ms_go         = 1'b0;
        countdown_go  = 1'b0;
        bin2bcd_start = 1'b0;
        led_state     = 1'b0;

        case (state_reg)

            idle:
            begin
                if (start)
                    state_next = load;
            end

            load:
            begin
                countdown_go = 1'b1;            // enable countdown decrement
                // Wait one extra cycle for the timer to be loaded before
                // checking done (countdown_done is 1 at reset - guard it)
                if (countdown_done && !start)   // timer reached 0 after counting
                    state_next = timing;
            end

            timing:
            begin
                ms_go     = 1'b1;
                led_state = 1'b1;
                if (stop)
                begin
                    state_next    = w2c;
                    bin2bcd_start = 1'b1;
                end
            end

            w2c:
            begin
                // Nothing - hold result until 'clear' resets FSM
            end

        endcase
    end

    // ---------------------------------------------------------------
    // Sub-module instantiations
    // ---------------------------------------------------------------

    // Binary-to-BCD converter (must be provided separately)
    bin2bcd b2b_unit
    (
        .clk      (clk),
        .reset    (clear),
        .start    (bin2bcd_start),
        .bin      (reaction_timer_reg),
        .ready    (),
        .done_tick(),
        .bcd3     (bcd3),
        .bcd2     (bcd2),
        .bcd1     (bcd1),
        .bcd0     (bcd0)
    );

    // 4-digit seven-segment display multiplexer
    // NOTE: on the Nexys 4 the 'an' bus is 8 bits wide on the board,
    //       but the top module only exposes 4 bits (AN3..AN0).
    //       Make sure displayMuxBasys drives only AN[3:0] low when active.
    displayMuxBasys disp_unit
    (
        .clk  (clk),
        .hex3 (bcd3),
        .hex2 (bcd2),
        .hex1 (bcd1),
        .hex0 (bcd0),
        .dp_in(4'b0111),   // decimal point after leftmost digit
        .an   (an),
        .sseg (sseg)
    );

    assign led = led_state;

endmodule