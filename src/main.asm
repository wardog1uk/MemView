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

// Table dimensions
.const TABLE_ROWS = 22
.const TABLE_COLS = 8

// Screen offsets
.const TITLE_OFFSET = 13
.const ADDRESS_OFFSET = 1
.const ROW_START = 2

// pointer to current line in screen memory
.const CURRENT_LINE_START = $fb

// pointer to address being written
.const CURRENT_ADDRESS = $fd
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
// ==========================================


// ==========================================
// Program Entry
// ==========================================
start:
    lda #$93
    jsr $ffd2

    jsr show_title

!:  jsr outputScreenData
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
// Write the data to the screen
// ==========================================
outputScreenData:
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
!:  jsr outputLine
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
    lda #1
    jsr increase_start_address
    rts

    // left arrow
!:  cmp #$9d
    bne !+
    lda #1
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

    // exit program
!:  pla
    pla
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
// Output the current line of data
// ==========================================
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
// ==========================================


// ==========================================
// Output the current address
// ==========================================
outputAddress:
    ldy #ADDRESS_OFFSET

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
