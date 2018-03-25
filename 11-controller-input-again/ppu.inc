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

; load the 1024 bytes of nametable + attribute table data at nametable_src_addr
; into the PPU's video memory at ppu_dest_addr ($2000, $2400, etc)
; uses zeropage addresses $01-02 for indirectly addressing the nametable data
.macro load_nametable nametable_src_addr, ppu_dest_addr
    ; set up the PPU for storing data at ppu_dest_addr:
    lda #>ppu_dest_addr     ; high byte of the VRAM address for this nametable
    sta PPU_ADDR
    lda #<ppu_dest_addr     ; low byte of the VRAM address for this nametable
    sta PPU_ADDR
    
    ; write nametable data to VRAM via the PPU's data register
    ; uses a nested loop with the X and Y registers to address >256 bytes of memory
    lda #<nametable_src_addr
    sta $01                 ; store the low byte at zp addr $01 for indirect addressing into nametable data
    lda #>nametable_src_addr
    sta $02                 ; store the high byte at the following zp addr $02
    ldx #$4                 ; initialize x to 4 for outer loop ($04 to $00)
    ldy #$0                 ; initialize y to 0 for inner loop ($00 to $FF) (4 x 256 = 1024 bytes, a whole nametable)
:   lda ($01), y            ; store into the accumulator the value at address ($02 $01) + y
    sta PPU_DATA            ; write that byte of nametable data to the PPU
    iny
    bne :-                  ; inner loop while y != 0
    inc $02
    dex
    bne :-                  ; outer loop while x != 0
.endmacro

; writes the given bytes of data to PPU memory at the given address
.macro ppu_write addr, data1, data2
    lda #>addr
    sta PPU_ADDR
    lda #<addr
    sta PPU_ADDR
    lda #data1
    sta PPU_DATA
.ifnblank data2
    lda #data2
    sta PPU_DATA
.endif
.endmacro

; writes tile_number to the second byte of the given sprite's OAM data,
; setting the tile it uses for graphics (see: see http://wiki.nesdev.com/w/index.php?title=PPU_OAM)
.macro set_sprite_tile sprite_index, tile_number
    lda #tile_number
    sta OAM_BASE_ADDR + 1 + (sprite_index * 4)
.endmacro
