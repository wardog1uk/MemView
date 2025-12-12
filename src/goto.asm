*=* "Goto Address Routine"
// ==========================================
// Get address from user and move there
// ==========================================
goto_address:
    // move to status line
    lda #<STATUS_LINE_START
    sta CURRENT_LINE_START
    lda #>STATUS_LINE_START
    sta CURRENT_LINE_START+1

    // calculate position to center goto text
    .var goto_start = (SCREEN_WIDTH-GOTO_TEXT.size()-4)/2
    ldy #goto_start
    ldx #0

    // output GOTO text
!:  lda GOTO,x
    beq goto_address_loop
    clc
    adc #128
    sta (CURRENT_LINE_START),y
    iny
    inx
    clc
    bcc !-

goto_address_loop:
    // output start address
    ldy #goto_start+GOTO_TEXT.size()
    lda START_ADDRESS+1
    jsr output_byte
    lda START_ADDRESS
    jsr output_byte

    // get key press
!:  jsr $ffe4
    beq !-

    // check for return key
    cmp #$0d
    bne !+

    // return key so redraw and exit
    jsr show_status_bar
    rts

    // not return
!:  jsr convert_hex_digit

    // restart loop if not a hex digit
    bmi goto_address_loop

    // handle hex digit
    // shift address left by one byte
    asl START_ADDRESS
    rol START_ADDRESS+1
    asl START_ADDRESS
    rol START_ADDRESS+1
    asl START_ADDRESS
    rol START_ADDRESS+1
    asl START_ADDRESS
    rol START_ADDRESS+1

    // add hex value to address
    ora START_ADDRESS
    sta START_ADDRESS

    // reset selected row and column for editing
    lda #0
    sta SELECTED_ROW
    sta SELECTED_COLUMN

    // restart loop
    clc
    bcc goto_address_loop
// ==========================================
