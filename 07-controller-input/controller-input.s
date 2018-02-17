;;
; This NES ROM displays a sprite on the screen which the player can move.
; Adapted from Nerdy Nights week 5: http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=7974
;;
.include "ppu.inc"
.include "controllers.inc"

; memory addresses where sprite attributes are stored in RAM
SPRITE_X = $0203
SPRITE_Y = $0200

.segment "ZEROPAGE"
buttons: .res 1         ; store controller #1 button states in $00

.segment "HEADER"
    .byte "NES", $1A    ; signature
    .byte $02           ; # of 16KB PRG-ROM banks
    .byte $01           ; # of 8KB VROM banks
    
.segment "CODE"
RESET:                  ; adapted from https://wiki.nesdev.com/w/index.php/Init_code
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
    STA SPRITE_Y        ; set sprite 0's top Y coordinate to $80 (near the center of the screen) (http://wiki.nesdev.com/w/index.php?title=PPU_OAM#Byte_0)
    STA SPRITE_X        ; set sprite 0's left X coordinate likewise (http://wiki.nesdev.com/w/index.php?title=PPU_OAM#Byte_3)
    LDA #$00
    STA $0201           ; set sprite 0's tile number to zero (http://wiki.nesdev.com/w/index.php?title=PPU_OAM#Byte_1)
    STA $0202           ; set sprite 0 to use sprite palette 0, and don't flip it (http://wiki.nesdev.com/w/index.php?title=PPU_OAM#Byte_2)
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
    JSR ReadJoypad1     ; read controller input
READ_UP:
    LDA buttons
    AND #BUTTON_UP
    BEQ READ_DOWN
    JSR MoveSpriteUp
READ_DOWN:
    LDA buttons
    AND #BUTTON_DOWN
    BEQ READ_LEFT
    JSR MoveSpriteDown
READ_LEFT:
    LDA buttons
    AND #BUTTON_LEFT
    BEQ READ_RIGHT
    JSR MoveSpriteLeft
READ_RIGHT:
    LDA buttons
    AND #BUTTON_RIGHT
    BEQ RIGHT_DONE
    JSR MoveSpriteRight
RIGHT_DONE:
    RTI                 ; return from NMI interrupt
    
; move sprite up by decrementing its Y coordinate
.proc MoveSpriteUp
    LDA SPRITE_Y
    SEC
    SBC #$01
    STA SPRITE_Y
    RTS
.endproc

; move sprite down by incrementing its Y coordinate
.proc MoveSpriteDown
    LDA SPRITE_Y
    CLC
    ADC #$01
    STA SPRITE_Y
    RTS
.endproc
    
; move sprite left by decrementing its X coordinate
.proc MoveSpriteLeft
    LDA SPRITE_X
    SEC
    SBC #$01
    STA SPRITE_X
    RTS
.endproc
    
; move sprite right by incrementing its X coordinate
.proc MoveSpriteRight
    LDA SPRITE_X
    CLC
    ADC #$01
    STA SPRITE_X
    RTS
.endproc
    
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
    .word NMI, RESET, 0;
    
.segment "CHARS"
    .incbin "smiley.chr"
