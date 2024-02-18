# CPU tests for GBA and ARM7TDMI

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
@ Now perform some tests!

@ Thumb mode tests

#ifdef TESTS_THUMB
  run_test(thtest_mvn,  "mvn r3, r0")
  run_test(thtest_neg,  "neg r3, r0")

  run_test(thtest_lsr,  "lsr r3, r0, r1")
  run_test(thtest_lsl,  "lsl r3, r0, r1")
  run_test(thtest_asr,  "asr r3, r0, r1")
  run_test(thtest_ror,  "ror r3, r0, r1")

  run_test(thtest_add,  "adds r3, r0, r1")
  run_test(thtest_sub,  "subs r3, r0, r1")
  run_test(thtest_adc,  "adcs r3, r0, r1")
  run_test(thtest_sbc,  "sbcs r3, r0, r1")
  run_test(thtest_and,  "ands r3, r0, r1")
  run_test(thtest_orr,  "orrs r3, r0, r1")
  run_test(thtest_eor,  "eors r3, r0, r1")
  run_test(thtest_bic,  "bics r3, r0, r1")
  run_test(thtest_mul,  "muls r3, r0, r1")
#endif

@ ARM mode tests

#ifdef TESTS_ARM_IMM
  run_test(test_imm_and,  "and  r3, r0, imm")
  run_test(test_imm_ands, "ands r3, r0, imm")
  run_test(test_imm_orr,  "orr  r3, r0, imm")
  run_test(test_imm_orrs, "orrs r3, r0, imm")
  run_test(test_imm_eor,  "eor  r3, r0, imm")
  run_test(test_imm_eors, "eors r3, r0, imm")
  run_test(test_imm_bic,  "bic  r3, r0, imm")
  run_test(test_imm_bics, "bics r3, r0, imm")
  run_test(test_imm_add,  "add  r3, r0, imm")
  run_test(test_imm_adds, "adds r3, r0, imm")
  run_test(test_imm_adc,  "adc  r3, r0, imm")
  run_test(test_imm_adcs, "adcs r3, r0, imm")
  run_test(test_imm_sub,  "sub  r3, r0, imm")
  run_test(test_imm_subs, "subs r3, r0, imm")
  run_test(test_imm_sbc,  "sbc  r3, r0, imm")
  run_test(test_imm_sbcs, "sbcs r3, r0, imm")
  run_test(test_imm_rsb,  "rsb  r3, r0, imm")
  run_test(test_imm_rsbs, "rsbs r3, r0, imm")
  run_test(test_imm_rsc,  "rsc  r3, r0, imm")
  run_test(test_imm_rscs, "rscs r3, r0, imm")

  run_test(test_imm_and_lsr,  "and r3, r0, r1, lsr imm")
  run_test(test_imm_and_lsl,  "and r3, r0, r1, lsl imm")
  run_test(test_imm_and_asr,  "and r3, r0, r1, asr imm")
  run_test(test_imm_and_ror,  "and r3, r0, r1, ror imm")
  run_test(test_imm_ands_lsr, "ands r3, r0, r1, lsr imm")
  run_test(test_imm_ands_lsl, "ands r3, r0, r1, lsl imm")
  run_test(test_imm_ands_asr, "ands r3, r0, r1, asr imm")
  run_test(test_imm_ands_ror, "ands r3, r0, r1, ror imm")
  run_test(test_imm_orr_lsr,  "orr r3, r0, r1, lsr imm")
  run_test(test_imm_orr_lsl,  "orr r3, r0, r1, lsl imm")
  run_test(test_imm_orr_asr,  "orr r3, r0, r1, asr imm")
  run_test(test_imm_orr_ror,  "orr r3, r0, r1, ror imm")
  run_test(test_imm_orrs_lsr, "orrs r3, r0, r1, lsr imm")
  run_test(test_imm_orrs_lsl, "orrs r3, r0, r1, lsl imm")
  run_test(test_imm_orrs_asr, "orrs r3, r0, r1, asr imm")
  run_test(test_imm_orrs_ror, "orrs r3, r0, r1, ror imm")
  run_test(test_imm_eor_lsr,  "eor r3, r0, r1, lsr imm")
  run_test(test_imm_eor_lsl,  "eor r3, r0, r1, lsl imm")
  run_test(test_imm_eor_asr,  "eor r3, r0, r1, asr imm")
  run_test(test_imm_eor_ror,  "eor r3, r0, r1, ror imm")
  run_test(test_imm_eors_lsr, "eors r3, r0, r1, lsr imm")
  run_test(test_imm_eors_lsl, "eors r3, r0, r1, lsl imm")
  run_test(test_imm_eors_asr, "eors r3, r0, r1, asr imm")
  run_test(test_imm_eors_ror, "eors r3, r0, r1, ror imm")
  run_test(test_imm_bic_lsr,  "bic r3, r0, r1, lsr imm")
  run_test(test_imm_bic_lsl,  "bic r3, r0, r1, lsl imm")
  run_test(test_imm_bic_asr,  "bic r3, r0, r1, asr imm")
  run_test(test_imm_bic_ror,  "bic r3, r0, r1, ror imm")
  run_test(test_imm_bics_lsr, "bics r3, r0, r1, lsr imm")
  run_test(test_imm_bics_lsl, "bics r3, r0, r1, lsl imm")
  run_test(test_imm_bics_asr, "bics r3, r0, r1, asr imm")
  run_test(test_imm_bics_ror, "bics r3, r0, r1, ror imm")

  run_test(test_imm_add_lsr,  "add r3, r0, r1, lsr imm")
  run_test(test_imm_add_lsl,  "add r3, r0, r1, lsl imm")
  run_test(test_imm_add_asr,  "add r3, r0, r1, asr imm")
  run_test(test_imm_add_ror,  "add r3, r0, r1, ror imm")
  run_test(test_imm_adds_lsr, "adds r3, r0, r1, lsr imm")
  run_test(test_imm_adds_lsl, "adds r3, r0, r1, lsl imm")
  run_test(test_imm_adds_asr, "adds r3, r0, r1, asr imm")
  run_test(test_imm_adds_ror, "adds r3, r0, r1, ror imm")
  run_test(test_imm_sub_lsr,  "sub r3, r0, r1, lsr imm")
  run_test(test_imm_sub_lsl,  "sub r3, r0, r1, lsl imm")
  run_test(test_imm_sub_asr,  "sub r3, r0, r1, asr imm")
  run_test(test_imm_sub_ror,  "sub r3, r0, r1, ror imm")
  run_test(test_imm_subs_lsr, "subs r3, r0, r1, lsr imm")
  run_test(test_imm_subs_lsl, "subs r3, r0, r1, lsl imm")
  run_test(test_imm_subs_asr, "subs r3, r0, r1, asr imm")
  run_test(test_imm_subs_ror, "subs r3, r0, r1, ror imm")

  run_test(test_imm_adc_lsr,  "adc r3, r0, r1, lsr imm")
  run_test(test_imm_adc_lsl,  "adc r3, r0, r1, lsl imm")
  run_test(test_imm_adc_asr,  "adc r3, r0, r1, asr imm")
  run_test(test_imm_adc_ror,  "adc r3, r0, r1, ror imm")
  run_test(test_imm_adcs_lsr, "adcs r3, r0, r1, lsr imm")
  run_test(test_imm_adcs_lsl, "adcs r3, r0, r1, lsl imm")
  run_test(test_imm_adcs_asr, "adcs r3, r0, r1, asr imm")
  run_test(test_imm_adcs_ror, "adcs r3, r0, r1, ror imm")
  run_test(test_imm_sbc_lsr,  "sbc r3, r0, r1, lsr imm")
  run_test(test_imm_sbc_lsl,  "sbc r3, r0, r1, lsl imm")
  run_test(test_imm_sbc_asr,  "sbc r3, r0, r1, asr imm")
  run_test(test_imm_sbc_ror,  "sbc r3, r0, r1, ror imm")
  run_test(test_imm_sbcs_lsr, "sbcs r3, r0, r1, lsr imm")
  run_test(test_imm_sbcs_lsl, "sbcs r3, r0, r1, lsl imm")
  run_test(test_imm_sbcs_asr, "sbcs r3, r0, r1, asr imm")
  run_test(test_imm_sbcs_ror, "sbcs r3, r0, r1, ror imm")
  run_test(test_imm_rsb_lsr,  "rsb r3, r0, r1, lsr imm")
  run_test(test_imm_rsb_lsl,  "rsb r3, r0, r1, lsl imm")
  run_test(test_imm_rsb_asr,  "rsb r3, r0, r1, asr imm")
  run_test(test_imm_rsb_ror,  "rsb r3, r0, r1, ror imm")
  run_test(test_imm_rsbs_lsr, "rsbs r3, r0, r1, lsr imm")
  run_test(test_imm_rsbs_lsl, "rsbs r3, r0, r1, lsl imm")
  run_test(test_imm_rsbs_asr, "rsbs r3, r0, r1, asr imm")
  run_test(test_imm_rsbs_ror, "rsbs r3, r0, r1, ror imm")
  run_test(test_imm_rsc_lsr,  "rsc r3, r0, r1, lsr imm")
  run_test(test_imm_rsc_lsl,  "rsc r3, r0, r1, lsl imm")
  run_test(test_imm_rsc_asr,  "rsc r3, r0, r1, asr imm")
  run_test(test_imm_rsc_ror,  "rsc r3, r0, r1, ror imm")
  run_test(test_imm_rscs_lsr, "rscs r3, r0, r1, lsr imm")
  run_test(test_imm_rscs_lsl, "rscs r3, r0, r1, lsl imm")
  run_test(test_imm_rscs_asr, "rscs r3, r0, r1, asr imm")
  run_test(test_imm_rscs_ror, "rscs r3, r0, r1, ror imm")
#endif

#ifdef TESTS_ARM_REG
  run_test(test_mov,   "mov r3, r0")
  run_test(test_movs,  "movs r3, r0")
  run_test(test_mvn,   "mvn r3, r0")
  run_test(test_mvns,  "mvns r3, r0")

  run_test(test_lsr,  "lsr r3, r0, r1")
  run_test(test_lsrs, "lsrs r3, r0, r1")
  run_test(test_lsl,  "lsl r3, r0, r1")
  run_test(test_lsls, "lsls r3, r0, r1")
  run_test(test_asr,  "asr r3, r0, r1")
  run_test(test_asrs, "asrs r3, r0, r1")
  run_test(test_ror,  "ror r3, r0, r1")
  run_test(test_rors, "rors r3, r0, r1")

  run_test(test_and,  "and r3, r0, r1")
  run_test(test_ands, "ands r3, r0, r1")
  run_test(test_orr,  "orr r3, r0, r1")
  run_test(test_orrs, "orrs r3, r0, r1")
  run_test(test_eor,  "eor r3, r0, r1")
  run_test(test_eors, "eors r3, r0, r1")
  run_test(test_bic,  "bic r3, r0, r1")
  run_test(test_bics, "bics r3, r0, r1")

  run_test(test_add,  "add r3, r0, r1")
  run_test(test_adds, "adds r3, r0, r1")
  run_test(test_adc,  "adc r3, r0, r1")
  run_test(test_adcs, "adcs r3, r0, r1")
  run_test(test_sub,  "sub r3, r0, r1")
  run_test(test_subs, "subs r3, r0, r1")
  run_test(test_sbc,  "sbc r3, r0, r1")
  run_test(test_sbcs, "sbcs r3, r0, r1")
  run_test(test_rsb,  "rsb r3, r0, r1")
  run_test(test_rsbs, "rsbs r3, r0, r1")
  run_test(test_rsc,  "rsc r3, r0, r1")
  run_test(test_rscs, "rscs r3, r0, r1")
  run_test(test_mul,  "mul r3, r0, r1")
  run_test(test_muls, "muls r3, r0, r1")

  run_test(test_umull,  "umull r3, r4, r0, r1")
  run_test(test_umulls, "umulls r3, r4, r0, r1")
  run_test(test_smull,  "smull r3, r4, r0, r1")
  run_test(test_smulls, "smulls r3, r4, r0, r1")
  run_test(test_mla,    "mla r3, r0, r1, r2")
  run_test(test_mlas,   "mlas r3, r0, r1, r2")

  run_test(test_and_lsr,  "and r3, r0, r1, lsr r2")
  run_test(test_and_lsl,  "and r3, r0, r1, lsl r2")
  run_test(test_and_asr,  "and r3, r0, r1, asr r2")
  run_test(test_and_ror,  "and r3, r0, r1, ror r2")
  run_test(test_ands_lsr, "ands r3, r0, r1, lsr r2")
  run_test(test_ands_lsl, "ands r3, r0, r1, lsl r2")
  run_test(test_ands_asr, "ands r3, r0, r1, asr r2")
  run_test(test_ands_ror, "ands r3, r0, r1, ror r2")
  run_test(test_orr_lsr,  "orr r3, r0, r1, lsr r2")
  run_test(test_orr_lsl,  "orr r3, r0, r1, lsl r2")
  run_test(test_orr_asr,  "orr r3, r0, r1, asr r2")
  run_test(test_orr_ror,  "orr r3, r0, r1, ror r2")
  run_test(test_orrs_lsr, "orrs r3, r0, r1, lsr r2")
  run_test(test_orrs_lsl, "orrs r3, r0, r1, lsl r2")
  run_test(test_orrs_asr, "orrs r3, r0, r1, asr r2")
  run_test(test_orrs_ror, "orrs r3, r0, r1, ror r2")
  run_test(test_eor_lsr,  "eor r3, r0, r1, lsr r2")
  run_test(test_eor_lsl,  "eor r3, r0, r1, lsl r2")
  run_test(test_eor_asr,  "eor r3, r0, r1, asr r2")
  run_test(test_eor_ror,  "eor r3, r0, r1, ror r2")
  run_test(test_eors_lsr, "eors r3, r0, r1, lsr r2")
  run_test(test_eors_lsl, "eors r3, r0, r1, lsl r2")
  run_test(test_eors_asr, "eors r3, r0, r1, asr r2")
  run_test(test_eors_ror, "eors r3, r0, r1, ror r2")
  run_test(test_bic_lsr,  "bic r3, r0, r1, lsr r2")
  run_test(test_bic_lsl,  "bic r3, r0, r1, lsl r2")
  run_test(test_bic_asr,  "bic r3, r0, r1, asr r2")
  run_test(test_bic_ror,  "bic r3, r0, r1, ror r2")
  run_test(test_bics_lsr, "bics r3, r0, r1, lsr r2")
  run_test(test_bics_lsl, "bics r3, r0, r1, lsl r2")
  run_test(test_bics_asr, "bics r3, r0, r1, asr r2")
  run_test(test_bics_ror, "bics r3, r0, r1, ror r2")

  run_test(test_add_lsr,  "add r3, r0, r1, lsr r2")
  run_test(test_add_lsl,  "add r3, r0, r1, lsl r2")
  run_test(test_add_asr,  "add r3, r0, r1, asr r2")
  run_test(test_add_ror,  "add r3, r0, r1, ror r2")
  run_test(test_adds_lsr, "adds r3, r0, r1, lsr r2")
  run_test(test_adds_lsl, "adds r3, r0, r1, lsl r2")
  run_test(test_adds_asr, "adds r3, r0, r1, asr r2")
  run_test(test_adds_ror, "adds r3, r0, r1, ror r2")
  run_test(test_sub_lsr,  "sub r3, r0, r1, lsr r2")
  run_test(test_sub_lsl,  "sub r3, r0, r1, lsl r2")
  run_test(test_sub_asr,  "sub r3, r0, r1, asr r2")
  run_test(test_sub_ror,  "sub r3, r0, r1, ror r2")
  run_test(test_subs_lsr, "subs r3, r0, r1, lsr r2")
  run_test(test_subs_lsl, "subs r3, r0, r1, lsl r2")
  run_test(test_subs_asr, "subs r3, r0, r1, asr r2")
  run_test(test_subs_ror, "subs r3, r0, r1, ror r2")

  run_test(test_adc_lsr,  "adc r3, r0, r1, lsr r2")
  run_test(test_adc_lsl,  "adc r3, r0, r1, lsl r2")
  run_test(test_adc_asr,  "adc r3, r0, r1, asr r2")
  run_test(test_adc_ror,  "adc r3, r0, r1, ror r2")
  run_test(test_adcs_lsr, "adcs r3, r0, r1, lsr r2")
  run_test(test_adcs_lsl, "adcs r3, r0, r1, lsl r2")
  run_test(test_adcs_asr, "adcs r3, r0, r1, asr r2")
  run_test(test_adcs_ror, "adcs r3, r0, r1, ror r2")
  run_test(test_sbc_lsr,  "sbc r3, r0, r1, lsr r2")
  run_test(test_sbc_lsl,  "sbc r3, r0, r1, lsl r2")
  run_test(test_sbc_asr,  "sbc r3, r0, r1, asr r2")
  run_test(test_sbc_ror,  "sbc r3, r0, r1, ror r2")
  run_test(test_sbcs_lsr, "sbcs r3, r0, r1, lsr r2")
  run_test(test_sbcs_lsl, "sbcs r3, r0, r1, lsl r2")
  run_test(test_sbcs_asr, "sbcs r3, r0, r1, asr r2")
  run_test(test_sbcs_ror, "sbcs r3, r0, r1, ror r2")
  run_test(test_rsb_lsr,  "rsb r3, r0, r1, lsr r2")
  run_test(test_rsb_lsl,  "rsb r3, r0, r1, lsl r2")
  run_test(test_rsb_asr,  "rsb r3, r0, r1, asr r2")
  run_test(test_rsb_ror,  "rsb r3, r0, r1, ror r2")
  run_test(test_rsbs_lsr, "rsbs r3, r0, r1, lsr r2")
  run_test(test_rsbs_lsl, "rsbs r3, r0, r1, lsl r2")
  run_test(test_rsbs_asr, "rsbs r3, r0, r1, asr r2")
  run_test(test_rsbs_ror, "rsbs r3, r0, r1, ror r2")
  run_test(test_rsc_lsr,  "rsc r3, r0, r1, lsr r2")
  run_test(test_rsc_lsl,  "rsc r3, r0, r1, lsl r2")
  run_test(test_rsc_asr,  "rsc r3, r0, r1, asr r2")
  run_test(test_rsc_ror,  "rsc r3, r0, r1, ror r2")
  run_test(test_rscs_lsr, "rscs r3, r0, r1, lsr r2")
  run_test(test_rscs_lsl, "rscs r3, r0, r1, lsl r2")
  run_test(test_rscs_asr, "rscs r3, r0, r1, asr r2")
  run_test(test_rscs_ror, "rscs r3, r0, r1, ror r2")

  run_test(test_mov_lsr,  "mov r3, r0, lsr r1")
  run_test(test_mov_lsl,  "mov r3, r0, lsl r1")
  run_test(test_mov_asr,  "mov r3, r0, asr r1")
  run_test(test_mov_ror,  "mov r3, r0, ror r1")
  run_test(test_movs_lsr, "movs r3, r0, lsr r1")
  run_test(test_movs_lsl, "movs r3, r0, lsl r1")
  run_test(test_movs_asr, "movs r3, r0, asr r1")
  run_test(test_movs_ror, "movs r3, r0, ror r1")
  run_test(test_mvn_lsr,  "mvn r3, r0, lsr r1")
  run_test(test_mvn_lsl,  "mvn r3, r0, lsl r1")
  run_test(test_mvn_asr,  "mvn r3, r0, asr r1")
  run_test(test_mvn_ror,  "mvn r3, r0, ror r1")
  run_test(test_mvns_lsr, "mvns r3, r0, lsr r1")
  run_test(test_mvns_lsl, "mvns r3, r0, lsl r1")
  run_test(test_mvns_asr, "mvns r3, r0, asr r1")
  run_test(test_mvns_ror, "mvns r3, r0, ror r1")

  run_test(test_cmp_lsr,  "cmp r0, r1, lsr r2")
  run_test(test_cmp_lsl,  "cmp r0, r1, lsl r2")
  run_test(test_cmp_asr,  "cmp r0, r1, asr r2")
  run_test(test_cmp_ror,  "cmp r0, r1, ror r2")
  run_test(test_cmn_lsr,  "cmn r0, r1, lsr r2")
  run_test(test_cmn_lsl,  "cmn r0, r1, lsl r2")
  run_test(test_cmn_asr,  "cmn r0, r1, asr r2")
  run_test(test_cmn_ror,  "cmn r0, r1, ror r2")
  run_test(test_tst_lsr,  "tst r0, r1, lsr r2")
  run_test(test_tst_lsl,  "tst r0, r1, lsl r2")
  run_test(test_tst_asr,  "tst r0, r1, asr r2")
  run_test(test_tst_ror,  "tst r0, r1, ror r2")
#endif

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
  screen_print_N(r0_text,    60, r0)
  screen_print_N(r1_text,    70, r1)
  screen_print_N(r2_text,    80, r2)
  screen_print_N(cpsr0_text, 90, r6)
  screen_print_N(res_text,  110, r3, r10)
  screen_print_N(res2_text, 120, r4, r11)
  screen_print_N(cpsr_text, 130, r5, r9)

  mov r0, $0x5000000
  ldr r1, =0x4F1B
  strh r1, [r0]


1:
  nop; nop; nop; nop; nop; nop;
  nop; nop; nop; nop; nop; nop;
  b 1b

title:
  .asciz "       GBA CPU testrom\n         by davidgf.net"

passmsg:
  .asciz "tests passed!"
testnstr:
  .asciz "test #%d"
r0_text:
  .asciz "r0:   0x%x"
r1_text:
  .asciz "r1:   0x%x"
r2_text:
  .asciz "r2:   0x%x"
cpsr0_text:
  .asciz "CPSR: 0x%x"
cpsr_text:
  .asciz "CPSR: 0x%x - 0x%x"
res_text:
  .asciz "r3:   0x%x - 0x%x"
res2_text:
  .asciz "r4:   0x%x - 0x%x"

#include "text.h"

#ifdef TESTS_ARM_IMM
#include "test.arm_imm.autogen.h"
#endif
#ifdef TESTS_ARM_REG
#include "test.arm_reg.autogen.h"
#endif
#ifdef TESTS_THUMB
#include "test.thumb.autogen.h"
#endif



