BasicUpstart2(start)
*=* "Start"


.const SCREEN_RAM = $0400
.const DEFAULT_ADDRESS = $c000

.const SCREEN_WIDTH = 40
.const ROW_START = 2
.const TABLE_ROWS = 21
.const TABLE_COLS = 8

// pointer to current line in screen memory
.const CURRENT_LINE_START = $02

// pointer to address being written
.const CURRENT_ADDRESS = $f2


// column offset for the address
ADDRESS_OFFSET: .byte 1

// column offsets for the bytes
BYTE_OFFSET: .byte 6, 9, 12, 15, 18, 21, 24, 27

// column offsets for the ASCII characters
ASCII_OFFSET: .byte 30, 31, 32, 33, 35, 36, 37, 38

// address at top left of screen
START_ADDRESS: .word DEFAULT_ADDRESS


start:
    lda #$93
    jsr $ffd2

loop:
    jsr outputScreenData

    // wait for key press
!:  jsr $ffe4
    beq !-

    // right arrow
    cmp #$1d
    bne !++
    inc START_ADDRESS
    bne !+
    inc START_ADDRESS+1
!:  clc
    bcc loop

    // left arrow
!:  cmp #$9d
    bne !++
    lda START_ADDRESS
    bne !+
    dec START_ADDRESS+1
!:  dec START_ADDRESS
    clc
    bcc loop

!:  rts


outputScreenData:
    // set start line to top left of screen
    lda #<SCREEN_RAM
    sta CURRENT_LINE_START
    lda #>SCREEN_RAM
    sta CURRENT_LINE_START+1

    // move to start of first row
    ldx #ROW_START
!:  jsr move_down
    dex
    bne !-

    // set current address to first address
    lda START_ADDRESS
    sta CURRENT_ADDRESS
    lda START_ADDRESS+1
    sta CURRENT_ADDRESS+1

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

    jsr outputAddress

    ldx #0

    // load value to A
!:  ldy #0
    lda (CURRENT_ADDRESS),y

    // output bytes
    ldy BYTE_OFFSET,x
    jsr output_byte

    // output ASCII
    ldy ASCII_OFFSET,x
    sta (CURRENT_LINE_START),y

    // move to next address
    inc CURRENT_ADDRESS
    bne !+
    inc CURRENT_ADDRESS+1

!:  inx
    cpx #TABLE_COLS
    bne !--

    // restore X
    pla
    tax

    rts


outputAddress:
    ldy ADDRESS_OFFSET

    lda CURRENT_ADDRESS+1
    jsr output_byte

    lda CURRENT_ADDRESS
    jsr output_byte

    rts


// ==========================================
// Output the hex value of the current byte
//-------------------------------------------
// Set Y to the column offset
// ==========================================
output_byte:
    // save byte to the stack
    pha
    pha

    // shift high byte to low byte
    lsr
    lsr
    lsr
    lsr

    // convert to screen character
    jsr byte_to_char

    // write character to screen
    sta (CURRENT_LINE_START),y
    iny

    // restore byte
    pla

    // convert to screen character
    jsr byte_to_char

    // write character to screen
    sta (CURRENT_LINE_START),y
    iny

    // restore original byte to A
    pla

    rts
//==========================================================


// ==========================================
// Convert low byte of A to screen character
// ------------------------------------------
byte_to_char:
    // mask off high byte
    and #$0f

    // add '0'
    ora #'0'

    // check if > 9
    cmp #'9'+1
    bcc !+

    // if > 9 then convert to 'a' to 'f' 
    sbc #'9'

!:  rts
// ==========================================


move_down:
    lda CURRENT_LINE_START
    clc
    adc #SCREEN_WIDTH
    bcc !+
    inc CURRENT_LINE_START+1
!:  sta CURRENT_LINE_START
    rts
