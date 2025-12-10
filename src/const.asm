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
.const CURRENT_LINE_START = $d1 // PNT

// pointer to address being written
.const CURRENT_ADDRESS = $c9    // LXSP

// pointer for general use
.const TEMP_POINTER = $fb

// Address for the start of the status line
.const STATUS_LINE_START = SCREEN_RAM + (SCREEN_HEIGHT * SCREEN_WIDTH)

.const TITLE_TEXT = "memory viewer"
.const CREDIT_TEXT = "by jonathan mathews 2025"
.const GOTO_TEXT = "goto:"
.const HELP_TEXT = "arrows+- to move, (g)o, (e)dit, (q)uit "

// Keyboard codes
.const ARROW_UP = $91
.const ARROW_DOWN = $11
.const ARROW_RIGHT = $1d
.const ARROW_LEFT = $9d
.const F1 = $85
.const F3 = $86
.const RETURN = $0d
// ==========================================
