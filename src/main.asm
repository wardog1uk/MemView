BasicUpstart2(start)
*=* "Start"


// ==========================================
// Constants
// ==========================================
// Location of screen memory
.const SCREEN_RAM = $0400

// Initial start address
.const DEFAULT_ADDRESS = $c000

.const SCREEN_WIDTH = 40
.const SCREEN_HEIGHT = 24

// Table dimensions
.const TABLE_ROWS = 21
.const TABLE_COLS = 8

// Screen offsets
.const ADDRESS_OFFSET = 1
.const ROW_START = 2

// pointer to current line in screen memory
.const CURRENT_LINE_START = $fb

// pointer to address being written
.const CURRENT_ADDRESS = $fd

// Address for the start of the status line
.const STATUS_LINE_START = SCREEN_RAM + (SCREEN_HEIGHT * SCREEN_WIDTH)

.const TITLE_TEXT = "memory viewer"
.const GOTO_TEXT = "goto:"
// ==========================================


// ==========================================
// Variables
// ==========================================
// column offsets for the bytes
BYTE_OFFSET: .byte 6, 9, 12, 15, 18, 21, 24, 27

// column offsets for the ASCII characters
ASCII_OFFSET: .byte 30, 31, 32, 33, 35, 36, 37, 38

// address at top left of screen
START_ADDRESS: .word DEFAULT_ADDRESS

TITLE:
    .text TITLE_TEXT
    .byte 0

GOTO:
    .text GOTO_TEXT
    .byte 0

// currently selected table location
SELECTED_ROW: .byte 0
SELECTED_COLUMN: .byte 0
// ==========================================


// ==========================================
// Program Entry
// ==========================================
start:
    lda #$93
    jsr $ffd2

    jsr show_title
    jsr show_status_bar

!:  jsr output_screen_data
    jsr update
    clc
    bcc !-
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

!:  rts
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
// Get and process user input
// ==========================================
update:
    // wait for key press
!:  jsr $ffe4
    beq !-

    // right arrow
    cmp #$1d
    bne !+
    lda #TABLE_COLS
    jsr increase_start_address
    rts

    // left arrow
!:  cmp #$9d
    bne !+
    lda #TABLE_COLS
    jsr decrease_start_address
    rts

    // up arrow
!:  cmp #$91
    bne !+
    lda #TABLE_COLS * TABLE_ROWS
    jsr decrease_start_address
    rts

    // down arrow
!:  cmp #$11
    bne !+
    lda #TABLE_COLS * TABLE_ROWS
    jsr increase_start_address
    rts

    // plus key
!:  cmp #'+'
    bne !+
    lda #1
    jsr increase_start_address
    rts

    // minus key
!:  cmp #'-'
    bne !+
    lda #1
    jsr decrease_start_address
    rts

    // G - goto address
!:  cmp #'G'
    bne !+
    jsr goto_address
    rts

    // S - select address
!:  cmp #'S'
    bne !+
    jsr select_address
    rts

    // Q - exit program
!:  cmp #'Q'
    bne !+
    pla
    pla
    rts

    // return to start
!:  rts
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

    // restart loop
    clc
    bcc !--

    // redraw status bar
!:  jsr show_status_bar

    rts
// ==========================================


// ==========================================
// Select and display an address
// ==========================================
select_address:
    // display current selection
    jsr toggle_selection

    // get address of selected byte
    jsr get_selected_address

    // load byte at selected address
    ldy #0
    lda (CURRENT_ADDRESS),y

    // display status bar
    jsr output_selected_address

    // get key press
!:  jsr $ffe4
    beq !-

    // up arrow
!:  cmp #$91
    bne !+
    jsr toggle_selection
    dec SELECTED_ROW
    clc
    bcc select_address

    // down arrow
!:  cmp #$11
    bne !+
    jsr toggle_selection
    inc SELECTED_ROW
    clc
    bcc select_address

    // left arrow
!:  cmp #$9d
    bne !+
    jsr toggle_selection
    dec SELECTED_COLUMN
    clc
    bcc select_address

    // right arrow
!:  cmp #$1d
    bne !+
    jsr toggle_selection
    inc SELECTED_COLUMN
    clc
    bcc select_address

!:  jsr show_status_bar

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
// Output the selected address status bar
// ------------------------------------------
// Displays CURRENT_ADDRESS and A as the byte
// ==========================================
output_selected_address:
    // save A to the stack
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

    // restore A and output
    pla
    jsr output_byte

    lda #']'+128
    sta (CURRENT_LINE_START),y
    iny

    // reset to normal characters
    lda #0
    sta CHAR_OFFSET

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
