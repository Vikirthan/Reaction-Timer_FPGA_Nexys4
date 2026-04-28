// ============================================================
// displayMuxBasys.v
// 4-digit seven-segment display multiplexer
// Compatible with Nexys 4 (active-low anodes and cathodes)
// Refresh rate ~381 Hz per digit @ 100 MHz clock
// ============================================================

module displayMuxBasys
    (
        input  wire        clk,
        input  wire [3:0]  hex3,    // thousands digit (BCD)
        input  wire [3:0]  hex2,    // hundreds  digit (BCD)
        input  wire [3:0]  hex1,    // tens      digit (BCD)
        input  wire [3:0]  hex0,    // ones      digit (BCD)
        input  wire [3:0]  dp_in,   // decimal point enable (1=off, 0=on) per digit
        output reg  [3:0]  an,      // anode select (active LOW)
        output reg  [7:0]  sseg     // cathode segments (active LOW)
                                    // sseg[7]=DP, sseg[6]=CA(a) .. sseg[0]=CG(g)
    );

    // -------------------------------------------------------
    // Refresh counter: 18 bits gives ~381 Hz per digit
    // at 100 MHz:  100e6 / 2^18 / 4 digits ? 95 Hz refresh
    // -------------------------------------------------------
    reg [17:0] refresh_reg;

    always @(posedge clk)
        refresh_reg <= refresh_reg + 1'b1;

    // Top 2 bits select the active digit
    wire [1:0] sel = refresh_reg[17:16];

    // -------------------------------------------------------
    // Digit select & hex mux
    // -------------------------------------------------------
    reg [3:0] hex_in;

    always @*
    begin
        case (sel)
            2'b00: begin an = 4'b1110; hex_in = hex0; sseg[7] = dp_in[0]; end
            2'b01: begin an = 4'b1101; hex_in = hex1; sseg[7] = dp_in[1]; end
            2'b10: begin an = 4'b1011; hex_in = hex2; sseg[7] = dp_in[2]; end
            2'b11: begin an = 4'b0111; hex_in = hex3; sseg[7] = dp_in[3]; end
            default: begin an = 4'b1111; hex_in = 4'b0000; sseg[7] = 1'b1; end
        endcase
    end

    // -------------------------------------------------------
    // 7-segment decoder (active LOW)
    // sseg[6]=a, sseg[5]=b, sseg[4]=c, sseg[3]=d,
    // sseg[2]=e, sseg[1]=f, sseg[0]=g
    //
    //   aaa
    //  f   b
    //  f   b
    //   ggg
    //  e   c
    //  e   c
    //   ddd
    // -------------------------------------------------------
    always @*
    begin
        case (hex_in)
            //                    abcdefg
            4'h0: sseg[6:0] = 7'b0000001; // 0
            4'h1: sseg[6:0] = 7'b1001111; // 1
            4'h2: sseg[6:0] = 7'b0010010; // 2
            4'h3: sseg[6:0] = 7'b0000110; // 3
            4'h4: sseg[6:0] = 7'b1001100; // 4
            4'h5: sseg[6:0] = 7'b0100100; // 5
            4'h6: sseg[6:0] = 7'b0100000; // 6
            4'h7: sseg[6:0] = 7'b0001111; // 7
            4'h8: sseg[6:0] = 7'b0000000; // 8
            4'h9: sseg[6:0] = 7'b0000100; // 9
            4'ha: sseg[6:0] = 7'b0001000; // A
            4'hb: sseg[6:0] = 7'b1100000; // b
            4'hc: sseg[6:0] = 7'b0110001; // C
            4'hd: sseg[6:0] = 7'b1000010; // d
            4'he: sseg[6:0] = 7'b0110000; // E
            4'hf: sseg[6:0] = 7'b0111000; // F
            default: sseg[6:0] = 7'b1111111; // blank
        endcase
    end

endmodule