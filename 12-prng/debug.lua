-- implement a breakpoint
-- (see "Example of custom breakpoint" http://www.fceux.com/web/help/fceux.html?LuaFunctionsList.html)
function init_breakpoint()
    emu.print(string.format("Seed: %02x%02x", memory.readbyte(0x0003), memory.readbyte(0x0002)))
    memory.registerexecute(0x8008, nil)  -- de-register callback
end
memory.registerexecute(0x8008, init_breakpoint)  -- end of seed init

function rng_breakpoint()
    local rng = memory.getregister("a")
    emu.print(string.format("Random number: %02x", rng))
    emu.pause()
end
memory.registerexecute(0x801E, rng_breakpoint)  -- end of prng routine
