;;
; This NES ROM displays an interactive controller on the screen.
;;
.include "ppu.inc"
.include "controllers.inc"

; variables in work RAM
.segment "ZEROPAGE"
buttons: .res 1             ; current frame's controller button states
buttons_old: .res 1         ; last frame's controller button states
released_buttons: .res 1    ; buttons that were released this frame (were pressed last frame but not the current frame, see get_released_buttons)
frame_counter: .res 1       ; counts up every frame for timing events

OAM_BASE_ADDR = $0200       ; location in work RAM where sprite data is stored (before DMA to VRAM)

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
    sta OAM_BASE_ADDR, x
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
    lda #%10001000
    sta PPU_CTRL            ; enable NMI, background uses pattern table 0, sprites use pattern table 1
    lda #%00011110
    sta PPU_MASK            ; enable sprites, enable background, no clipping on left side
loop:
    jmp loop                ; loop forever
    
nmi:
    inc frame_counter
copy_sprite_oam:
    lda #$00
    sta OAM_ADDR                ; set the low byte ($00) of the RAM address
    lda #$02
    sta OAM_DMA                 ; set the high byte ($02) of the RAM address + start the transfer
animate:
    lda frame_counter
    and #$7F                    ; mask out the most significant bit
    bne read_input              ; branch if non-zero to blink every 128 frames
    jsr blink
read_input:
    lda buttons
    sta buttons_old             ; save copy of last frame's buttons
    jsr read_joypad1            ; read current frame's controller buttons
    jsr get_released_buttons    ; determine buttons released this frame
is_up_pressed:
    lda buttons
    and #BUTTON_UP
    beq is_up_released
    jsr up_pressed
is_up_released:
    lda released_buttons
    and #BUTTON_UP
    beq is_down_pressed
    jsr up_released
is_down_pressed:
    lda buttons
    and #BUTTON_DOWN
    beq is_down_released
    JSR down_pressed
is_down_released:
    lda released_buttons
    and #BUTTON_DOWN
    beq is_left_pressed
    JSR down_released
is_left_pressed:
    lda buttons
    and #BUTTON_LEFT
    beq is_left_released
    jsr left_pressed
is_left_released:
    lda released_buttons
    and #BUTTON_LEFT
    beq is_right_pressed
    jsr left_released
is_right_pressed:
    lda buttons
    and #BUTTON_RIGHT
    beq is_right_released
    jsr right_pressed
is_right_released:
    lda released_buttons
    and #BUTTON_RIGHT
    beq is_select_pressed
    jsr right_released
is_select_pressed:
    lda buttons
    and #BUTTON_SELECT
    beq is_select_released
    jsr select_pressed
is_select_released:
    lda released_buttons
    and #BUTTON_SELECT
    beq is_start_pressed
    jsr select_released
is_start_pressed:
    lda buttons
    and #BUTTON_START
    beq is_start_released
    jsr start_pressed
is_start_released:
    lda released_buttons
    and #BUTTON_START
    beq is_a_pressed
    jsr start_released
is_a_pressed:
    lda buttons
    and #BUTTON_A
    beq is_a_released
    jsr a_pressed
is_a_released:
    lda released_buttons
    and #BUTTON_A
    beq is_b_pressed
    jsr a_released
is_b_pressed:
    lda buttons
    and #BUTTON_B
    beq is_b_released
    jsr b_pressed
is_b_released:
    lda released_buttons
    and #BUTTON_B
    beq input_done
    jsr b_released
input_done:
    ; tell the PPU to render the background from (0, 0) (no scrolling)
    lda #$00
    sta PPU_SCROLL
    sta PPU_SCROLL
    rti

; update nametable for pressing up on the d-pad
.proc up_pressed
    ppu_write $2129, $0E
    rts
.endproc

; update nametable for releasing up on the d-pad
.proc up_released
    ppu_write $2129, $0B
    rts
.endproc

; update nametable for pressing down on the d-pad
.proc down_pressed
    ppu_write $2169, $2E
    rts
.endproc

; update nametable for releasing down on the d-pad
.proc down_released
    ppu_write $2169, $2B
    rts
.endproc

; update nametable for pressing left on the d-pad 
.proc left_pressed
    ppu_write $2148, $1D
    rts
.endproc

; update nametable for releasing left on the d-pad 
.proc left_released
    ppu_write $2148, $1A
    rts
.endproc
    
; update nametable for pressing right on the d-pad
.proc right_pressed
    ppu_write $214A, $1F
    rts
.endproc

; update nametable for releasing right on the d-pad
.proc right_released
    ppu_write $214A, $1C
    rts
.endproc

; update nametable for pressing the select button
.proc select_pressed
    ppu_write $214D, $54
    rts
.endproc

; update nametable for releasing the select button
.proc select_released
    ppu_write $214D, $51
    rts
.endproc

; update nametable for pressing the start button
.proc start_pressed
    ppu_write $214F, $54
    rts
.endproc

; update nametable for releasing the start button
.proc start_released
    ppu_write $214F, $51
    rts
.endproc

; update nametable for pressing the A button
.proc a_pressed
    ppu_write $2155, $32, $33
    ppu_write $2175, $42, $43
    rts
.endproc

; update nametable for releasing the A button
.proc a_released
    ppu_write $2155, $30, $31
    ppu_write $2175, $40, $41
    rts
.endproc

; update nametable for pressing the B button
.proc b_pressed
    ppu_write $2152, $32, $33
    ppu_write $2172, $42, $43
    rts
.endproc

; update nametable for releasing the B button
.proc b_released
    ppu_write $2152, $30, $31
    ppu_write $2172, $40, $41
    rts
.endproc

; update sprites to make roly blink --
; toggle sprite 1 between tile #$04 (eyes closed) and #$01 (eyes open)
.proc blink
    lda $0205
    cmp #$01            ; eyes open?
    beq close_eyes      ; then close
open_eyes:              ; else open
    ;lda #$01
    ;sta $0205
    set_sprite_tile $1, $1
    rts
close_eyes:
    ;lda #$04
    ;sta $0205
    set_sprite_tile $1, $4
    rts
.endproc

; sprite attribute data to load on startup
; y position, tile #, attributes, x position
; for more info, see http://wiki.nesdev.com/w/index.php?title=PPU_OAM
initial_sprite_data:
    .byte $98, $00, $00, $68    ; sprite 0 (top left)
    .byte $98, $01, $00, $70    ; sprite 1 (top middle)
    .byte $98, $02, $00, $78    ; sprite 2 (top right)
    .byte $A0, $10, $00, $68    ; sprite 3 (bottom left)
    .byte $A0, $11, $00, $70    ; sprite 4 (bottom middle)
    .byte $A0, $12, $00, $78    ; sprite 5 (bottom right)

; screen tile numbers and attribute table (palettes)
nametable:
    .incbin "gfx\nesjoy.nam"
    
; background colors to be loaded into $3F00
; available colors: https://wiki.nesdev.com/w/index.php/PPU_palettes#2C02
palette_data:
    .incbin "gfx\nesjoy.pal"
    ; sprite colors to be loaded into $3F10
    .byte $0F             ; universal background color
    .byte $01, $30, $06   ; sprite palette 0 (blue, white, red)
    .byte $0F             ; ignored
    .byte $00, $00, $00   ; sprite palette 1 (unused)
    .byte $0F             ; ignored
    .byte $00, $00, $00   ; sprite palette 2 (unused)
    .byte $0F             ; ignored
    .byte $00, $00, $00   ; sprite palette 3 (unused)

.segment "VECTORS"
    .word nmi, reset, 0
    
.segment "CHARS"
    .incbin "gfx\nesjoy.chr"
