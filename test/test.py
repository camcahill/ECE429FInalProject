import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


def controls(set_mode=0, inc_hour=0, inc_minute=0, pause=0,
             output_select=0, toggle_ampm=0, clear_seconds=0):
    return (
        (set_mode & 1)
        | ((inc_hour & 1) << 1)
        | ((inc_minute & 1) << 2)
        | ((pause & 1) << 3)
        | ((output_select & 3) << 4)
        | ((toggle_ampm & 1) << 6)
        | ((clear_seconds & 1) << 7)
    )


async def reset_dut(dut):
    dut.ena.value = 1
    dut.ui_in.value = controls(pause=1)
    dut.uio_in.value = 0

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)

    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 3)
    await Timer(50, unit="ns")


async def read_seconds(dut):
    dut.ui_in.value = controls(pause=1, output_select=0)
    await ClockCycles(dut.clk, 1)
    await Timer(50, unit="ns")
    return int(dut.uo_out.value) & 0x3F


async def read_minutes(dut):
    dut.ui_in.value = controls(pause=1, output_select=1)
    await ClockCycles(dut.clk, 1)
    await Timer(50, unit="ns")
    return int(dut.uo_out.value) & 0x3F


async def read_hours(dut):
    dut.ui_in.value = controls(pause=1, output_select=2)
    await ClockCycles(dut.clk, 1)
    await Timer(50, unit="ns")
    return int(dut.uo_out.value) & 0x0F


async def read_status(dut):
    dut.ui_in.value = controls(pause=1, output_select=3)
    await ClockCycles(dut.clk, 1)
    await Timer(50, unit="ns")
    return int(dut.uo_out.value)


async def read_pm(dut):
    await Timer(50, unit="ns")
    return (int(dut.uio_out.value) >> 1) & 0x01


async def pulse_hour(dut):
    dut.ui_in.value = controls(set_mode=1, inc_hour=1, pause=1)
    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = controls(set_mode=1, inc_hour=0, pause=1)
    await ClockCycles(dut.clk, 1)


async def pulse_minute(dut):
    dut.ui_in.value = controls(set_mode=1, inc_minute=1, pause=1)
    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = controls(set_mode=1, inc_minute=0, pause=1)
    await ClockCycles(dut.clk, 1)


async def pulse_toggle_ampm(dut):
    dut.ui_in.value = controls(set_mode=1, toggle_ampm=1, pause=1)
    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = controls(set_mode=1, toggle_ampm=0, pause=1)
    await ClockCycles(dut.clk, 1)


async def pulse_clear_seconds(dut):
    dut.ui_in.value = controls(clear_seconds=1, pause=1)
    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = controls(clear_seconds=0, pause=1)
    await ClockCycles(dut.clk, 1)


async def run_clock_cycles(dut, cycles):
    dut.ui_in.value = controls(pause=0, output_select=0)
    await ClockCycles(dut.clk, cycles)

    dut.ui_in.value = controls(pause=1, output_select=0)
    await ClockCycles(dut.clk, 1)
    await Timer(50, unit="ns")


@cocotb.test()
async def test_reset(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    assert await read_hours(dut) == 12
    assert await read_minutes(dut) == 0
    assert await read_seconds(dut) == 0
    assert await read_pm(dut) == 0


@cocotb.test()
async def test_set_mode_and_run(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    await pulse_hour(dut)
    await pulse_hour(dut)

    await pulse_minute(dut)
    await pulse_minute(dut)
    await pulse_minute(dut)

    assert await read_hours(dut) == 2
    assert await read_minutes(dut) == 3
    assert await read_seconds(dut) == 0

    await run_clock_cycles(dut, 5)

    assert await read_hours(dut) == 2
    assert await read_minutes(dut) == 3
    assert await read_seconds(dut) == 5


@cocotb.test()
async def test_pause_and_clear_seconds(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    await run_clock_cycles(dut, 5)
    assert await read_seconds(dut) == 5

    dut.ui_in.value = controls(pause=1)
    await ClockCycles(dut.clk, 5)
    await Timer(50, unit="ns")

    assert await read_seconds(dut) == 5

    await pulse_clear_seconds(dut)
    assert await read_seconds(dut) == 0


@cocotb.test()
async def test_rollover_and_am_pm(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    assert await read_pm(dut) == 0

    await pulse_toggle_ampm(dut)
    assert await read_pm(dut) == 1

    await pulse_toggle_ampm(dut)
    assert await read_pm(dut) == 0

    # Set time to 11:59:00 AM.
    # Reset starts at 12, so 11 hour pulses reaches 11.
    for _ in range(11):
        await pulse_hour(dut)

    for _ in range(59):
        await pulse_minute(dut)

    assert await read_hours(dut) == 11
    assert await read_minutes(dut) == 59
    assert await read_seconds(dut) == 0
    assert await read_pm(dut) == 0

    # Run 60 seconds:
    # 11:59:00 AM -> 12:00:00 PM
    await run_clock_cycles(dut, 60)

    assert await read_hours(dut) == 12
    assert await read_minutes(dut) == 0
    assert await read_seconds(dut) == 0
    assert await read_pm(dut) == 1
