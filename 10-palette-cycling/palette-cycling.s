;;
; This NES ROM displays simple color animations by changing palette colors.
;;
.include "ppu.inc"

FRAME_COUNTER = $00
CLR_ROT_COUNTER = $03

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
    lda #$FE                ; move all sprites off the screen
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
    cpx #$10                ; all 16 bytes copied?
    bne load_palette_loop   ; if not, keep looping
enable_ppu:
    lda #%10010000
    sta PPU_CTRL            ; enable NMI, background from pattern table 1, sprites from pattern table 0
    lda #%00001110
    sta PPU_MASK            ; disable sprites, enable background, no clipping on left side
loop:
    jmp loop                ; loop forever
    
nmi:
    ; palette cycle
    inc FRAME_COUNTER
    lda FRAME_COUNTER
    and #$07                ; mask out all but the three LSB
    bne nmi_done            ; branch if non-zero to do this every eighth frame
    inc CLR_ROT_COUNTER
    lda CLR_ROT_COUNTER
    cmp #$06
    bne nmi_done
    lda #$00                ; reset color rotation index counter back to zero
    sta CLR_ROT_COUNTER
nmi_done:
    ; update palette color at PPU address $3F0D
    lda PPU_STATUS          ; read PPU_STATUS to force the high/low PPU_ADDR latch to high
    lda #$3F
    sta PPU_ADDR            ; write the high byte of $3F0D, the address of the color we want to overwrite, to the PPU's address register
    lda #$0D
    sta PPU_ADDR            ; write the low byte of $3F0D, the address of the color we want to overwrite, to the PPU's address register
    ldx CLR_ROT_COUNTER
    lda color_rotate_palette, x
    sta PPU_DATA
    ; tell the PPU to render the background from (0, 0) (no scrolling)
    lda #$00
    sta PPU_SCROLL
    sta PPU_SCROLL
    ; reset PPU control register since writing to PPU_ADDR corrupts it (https://wiki.nesdev.com/w/index.php/Errata#Video)
    lda #%10010000
    sta PPU_CTRL            ; enable NMI, background from pattern table 1, sprites from pattern table 0
    rti

nametable:
    .incbin "gfx\mariobg.nam"
    
palette_data:
    ; available colors: https://wiki.nesdev.com/w/index.php/PPU_palettes#2C02
    ; background colors to be loaded into $3F00
    .incbin "gfx\mariobg.pal"
    
; loop the bg color at PPU address $3F0D through these colors every 8 frames
color_rotate_palette:
    .byte $27, $27, $27, $17, $07, $17

.segment "VECTORS"
    .word nmi, reset, 0
    
.segment "CHARS"
    .incbin "gfx\mario.chr"
