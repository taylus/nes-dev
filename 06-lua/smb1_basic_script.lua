-- This script prints the NES's CPU registers and draws a bounding box around Mario in SMB1
-- as a demonstration of how Lua scripting in the FCEUX emulator can work with memory and etc.

function printRegisters()
    local a = memory.getregister("a")
    local x = memory.getregister("x")
    local y = memory.getregister("y")
    local s = memory.getregister("s")
    local p = memory.getregister("p")
    local pc = memory.getregister("pc")
    local text = string.format("CPU Registers:\nA:  %X\nX:  %X\nY:  %X\nS:  %X\nP:  %X\nPC: %X", a, x, y, s, p, pc)
    gui.text(0, 176, text)
end

-- read Mario's position from memory for SMB1
function drawMarioBoundingBox()
    -- memory addresses obtained from https://datacrystal.romhacking.net/wiki/Super_Mario_Bros.:RAM_map
    local marioOnScreen = memory.readbyte(0x0033) ~= 0
    if true then
        local marioX = memory.readbyte(0x03AD)
        local marioY = memory.readbyte(0x03B8) -- 0x00CE?
        local shortMario = memory.readbyte(0x0754) == 1
        if shortMario then
            gui.box(marioX, marioY + 16, marioX + 16, marioY + 32)
        else
            gui.box(marioX, marioY, marioX + 16, marioY + 32)
        end
        local text = string.format("Mario X: %s\nMario Y: %s\nSuper Mario? %s", marioX, marioY, tostring(not shortMario))
        gui.text(0, 9, text)
    end
end

while (true) do
    printRegisters()
    drawMarioBoundingBox()
    emu.frameadvance()
end
