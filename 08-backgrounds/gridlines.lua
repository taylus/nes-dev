-- This script draws 8x8 and 16x16 gridlines on the screen.
-- This helps visualize an NES ROM's nametable (background tiles)
-- and the 2x2 blocks in which they are colored by the attribute table.

local function draw()
    local SCREEN_WIDTH = 256
    local SCREEN_HEIGHT = 240
    
    local TILE_SIZE = 8
    local BLOCK_SIZE = 16
    
    local TILE_GRID_COLOR = "#EEEEEE33"
    local BLOCK_GRID_COLOR = "#44444455"
    
    -- draw 8x8 tile grid
    for x = 0, SCREEN_WIDTH, TILE_SIZE do
        gui.line(x, 0, x, SCREEN_HEIGHT, TILE_GRID_COLOR);
    end
    for y = 0, SCREEN_HEIGHT, TILE_SIZE do
        gui.line(0, y, SCREEN_WIDTH, y, TILE_GRID_COLOR);
    end
    
    -- draw 16x16 tile grid
    for x = 0, SCREEN_WIDTH, BLOCK_SIZE do
        gui.line(x, 0, x, SCREEN_HEIGHT, BLOCK_GRID_COLOR);
    end
    for y = 0, SCREEN_HEIGHT, BLOCK_SIZE do
        gui.line(0, y, SCREEN_WIDTH, y, BLOCK_GRID_COLOR);
    end
end

emu.registerafter(draw)
