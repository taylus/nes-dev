;;
; Defines memory-mapped register locations for the NES Picture Processing Unit (PPU)
;;
PPU_CTRL   = $2000       ; https://wiki.nesdev.com/w/index.php/PPU_registers#PPUCTRL
PPU_MASK   = $2001       ; https://wiki.nesdev.com/w/index.php/PPU_registers#PPUMASK
PPU_STATUS = $2002       ; https://wiki.nesdev.com/w/index.php/PPU_registers#PPUSTATUS
PPU_SCROLL = $2005       ; https://wiki.nesdev.com/w/index.php/PPU_registers#PPUSCROLL
PPU_ADDR   = $2006       ; https://wiki.nesdev.com/w/index.php/PPU_registers#PPUADDR
PPU_DATA   = $2007       ; https://wiki.nesdev.com/w/index.php/PPU_registers#PPUDATA

OAM_ADDR   = $2003       ; http://wiki.nesdev.com/w/index.php?title=PPU_registers#OAMADDR
OAM_DATA   = $2004       ; http://wiki.nesdev.com/w/index.php?title=PPU_registers#OAMDATA
OAM_DMA    = $4014       ; http://wiki.nesdev.com/w/index.php?title=PPU_registers#OAMDMA
