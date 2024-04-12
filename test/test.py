import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.types import LogicArray
from cocotb.types.range import Range
from posit import from_bits, from_double

async def printStates(dut):
    await RisingEdge(dut.clk)
    return [dut.x.value, dut.y.value, dut.z.value]


@cocotb.test()
async def dda(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 83, units="ns") # 83
    cocotb.start_soon(clock.start())
    
    # Reset
    dut._log.info("Reset")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    # Set the input values, wait one clock cycle, and check the output
    dut._log.info("Setting initial conditions")

    N = 16
    ES = 1
    
    dt = (1./256) #1./256
    x = [-1.]
    y = [0.1]
    z = [25.]
    sigma = 10.0
    beta = 8./3.
    rho = 28.0

    p_icx = from_double(x=x[0], size=N, es=ES)
    p_icy = from_double(x=y[0], size=N, es=ES)
    p_icz = from_double(x=z[0], size=N, es=ES)
    p_sigma = from_double(x=sigma, size=N, es=ES)
    p_beta = from_double(x=beta, size=N, es=ES)
    p_rho = from_double(x=rho, size=N, es=ES)
    p_dt = from_double(x=dt, size=N, es=ES)

    dut.icx.value = LogicArray(p_icx.bit_repr(),Range(N-1,'downto',0))
    dut.icy.value = LogicArray(p_icy.bit_repr(),Range(N-1,'downto',0))
    dut.icz.value = LogicArray(p_icz.bit_repr(),Range(N-1,'downto',0))
    dut.sigma.value = LogicArray(p_sigma.bit_repr(),Range(N-1,'downto',0))
    dut.beta.value = LogicArray(p_beta.bit_repr(),Range(N-1,'downto',0))
    dut.rho.value = LogicArray(p_rho.bit_repr(),Range(N-1,'downto',0))
    dut.dt.value = LogicArray(p_dt.bit_repr(),Range(N-1,'downto',0))
    dut.en.value = 1
    # dut.log.info("Read data: %s", rx_data)
    # dut.ui_in.value = 20
    # dut.uio_in.value = 30

    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    run = 1
    f_out = open(f"run_dda_{run}.dat","w")

    dut._log.info("Testing solver")
    for _ in range(10000):
        state = await printStates(dut)
        p_x = from_bits(state[0].integer,N,ES)
        p_y = from_bits(state[1].integer,N,ES)
        p_z = from_bits(state[2].integer,N,ES)
        f_out.write(f"{p_x.eval()}, {p_y.eval()}, {p_z.eval()}\n")
    f_out.close()