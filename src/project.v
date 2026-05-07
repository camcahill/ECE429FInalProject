/*
 * Copyright (c) 2024 Cameron Cahill
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_camcahill_analog_clock (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // All 8 input pins are used.
    wire set_mode;
    wire inc_hour;
    wire inc_minute;
    wire pause_clock;
    wire [1:0] output_select;
    wire toggle_ampm;
    wire clear_seconds;

    assign set_mode      = ui_in[0];
    assign inc_hour      = ui_in[1];
    assign inc_minute    = ui_in[2];
    assign pause_clock   = ui_in[3];
    assign output_select = ui_in[5:4];
    assign toggle_ampm   = ui_in[6];
    assign clear_seconds = ui_in[7];

    // Clock registers
    reg [5:0] seconds;     // 0 to 59
    reg [5:0] minutes;     // 0 to 59
    reg [3:0] hours;       // 1 to 12
    reg       pm;          // 0 = AM, 1 = PM

    // Edge detection registers
    reg prev_inc_hour;
    reg prev_inc_minute;
    reg prev_toggle_ampm;

    wire inc_hour_pulse;
    wire inc_minute_pulse;
    wire toggle_ampm_pulse;

    assign inc_hour_pulse    = inc_hour    & ~prev_inc_hour;
    assign inc_minute_pulse  = inc_minute  & ~prev_inc_minute;
    assign toggle_ampm_pulse = toggle_ampm & ~prev_toggle_ampm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seconds          <= 6'd0;
            minutes          <= 6'd0;
            hours            <= 4'd12;
            pm               <= 1'b0;

            prev_inc_hour    <= 1'b0;
            prev_inc_minute  <= 1'b0;
            prev_toggle_ampm <= 1'b0;
        end else begin
            prev_inc_hour    <= inc_hour;
            prev_inc_minute  <= inc_minute;
            prev_toggle_ampm <= toggle_ampm;

            if (clear_seconds) begin
                seconds <= 6'd0;
            end else if (set_mode) begin
                seconds <= 6'd0;

                if (inc_hour_pulse) begin
                    if (hours == 4'd11) begin
                        hours <= 4'd12;
                        pm <= ~pm;
                    end else if (hours == 4'd12) begin
                        hours <= 4'd1;
                    end else begin
                        hours <= hours + 4'd1;
                    end
                end

                if (inc_minute_pulse) begin
                    if (minutes == 6'd59)
                        minutes <= 6'd0;
                    else
                        minutes <= minutes + 6'd1;
                end

                if (toggle_ampm_pulse) begin
                    pm <= ~pm;
                end
            end else if (!pause_clock) begin
                if (seconds == 6'd59) begin
                    seconds <= 6'd0;

                    if (minutes == 6'd59) begin
                        minutes <= 6'd0;

                        if (hours == 4'd11) begin
                            hours <= 4'd12;
                            pm <= ~pm;
                        end else if (hours == 4'd12) begin
                            hours <= 4'd1;
                        end else begin
                            hours <= hours + 4'd1;
                        end
                    end else begin
                        minutes <= minutes + 6'd1;
                    end
                end else begin
                    seconds <= seconds + 6'd1;
                end
            end
        end
    end

    // Status output uses all 8 bidirectional output pins.
    wire [7:0] status_output;

    assign status_output = {
        clear_seconds,
        toggle_ampm,
        inc_minute,
        inc_hour,
        pause_clock,
        set_mode,
        pm,
        1'b1
    };

    // Main 8-bit output bus uses all 8 dedicated output pins.
    reg [7:0] selected_output;

    always @* begin
        case (output_select)
            2'b00: selected_output = {2'b00, seconds};
            2'b01: selected_output = {2'b00, minutes};
            2'b10: selected_output = {4'b0000, hours};
            2'b11: selected_output = status_output;
            default: selected_output = 8'b00000000;
        endcase
    end

    assign uo_out  = selected_output;
    assign uio_out = status_output;
    assign uio_oe  = 8'hFF;

    // Prevent unused warning for TinyTapeout pins not used as logic inputs.
    wire _unused = &{ena, uio_in, 1'b0};

endmodule
