*=* "Help"
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
