BasicUpstart2(start)
*=* "Start"


.const SCREEN_RAM = $0400

.const SCREEN_WIDTH = 40
.const ROW_START = 2
.const TABLE_ROWS = 21
.const TABLE_COLS = 8

// current line in screen memory
.const CURRENT_LINE_START = $02


// column offset for the address
ADDRESS_OFFSET: .byte 1

// column offsets for the bytes
BYTE_OFFSET: .byte 6, 9, 12, 15, 18, 21, 24, 27

// column offsets for the ASCII characters
ASCII_OFFSET: .byte 30, 31, 32, 33, 35, 36, 37, 38


start:
    lda #$93
    jsr $ffd2

    jsr outputScreenData
    rts


outputScreenData:
    // set to start of screen
    lda #<SCREEN_RAM
    sta CURRENT_LINE_START
    lda #>SCREEN_RAM
    sta CURRENT_LINE_START+1

    // move to start of first row
    ldx #ROW_START
!:  jsr move_down
    dex
    bne !-

    // output all lines
    ldx #TABLE_ROWS
!:  jsr outputLine
    jsr move_down
    dex
    bne !-

    rts


outputLine:
    // save X to the stack
    txa
    pha

    lda #'0'

    // output address
    ldy ADDRESS_OFFSET
    sta (CURRENT_LINE_START),y
    iny
    sta (CURRENT_LINE_START),y
    iny
    sta (CURRENT_LINE_START),y
    iny
    sta (CURRENT_LINE_START),y

    ldx #0

    // load value to A
!:  lda #'x'

    // output bytes
    ldy BYTE_OFFSET,x
    sta (CURRENT_LINE_START),y
    iny
    sta (CURRENT_LINE_START),y

    // output ASCII
    ldy ASCII_OFFSET,x
    sta (CURRENT_LINE_START),y

    inx
    cpx #TABLE_COLS
    bne !-

    // restore X
    pla
    tax

    rts


move_down:
    lda CURRENT_LINE_START
    clc
    adc #SCREEN_WIDTH
    bcc !+
    inc CURRENT_LINE_START+1
!:  sta CURRENT_LINE_START
    rts
