;;
; Defines memory-mapped I/O locations for the NES controllers ("joypads")
; https://wiki.nesdev.com/w/index.php/Standard_controller
;;
JOYPAD1 = $4016
JOYPAD2 = $4017

BUTTON_A     = 1 << 7
BUTTON_B     = 1 << 6
BUTTON_SEL   = 1 << 5
BUTTON_START = 1 << 4
BUTTON_UP    = 1 << 3
BUTTON_DOWN  = 1 << 2
BUTTON_LEFT  = 1 << 1
BUTTON_RIGHT = 1

; Taken from https://wiki.nesdev.com/w/index.php/Controller_Reading
; This subroutine loops 8 times, reading controller #1's state into
; the "buttons" variable according to the bit flags above
.proc read_joypad1
    lda #$01
    ; While the strobe bit is set, buttons will be continuously reloaded.
    ; This means that reading from JOYPAD1 will only return the state of the first button (A)
    sta JOYPAD1
    sta buttons
    lsr a           ; now A is 0
    ; By storing 0 into JOYPAD1, the strobe bit is cleared and the reloading stops.
    ; This allows all 8 buttons (newly reloaded) to be read from JOYPAD1
    sta JOYPAD1
loop:
    lda JOYPAD1
    lsr a           ; bit0 -> Carry
    rol buttons     ; Carry -> bit0; bit 7 -> Carry
    bcc loop
    rts
.endproc

; example usage:
; jsr read_joypad1
; lda buttons
; and #BUTTON_A
; beq a_handling_done
; ... A was pressed
; ... handle it here
; a_handling_done:
; ... continue
