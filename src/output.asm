*=* "Output"
// ==========================================
// Clear the screen
// ==========================================
clear_screen:
    ldx #0
!:  jsr $e9ff
    inx
    cpx #25
    bne !-

    // reset basic cursor
    ldy #0
    sty $d3
    sty $d6

    rts
// ==========================================


// ==========================================
// Clear the current line with reverse spaces
// ==========================================
clear_line:
    lda #' '+128
    ldy #SCREEN_WIDTH
!:  dey
    sta (CURRENT_LINE_START),y
    bne !-
    rts
// ==========================================


// ==========================================
// Display the title
// ==========================================
show_title:
    jsr reset_line_start

    jsr clear_line

    ldy #(SCREEN_WIDTH-TITLE_TEXT.size())/2
    ldx #0

!:  lda TITLE,x
    beq !+
    clc
    adc #128
    sta (CURRENT_LINE_START),y
    iny
    inx
    clc
    bcc !-

!:  ldy #SCREEN_WIDTH-2
    lda #'f'+128
    sta (CURRENT_LINE_START),y
    iny
    lda #'1'+128
    sta (CURRENT_LINE_START),y
    iny

    rts
// ==========================================


// ==========================================
// Display the status bar
// ==========================================
show_status_bar:
    lda #<STATUS_LINE_START
    sta CURRENT_LINE_START
    lda #>STATUS_LINE_START
    sta CURRENT_LINE_START+1

    jsr clear_line

    // check if $0 has bit 0 set
    lda $1
    and #1
    bne !+

    // write an L to the bottom right corner
    ldy #SCREEN_WIDTH-1
    lda #'l'+128
    sta (CURRENT_LINE_START),y

!:  rts
// ==========================================


// ==========================================
// Write the data to the screen
// ==========================================
output_screen_data:
    jsr reset_line_start

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
!:  jsr output_line
    jsr move_down
    dex
    bne !-

    rts
// ==========================================


// ==========================================
// Output the current line of data
// ==========================================
output_line:
    // save X to the stack
    txa
    pha

    // output address
    ldy #ADDRESS_OFFSET
    lda CURRENT_ADDRESS+1
    jsr output_byte
    lda CURRENT_ADDRESS
    jsr output_byte

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
// ==========================================


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
// ==========================================


// ==========================================
// Output the selected address status bar
// ------------------------------------------
// Displays CURRENT_ADDRESS and A as the byte
// ==========================================
output_selected_address:
    // save A to the stack
    pha
    pha
    pha

    // move to status line
    lda #<STATUS_LINE_START
    sta CURRENT_LINE_START
    lda #>STATUS_LINE_START
    sta CURRENT_LINE_START+1

    // set to output inverted characters
    lda #128
    sta CHAR_OFFSET

    ldy #0

    lda #'['+128
    sta (CURRENT_LINE_START),y
    iny

    // output address
    lda CURRENT_ADDRESS+1
    jsr output_byte
    lda CURRENT_ADDRESS
    jsr output_byte

    lda #':'+128
    sta (CURRENT_LINE_START),y
    iny

    // restore A and output hex value
    pla
    jsr output_byte

    lda #','+128
    sta (CURRENT_LINE_START),y
    iny

    // restore A and output decimal value
    pla
    jsr output_decimal

    lda #','+128
    sta (CURRENT_LINE_START),y
    iny

    // restore A and output binary value
    pla
    jsr output_binary

    lda #']'+128
    sta (CURRENT_LINE_START),y
    iny

    // reset to normal characters
    lda #0
    sta CHAR_OFFSET

    // output run text
    ldy #SCREEN_WIDTH-5
    lda #'('+128
    sta (CURRENT_LINE_START),y
    iny
    lda #'r'+128
    sta (CURRENT_LINE_START),y
    iny
    lda #')'+128
    sta (CURRENT_LINE_START),y
    iny
    lda #'u'+128
    sta (CURRENT_LINE_START),y
    iny
    lda #'n'+128
    sta (CURRENT_LINE_START),y

    rts
// ==========================================


// ==========================================
// Output decimal value of the byte in A
// ------------------------------------------
// Writes to current line from position Y
// ==========================================
output_decimal:
    // save A to the stack
    pha
    pha

    // Start with highest power (100)
    ldx #2

decimal_loop:
    // store zero character in current_digit
    lda #'0'+128
    sta current_digit

    // restore A from the stack
    pla

    // check if A is < current power
!:  cmp powers,x
    bcc !+

    // else increment digit, subtract power from A and check again
    inc current_digit
    sec
    sbc powers,x
    bcs !-

    // save remainder to the stack
!:  pha

    // output digit to screen
    lda current_digit
    sta (CURRENT_LINE_START),y
    iny

    // loop for all digits
    dex
    bpl decimal_loop

    // remove last value and restore original A
    pla
    pla

    rts

current_digit: .byte 0
powers: .byte 1, 10, 100    // Powers of 10: 10^0, 10^1, 10^2
// ==========================================


// ==========================================
// Output binary value of the byte in A
// ------------------------------------------
// Writes to current line from position Y
// ==========================================
output_binary:
    // save A to the stack
    pha

    // set loop counter and offset
    ldx #8

    // shift value left so highest bit goes into carry
!:  asl

    // save value to the stack
    pha

    // set A to '0' or '1' by adding the carry bit
    lda #'0'+128
    adc #0

    // output to screen
!:  sta (CURRENT_LINE_START),y
    iny

    // restore value
    pla

    // loop for all bits
    dex
    bne !--

    // restore original A
    pla

    rts
// ==========================================
