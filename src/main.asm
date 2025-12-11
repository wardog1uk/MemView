#import "const.asm"
#import "variables.asm"
#import "edit.asm"
#import "output.asm"

#if C000
    *=$c000 "MemView"
    jmp start
#else
    BasicUpstart2(start)
    *=* "MemView"
#endif


// ==========================================
// Program Entry
// ==========================================
start:
    jsr clear_screen
    jsr show_title
    jsr show_status_bar

!:  jsr output_screen_data
    jsr get_user_input
    clc
    bcc !-
// ==========================================


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
// Show the title
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
// Show the status bar
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
// Get and process user input
// ==========================================
get_user_input:
    // wait for key press
    jsr $ffe4
    beq get_user_input

    ldx #0
    jsr process_input

    rts
// ==========================================


// ==========================================
// Check for key input and jump to action
// Starts from position X in input_keys
// ==========================================
process_input:
    // return if no more input keys to check
    ldy input_keys,x
    bne !+
    rts

    // check if A matches this input
!:  cmp input_keys,x
    beq !+

    // no match so move to next input key
    inx
    clc
    bcc process_input

    // match found, get address
!:  lda actions_low,x
    sta TEMP_POINTER
    lda actions_high,x
    sta TEMP_POINTER+1

    // jump to the address
    jmp (TEMP_POINTER)
// ==========================================


// ==========================================
exit_program:
    ldx #6
!:  pla
    dex
    bne !-
    jsr clear_screen
    rts
// ==========================================


// ==========================================
arrow_right:
    lda #TABLE_COLS
    jsr increase_start_address
    rts
// ==========================================


// ==========================================
arrow_left:
    lda #TABLE_COLS
    jsr decrease_start_address
    rts
// ==========================================


// ==========================================
arrow_up:
    lda #TABLE_COLS * TABLE_ROWS
    jsr decrease_start_address
    rts
// ==========================================


// ==========================================
arrow_down:
    lda #TABLE_COLS * TABLE_ROWS
    jsr increase_start_address
    rts
// ==========================================


// ==========================================
plus_key:
    lda #1
    jsr increase_start_address
    rts
// ==========================================


// ==========================================
minus_key:
    lda #1
    jsr decrease_start_address
    rts
// ==========================================


// ==========================================
// Increase the start address by A
// ==========================================
increase_start_address:
    clc
    adc START_ADDRESS
    bcc !+
    inc START_ADDRESS+1
!:  sta START_ADDRESS
    rts
// ==========================================


// ==========================================
// Decrease the start address by A
// ==========================================
decrease_start_address:
    // add two's complement of A to subtract
    eor #$ff
    clc
    adc #1
    clc
    adc START_ADDRESS
    bcs !+
    dec START_ADDRESS+1
!:  sta START_ADDRESS
    rts
// ==========================================


// ==========================================
// Toggle LORAM memory bank
// ==========================================
toggle_loram:
    lda $01
    eor #%00000001
    sta $01
    jsr show_status_bar
    rts
// ==========================================


// ==========================================
goto_address:
    // move to status line
    lda #<STATUS_LINE_START
    sta CURRENT_LINE_START
    lda #>STATUS_LINE_START
    sta CURRENT_LINE_START+1

    .var goto_start = (SCREEN_WIDTH-GOTO_TEXT.size()-4)/2
    ldy #goto_start
    ldx #0

    // output GOTO text
!:  lda GOTO,x
    beq !+
    clc
    adc #128
    sta (CURRENT_LINE_START),y
    iny
    inx
    clc
    bcc !-

    // output start address
!:  ldy #goto_start+GOTO_TEXT.size()
    lda START_ADDRESS+1
    jsr output_byte
    lda START_ADDRESS
    jsr output_byte

    // get key press
!:  jsr $ffe4
    beq !-

    // check for return key
    cmp #$0d
    beq !+

    jsr convert_hex_digit

    // not a hex digit
    bmi !-

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

    // reset selected row and column
    lda #0
    sta SELECTED_ROW
    sta SELECTED_COLUMN

    // restart loop
    clc
    bcc !--

    // redraw status bar
!:  jsr show_status_bar

    rts
// ==========================================


// ==========================================
// Show help text
// ==========================================
show_help:
    // update title line
    jsr reset_line_start
    jsr clear_line

    ldy #1
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

!:  iny
    ldx #0
!:  lda CREDIT,x
    beq !+
    clc
    adc #128
    sta (CURRENT_LINE_START),y
    iny
    inx
    clc
    bcc !-

    // move to status line
!:  lda #<STATUS_LINE_START
    sta CURRENT_LINE_START
    lda #>STATUS_LINE_START
    sta CURRENT_LINE_START+1

    ldy #1
    ldx #0

    // output help text
!:  lda HELP,x
    beq !+
    clc
    adc #128
    sta (CURRENT_LINE_START),y
    iny
    inx
    clc
    bcc !-

    // get key press
!:  jsr $ffe4
    beq !-

    jsr show_title
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
// Convert low byte of A to screen character
// ------------------------------------------
// Adds CHAR_OFFSET to screen character
// ==========================================
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

    // add any offset
!:  clc
    adc CHAR_OFFSET: #0

    rts
// ==========================================


// ==========================================
// Move line start to top left of screen
// ==========================================
reset_line_start:
    // set start line to top left of screen
    lda #<SCREEN_RAM
    sta CURRENT_LINE_START
    lda #>SCREEN_RAM
    sta CURRENT_LINE_START+1
    rts
// ==========================================


// ==========================================
// Move CURRENT_LINE_START to the next line
// ==========================================
move_down:
    lda CURRENT_LINE_START
    clc
    adc #SCREEN_WIDTH
    bcc !+
    inc CURRENT_LINE_START+1
!:  sta CURRENT_LINE_START
    rts
// ==========================================


// ==========================================
// Set A to binary value of hex digit in A
// or $ff if not a hex digit.
// ==========================================
convert_hex_digit:
    sec
    sbc #'0'
    bcc !+      // bad if <0

    cmp #10
    bcc !++     // good if 0-9

    sbc #7
    cmp #16
    bcs !+      // bad if >15

    cmp #10
    bcs !++     // good if 10-15

    // bad - set negative flag
!:  lda #$ff
    rts

    // good - clear negative flag
!:  ldx #0
    rts
// ==========================================
