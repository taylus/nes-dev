;;
; This NES ROM loads and displays some sprites on the screen.
; Adapted from Nerdy Nights week 4: http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=6082
;;
.include "ppu.inc"

.segment "HEADER"
    .byte "NES", $1A    ; signature
    .byte $02           ; # of 16KB PRG-ROM banks
    .byte $01           ; # of 8KB VROM banks
    
.segment "CODE"
STARTUP:                ; adapted from https://wiki.nesdev.com/w/index.php/Init_code
    SEI                 ; disable IRQs
    CLD                 ; disable decimal mode
VBLANKWAIT1:            ; first wait for vblank to make sure the PPU is ready
    LDA PPU_STATUS
    BPL VBLANKWAIT1
VBLANKWAIT2:            ; second wait for vblank; PPU is ready for drawing after this
    LDA PPU_STATUS
    BPL VBLANKWAIT2
LOADPALETTE:
    LDA PPU_STATUS      ; read PPU_STATUS to force the high/low PPU_ADDR latch to high
    LDA #$3F
    STA PPU_ADDR        ; write the high byte of $3F00, where palettes start, to the PPU's address register
    LDA #$00
    STA PPU_ADDR        ; write the low byte of $3F00, where palettes start, to the PPU's address register
    LDX #$00
LOADPALETTELOOP:        ; copy all 32 bytes of palette data into VRAM
    LDA PALETTEDATA, X
    STA PPU_DATA
    INX
    CPX #$20            ; all 32 bytes copied?
    BNE LOADPALETTELOOP ; if not, copy the next
LOADSPRITEOAM:
    ; sprite data lives inside a special 256 byte on-chip memory of the PPU called OAM (object attribute memory)
    ; it is common to set up sprite data in a section of the CPU's own RAM and then copy it all over using DMA (direct memory access) (see: http://wiki.nesdev.com/w/index.php?title=PPU_OAM#DMA)
    ; this section sets up sprite zero's OAM values (see: http://wiki.nesdev.com/w/index.php?title=PPU_OAM)
    LDA #$80
    STA $0200           ; set sprite 0's top Y coordinate to $80 (near the center of the screen) (http://wiki.nesdev.com/w/index.php?title=PPU_OAM#Byte_0)
    STA $0203           ; set sprite 0's left X coordinate likewise (http://wiki.nesdev.com/w/index.php?title=PPU_OAM#Byte_3)
    LDA #$00
    STA $0201           ; set sprite 0's tile number to zero (http://wiki.nesdev.com/w/index.php?title=PPU_OAM#Byte_1)
    ;LDA #$01           ; (use values 0-3 for the different sprite palettes)
    STA $0202           ; set sprite 0 to use sprite palette 0, and don't flip it (http://wiki.nesdev.com/w/index.php?title=PPU_OAM#Byte_2)
    ; set up another sprite's OAM values
    LDA #$8A
    STA $0204           ; set sprite 1's Y coordinate to $8A
    LDA #$80
    STA $0207           ; set sprite 1's X coordinate to $80
    LDA #$00
    STA $0205           ; set sprite 1's tile number to zero
    LDA #%10000011            
    STA $0206           ; set sprite 1 to use sprite palette 3 and flip it vertically
ENABLESPRITES:
    LDA #%10000000
    STA PPU_CTRL        ; enable NMI, and use sprites from pattern table 0
    LDA #%00010000
    STA PPU_MASK        ; no color intensify (black bg), show sprites, hide bg
LOOP:
    JMP LOOP            ; loop forever
    
NMI:
    ; non-maskable interrupt handler called every vblank between drawing frames
    ; performs a DMA copy of sprite data from RAM address $0200-$02FF to the PPU's OAM
    LDA #$00
    STA OAM_ADDR        ; set the low byte ($00) of the RAM address
    LDA #$02
    STA OAM_DMA         ; set the high byte ($02) of the RAM address + start the transfer
    RTI                 ; return from interrupt
    
PALETTEDATA:
    ; available colors: https://wiki.nesdev.com/w/index.php/PPU_palettes#2C02
    ; background colors to be loaded into $3F00
    .byte $0F             ; universal background color
    .byte $3D, $2D, $1D   ; background palette 0 (grays)
    .byte $0F             ; ignored
    .byte $16, $27, $18   ; background palette 1 (reds)
    .byte $0F             ; ignored
    .byte $19, $2A, $1B   ; background palette 2 (greens)
    .byte $0F             ; ignored
    .byte $11, $22, $13   ; background palette 3 (blues)
    ; sprite colors to be loaded into $3F10
    .byte $0F             ; ignored
    .byte $17, $28, $06   ; sprite palette 0 (brown, yellow, darker brown)
    .byte $0F             ; ignored
    .byte $16, $27, $18   ; sprite palette 1 (reds)
    .byte $0F             ; ignored
    .byte $19, $2A, $1B   ; sprite palette 2 (greens)
    .byte $0F             ; ignored
    .byte $11, $22, $13   ; sprite palette 3 (blues)

.segment "VECTORS"
    .word NMI, STARTUP, 0;
    
.segment "CHARS"
    .incbin "smiley.chr"
