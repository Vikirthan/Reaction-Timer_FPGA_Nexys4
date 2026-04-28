# ⚡ Reaction Timer — FPGA (Nexys 4)

> A hardware reaction time measurer built in Verilog. Press a button when the LED lights up — your time displays in milliseconds on the 7-segment display.

---

## 📋 Table of Contents

- [What It Does](#what-it-does)
- [How To Play](#how-to-play)
- [Project Files](#project-files)
- [Architecture](#architecture)
- [FSM States](#fsm-states)
- [Pin Mapping](#pin-mapping)
- [How To Program The Board](#how-to-program-the-board)
- [Reaction Time Ratings](#reaction-time-ratings)
- [Technical Details](#technical-details)

---

## What It Does

The system measures how quickly you can react to a visual stimulus (an LED turning on). It:

1. Waits for you to press **START**
2. Generates a **random delay** of 1.5 – 5 seconds before the LED fires
3. Turns on **LED (LD0)** — your signal to react
4. Measures the time between LED turning on and you pressing **STOP** in milliseconds
5. Displays the result on the **4-digit 7-segment display**

The result is shown as `X.XXX` seconds — so a display of `0247` means **247 ms**.

---

## How To Play

```
Step 1 — Power on the board
         Display: 0000  |  LED: OFF  |  State: IDLE

Step 2 — Press BTNU (Up button)
         Random countdown begins internally
         Display: 0000  |  LED: OFF  |  State: LOAD
         ⚠ Do NOT press anything — wait!

Step 3 — LED (LD0) turns ON
         ⚡ REACT NOW — press BTND (Down button)!
         Display: counting up  |  LED: ON  |  State: TIMING

Step 4 — Result appears on display
         e.g. 0247 = 247ms reaction time
         LED: OFF  |  State: W2C (waiting to clear)

Step 5 — Press BTNC (Centre) to reset and play again
         Display: 0000  |  State: IDLE
```

---

## Project Files

```
reaction_timer/
├── rxn.v                        # Top module — FSM, counters, glue logic
├── bin2bcd.v                    # Binary to BCD converter (Double Dabble)
├── display.v                    # 4-digit 7-segment display multiplexer
├── Reaction_timer_xdcfile.xdc   # Pin constraints for Nexys 4
└── reactionTimer_bitfile_.bit   # Pre-compiled bitfile — program directly
```

---

## Architecture

The design consists of three Verilog modules:

### `rxn.v` — Top Module (reactionTimer)

The main module that ties everything together. Contains:

- **4-state FSM** controlling the entire game flow
- **Free-running random counter** cycling 15 → 50 continuously — captures a pseudo-random value when START is pressed
- **Millisecond tick generator** — divides 100 MHz clock to produce one pulse every 1 ms (every 100,000 cycles)
- **Reaction timer register** — increments on every ms tick, counts 0 to 9999
- **Countdown timer** — 30-bit counter loaded with `random_value × 10,000,000` clock cycles

### `bin2bcd.v` — Binary to BCD Converter

Converts the 14-bit binary reaction time (0–9999) into four separate BCD digits using the **Double Dabble (shift-and-add-3)** algorithm.

- Takes 14 clock cycles to complete
- Fires a `done_tick` signal when conversion is complete
- Outputs four 4-bit BCD digits: thousands, hundreds, tens, ones

### `display.v` — 7-Segment Display Multiplexer (displayMuxBasys)

Drives the 4-digit seven-segment display using time-division multiplexing.

- **18-bit refresh counter** cycles through all 4 digits rapidly
- **~95 Hz** refresh rate per digit — appears solid to the human eye
- Active-LOW anodes and cathodes (standard for Nexys 4)
- Full hex decoder supports digits 0–9 and A–F
- Decimal point placed after the first digit (`X.XXX` format)

---

## FSM States

The system uses a 4-state Moore FSM:

| State | Binary | Name | Description |
|-------|--------|------|-------------|
| `idle` | `2'b00` | IDLE | Waiting for START button |
| `load` | `2'b01` | LOAD | Counting down random delay |
| `timing` | `2'b10` | TIMING | LED ON, measuring reaction |
| `w2c` | `2'b11` | Wait-to-Clear | Result displayed, awaiting CLEAR |

### State Transitions

```
         start                countdown_done
  IDLE ────────→ LOAD ─────────────────────→ TIMING
   ↑                                            │
   │ clear (async reset from any state)         │ stop
   └────────────────────────────────────────────┘
                                                ↓
                                               W2C ──── (hold until clear)
```

---

## Pin Mapping

| Signal | Pin | Component | Function |
|--------|-----|-----------|----------|
| `clk` | E3 | On-board oscillator | 100 MHz system clock |
| `clear` | E16 | BTNC (Centre button) | Reset to IDLE state |
| `start` | F15 | BTNU (Up button) | Start the random countdown |
| `stop` | V10 | BTND (Down button) | Stop timer, record result |
| `led` | T8 | LD0 | Lights when it's time to react |
| `an[0]` | N6 | 7-SEG Anode 0 | Digit 0 enable (active LOW) |
| `an[1]` | M6 | 7-SEG Anode 1 | Digit 1 enable (active LOW) |
| `an[2]` | M3 | 7-SEG Anode 2 | Digit 2 enable (active LOW) |
| `an[3]` | N5 | 7-SEG Anode 3 | Digit 3 enable (active LOW) |
| `sseg[6]` | L3 | Segment CA (a) | Top horizontal segment |
| `sseg[5]` | N1 | Segment CB (b) | Upper right vertical |
| `sseg[4]` | L5 | Segment CC (c) | Lower right vertical |
| `sseg[3]` | L4 | Segment CD (d) | Bottom horizontal |
| `sseg[2]` | K3 | Segment CE (e) | Lower left vertical |
| `sseg[1]` | M2 | Segment CF (f) | Upper left vertical |
| `sseg[0]` | L6 | Segment CG (g) | Middle horizontal |
| `sseg[7]` | M4 | Decimal Point (DP) | Decimal point |

---

## How To Program The Board

### Option A — Use the Pre-compiled Bitfile (Fastest)

No synthesis required. Just program directly.

1. Open **Vivado Hardware Manager**
2. Connect your **Nexys 4** board via USB
3. Click **Open Target → Auto Connect**
4. Click **Program Device**
5. Browse to `reactionTimer_bitfile_.bit`
6. Click **Program**
7. Done — ready to play immediately

### Option B — Build From Source in Vivado

1. Open Vivado and create a new **RTL Project**
2. Set the part to **Nexys 4** (xc7a100tcsg324-1)
3. Add source files: `rxn.v`, `bin2bcd.v`, `display.v`
4. Set `rxn.v` (module `reactionTimer`) as the **Top Module**
5. Add `Reaction_timer_xdcfile.xdc` as the constraints file
6. Run **Synthesis** → **Implementation** → **Generate Bitstream**
7. Open Hardware Manager and program the board

---

## Reaction Time Ratings

| Result | Rating |
|--------|--------|
| `< 150 ms` | ⚡ Superhuman |
| `150 – 200 ms` | 🏆 Excellent |
| `200 – 250 ms` | ✅ Average Human |
| `250 – 300 ms` | 📊 Below Average |
| `300 – 500 ms` | 😴 Slow |
| `> 500 ms` | 💀 Fell Asleep |

> Average human visual reaction time is around **200–250 ms**.

---

## Technical Details

### Clock & Timing

```
Clock frequency    : 100 MHz (10 ns period)
1 ms tick period   : 100,000 clock cycles (17-bit counter, max 99,999)
Max reaction time  : 9,999 ms (14-bit register)
Display refresh    : ~95 Hz per digit (18-bit counter, top 2 bits select digit)
```

### Random Delay Generation

```
Random counter     : free-runs 15 → 50 → 15 → ... every clock cycle
Delay range        : 15 × 10,000,000 = 1.5 sec  to  50 × 10,000,000 = 5.0 sec
Counter bit width  : 30 bits (max value = 500,000,000 < 2^30 = 1,073,741,824)
```

### Binary to BCD Conversion

The **Double Dabble** algorithm works by shifting the binary number left bit by bit. Before each shift, if any BCD nibble is ≥ 5, add 3 to it. After 14 shifts (one per bit), the BCD registers hold the decimal digits.

```
Input  : 14-bit binary  (e.g. 14'd247 = 0b00011110111)
Output : bcd3=0, bcd2=2, bcd1=4, bcd0=7  (displays "0247")
Cycles : 14 clock cycles to complete
```

### Display Multiplexing

Only one digit is physically ON at any moment. The controller cycles through all four digits so fast (~95 Hz) that persistence of vision makes them appear all ON simultaneously.

```
Digit select  : refresh_reg[17:16]  (top 2 bits of 18-bit counter)
Anode logic   : active LOW  (0 = digit ON, 1 = digit OFF)
Cathode logic : active LOW  (0 = segment ON, 1 = segment OFF)
```

---

## Module Port Summary

### reactionTimer (rxn.v)

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | 100 MHz clock |
| `clear` | input | 1 | Async reset (BTNC) |
| `start` | input | 1 | Start game (BTNU) |
| `stop` | input | 1 | Stop timer (BTND) |
| `led` | output | 1 | React signal LED |
| `an` | output | 4 | 7-seg anode select |
| `sseg` | output | 8 | 7-seg segments + DP |

### bin2bcd (bin2bcd.v)

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `reset` | input | 1 | Async reset |
| `start` | input | 1 | Begin conversion |
| `bin` | input | 14 | Binary value (0–9999) |
| `ready` | output | 1 | Ready for new conversion |
| `done_tick` | output | 1 | Conversion complete pulse |
| `bcd3..bcd0` | output | 4×4 | BCD digits (thousands to ones) |

### displayMuxBasys (display.v)

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `hex3..hex0` | input | 4×4 | BCD digits to display |
| `dp_in` | input | 4 | Decimal point per digit |
| `an` | output | 4 | Anode select (active LOW) |
| `sseg` | output | 8 | Segments + DP (active LOW) |

---

*Built with Verilog · Synthesized on Nexys 4 (Artix-7) · 100 MHz clock · Bitfile included*
