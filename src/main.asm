#import "const.asm"
#import "variables.asm"
#import "edit.asm"
#import "convert.asm"
#import "input.asm"
#import "output.asm"
#import "goto.asm"
#import "help.asm"

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
