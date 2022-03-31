# Memory tests for GBA and ARM7TDMI

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
@ Reserve some space for variables
  sub sp, sp, $128

@ Fill EWRAM
  bl init_random
  ldr r5, =0x02000000
  add r6, r5, $0x40000
1:
  bl genrnd
  str r0, [r5], #4
  cmp r5, r6
  bne 1b

@ Fill IWRAM
  ldr r5, =0x03000000
  add r6, r5, $0x8000
1:
  bl genrnd
  str r0, [r5], #4
  cmp r5, r6
  bne 1b

@ Prepare memory regions with some interesting data

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
  screen_print(lr, 70); \
  adr lr, 40b; \
  screen_print(lr, 80); \
  b testfail; \
  90:

#define test_check(code) \
  b##code 50b;


mov r0, $0x03000000
ldr r1, =0x01234567
ldr r2, =0x8899aabb
str r1, [r0], #4; str r2, [r0], #4; str r1, [r0], #4; str r2, [r0], #4

mov r0, $0x02000000
ldr r1, =0x89abcdef
ldr r2, =0xccddeeff
str r1, [r0], #4; str r2, [r0], #4; str r1, [r0], #4; str r2, [r0], #4

ldr r0, =0xa0b1c2d3
ldr r1, =0x05000200
str r0, [r1], #4; str r0, [r1], #4; str r0, [r1], #4; str r0, [r1], #4

ldr r0, =0x4a5b6c7d
ldr r1, =0x07000200
str r0, [r1], #4; str r0, [r1], #4; str r0, [r1], #4; str r0, [r1], #4

ldr r0, =0x11223344
ldr r1, =0x06008f00
str r0, [r1], #4; str r0, [r1], #4; str r0, [r1], #4; str r0, [r1], #4


@ Now perform some tests!

  @ Validate reads, particulary alignment
  test_begin(1, "32b aligned read IWRAM", "ldr r1, [r0]", "cmp r1, r2")
  mov r0, $0x03000000
  ldr r2, =0x01234567
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(2, "32b misaligned read IWRAM", "ldr r1, [r0, #1]", "cmp r1, r2")
  ldr r0, =0x03000000
  ldr r2, =0x67012345
  ldr r1, [r0, #1]
  cmp r2, r1
  test_check(ne)

  test_begin(3, "32b misaligned read IWRAM", "ldr r1, [r0, #2]", "cmp r1, r2")
  ldr r0, =0x03000000
  ldr r2, =0x45670123
  ldr r1, [r0, #2]
  cmp r2, r1
  test_check(ne)

  test_begin(4, "32b misaligned read IWRAM", "ldr r1, [r0, #3]", "cmp r1, r2")
  ldr r0, =0x03000000
  ldr r2, =0x23456701
  ldr r1, [r0, #3]
  cmp r2, r1
  test_check(ne)

  test_begin(5, "16b aligned read IWRAM", "ldrh r1, [r0]", "cmp r1, r2")
  ldr r0, =0x03000000
  ldr r2, =0x4567
  ldrh r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(6, "16b misaligned read IWRAM", "ldrh r1, [r0, #1]", "cmp r1, r2")
  ldr r0, =0x03000000
  ldr r2, =0x67000045
  ldrh r1, [r0, #1]
  cmp r2, r1
  test_check(ne)

  test_begin(7, "s16b misaligned read IWRAM", "ldrsh r1, [r0, #1]", "cmp r1, r2")
  ldr r0, =0x03000000
  ldr r2, =0x00000045
  ldrsh r1, [r0, #1]
  cmp r2, r1
  test_check(ne)

  test_begin(8, "s16 aligned read EWRAM", "ldrsh r1, [r0]", "cmp r1, r2")
  ldr r0, =0x02000000
  ldr r2, =0xffffcdef
  ldrsh r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(9, "s16 misaligned read EWRAM", "ldrsh r1, [r0, #1]", "cmp r1, r2")
  ldr r0, =0x02000000
  ldr r2, =0xffffffcd
  ldrsh r1, [r0, #1]
  cmp r2, r1
  test_check(ne)

  test_begin(10, "8b read IWRAM", "ldrb r1, [r0]", "cmp r1, r2")
  ldr r0, =0x03000000
  ldr r2, =0x67
  ldrb r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(11, "8b read IWRAM", "ldrb r1, [r0, #1]", "cmp r1, r2")
  ldr r0, =0x03000000
  ldr r2, =0x00000045
  ldrb r1, [r0, #1]
  cmp r2, r1
  test_check(ne)

  test_begin(12, "LDMIA read IWRAM", "ldm r0, {r4-r7}", "r2=r4=r6  r3=r5=r7")
  mov r0, $0x03000000
  ldm r0, {r4-r7}
  ldr r2, =0x01234567
  ldr r3, =0x8899aabb
  cmp r2, r4; test_check(ne)
  cmp r2, r6; test_check(ne)
  cmp r3, r5; test_check(ne)
  cmp r3, r7; test_check(ne)

  test_begin(13, "LDMIA read EWRAM", "ldm r0, {r4-r7}", "r2=r4=r6  r3=r5=r7")
  mov r0, $0x02000000
  ldm r0, {r4-r7}
  ldr r2, =0x89abcdef
  ldr r3, =0xccddeeff
  cmp r2, r4; test_check(ne)
  cmp r2, r6; test_check(ne)
  cmp r3, r5; test_check(ne)
  cmp r3, r7; test_check(ne)

  @ Memory mirrors
  test_begin(14, "IWRAM mirror #1", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x03008000
  ldr r2, =0x01234567
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(15, "IWRAM mirror #2", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x03010000
  ldr r2, =0x01234567
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(16, "IWRAM mirror end", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x03FF8000
  ldr r2, =0x01234567
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(17, "EWRAM mirror #1", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x02040000
  ldr r2, =0x89abcdef
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(18, "EWRAM mirror #2", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x02080000
  ldr r2, =0x89abcdef
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(19, "Palette mirror #1", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x05000200
  ldr r2, =0xa0b1c2d3
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(20, "Palette mirror #2", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x05000600
  ldr r2, =0xa0b1c2d3
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(21, "Palette mirror end", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x05fffe00
  ldr r2, =0xa0b1c2d3
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(22, "OAM mirror #1", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x07000200
  ldr r2, =0x4a5b6c7d
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(23, "OAM mirror #2", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x07000600
  ldr r2, =0x4a5b6c7d
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(24, "OAM mirror end", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x07fffe00
  ldr r2, =0x4a5b6c7d
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(25, "VRAM mirror #1", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x06008f00
  ldr r2, =0x11223344
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(26, "VRAM mirror #2", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x06028f00
  ldr r2, =0x11223344
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(27, "VRAM mirror end", "ldr r1, [r0]", "cmp r1, r2")
  ldr r0, =0x06fe8f00
  ldr r2, =0x11223344
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  @ Validate unaligned writes
  test_begin(28, "32b unaligned write IWRAM", "str r2, [r0, #2]", "ldr r1, [r0]")
  mov r0, $0x03000000
  ldr r2, =0x9a8b7c6d
  str r2, [r0, #2]
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(29, "32b unaligned write EWRAM", "str r2, [r0, #2]", "ldr r1, [r0]")
  mov r0, $0x02000000
  ldr r2, =0x40516273
  str r2, [r0, #2]
  ldr r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(30, "16b unaligned write IWRAM", "strh r2, [r0, #1]", "ldrh r1, [r0]")
  mov r0, $0x03000000
  ldr r2, =0x1234
  strh r2, [r0, #1]
  ldrh r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(31, "16b unaligned write EWRAM", "strh r2, [r0, #1]", "ldrh r1, [r0]")
  mov r0, $0x02000000
  ldr r2, =0x9abc
  strh r2, [r0, #1]
  ldrh r1, [r0]
  cmp r2, r1
  test_check(ne)

  test_begin(32, "8b write to palette RAM", "strb r2, [r0, #1]", "ldrh r1, [r0]")
  ldr r0, =0x05000200
  mov r2, $0x55
  strb r2, [r0, #0]
  ldrh r1, [r0]
  orr r3, r2, r2, lsl #8
  cmp r3, r1
  test_check(ne)


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
  screen_print_N(testnstr,   35, r12)
  screen_print_N(r0_text,   100, r0, r4)
  screen_print_N(r1_text,   110, r1, r5)
  screen_print_N(r2_text,   120, r2, r6)
  screen_print_N(r3_text,   130, r3, r7)

  mov r0, $0x5000000
  ldr r1, =0x4F1B
  strh r1, [r0]


1:
  nop; nop; nop; nop; nop; nop;
  nop; nop; nop; nop; nop; nop;
  b 1b


init_random:
  ldr r0, =0x03007F00
  mov r1, $0
  str r1, [r0]
  bx lr

genrnd:
  ldr r4, =0x03007F00
  ldr r1, [r4]
  ldr r2, =1103515245
  ldr r3, =12345
  mla r0, r1, r2, r3
  bic r1, r0, $0x80000000
  str r1, [r4]
  bx lr

title:
  .asciz "      GBA memory testrom\n         by davidgf.net"

passmsg:
  .asciz "tests passed!"
testnstr:
  .asciz "test #%d"
r0_text:
  .asciz " r0 0x%x  r4 0x%x"
r1_text:
  .asciz " r1 0x%x  r5 0x%x"
r2_text:
  .asciz " r2 0x%x  r6 0x%x"
r3_text:
  .asciz " r3 0x%x  r7 0x%x"

#include "text.h"



