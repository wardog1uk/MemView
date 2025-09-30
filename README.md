# MemView

A hexadecimal memory viewer for the Commodore 64, written in 6502 assembly language.

## Overview

MemView is a utility that allows you to browse and examine the contents of your Commodore 64's memory in real-time. It displays memory contents in both hexadecimal and ASCII format, making it useful for debugging, reverse engineering, and understanding how programs use memory.

## Features

- **Hexadecimal Display**: View memory contents as hex bytes in an organized 8-column layout
- **ASCII Representation**: See the ASCII interpretation of memory bytes alongside hex values
- **Navigation Controls**: 
  - Arrow keys for moving through memory pages
  - Plus/minus keys for fine-grained navigation
  - 'G' command for jumping to specific addresses
- **Real-time Viewing**: Memory contents update dynamically
- **Clean Interface**: Simple, efficient display optimized for the C64's 40x25 screen

## Controls

| Key | Action |
|-----|--------|
| ← → | Navigate left/right by 8 bytes |
| ↑ ↓ | Navigate up/down by one screen |
| + - | Move forwards/backwards by 1 byte |
| G | Go to address (prompts for input) |
| Q | Quit program |

## Technical Details

- **Language**: 6502 Assembly (KickAssembler syntax)
- **Target**: Commodore 64
- **Memory Usage**: Minimal footprint, uses zero page locations $FB-$FE
- **Screen Mode**: Standard text mode (40x25 characters)
