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

    wire rst;
    assign rst = ~rst_n;

    // Control inputs
    wire set_mode;
    wire inc_hour;
    wire inc_minute;
    wire pause_clock;

    assign set_mode    = ui_in[0];
    assign inc_hour    = ui_in[1];
    assign inc_minute  = ui_in[2];
    assign pause_clock = ui_in[3];

    // Output select:
    // 00 = seconds
    // 01 = minutes
    // 10 = hours
    // 11 = status
    wire [1:0] output_select;
    assign output_select = ui_in[5:4];

    // Time registers
    reg [5:0] seconds;     // 0 to 59
    reg [5:0] minutes;     // 0 to 59
    reg [3:0] hours;       // 1 to 12
    reg       pm;          // 0 = AM, 1 = PM

    // Edge detection for button-like inputs
    reg prev_inc_hour;
    reg prev_inc_minute;

    wire inc_hour_pulse;
    wire inc_minute_pulse;

    assign inc_hour_pulse   = inc_hour   & ~prev_inc_hour;
    assign inc_minute_pulse = inc_minute & ~prev_inc_minute;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seconds         <= 6'd0;
            minutes         <= 6'd0;
            hours           <= 4'd12;
            pm              <= 1'b0;     // reset to 12:00:00 AM
            prev_inc_hour   <= 1'b0;
            prev_inc_minute <= 1'b0;
        end else begin
            prev_inc_hour   <= inc_hour;
            prev_inc_minute <= inc_minute;

            if (set_mode) begin
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

    // Output mux
    reg [7:0] selected_output;

    always @* begin
        case (output_select)
            2'b00: selected_output = {2'b00, seconds};
            2'b01: selected_output = {2'b00, minutes};
            2'b10: selected_output = {4'b0000, hours};
            2'b11: selected_output = {4'b0000, pause_clock, set_mode, pm, 1'b1};
            default: selected_output = 8'b0;
        endcase
    end

    assign uo_out = selected_output;

    // Status outputs
    assign uio_out[0] = pm;          // 0 = AM, 1 = PM
    assign uio_out[1] = set_mode;
    assign uio_out[2] = pause_clock;
    assign uio_out[7:3] = 5'b00000;

    assign uio_oe = 8'hFF;

    wire _unused;
    assign _unused = &{ena, uio_in, ui_in[7:6], 1'b0};

endmodule
