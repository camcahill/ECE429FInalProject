# Analog Clock Controller

## What it does

This project is a digital analog clock controller for Tiny Tapeout. It tracks seconds, minutes, hours, and AM/PM status. The clock starts at 12:00:00 AM after reset. It counts in a 12-hour format and toggles AM/PM when the time rolls from 11:59:59 to 12:00:00.

The design is called an analog clock controller because the counters represent the positions of the second, minute, and hour hands on a traditional analog clock.

## How it works

The design uses internal counters for seconds, minutes, and hours. The seconds counter counts from 0 to 59. When it reaches 59, it rolls over to 0 and increments the minutes counter. The minutes counter also counts from 0 to 59. When it reaches 59, it rolls over to 0 and increments the hour counter.

The hour counter uses a 12-hour format. It starts at 12, counts to 1 after 12, and eventually reaches 11. When the clock rolls from 11:59:59 to 12:00:00, the AM/PM flag toggles.

The input pins control set mode, hour increment, minute increment, pause, and output selection. The output select bits choose whether the output bus shows seconds, minutes, hours, or status.

## Block diagram

    ui_in[7:0]
        |
        v
    +----------------+
    | Control Logic  |
    | set/pause/inc  |
    +-------+--------+
            |
            v
    +----------------+
    | Seconds Counter|
    | 0 to 59        |
    +-------+--------+
            |
            v
    +----------------+
    | Minutes Counter|
    | 0 to 59        |
    +-------+--------+
            |
            v
    +----------------+
    | Hours Counter  |
    | 1 to 12        |
    +-------+--------+
            |
            v
    +----------------+
    | AM/PM Flag     |
    +-------+--------+
            |
            v
    +----------------+
    | Output Mux     |
    +-------+--------+
            |
            v
    uo_out[7:0], uio_out[7:0]

## Top-level I/O pins

| Pin | Direction | Purpose |
|---|---|---|
| ui_in[0] | Input | Set mode |
| ui_in[1] | Input | Increment hour |
| ui_in[2] | Input | Increment minute |
| ui_in[3] | Input | Pause clock |
| ui_in[4] | Input | Output select bit 0 |
| ui_in[5] | Input | Output select bit 1 |
| ui_in[7:6] | Input | Unused |
| uo_out[7:0] | Output | Selected clock value |
| uio_out[0] | Output | AM/PM status, 0 = AM and 1 = PM |
| uio_out[1] | Output | Set mode status |
| uio_out[2] | Output | Pause status |
| uio_out[7:3] | Output | Unused status outputs |

## How to test

The cocotb testbench checks the main clock behaviors. It resets the design and verifies that the time starts at 12:00:00 AM. It then checks that the seconds counter increments when the clock is running. The testbench also checks set mode, pause mode, rollover from 59 seconds to 0 seconds, and AM/PM rollover from 11:59:59 to 12:00:00.

To run the test locally:

```bash
cd test
make clean
make
