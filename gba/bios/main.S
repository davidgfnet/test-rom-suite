# Basic BIOS tests for GBA and ARM7TDMI

#include "macros.h"

.globl _start
_start:
  b main

  @ Nintendo Logo Character Data
  .fill   156,1,0

  @ Game Title (80000A0h)
  .byte   0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
  .byte   0x00,0x00,0x00,0x00

  @ Game Code (80000ACh)
  .byte   0x00,0x00,0x00,0x00

  @ Maker Code (80000B0h)
  .byte   0x30,0x31

  @ Fixed Value (80000B2h)
  .byte   0x96

  @ Main Unit Code (80000B3h)
  .byte   0x00

  @ Device Type (80000B4h)
  .byte   0x00

  @ Unused Data (7Byte) (80000B5h)
  .byte   0x00,0x00,0x00,0x00,0x00,0x00,0x00

  @ Software Version No (80000BCh)
  .byte   0x00

  @ Complement Check (80000BDh)
  .byte   0xf0

  @ Checksum (80000BEh)
  .byte   0x00,0x00

main:

@ Setup screen to a background mode for text writing
  mov r0, $0x4000000    @ LCD control register
  mov r1, $0x400        @ Mode 4 and BG2 enabled
  orr r1, $0x004
  strh r1, [r0]

  bl clear_screen

@ Setup palette colors
  mov r0, $0x5000000
  ldr r1, =0x6318
  mov r2, $0
  strh r1, [r0]
  strh r2, [r0, #2]

@ Print title message
  ldr r0, =title
  mov r1, $0
  bl write_text
  b gotest

.pool
.align 4

gotest:

#define test_begin(testn, testdesc, instdesc, instdesc2)  \
  mov r12, $(testn); \
  b 90f; \
  20: .ascii "> " testdesc; .byte 0; \
  30: .ascii "    " instdesc; .byte 0; \
  40: .ascii "    " instdesc2; .byte 0; \
  .pool; \
  .align 4; \
  50: \
  adr lr, 20b; \
  screen_print(lr, 45); \
  adr lr, 30b; \
  screen_print(lr, 65); \
  adr lr, 40b; \
  screen_print(lr, 75); \
  b testfail; \
  90:

#define test_check(code) \
  b##code 50b;

#define do_swi_arm(swinum) \
  swi $(swinum << 16)

#define do_swi_thumb(swinum) \
  ldr lr, =(1f + 1); \
  bx lr; \
  1: .thumb; \
  swi $(swinum); \
  adr r7, 2f; \
  bx r7; nop; \
  2: .arm

#define test_div6(mode, num, denom, res, mod, resabs) \
  mov r0, $(num); \
  mov r1, $(denom); \
  push {r0-r3}; \
  do_swi_##mode(6); \
  cmp   r0, $(res); \
  cmpeq r1, $(mod); \
  cmpeq r3, $(resabs); \
  test_check(ne)

#define test_div7(mode, num, denom, res, mod, resabs) \
  mov r1, $(num); \
  mov r0, $(denom); \
  push {r0-r3}; \
  do_swi_##mode(7); \
  cmp   r0, $(res); \
  cmpeq r1, $(mod); \
  cmpeq r3, $(resabs); \
  test_check(ne)

#define test_unary(swin, inum, res) \
  mov r0, $(inum); \
  push {r0-r3}; \
  swi $(swin << 16); \
  cmp   r0, $(res); \
  test_check(ne)


@ Now perform some tests!

  @ Test basic stuff like div and divram, these are usually HLE emulated
  test_begin(1, "swi 6 (division, arm)", "swi 0x60000", "r0=1 r1=0 r3=1")
  test_div6(arm, 0x99, 0x99, 1, 0, 1)

  test_begin(2, "swi 6 (division, arm)", "swi 0x60000", "r0=2 r1=0 r3=2")
  test_div6(arm, -80, -40, 2, 0, 2)

  test_begin(3, "swi 6 (division, arm)", "swi 0x60000", "r0=-2 r1=10 r3=2")
  test_div6(arm, 90, -40, -2, 10, 2)

  test_begin(4, "swi 6 (division, arm)", "swi 0x60000", "r0=-2 r1=-10 r3=2")
  test_div6(arm, -90, 40, -2, -10, 2)

  test_begin(5, "swi 6 (division, arm)", "swi 0x60000", "r0=2 r1=10 r3=2")
  test_div6(arm, 90, 20, 4, 10, 4)

  test_begin(6, "swi 7 (division, arm)", "swi 0x60000", "r0=1 r1=0 r3=1")
  test_div7(arm, 0x99, 0x99, 1, 0, 1)

  test_begin(7, "swi 7 (division, arm)", "swi 0x70000", "r0=2 r1=0 r3=2")
  test_div7(arm, -80, -40, 2, 0, 2)

  test_begin(8, "swi 7 (division, arm)", "swi 0x70000", "r0=-2 r1=10 r3=2")
  test_div7(arm, 90, -40, -2, 10, 2)

  test_begin(9, "swi 7 (division, arm)", "swi 0x70000", "r0=-2 r1=-10 r3=2")
  test_div7(arm, -90, 40, -2, -10, 2)

  test_begin(10, "swi 7 (division, arm)", "swi 0x70000", "r0=2 r1=10 r3=2")
  test_div7(arm, 90, 20, 4, 10, 4)

  @ thumb mode
  test_begin(11, "swi 6 (division, thumb)", "swi 0x6", "r0=1 r1=0 r3=1")
  test_div6(thumb, 0x99, 0x99, 1, 0, 1)

  test_begin(12, "swi 6 (division, thumb)", "swi 0x6", "r0=2 r1=0 r3=2")
  test_div6(thumb, -80, -40, 2, 0, 2)

  test_begin(13, "swi 6 (division, thumb)", "swi 0x6", "r0=-2 r1=10 r3=2")
  test_div6(thumb, 90, -40, -2, 10, 2)

  test_begin(14, "swi 6 (division, thumb)", "swi 0x6", "r0=-2 r1=-10 r3=2")
  test_div6(thumb, -90, 40, -2, -10, 2)

  test_begin(15, "swi 6 (division, thumb)", "swi 0x6", "r0=2 r1=10 r3=2")
  test_div6(thumb, 90, 20, 4, 10, 4)

  test_begin(16, "swi 7 (division, thumb)", "swi 0x6", "r0=1 r1=0 r3=1")
  test_div7(thumb, 0x99, 0x99, 1, 0, 1)

  test_begin(17, "swi 7 (division, thumb)", "swi 0x7", "r0=2 r1=0 r3=2")
  test_div7(thumb, -80, -40, 2, 0, 2)

  test_begin(18, "swi 7 (division, thumb)", "swi 0x7", "r0=-2 r1=10 r3=2")
  test_div7(thumb, 90, -40, -2, 10, 2)

  test_begin(19, "swi 7 (division, thumb)", "swi 0x7", "r0=-2 r1=-10 r3=2")
  test_div7(thumb, -90, 40, -2, -10, 2)

  test_begin(20, "swi 7 (division, thumb)", "swi 0x7", "r0=2 r1=10 r3=2")
  test_div7(thumb, 90, 20, 4, 10, 4)


  @ Test some math stuff too
  test_begin(21, "swi 8 (sqrt)", "swi 0x80000", "cmp r0, $16")
  test_unary(8, 256, 16)

  test_begin(22, "swi 8 (sqrt)", "swi 0x80000", "cmp r0, $15")
  test_unary(8, 255, 15)

  test_begin(23, "swi 8 (sqrt)", "swi 0x80000", "cmp r0, $0")
  test_unary(8, 0, 0)

  test_begin(24, "swi 8 (sqrt)", "swi 0x80000", "cmp r0, $1")
  test_unary(8, 1, 1)


  progress_bar(30)
  screen_print_N(passmsg,   45, r0)

@ Test pass!
  mov r0, $0x5000000
  ldr r1, =0x5F73
  strh r1, [r0]

1:
  nop; nop; nop; nop; nop; nop;
  nop; nop; nop; nop; nop; nop;
  b 1b

testfail:
  pop {r4-r7}
  screen_print_N(testnstr,   35, r12)
  screen_print_N(info,      100, r0)
  screen_print_N(r0_text,   115, r0, r4)
  screen_print_N(r1_text,   125, r1, r5)
  screen_print_N(r2_text,   135, r2, r6)
  screen_print_N(r3_text,   145, r3, r7)

  mov r0, $0x5000000
  ldr r1, =0x4F1B
  strh r1, [r0]


1:
  nop; nop; nop; nop; nop; nop;
  nop; nop; nop; nop; nop; nop;
  b 1b

title:
  .asciz "       GBA BIOS testrom\n         by davidgf.net"

passmsg:
  .asciz "tests passed!"
testnstr:
  .asciz "test #%d"
info:
  .asciz "    result           call "
r0_text:
  .asciz " r0 0x%x  r0 0x%x"
r1_text:
  .asciz " r1 0x%x  r1 0x%x"
r2_text:
  .asciz " r2 0x%x  r2 0x%x"
r3_text:
  .asciz " r3 0x%x  r3 0x%x"

#include "text.h"



