;;
; This NES ROM displays multiple sprites on the screen, demonstrating the > 8 per scanline problem.
;;
.include "ppu.inc"
.include "controllers.inc"

; memory addresses where sprite attributes are stored in RAM
SPRITE_X = $0203
SPRITE_Y = $0200

; variables in work RAM
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
clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  lda #$FE                  ; move all sprites off the screen
  sta $0200, x
  inx
  bne clear_memory
vblank_wait_1:              ; first wait for vblank to make sure the PPU is ready
    lda PPU_STATUS
    bpl vblank_wait_1
vblank_wait_2:              ; second wait for vblank; PPU is ready for drawing after this
    lda PPU_STATUS
    bpl vblank_wait_2
    load_nametable nametable, $2000
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
    ldx #$00
load_sprite_loop:
    lda initial_sprite_data, x
    sta $0200, x
    inx
    cpx #$24                ; all 36 bytes copied?
    bne load_sprite_loop    ; if not, keep looping
enable_ppu:
    lda #%10010000
    sta PPU_CTRL        ; enable NMI, background from pattern table 1, sprites from pattern table 0
    lda #%00011110
    sta PPU_MASK        ; enable sprites, enable background, no clipping on left side
loop:
    jmp loop            ; loop forever
    
nmi:
    jsr sprite_shuffle
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

; sprite drawing priority is determined by position in memory (lower = drawn first)
; swap sprites 7 and 8 to induce flicker when there are > 8 sprites per scanlnie
.proc sprite_shuffle
    ; swap y position bytes
    ldx $021C
    ldy $0220
    stx $0220
    sty $021C
    ; swap tile # bytes
    ldx $021D
    ldy $0221
    stx $0221
    sty $021D
    ; swap attribute bytes
    ldx $021E
    ldy $0222
    stx $0222
    sty $021E
    ; swap x position bytes
    ldx $021F
    ldy $0223
    stx $0223
    sty $021F
    rts
.endproc

; sprite attribute data to load on startup
; y position, tile #, attributes, x position
; for more info, see http://wiki.nesdev.com/w/index.php?title=PPU_OAM
initial_sprite_data:
    .byte $50, $00, $00, $19    ; sprite 0
    .byte $80, $01, $00, $32    ; sprite 1
    .byte $80, $02, $00, $4B    ; sprite 2
    .byte $80, $03, $00, $64    ; sprite 3
    .byte $80, $04, $00, $7D    ; sprite 4
    .byte $80, $05, $00, $96    ; sprite 5
    .byte $80, $06, $00, $AF    ; sprite 6
    .byte $80, $07, $00, $C8    ; sprite 7
    .byte $80, $08, $00, $E1    ; sprite 8

nametable:
    .incbin "gfx\mariobg.nam"
    
palette_data:
    ; available colors: https://wiki.nesdev.com/w/index.php/PPU_palettes#2C02
    ; background colors to be loaded into $3F00
    .incbin "gfx\mariobg.pal"
    ; sprite colors to be loaded into $3F10
    .byte $22             ; universal background color
    .byte $17, $28, $06   ; sprite palette 0 (brown, yellow, darker brown)
    .byte $22             ; ignored
    .byte $16, $27, $18   ; sprite palette 1 (reds)
    .byte $22             ; ignored
    .byte $19, $2A, $1B   ; sprite palette 2 (greens)
    .byte $22             ; ignored
    .byte $11, $22, $13   ; sprite palette 3 (blues)

.segment "VECTORS"
    .word nmi, reset, 0
    
.segment "CHARS"
    .incbin "gfx\mario.chr"
