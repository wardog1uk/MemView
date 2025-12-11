*=* "Input"
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
