#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# We generate a test for every (or most) LDM/STM instruction with valid
# inputs and expected outputs. Reference data is compressed due to size
# requirements.

import random, math

def genRandValue():
  return random.randint(0, (1<<32)-1)

# Generate data tables for ARM tests
print(".align 4")
print("ldm_table:")
for _ in range(32*16):
  print("  .word 0x%08x" % genRandValue())
print("ldm_table_end:")

print("stm_table:")
for _ in range(32*16):
  print("  .word 0x%08x" % genRandValue())
print("stm_table_end:")


# Generate the thumb tests since they do not need that much ROM space

def reglist(m):
  return ",".join("r%d" % i for i in range(8) if (m & (1 << i)))

print(".thumb")
print(".thumb_func")
print("thumb_ld_tests:")

print("mov r0, lr; str r0, [sp]")
print("word_copy_thumb(ldm_table, LDM_AREA);")

for regb in range(8):
  for regl in range(1, 256):   # Empty reglist is undefined!
    print("ldr r0, =(LDM_AREA);")
    print("ldr r1, =REF_AREA;")
    print("bl fill_playg_1_thumb")

    print("mov r0, $%d" % regb)
    print("mov r1, $%d" % regl)
    print("ldr r2, =REF_AREA")
    print("bl emulate_thumb_ldmia")    # Emulation code

    # Setup registers, initial state
    print("bl setup_thumb_regs_ldm;")
    ienc = 0xC800 | regl | (regb << 8)
    print(".word 0x46c0%04x  // ldmia r%d!, {%s};" % (ienc, regb, reglist(regl)))
    print("validate_thumb_ldm_regs(%d, %d);" % (regb, regl))
    print(".pool")
    print("1:")

print("ldr r1, [sp]; bx r1")


print(".thumb")
print(".thumb_func")
print("thumb_st_tests:")

print("mov r0, lr; str r0, [sp]")

for regb in range(8):
  for regl in range(1, 256):   # Empty reglist is undefined!
    # Prepare mem area for the store
    print("word_copy_fast64_thumb(stm_table, STM_AREA);")

    # Fill register space
    print("ldr r0, =STM_AREA;")
    print("ldr r1, =STM_A_REGS;")
    print("bl fill_playg_1_thumb")

    print("mov r0, $%d" % regb)
    print("mov r1, $%d" % regl)
    print("ldr r2, =STM_A_REGS")
    print("bl emulate_thumb_stmia")

    print("word_copy_fast64_thumb(STM_AREA, REF_AREA);")  # Copy the result to the ref area for later check

    print("word_copy_fast64_thumb(stm_table, STM_AREA);")  # Re-init the areas again, for the new execution

    # Setup registers, initial state
    print("bl setup_thumb_regs_stm;")
    ienc = 0xC000 | regl | (regb << 8)
    print(".word 0x46c0%04x  // stmia r%d!, {%s};" % (ienc, regb, reglist(regl)))
    print("validate_thumb_stm(%d, %d);" % (regb, regl))
    print(".pool")
    print("1:")

print("ldr r1, [sp]; bx r1")


