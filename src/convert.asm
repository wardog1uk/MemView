*=* "Convert"
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
