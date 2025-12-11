*=* "Edit"
// ==========================================
// Select and edit a byte
// ==========================================
edit_byte:
    // hide "F1" from title bar
    jsr reset_line_start
    lda #' '+128
    ldy #SCREEN_WIDTH-2
    sta (CURRENT_LINE_START),y
    iny
    sta (CURRENT_LINE_START),y

    // display current selection
    jsr show_selection

    // get address of selected byte
    jsr get_selected_address

edit_loop:
    // load byte at selected address
    ldy #0
    lda (CURRENT_ADDRESS),y

    // display status bar
    jsr output_selected_address

    // get key press
!:  jsr $ffe4
    beq !-

    // up arrow
!:  cmp #ARROW_UP
    bne !+
    jsr hide_selection
    ldx SELECTED_ROW
    beq edit_byte
    dec SELECTED_ROW
    clc
    bcc edit_byte

    // down arrow
!:  cmp #ARROW_DOWN
    bne !+
    jsr hide_selection
    ldx SELECTED_ROW
    cpx #TABLE_ROWS-1
    bcs edit_byte
    inc SELECTED_ROW
    clc
    bcc edit_byte

    // left arrow
!:  cmp #ARROW_LEFT
    bne !+
    jsr hide_selection
    ldx SELECTED_COLUMN
    beq edit_byte
    dec SELECTED_COLUMN
    clc
    bcc edit_byte

    // right arrow
!:  cmp #ARROW_RIGHT
    bne !+
    jsr hide_selection
    ldx SELECTED_COLUMN
    cpx #TABLE_COLS-1
    bcs edit_byte
    inc SELECTED_COLUMN
    clc
    bcc edit_byte

!:  cmp #'R'
    bne !+
    jsr hide_selection
    jsr execute
    clc
    bcc edit_byte

    // return key
!:  cmp #RETURN
    beq !+

    // check for and handle hex digit
    jsr hex_input_when_editing

    // restart loop
    clc
    bcc edit_loop

!:  jsr hide_selection

    // put "F1" back on title bar
    jsr reset_line_start
    lda #'f'+128
    ldy #SCREEN_WIDTH-2
    sta (CURRENT_LINE_START),y
    lda #'1'+128
    iny
    sta (CURRENT_LINE_START),y

    // redraw status bar and exit routine
    jsr show_status_bar

    rts
// ==========================================


// ==========================================
// Point CURRENT_ADDRESS to selected address
// ==========================================
get_selected_address:
    // set current address to start address
    lda START_ADDRESS+1
    sta CURRENT_ADDRESS+1
    lda START_ADDRESS

    // loop for all rows until X is 0
    ldx SELECTED_ROW
!:  beq !++

    // add table width
    clc
    adc #TABLE_COLS
    bcc !+
    inc CURRENT_ADDRESS+1

    // decrement X and restart loop
!:  dex
    clc
    bcc !--

    // add columns
!:  clc
    adc SELECTED_COLUMN
    bcc !+
    inc CURRENT_ADDRESS+1
!:  sta CURRENT_ADDRESS

    rts
// ==========================================


// ==========================================
// Start execution at the current address
// ==========================================
execute:
    jmp (CURRENT_ADDRESS)
    rts
// ==========================================


// ==========================================
// Handle hex input when in edit mode
// ==========================================
hex_input_when_editing:
    jsr convert_hex_digit
    bpl !+

    // not a hex digit
    rts

    // store hex value
!:  sta edit_value

    // get current byte
    ldy #0
    lda (CURRENT_ADDRESS),y

    // shift left
    asl
    asl
    asl
    asl

    // add hex value to byte
    ora edit_value: #0

    // write new byte to memory
    sta (CURRENT_ADDRESS),y

    // reload byte from memory in case it wasn't written
    lda (CURRENT_ADDRESS),y

    // save byte
    pha

    // move to correct place
    jsr hide_selection
    dey

    // output byte
    pla
    jsr output_byte

    // invert selection
    jsr show_selection

    rts
// ==========================================


// ==========================================
// Show cursor for selected byte
// ==========================================
show_selection:
    jsr toggle_selection

    // draw right side bar
    iny
    lda #$75
    sta (CURRENT_LINE_START),y

    // draw left side bar
    dey
    dey
    dey
    lda #$76
    sta (CURRENT_LINE_START),y

    // restore y
    iny
    iny

    rts
// ==========================================


// ==========================================
// Hide cursor for selected byte
// ==========================================
hide_selection:
    jsr toggle_selection

    // hide right side bar
    iny
    lda #' '
    sta (CURRENT_LINE_START),y

    // hide left side bar
    dey
    dey
    dey
    sta (CURRENT_LINE_START),y

    // restore y
    iny
    iny

    rts
// ==========================================


// ==========================================
// Toggle the selection display
// ==========================================
toggle_selection:
    jsr reset_line_start

    // calculate row offset on screen
    lda #ROW_START
    clc
    adc SELECTED_ROW
    tay

    // move CURRENT_LINE_START to correct row
!:  jsr move_down
    dey
    bne !-

    // get byte offset for selected column
    ldx SELECTED_COLUMN
    ldy BYTE_OFFSET,x

    // invert first digit
    lda (CURRENT_LINE_START),y
    clc
    adc #128
    sta (CURRENT_LINE_START),y

    iny

    // invert second digit
    lda (CURRENT_LINE_START),y
    clc
    adc #128
    sta (CURRENT_LINE_START),y

    rts
// ==========================================
