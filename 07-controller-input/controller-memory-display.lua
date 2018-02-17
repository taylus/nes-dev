-- This script reads and displays the content of memory address $0000
-- (where controller-input.nes stores controller #1's button states)
-- and $0200-$0203 (where sprite attribute data is stored)

while (true) do
    local buttons = memory.readbyte(0x0000)
    local buttonText = string.format("Controller #1 state: %s\nA: %s\nB: %s\nSELECT: %s\nSTART: %s\nUP: %s\nDOWN: %s\nLEFT: %s\nRIGHT: %s",
        buttons,
        tostring(AND(buttons, 128) > 0),
        tostring(AND(buttons, 64) > 0),
        tostring(AND(buttons, 32) > 0),
        tostring(AND(buttons, 16) > 0),
        tostring(AND(buttons, 8) > 0),
        tostring(AND(buttons, 4) > 0),
        tostring(AND(buttons, 2) > 0),
        tostring(AND(buttons, 1) > 0))
    gui.text(0, 9, buttonText)
    
    local spriteX = memory.readbyte(0x0203)
    local spriteY = memory.readbyte(0x0200)
    gui.text(0, 224, string.format("Sprite position: (%s, %s)", spriteX, spriteY))
    
    emu.frameadvance()
end
