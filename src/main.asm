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
.const TITLE_OFFSET = 13
.const ADDRESS_OFFSET = 1
.const ROW_START = 2

// pointer to current line in screen memory
.const CURRENT_LINE_START = $fb

// pointer to address being written
.const CURRENT_ADDRESS = $fd

// Address for the start of the status line
.const STATUS_LINE_START = SCREEN_RAM + (SCREEN_HEIGHT * SCREEN_WIDTH)
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
    .text "memory viewer"
    .byte 0

GOTO:
    .text "goto:"
    .byte 0
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

    lda #' '+128
    ldy #SCREEN_WIDTH
!:  dey
    sta (CURRENT_LINE_START),y
    bne !-

    ldy #TITLE_OFFSET
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
!:  cmp #$2b
    bne !+
    lda #1
    jsr increase_start_address
    rts

    // minus key
!:  cmp #$2d
    bne !+
    lda #1
    jsr decrease_start_address
    rts

    // G - goto address
!:  cmp #$47
    bne !+
    jsr goto_address
    rts

    // Q - exit program
!:  cmp #$51
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

    ldy #15
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
!:  lda START_ADDRESS
    sta CURRENT_ADDRESS
    lda START_ADDRESS+1
    sta CURRENT_ADDRESS+1

    ldy #20
    jsr output_address

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
// Output the current line of data
// ==========================================
output_line:
    // save X to the stack
    txa
    pha

    ldy #ADDRESS_OFFSET
    jsr output_address

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
// Output the current address at position Y
// ==========================================
output_address:
    lda CURRENT_ADDRESS+1
    jsr output_byte

    lda CURRENT_ADDRESS
    jsr output_byte

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

!:  rts
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

    sec
    cmp #10
    bcs !++     // good if 9-15

    // bad - set negative flag
!:  lda #$ff
    rts

    // good - clear negative flag
!:  ldx #0
    rts
// ==========================================
