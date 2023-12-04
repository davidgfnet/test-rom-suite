# LDM/STM tests for GBA and ARM7TDMI

.set printbuf, 0x03002EC0

#define IWRAM_CODE_AREA 0x03004000

.global stm_test_inst
.global stm_test_fixture

#define word_copy_thumb(source, destination)\
  ldr r0, =(source);                        \
  ldr r1, =(##source##_end);                \
  ldr r2, =destination;                     \
  bl wordcpy_thumb;

#define word_copy(source, destination)      \
  ldr r0, =(source);                        \
  ldr r1, =(##source##_end);                \
  ldr r2, =destination;                     \
  bl wordcpy;

#define word_copy_fast64(source, destination)            \
  ldr r0, =(source);                                     \
  ldr r1, =(##source##_end);                             \
  ldr r2, =destination;                                  \
  ldr r3, =(IWRAM_CODE_AREA);                            \
  mov lr, pc;                                            \
  bx r3;

.arm

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

@ Copy work-intensive routines to IWRAM:
  ldr r0, =util_iwram
  ldr r1, =util_iwram_end
  ldr r2, =IWRAM_CODE_AREA
  1:
    ldr r3, [r0], #4
    str r3, [r2], #4
    cmp r0, r1
    bne 1b

@ Now perform some tests!

  sub sp, sp, $32    @ reserve some useful stack space

@ Thumb mode tests

  @ Test Thumb LDR
  screen_print_N(test_ldm_thb,  40, r2)
  ldr r0, =thumb_ld_tests
  mov lr, pc
  bx r0
  
@ ARM mode tests

  @ LDM tests
  screen_print_N(test_ldm_arm,  40, r2)

  @ Setup the LDM test memory space.
  @ Each test has a different reglist, we test all 15 base regs, 8 modes = 120
  @ For each test we store 60 bytes (register values). Total 120*60 = 7200 bytes
  @ 0x03000000 - 0x03002000    // Reference data area.  8KB
  @ 0x03002000 - 0x03002800    // Load area for LDM (read only). 2KB (128 bytes * 16 regs)
  @ 0x03002800 - 0x03002A00    // Instruction storage area (512b)
  @ 0x03002A00 - 0x03002E80    // Code area (1.1KB)
  @ 0x03002E80 - 0x03003000    // Scratch area, temp store. 256 bytes

  @ r4 points to the saved data pointer base
  @ r5 used for base reg
  @ r6 contains the reglist

  #define REF_AREA     0x03000000
  #define REF_AREA_2   0x03001000
  #define LDM_AREA     0x03002000
  #define INST_AREA    0x03002800
  #define CODE_AREA    0x03002A00
  #define SAVED_DATA   0x03002E80
  #define SAVED_SP     0x0
  #define REGLIST      0x4
  #define ITERATION    0x8
  #define REG_DUMPPTR  0xC
  #define REG_ERR      0x10
  #define REG_MEM_OFF  0x14
  #define REG_MEM_V1   0x18
  #define REG_MEM_V2   0x1C

  ldr r4, =SAVED_DATA
  str sp, [r4, #SAVED_SP]

  ldr r6, =0x7fff
  str r6, [r4, #REGLIST]

  word_copy(ldm_test_fixture, CODE_AREA);   @ Copy testing fixture into IWRAM for speed.
  word_copy(ldm_table, LDM_AREA);           @ Copy LDM_AREA data with randomly pre-generated data

1:
  @ Fill the reference area, it is udpated by the emulation routines
  ldr r0, =(LDM_AREA)
  ldr r1, =(REF_AREA)
  bl fill_playg

  @ Fill the reference data, go through all base regs (r0..r14)
  mov r5, #0  @ basereg
  ldr r7, =INST_AREA
  2:
    @ r2 points to buffer[(basereg * 64 + 32) * 4]
    #define call_ref(n, fnname)           \
      mov r0, r5;  /* base reg */      \
      mov r1, r6;  /* reglist */       \
      ldr r2, =(REF_AREA + 64*n);      \
      add r2, r2, r5, lsl #9;          \
      ldr lr, =ldm_emu_tbl;            \
      ldr r3, [lr, #(n * 4)];          \
      mov lr, pc;                      \
      bx r3;                           \
      str r0, [r7], #4;

    call_ref(0, emulate_ldm_pre_up_nwb)
    call_ref(1, emulate_ldm_pre_up_wb)
    call_ref(2, emulate_ldm_pre_down_nwb)
    call_ref(3, emulate_ldm_pre_down_wb)
    call_ref(4, emulate_ldm_post_up_nwb)
    call_ref(5, emulate_ldm_post_up_wb)
    call_ref(6, emulate_ldm_post_down_nwb)
    call_ref(7, emulate_ldm_post_down_wb)

    add r5, r5, #1
    cmp r5, #15
    bne 2b

  str r4, [sp, #4]       @ Save some regs
  str r6, [sp, #8]

  @ Jump to code execution! SP is preserved across the call
  mov r0, $0
  str r0, [r4, #ITERATION]

  str pc, [sp]           @ Return addr, PC + 8
  ldr r0, =CODE_AREA
  bx r0

  ldr r4, [sp, #4]       @ Restore regs
  ldr r6, [sp, #8]

  @ Check result
  tst r0, r0
  bpl testfail_ldm

  @ Update progress bar whenever the last 8 bits are zero
  tst r6, $0xFF
  bne 10f
    mov r2, $4
    mul r1, r6, r2
    mov r1, r1, lsr #15
    rsb r1, r1, $4
    progress_bar_r1()
  10:

  subs r6, r6, #1
  str r6, [r4, #REGLIST]
  bne 1b


  @ STM tests
  screen_print_N(test_stm_arm,  40, r2)

  @ Setup the STM test memory space.
  @ Each test has a different reglist, we test all 15 base regs, 8 modes = 120
  @ Each test ends up writing in a 2KB memory region and also updates the reglist
  @ This "state" is preserved across reference and actual STM to compare and validate
  @ 0x03000000 - 0x03000840    // Reference data area.  2KB + 64B
  @ 0x03001000 - 0x03001840    // Store area for STM.   2KB + 64B (128 bytes * 16 regs)
  @ 0x03002A00 - 0x03002E80    // Code area (1.1KB)
  @ 0x03002E80 - 0x03003000    // Scratch area, temp store. 128 bytes

  @ r4 points to the saved data pointer base
  @ r5 used for base reg
  @ r6 contains the reglist

  #define REF_AREA_R   0x03000800
  #define STM_AREA     0x03001000
  #define STM_A_REGS   0x03001800
  #define STM_AREA_end 0x03001840

  ldr r4, =SAVED_DATA
  str sp, [r4, #SAVED_SP]

  ldr r6, =0x7fff
  str r6, [r4, #REGLIST]

  word_copy(stm_test_fixture, CODE_AREA);   @ Copy testing fixture into IWRAM for speed.

  @ r4 points to the saved data pointer base
  @ r5 used for (base reg || mode), that is, 4 and 3 bits
  @ r6 contains the reglist

1:

  @ Loop for every base reg and every mode (15*8 = 120)
  @ Run the emulation code
  mov r5, $0
  2:
    @ Copy STM_AREA data with randomly pre-generated data
    word_copy_fast64(stm_table, STM_AREA);

    @ Fill the register area. These are all pointers to STM_AREA (where random data lives)
    ldr r0, =STM_AREA
    ldr r1, =STM_A_REGS
    bl fill_playg_1

    @ Run the corresponding emulation routine
    ldr r0, =stm_emu_tbl
    and r1, r5, $0x7         @ take lower 3 bits for mode
    ldr r3, [r0, r1, lsl #2] @ fn ptr

    lsr r0, r5, #3           @ base reg
    mov r1, r6;              @ reglist
    ldr r2, =STM_A_REGS
    mov lr, pc
    bx r3

    @ Patch stm instruction in the code area routine (ret val)
    ldr r1, =CODE_AREA
    str r0, [r1, #(stm_test_inst - stm_test_fixture)]

    word_copy_fast64(STM_AREA, REF_AREA);   @ Copy the result to the ref area for later check

    @ Re-init the areas again, for the new execution
    word_copy_fast64(stm_table, STM_AREA);  @ TODO: do this in the Code Area for speed?

    ldr r0, =STM_AREA
    ldr r1, =STM_A_REGS
    bl fill_playg_1

    str r4, [sp, #4]       @ save regs before call
    str r5, [sp, #8]
    str r6, [sp, #12]

    str pc, [sp]           @ Return addr, PC + 8
    ldr r0, =CODE_AREA
    bx r0

    ldr r4, [sp, #4]       @ restore regs
    ldr r5, [sp, #8]
    ldr r6, [sp, #12]

    cmp r0, $0             @ Check for reg mismatch
    beq testfail_stm_reg
    cmp r0, $1             @ Check for mem mismatch
    beq testfail_stm_mem

    add r5, r5, $1
    cmp r5, $120
    bne 2b

  @ Progress display
  tst r6, $0xFF
  bne 10f
    mov r2, $26
    mul r1, r6, r2
    mov r1, r1, lsr #15
    rsb r1, r1, $26
    add r1, r1, $4
    progress_bar_r1()
  10:

  subs r6, r6, #1
  bne 1b

  screen_print_N(passmsg,   40, r0)

@ Test pass!
  mov r0, $0x5000000
  ldr r1, =0x5F73
  strh r1, [r0]

1:
  nop; nop; nop; nop; nop; nop;
  nop; nop; nop; nop; nop; nop;
  b 1b

ldm_emu_tbl:
  .word emulate_ldm_pre_up_nwb
  .word emulate_ldm_pre_up_wb
  .word emulate_ldm_pre_down_nwb
  .word emulate_ldm_pre_down_wb
  .word emulate_ldm_post_up_nwb
  .word emulate_ldm_post_up_wb
  .word emulate_ldm_post_down_nwb
  .word emulate_ldm_post_down_wb

stm_emu_tbl:
  .word emulate_stm_pre_up_nwb
  .word emulate_stm_pre_up_wb
  .word emulate_stm_pre_down_nwb
  .word emulate_stm_pre_down_wb
  .word emulate_stm_post_up_nwb
  .word emulate_stm_post_up_wb
  .word emulate_stm_post_down_nwb
  .word emulate_stm_post_down_wb

.pool

@ r0: ptr source
@ r1: ptr source end
@ r2: ptr dest
wordcpy:
  ldr r3, [r0], #4
  str r3, [r2], #4
  cmp r0, r1
  bne wordcpy
  bx lr


util_iwram:

@ Copies in blocks of 64 bytes (len must be divisible by 64)
@ Assumes LDMIA works well (only used for STM testing)
@ r0: ptr source
@ r1: ptr source end
@ r2: ptr dest
wordcpy64:
  push {r4-r11}
1:
  ldmia r0!, {r4-r11}

  str r4, [r2], #4
  str r5, [r2], #4
  str r6, [r2], #4
  str r7, [r2], #4
  str r8, [r2], #4
  str r9, [r2], #4
  str r10, [r2], #4
  str r11, [r2], #4

  ldmia r0!, {r4-r11}

  str r4, [r2], #4
  str r5, [r2], #4
  str r6, [r2], #4
  str r7, [r2], #4
  str r8, [r2], #4
  str r9, [r2], #4
  str r10, [r2], #4
  str r11, [r2], #4

  cmp r0, r1
  bne 1b
  pop {r4-r11}
  bx lr

util_iwram_end:

@ r0: pointer base to use
@ r1: table pointer to fill
fill_playg:
  @ Fill the playground area.
  mov r2, $0
  2:
    @ Fills the register values to point to different offsets in LDM table
    mov r3, $16*4
    and r9, r2, $15
    add r3, r3, r9, lsl #7   @ (32*4)
    add r3, r3, r0

    str r3, [r1], #4
    adds r2, $1
    cmp r2, $2048
    bne 2b
  bx lr

fill_playg_1:
  @ Fill the playground area.
  mov r2, $0
  2:
    @ Fills the register values to point to different offsets in LDM table
    mov r3, $16*4
    add r3, r3, r2, lsl #7   @ (32*4)
    add r3, r3, r0

    str r3, [r1], #4
    adds r2, $1
    cmp r2, $16
    bne 2b
  bx lr

testfail_ldm:
  ldr r1, =SAVED_DATA
  ldr r1, [r1, #REG_DUMPPTR]
  ldr r2, [r1, #0]; ldr r3, [r1, #4];
  screen_print_N(r0_1_text,  60, r2, r3)
  ldr r2, [r1, #8]; ldr r3, [r1, #12];
  screen_print_N(r2_3_text,  70, r2, r3)
  ldr r2, [r1, #16]; ldr r3, [r1, #20];
  screen_print_N(r4_5_text,  80, r2, r3)
  ldr r2, [r1, #24]; ldr r3, [r1, #28];
  screen_print_N(r6_7_text,  90, r2, r3)
  ldr r2, [r1, #32]; ldr r3, [r1, #36];
  screen_print_N(r8_9_text,  100, r2, r3)
  ldr r2, [r1, #40]; ldr r3, [r1, #44];
  screen_print_N(r10_11_text, 110, r2, r3)
  ldr r2, [r1, #48]; ldr r3, [r1, #52];
  screen_print_N(r12_13_text, 120, r2, r3)
  ldr r2, [r1, #56];
  screen_print_N(r14_text, 130, r2)

  mov r3, r6
  and r2, r0, $7           @ mode
  lsr r1, r0, #3           @ base reg
  ldr r0, =printbuf
  bl ldm_fmt

  screen_print_N(printbuf,   40, r0)

  ldr r1, =SAVED_DATA
  ldr r1, [r1, #REG_ERR]   @ mismatch reg
  ldr r0, =printbuf
  bl reg_err_fmt
  screen_print_N(printbuf,  145, r0)

  mov r0, $0x5000000
  ldr r1, =0x4F1B
  strh r1, [r0]

  b endloop

testfail_stm_reg:
  @ Print register dump, indicate register mismatch too
  ldr r1, =SAVED_DATA
  ldr r1, [r1, #REG_DUMPPTR]
  ldr r2, [r1, #0]; ldr r3, [r1, #4];
  screen_print_N(r0_1_text,  60, r2, r3)
  ldr r2, [r1, #8]; ldr r3, [r1, #12];
  screen_print_N(r2_3_text,  70, r2, r3)
  ldr r2, [r1, #16]; ldr r3, [r1, #20];
  screen_print_N(r4_5_text,  80, r2, r3)
  ldr r2, [r1, #24]; ldr r3, [r1, #28];
  screen_print_N(r6_7_text,  90, r2, r3)
  ldr r2, [r1, #32]; ldr r3, [r1, #36];
  screen_print_N(r8_9_text,  100, r2, r3)
  ldr r2, [r1, #40]; ldr r3, [r1, #44];
  screen_print_N(r10_11_text, 110, r2, r3)
  ldr r2, [r1, #48]; ldr r3, [r1, #52];
  screen_print_N(r12_13_text, 120, r2, r3)
  ldr r2, [r1, #56];
  screen_print_N(r14_text, 130, r2)

  bl print_stm_inst

  ldr r1, =SAVED_DATA
  ldr r1, [r1, #REG_ERR]   @ mismatch reg
  ldr r0, =printbuf
  bl reg_err_fmt
  screen_print_N(printbuf,  145, r0)

  mov r0, $0x5000000
  ldr r1, =0x4F1B
  strh r1, [r0]

  b endloop


testfail_stm_mem:

  mov r0, r5
  bl print_stm_inst

  @ Draw address offset and values:
  ldr r0, =SAVED_DATA
  ldr r1, [r0, #REG_MEM_OFF]
  @ Subtract the mem offset from the original base-reg value.
  lsr r2, r5, #3
  sub r1, r1, r2, lsl #7   @ sub 128 bytes
  sub r1, r1, $16*4
  screen_print_N(mem_off,  70, r1)

  ldr r1, [r0, #REG_MEM_V1]
  ldr r2, [r0, #REG_MEM_V2]
  screen_print_N(mem_cmp,  80, r1, r2)

  ldr r0, =printbuf
  bl mem_err_fmt
  screen_print_N(printbuf,  145, r0)

  mov r0, $0x5000000
  ldr r1, =0x4F1B
  strh r1, [r0]

  b endloop

endloop:
  nop; nop; nop; nop; nop; nop;
  nop; nop; nop; nop; nop; nop;
  b endloop

print_stm_inst:
  str lr, [sp]

  @ Write instruction string
  @ void stm_fmt(char *out, unsigned base_reg, unsigned mode)

  mov r3, r6
  and r2, r0, $7           @ mode
  lsr r1, r0, #3           @ base reg
  ldr r0, =printbuf
  bl stm_fmt

  screen_print_N(printbuf,   40, r0)

  ldr pc, [sp]

.pool  @ Drop the pool here before the fixtures


@ LDM test code: this bit runs on IWRAM for speed.

ldm_test_fixture:
  @ TODO store this info in the data pool?
  ldr r0, =SAVED_DATA
  ldr r1, [r0, #ITERATION]

  ldr r0, =INST_AREA         @ lookup inst in the inst area
  ldr r1, [r0, r1, lsl #2]   @ r1 contains the instruction

ldm_test_store_inst:
  @ Overwrite the instruction
  str r1, [pc, #(ldm_test_inst - ldm_test_store_inst - 8)]

  ldr r0, =(LDM_AREA + 16*4)
  add  r1,  r0, $32*4
  add  r2,  r1, $32*4
  add  r3,  r2, $32*4
  add  r4,  r3, $32*4
  add  r5,  r4, $32*4
  add  r6,  r5, $32*4
  add  r7,  r6, $32*4
  add  r8,  r7, $32*4
  add  r9,  r8, $32*4
  add r10,  r9, $32*4
  add r11, r10, $32*4
  add r12, r11, $32*4
  add r13, r12, $32*4
  add r14, r13, $32*4
ldm_test_inst:
  nop     @ Actual LDM instruction
  str r0, [pc, #(ldm_test_data - ldm_test_inst - 12)]
  str r1, [pc, #(ldm_test_data - ldm_test_inst - 12)]
  str r2, [pc, #(ldm_test_data - ldm_test_inst - 12)]

  ldr r0, =SAVED_DATA
  ldr r1, [r0, #ITERATION]

  ldr r0, =REF_AREA          @ result reference area
  add r1, r0, r1, lsl #6     @ points to first entry in the results table

  #define compare_reg(reg, offset) \
    ldr r0, [r1, #(offset)];       \
    cmp r0, reg;                   \
    movne r1, #(offset / 4);       \
    bne ldm_test_fail;

  compare_reg( r2,  8)  compare_reg( r3, 12)
  compare_reg( r4, 16)  compare_reg( r5, 20)
  compare_reg( r6, 24)  compare_reg( r7, 28)
  compare_reg( r8, 32)  compare_reg( r9, 36)
  compare_reg(r10, 40)  compare_reg(r11, 44)
  compare_reg(r12, 48)  compare_reg(r13, 52)
  compare_reg(r14, 56)

  @ Check r0 and r1
1:ldr r2, [pc, #(ldm_test_data - 1b - 8)]
  compare_reg(r2, 0)
1:ldr r2, [pc, #(ldm_test_data - 1b - 4)]
  compare_reg(r2, 4)

  ldr r0, =SAVED_DATA
  ldr r1, [r0, #ITERATION]
  add r1, r1, $1
  str r1, [r0, #ITERATION]
  cmp r1, $120

  bne ldm_test_fixture       @ skip data section to the next block of data.

  @ Return OK (-1)
  ldr r0, =SAVED_DATA
  ldr sp, [r0, #SAVED_SP]    @ Restore smashed stack
  mov r0, $-1
  ldr pc, [sp]

ldm_test_fail:
  @ Save the remaining registers (r3-r14)
  str r3, [pc, #(ldm_test_data - ldm_test_fail + 4)]
  str r4, [pc, #(ldm_test_data - ldm_test_fail + 4)]
  str r5, [pc, #(ldm_test_data - ldm_test_fail + 4)]
  str r6, [pc, #(ldm_test_data - ldm_test_fail + 4)]
  str r7, [pc, #(ldm_test_data - ldm_test_fail + 4)]
  str r8, [pc, #(ldm_test_data - ldm_test_fail + 4)]
  str r9, [pc, #(ldm_test_data - ldm_test_fail + 4)]
  str r10, [pc, #(ldm_test_data - ldm_test_fail + 4)]
  str r11, [pc, #(ldm_test_data - ldm_test_fail + 4)]
  str r12, [pc, #(ldm_test_data - ldm_test_fail + 4)]
  str r13, [pc, #(ldm_test_data - ldm_test_fail + 4)]
  str r14, [pc, #(ldm_test_data - ldm_test_fail + 4)]

  @ Return iteration number where the mismatch was found
  ldr r0, =SAVED_DATA
  str r1, [r0, #REG_ERR]
  ldr sp, [r0, #SAVED_SP]    @ Restore smashed stack
1:add r1, pc, $(ldm_test_data - 1b - 8)
  str r1, [r0, #REG_DUMPPTR]
  ldr r0, [r0, #ITERATION]
  ldr pc, [sp]

ldm_test_data:
  .fill 15, 4, 0    @ Reg storage area
  .pool             @ Drop any pool here too!
ldm_test_fixture_end:



@ STM test code: this bit runs on IWRAM for speed.
@ Return code: -1 (OK), 0 if reg mismatch, 1 if mem mismatch addr

stm_test_fixture:
  ldr r0, =(STM_AREA + 16*4)
  add  r1,  r0, $32*4
  add  r2,  r1, $32*4
  add  r3,  r2, $32*4
  add  r4,  r3, $32*4
  add  r5,  r4, $32*4
  add  r6,  r5, $32*4
  add  r7,  r6, $32*4
  add  r8,  r7, $32*4
  add  r9,  r8, $32*4
  add r10,  r9, $32*4
  add r11, r10, $32*4
  add r12, r11, $32*4
  add r13, r12, $32*4
  add r14, r13, $32*4
stm_test_inst:
  nop     @ Actual STM instruction
  str r0, [pc, #(stm_test_data - stm_test_inst - 12)]
  str r1, [pc, #(stm_test_data - stm_test_inst - 12)]
  str r2, [pc, #(stm_test_data - stm_test_inst - 12)]

  @ Check registers first
  ldr r1, =REF_AREA_R

  #define check_reg(reg, offset)   \
    ldr r0, [r1, #(offset)];       \
    cmp r0, reg;                   \
    movne r1, #(offset / 4);       \
    bne stm_test_fail;

  check_reg( r2,  8)  check_reg( r3, 12)
  check_reg( r4, 16)  check_reg( r5, 20)
  check_reg( r6, 24)  check_reg( r7, 28)
  check_reg( r8, 32)  check_reg( r9, 36)
  check_reg(r10, 40)  check_reg(r11, 44)
  check_reg(r12, 48)  check_reg(r13, 52)
  check_reg(r14, 56)

  @ Check r0 and r1
1:ldr r2, [pc, #(stm_test_data - 1b - 8)]
  check_reg(r2, 0)
1:ldr r2, [pc, #(stm_test_data - 1b - 4)]
  check_reg(r2, 4)

  @ Regs OK: Check now the memory area
  ldr r0, =REF_AREA
  ldr r1, =STM_AREA
  mov r4, $(512)
  5:
    ldr r5, [r0], #4
    ldr r9, [r1], #4
    cmp    r5, r9
    bne stm_test_fail_mem

    ldr r5, [r0], #4
    ldr r9, [r1], #4
    cmp    r5, r9
    bne stm_test_fail_mem

    subs r4, r4, $2
    bne 5b

  @ Return OK (-1)
  ldr r0, =SAVED_DATA
  ldr sp, [r0, #SAVED_SP]    @ Restore smashed stack
  mov r0, $-1
  ldr pc, [sp]

stm_test_fail:
  @ Save the remaining registers (r3-r14)
  str r3, [pc, #(stm_test_data - stm_test_fail + 4)]
  str r4, [pc, #(stm_test_data - stm_test_fail + 4)]
  str r5, [pc, #(stm_test_data - stm_test_fail + 4)]
  str r6, [pc, #(stm_test_data - stm_test_fail + 4)]
  str r7, [pc, #(stm_test_data - stm_test_fail + 4)]
  str r8, [pc, #(stm_test_data - stm_test_fail + 4)]
  str r9, [pc, #(stm_test_data - stm_test_fail + 4)]
  str r10, [pc, #(stm_test_data - stm_test_fail + 4)]
  str r11, [pc, #(stm_test_data - stm_test_fail + 4)]
  str r12, [pc, #(stm_test_data - stm_test_fail + 4)]
  str r13, [pc, #(stm_test_data - stm_test_fail + 4)]
  str r14, [pc, #(stm_test_data - stm_test_fail + 4)]

  @ Store reg issue in register
  ldr r0, =SAVED_DATA
  str r1, [r0, #REG_ERR]
  ldr sp, [r0, #SAVED_SP]    @ Restore smashed stack
1:add r1, pc, $(stm_test_data - 1b - 8)
  str r1, [r0, #REG_DUMPPTR]
  mov r0, $0   @ indicate that there's an error mismatch
  ldr pc, [sp]

stm_test_fail_mem:
  @ Return mem address where check failed
  ldr r0, =SAVED_DATA

  ldr r2, =STM_AREA
  sub r1, r1, r2      @ generate mem offset
  sub r1, r1, #4
  str r1, [r0, #REG_MEM_OFF]

  str r5, [r0, #REG_MEM_V1]
  str r9, [r0, #REG_MEM_V2]

  ldr sp, [r0, #SAVED_SP]    @ Restore smashed stack
  mov r0, $1   @ error with address
  ldr pc, [sp]

stm_test_data:
  .fill 15, 4, 0    @ Reg storage area
  .pool             @ Drop any pool here too!
stm_test_fixture_end:

thumb_ldmia_test_fail:
  str r1, [sp]

  mov r3, r2
  mov r2, $3               @ mode (IA!)
  ldr r0, =printbuf
  bl ldm_fmt

  screen_print_N(printbuf,   40, r0)

  ldr r0, =printbuf
  ldr r1, [sp]
  bl reg_err_fmt
  screen_print_N(printbuf,  145, r0)

  ldr r2, =REF_AREA_2
  ldr r3, [r2, #0]; ldr r4, [r2, #4];
  screen_print_N(r0_1_text,  60, r3, r4)
  ldr r3, [r2, #8]; ldr r4, [r2, #12];
  screen_print_N(r2_3_text,  70, r3, r4)
  ldr r3, [r2, #16]; ldr r4, [r2, #20];
  screen_print_N(r4_5_text,  80, r3, r4)
  ldr r3, [r2, #24]; ldr r4, [r2, #28];
  screen_print_N(r6_7_text,  90, r3, r4)

  mov r0, $0x5000000
  ldr r1, =0x4F1B
  strh r1, [r0]

  b endloop


@ Thumb testing aux routines
.thumb
.thumb_func
setup_thumb_regs:
  ldr r0, =(LDM_AREA + 16*4);
  ldr r1, =(LDM_AREA + 16*4 + 32*4 * 1)
  ldr r2, =(LDM_AREA + 16*4 + 32*4 * 2)
  ldr r3, =(LDM_AREA + 16*4 + 32*4 * 3)
  ldr r4, =(LDM_AREA + 16*4 + 32*4 * 4)
  ldr r5, =(LDM_AREA + 16*4 + 32*4 * 5)
  ldr r6, =(LDM_AREA + 16*4 + 32*4 * 6)
  ldr r7, =(LDM_AREA + 16*4 + 32*4 * 7)
  bx lr

#define setup_thumb_regs_call()            \
  bl setup_thumb_regs;                     \

#define cmp_thb_reg(reg, offset) \
  ldr r1, [r0, #(offset)];       \
  cmp r1, reg;                   \
  bne 5f;


#define validate_thumb_regs(breg, msk)     \
  mov r8, r0;                              \
  mov r9, r1;                              \
  ldr r0, =REF_AREA;                       \
                                           \
  cmp_thb_reg( r8,  0)                     \
  cmp_thb_reg( r9,  4)                     \
  cmp_thb_reg( r2,  8)                     \
  cmp_thb_reg( r3, 12)                     \
  cmp_thb_reg( r4, 16)                     \
  cmp_thb_reg( r5, 20)                     \
  cmp_thb_reg( r6, 24)                     \
  cmp_thb_reg( r7, 28)                     \
                                           \
  b 1f;    /* Jump to the next test */     \
5:                                         \
  /* Test fail path */                     \
  ldr r0, =REF_AREA_2;                     \
  str r7, [r0, #28];                       \
  str r6, [r0, #24];                       \
  str r5, [r0, #20];                       \
  str r4, [r0, #16];                       \
  str r3, [r0, #12];                       \
  str r2, [r0,  #8];                       \
  mov r1, r9;                              \
  str r1, [r0,  #4];                       \
  mov r1, r8;                              \
  str r1, [r0,  #0];                       \
                                           \
  mov r1, $breg;                           \
  mov r2, $msk;                            \
  ldr r0, =thumb_ldmia_test_fail;          \
  bx r0
  

.thumb_func
fill_playg_1_thumb:
  ldr r2, =fill_playg_1
  bx r2

.thumb_func
wordcpy_thumb:
  ldr r3, [r0]
  str r3, [r2]
  add r0, $4
  add r2, $4
  cmp r0, r1
  bne wordcpy_thumb
  bx lr

.pool
.arm

@ Text/display stuff
title:
  .asciz "     GBA LDM/STM testrom\n         by davidgf.net"
passmsg:
  .asciz "tests passed!"

test_ldm_thb:  .asciz " testing Thumb LDM ..."
test_ldm_arm:  .asciz " testing ARM LDM ...  "
test_stm_arm:  .asciz " testing ARM STM ...  "

r0_1_text:   .asciz "r0  0x%x r1  0x%x"
r2_3_text:   .asciz "r2  0x%x r3  0x%x"
r4_5_text:   .asciz "r4  0x%x r5  0x%x"
r6_7_text:   .asciz "r6  0x%x r7  0x%x"
r8_9_text:   .asciz "r8  0x%x r9  0x%x"
r10_11_text: .asciz "r10 0x%x r11 0x%x"
r12_13_text: .asciz "r12 0x%x r13 0x%x"
r14_text:    .asciz "r14 0x%x"

mem_off:   .asciz " Mem offset: %d"
mem_cmp:   .asciz " %x != %x"

.pool

#include "text.h"
#include "test.autogen.h"


