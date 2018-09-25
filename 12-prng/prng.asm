; This NES ROM demoes https://wiki.nesdev.com/w/index.php/Random_number_generator
.segment "HEADER"
    .byte "NES", $1A
    .byte $02, $01

.segment "ZEROPAGE"
seed: .res 2

.segment "STARTUP"
main:
    ; initialize seed
    lda #$be
    sta seed
    lda #$ba
    sta seed + 1
:
    jsr prng
    jmp :-

prng:
    ldx #8
    lda seed
:
    asl
    rol seed + 1
    bcc :+
    eor #$2D
:
    dex
    bne :--
    sta seed
    cmp #0
    rts

.segment "VECTORS"
    .word 0, main, 0

.segment "CHARS"
