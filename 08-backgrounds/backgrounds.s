;;
; This NES ROM displays a sprite on the screen which the player can move plus a background layer.
; Adapted from Nerdy Nights week 6: http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=8172
;;
.include "ppu.inc"
.include "controllers.inc"

; memory addresses where sprite attributes are stored in RAM
SPRITE_X = $0203
SPRITE_Y = $0200

.segment "ZEROPAGE"
buttons: .res 1             ; store controller #1 button states in $00

.segment "HEADER"
    .byte "NES", $1A        ; signature
    .byte $02               ; # of 16KB PRG-ROM banks
    .byte $01               ; # of 8KB VROM banks
    
.segment "CODE"
reset:                      ; adapted from https://wiki.nesdev.com/w/index.php/Init_code
    sei                     ; disable IRQs
    cld                     ; disable decimal mode
vblank_wait_1:              ; first wait for vblank to make sure the PPU is ready
    lda PPU_STATUS
    bpl vblank_wait_1
vblank_wait_2:              ; second wait for vblank; PPU is ready for drawing after this
    lda PPU_STATUS
    bpl vblank_wait_2
load_bg:                    ; write ascending values $00-$FF to nametable zero at PPU memory address $2000
    lda PPU_STATUS          ; read PPU_STATUS to force the high/low PPU_ADDR latch to high
    lda #$20
    sta PPU_ADDR            ; write the high byte of $2000, the nametable we're writing background tile #s to
    lda #$00
    sta PPU_ADDR            ; write the low byte of $2000, the nametable we're writing background tile #s to
    ldy #$04                ; outer loop Y 4 times
ld_bg_outer_loop:
    ldx #$00                ; inner loop X 256 times (to fill 4 x 256 = 1024 bytes of nametable + attribute table data)
load_bg_inner_loop:
    stx PPU_DATA
    inx
    bne load_bg_inner_loop
    dey
    bne ld_bg_outer_loop
    ;jsr clear_attribute_table ; comment this out for a technicolor nightmare (attribute table set to various colors)
load_palette:
    lda PPU_STATUS          ; read PPU_STATUS to force the high/low PPU_ADDR latch to high
    lda #$3F
    sta PPU_ADDR            ; write the high byte of $3F00, where palettes start, to the PPU's address register
    lda #$00
    sta PPU_ADDR            ; write the low byte of $3F00, where palettes start, to the PPU's address register
    ldx #$00                ; initialize register X as a loop counter
load_palette_loop:          ; copy all 32 bytes of palette data into VRAM
    lda palette_data, x     ; relative load from label + X
    sta PPU_DATA
    inx
    cpx #$20                ; all 32 bytes copied?
    bne load_palette_loop   ; if not, keep looping
load_sprite_oam:
    ; sprite data lives inside a special 256 byte on-chip memory of the PPU called OAM (object attribute memory)
    ; it is common to set up sprite data in a section of the CPU's own RAM and then copy it all over using DMA (direct memory access) (see: http://wiki.nesdev.com/w/index.php?title=PPU_OAM#DMA)
    ; this section sets up sprite zero's OAM values (see: http://wiki.nesdev.com/w/index.php?title=PPU_OAM)
    lda #$80
    sta SPRITE_Y        ; set sprite 0's top Y coordinate to $80 (near the center of the screen) (http://wiki.nesdev.com/w/index.php?title=PPU_OAM#Byte_0)
    sta SPRITE_X        ; set sprite 0's left X coordinate likewise (http://wiki.nesdev.com/w/index.php?title=PPU_OAM#Byte_3)
    lda #$01
    sta $0201           ; set sprite 0's tile number (http://wiki.nesdev.com/w/index.php?title=PPU_OAM#Byte_1)
    lda #$00
    sta $0202           ; set sprite 0 to use sprite palette 0, and don't flip it (http://wiki.nesdev.com/w/index.php?title=PPU_OAM#Byte_2)
enable_ppu:
    lda #%10010000
    sta PPU_CTRL        ; enable NMI, background from pattern table 1, sprites from pattern table 0
    lda #%00011110
    sta PPU_MASK        ; enable sprites, enable background, no clipping on left side
loop:
    jmp loop            ; loop forever
    
nmi:
    ; non-maskable interrupt handler called every vblank between drawing frames
    ; performs a DMA copy of sprite data from RAM address $0200-$02FF to the PPU's OAM
    lda #$00
    sta OAM_ADDR        ; set the low byte ($00) of the RAM address
    lda #$02
    sta OAM_DMA         ; set the high byte ($02) of the RAM address + start the transfer
    jsr read_joypad1    ; read controller input
read_up:
    lda buttons
    and #BUTTON_UP
    beq read_down
    jsr move_sprite_up
read_down:
    lda buttons
    and #BUTTON_DOWN
    beq read_left
    JSR move_sprite_down
read_left:
    lda buttons
    and #BUTTON_LEFT
    beq read_right
    jsr move_sprite_left
read_right:
    lda buttons
    and #BUTTON_RIGHT
    beq right_done
    jsr move_sprite_right
right_done:
    ; tell the PPU to render the background from (0, 0) (no scrolling)
    lda #$00
    sta PPU_SCROLL
    sta PPU_SCROLL
    rti                 ; return from NMI interrupt
    
; move sprite up by decrementing its Y coordinate
.proc move_sprite_up
    lda SPRITE_Y
    sec
    sbc #$01
    sta SPRITE_Y
    rts
.endproc

; move sprite down by incrementing its Y coordinate
.proc move_sprite_down
    lda SPRITE_Y
    clc
    adc #$01
    sta SPRITE_Y
    rts
.endproc
    
; move sprite left by decrementing its X coordinate
.proc move_sprite_left
    lda SPRITE_X
    sec
    sbc #$01
    sta SPRITE_X
    rts
.endproc
    
; move sprite right by incrementing its X coordinate
.proc move_sprite_right
    lda SPRITE_X
    clc
    adc #$01
    sta SPRITE_X
    rts
.endproc

; zero out the last 64 bytes of the nametable ($23C0 - $23FF) so we don't have crazy colors all over
.proc clear_attribute_table       
    lda PPU_STATUS
    lda #$23
    sta PPU_ADDR
    lda #$C0
    sta PPU_ADDR
    ldx #$40            ; loop 64 times
    lda #$00
loop:
    sta PPU_DATA
    dex
    bne loop
    rts
.endproc

; TODO: layout a real background with real tiles instead of just counting tiles
nametable:
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
    .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
    ; ...
    
palette_data:
    ; available colors: https://wiki.nesdev.com/w/index.php/PPU_palettes#2C02
    ; background colors to be loaded into $3F00
    .byte $0F             ; universal background color
    .byte $2D, $10, $1D   ; background palette 0 (grays)
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
    .word nmi, reset, 0
    
.segment "CHARS"
    .incbin "graphics.chr"
