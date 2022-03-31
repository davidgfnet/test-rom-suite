# GBA minimal input latency test ROM

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

  @ Set video mode
  mov r0, $0x4000000    @ LCD control register
  mov r1, $0x400        @ Mode 4 and BG2 enabled
  orr r1, $0x004
  str r1, [r0]

  @ Clear screen
  mov r0, $0x6000000    @ Vram base, our frame buffer
  mov r1, $38400        @ 240x160 bytes to update
  mov r2, $0x80
copyloop:
  strh r2, [r0]
  add r0, $2
  adds r1, $-2
  bne copyloop

  mov r8, $0            @ assume no key pressed?
  mov r9, $0x55         @ some magenta color
  orr r9, $0x5500

loop:
  @ Wait for Vblank
  mov r4, $0x4000000
  orr r4, $0x6
  ldrh r5, [r4]
  subs r5, $160
  bne loop

  @ Read input keys
  mov r4, $0x4000000
  orr r4, $0x0130
  ldr r5, [r4]          @ Load the key value
  subs r5, r8           @ Compare to previous value
  ldr r8, [r4]
  beq skip
  mvn r0, $0
  eor r9, r0

  skip:

  mov r0, $0x5000000    @ Palette addr
  mov r1, $512

  ploop:
    strh r9, [r0]
    add r0, $2
    adds r1, $-2
    bne ploop

  b loop

