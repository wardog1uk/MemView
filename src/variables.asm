*=* "Variables"
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

CREDIT:
    .text CREDIT_TEXT
    .byte 0

GOTO:
    .text GOTO_TEXT
    .byte 0

HELP:
    .text HELP_TEXT
    .byte 0

// currently selected table location
SELECTED_ROW: .byte 0
SELECTED_COLUMN: .byte 0

// Table of valid keys
input_keys: .byte ARROW_RIGHT, ARROW_LEFT, ARROW_UP, ARROW_DOWN, '+', '-', 'G', 'E', F1, F3, 'Q', $0

// Addresses of routines for each key
actions_low:  .byte <arrow_right, <arrow_left, <arrow_up, <arrow_down, <plus_key, <minus_key
              .byte <goto_address, <edit_byte, <show_help, <toggle_loram, <exit_program
actions_high: .byte >arrow_right, >arrow_left, >arrow_up, >arrow_down, >plus_key, >minus_key
              .byte >goto_address, >edit_byte, >show_help, >toggle_loram, >exit_program

// ==========================================
