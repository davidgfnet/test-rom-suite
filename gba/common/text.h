
hexnum:
  .ascii "0123456789ABCDEF"

.align 4

@ r0 buffer
@ r1 integer
int2hex:
  push {r0-r4, lr}
  adr r3, hexnum

  mov r2, $0
  add r0, r0, #8
  strb r2, [r0], #-1
  mov r4, $8

1:
  and r2, r1, $0xf
  ldrb r2, [r2, r3]
  strb r2, [r0], #-1
  lsr r1, r1, $4
  subs r4, r4, $1
  bne 1b

  pop {r0-r4, pc}

@ r0 buffer
@ r1 integer
int2dec:
  push {r1-r5, lr}
  ldr r4, =0xcccccccd
  mov r5, r0

1:
  umull	r3, r2, r4, r1
  lsrs r2, r2, #3          @ Div result in r2
  add r3, r2, r2, lsl #2
  sub r3, r1, r3, lsl #1   @ Mod in r3
  mov r1, r2

  add r3, r3, $'0'
  strb r3, [r5], #1
  bne 1b

  sub r3, r5, r0           @ Number of written digits
  mov r1, $0
  strb r1, [r5], #-1

2:
  ldrb r1, [r0]
  ldrb r2, [r5]
  strb r1, [r5], #-1
  strb r2, [r0], # 1
  cmp r0, r5
  blo 2b

  mov r0, r3
  pop {r1-r5, pc}

@ r0 buffer
@ r1 format
@ other args in stack
printfn:
  push {r0-r4, lr}

  add r2, sp, $24
  mov r3, r0  @ out buffer
  mov r4, r1  @ fmt

1:
  ldrb r0, [r4], #1
  cmp r0, $0
  beq 9f
  cmp r0, $'%'

  strneb r0, [r3], #1
  bne 1b

  ldrb r0, [r4], #1
  cmp r0, $'x'
  beq 4f
  cmp r0, $'d'
  beq 5f
  b 1b

4:
  mov r0, r3
  ldr r1, [r2], #4
  bl int2hex
  add r3, r3, $8
  b 1b

5:
  cmp r0, $'d'
  mov r0, r3
  ldr r1, [r2], #4
  bl int2dec
  add r3, r3, r0
  b 1b

9:
  strb r0, [r3]
  pop {r0-r4, pc}

@ r1 line
clear_row:
  push {r0-r2, lr}
  mov r0, $0x6000000
  mov r2, $240
  mla r0, r1, r2, r0
  mov r2, $(240)
  mov r1, $0
  1: str r1, [r0], #4
     str r1, [r0], #4
     subs r2, r2, $1
     bne 1b
  pop {r0-r2, pc}

@ r0 pointer to ascii text
@ r1 line
write_text:
  push {r0-r3, lr}
  
  bl clear_row

  mov r3, r0
  mov r2, r1
  mov r1, $0
1:
  ldrb r0, [r3], #1
  cmp r0, $0
  beq 2f
  cmp r0, $'\n'
  moveq r1, $(-8)
  addeq r2, r2, $8
  beq 1b

  bl draw_char
  add r1, r1, $8
  b 1b

2:
  pop {r0-r3, pc}

@ r0 contains character
@ r1 contains x coord
@ r2 contains y coord
draw_char:
  push {r0-r7, lr}
  mov r6, $0x6000000
  mov r5, $240
  mla r6, r5, r2, r6    @ Calculate Y offset
  add r6, r1
  adr r7, textchars
  sub r0, r0, $32
  add r7, r0, lsl #3

  mov r2, $8
1:
  ldrb r3, [r7], #1     @ Each byte is a line
  mov r0, $4

  2:
    and r1, r3, $1      @ Two pixels at a time
    and r4, r3, $2      @ since VRAM must be accessed
    lsr r3, r3, $2      @ at 16 or 32 bit granularity
    orr r1, r4, lsl #7
    strh r1, [r6], #2
    subs r0, $1
    bne 2b

  add r6, r6, $(240-8)  @ Advance to next line
  subs r2, $1
  bne 1b

  pop {r0-r7, pc}

clear_screen:
  mov r0, $0x6000000    @ Vram base, our frame buffer
  mov r1, $38400        @ 240x160 bytes to update
  mov r2, $0x00
1:
  strh r2, [r0]
  add r0, $2
  adds r1, $-2
  bne 1b
  bx lr

.align 4
textchars:
 @ Extracted from tonclib
 .long 0x00000000,0x00000000,0x18181818,0x00180018,0x00003636,0x00000000,0x367F3636,0x0036367F
 .long 0x3C067C18,0x00183E60,0x1B356600,0x0033566C,0x6E16361C,0x00DE733B,0x000C1818,0x00000000
 .long 0x0C0C1830,0x0030180C,0x3030180C,0x000C1830,0xFF3C6600,0x0000663C,0x7E181800,0x00001818
 .long 0x00000000,0x0C181800,0x7E000000,0x00000000,0x00000000,0x00181800,0x183060C0,0x0003060C
 .long 0x7E76663C,0x003C666E,0x181E1C18,0x00181818,0x3060663C,0x007E0C18,0x3860663C,0x003C6660
 .long 0x33363C38,0x0030307F,0x603E067E,0x003C6660,0x3E060C38,0x003C6666,0x3060607E,0x00181818
 .long 0x3C66663C,0x003C6666,0x7C66663C,0x001C3060,0x00181800,0x00181800,0x00181800,0x0C181800
 .long 0x06186000,0x00006018,0x007E0000,0x0000007E,0x60180600,0x00000618,0x3060663C,0x00180018
 .long 0x5A5A663C,0x003C067A,0x7E66663C,0x00666666,0x3E66663E,0x003E6666,0x06060C78,0x00780C06
 .long 0x6666361E,0x001E3666,0x1E06067E,0x007E0606,0x1E06067E,0x00060606,0x7606663C,0x007C6666
 .long 0x7E666666,0x00666666,0x1818183C,0x003C1818,0x60606060,0x003C6660,0x0F1B3363,0x0063331B
 .long 0x06060606,0x007E0606,0x6B7F7763,0x00636363,0x7B6F6763,0x00636373,0x6666663C,0x003C6666
 .long 0x3E66663E,0x00060606,0x3333331E,0x007E3B33,0x3E66663E,0x00666636,0x3C0E663C,0x003C6670
 .long 0x1818187E,0x00181818,0x66666666,0x003C6666,0x66666666,0x00183C3C,0x6B636363,0x0063777F
 .long 0x183C66C3,0x00C3663C,0x183C66C3,0x00181818,0x0C18307F,0x007F0306,0x0C0C0C3C,0x003C0C0C
 .long 0x180C0603,0x00C06030,0x3030303C,0x003C3030,0x00663C18,0x00000000,0x00000000,0x003F0000
 .long 0x00301818,0x00000000,0x603C0000,0x007C667C,0x663E0606,0x003E6666,0x063C0000,0x003C0606
 .long 0x667C6060,0x007C6666,0x663C0000,0x003C067E,0x0C3E0C38,0x000C0C0C,0x667C0000,0x3C607C66
 .long 0x663E0606,0x00666666,0x18180018,0x00301818,0x30300030,0x1E303030,0x36660606,0x0066361E
 .long 0x18181818,0x00301818,0x7F370000,0x0063636B,0x663E0000,0x00666666,0x663C0000,0x003C6666
 .long 0x663E0000,0x06063E66,0x667C0000,0x60607C66,0x663E0000,0x00060606,0x063C0000,0x003E603C
 .long 0x0C3E0C0C,0x00380C0C,0x66660000,0x007C6666,0x66660000,0x00183C66,0x63630000,0x00367F6B
 .long 0x36630000,0x0063361C,0x66660000,0x0C183C66,0x307E0000,0x007E0C18,0x0C181830,0x00301818
 .long 0x18181818,0x00181818,0x3018180C,0x000C1818,0x003B6E00,0x00000000,0xFFFFFFFF,0xFFFFFFFF


