# Analog Clock Controller

## What it does

This project is a digital analog clock controller for Tiny Tapeout. It tracks seconds, minutes, hours, and AM/PM status. The clock starts at 12:00:00 AM after reset. It counts in a 12-hour format and toggles AM/PM when the time rolls from 11:59:59 to 12:00:00.

The design is called an analog clock controller because the internal counters represent the positions of the second, minute, and hour hands on a traditional analog clock.

## How it works

The design uses internal counters for seconds, minutes, and hours. The seconds counter counts from 0 to 59. When it reaches 59, it rolls over to 0 and increments the minutes counter. The minutes counter also counts from 0 to 59. When it reaches 59, it rolls over to 0 and increments the hour counter.

The hour counter uses a 12-hour format. It starts at 12, counts to 1 after 12, and eventually reaches 11. When the clock rolls from 11:59:59 to 12:00:00, the AM/PM flag toggles.

All 8 TinyTapeout input pins are used. The inputs control set mode, hour increment, minute increment, pause, output selection, AM/PM toggle, and clear seconds. The output bus shows seconds, minutes, hours, or status depending on the output select pins.

## Block diagram

    ui_in[7:0]
        |
        v
    +----------------------+
    | Control Logic        |
    | set, pause, inc,     |
    | clear, AM/PM toggle  |
    +----------+-----------+
               |
               v
    +----------------------+
    | Seconds Counter      |
    | 0 to 59              |
    +----------+-----------+
               |
               v
    +----------------------+
    | Minutes Counter      |
    | 0 to 59              |
    +----------+-----------+
               |
               v
    +----------------------+
    | Hours Counter        |
    | 1 to 12              |
    +----------+-----------+
               |
               v
    +----------------------+
    | AM/PM Flag           |
    +----------+-----------+
               |
               v
    +----------------------+
    | Output Select Mux    |
    | sec/min/hour/status  |
    +----------+-----------+
               |
               v
       uo_out[7:0], uio_out[7:0]

## Top-level I/O pins

| TinyTapeout Pin | Internal Name | Direction | Purpose |
|---|---|---|---|
| ui_in[0] | set_mode | Input | Enables manual time setting |
| ui_in[1] | inc_hour | Input | Increments the hour |
| ui_in[2] | inc_minute | Input | Increments the minute |
| ui_in[3] | pause_clock | Input | Pauses the clock |
| ui_in[4] | output_select[0] | Input | Output select bit 0 |
| ui_in[5] | output_select[1] | Input | Output select bit 1 |
| ui_in[6] | toggle_ampm | Input | Toggles AM/PM in set mode |
| ui_in[7] | clear_seconds | Input | Clears seconds to zero |
| uo_out[7:0] | selected_output | Output | Selected clock value |
| uio_out[0] | valid | Output | Status valid bit |
| uio_out[1] | pm | Output | AM/PM status |
| uio_out[2] | set_mode | Output | Set mode status |
| uio_out[3] | pause_clock | Output | Pause status |
| uio_out[4] | inc_hour | Output | Increment hour status |
| uio_out[5] | inc_minute | Output | Increment minute status |
| uio_out[6] | toggle_ampm | Output | Toggle AM/PM status |
| uio_out[7] | clear_seconds | Output | Clear seconds status |

## Output select table

| ui_in[5:4] | uo_out[7:0] shows |
|---|---|
| 00 | Seconds |
| 01 | Minutes |
| 10 | Hours |
| 11 | Status byte |

## Example behavior

After reset, the clock starts at 12:00:00 AM.

If the clock is not paused and not in set mode, seconds count upward. After 59 seconds, seconds roll over to 0 and minutes increment. After 59 minutes and 59 seconds, minutes and seconds roll over and the hour increments. When the time changes from 11:59:59 to 12:00:00, the AM/PM flag toggles.

In set mode, the increment hour and increment minute inputs allow the user to manually set the time. The toggle AM/PM input lets the user manually change AM or PM. The clear seconds input clears the seconds counter to zero.

## How to test

The cocotb testbench checks the main clock behaviors. It resets the design and verifies that the time starts at 12:00:00 AM. It checks that seconds increment, set mode works, pause mode works, clear seconds works, AM/PM toggle works, and the clock rolls over correctly.

To run the test locally:

    cd test
    make clean
    make

A successful test should report that all cocotb tests passed.
