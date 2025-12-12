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
