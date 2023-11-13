
# We generate a test for every (or most) LDM/STM instruction with valid
# inputs and expected outputs. Reference data is compressed due to size
# requirements.

import random, math

def genRandValue():
  return random.randint(0, (1<<32)-1)

# Generate data tables for tests
print(".align 4")
print("ldm_table:")
for _ in range(32*16):
  print("  .word 0x%08x" % genRandValue())
print("ldm_table_end:")

print("stm_table:")
for _ in range(32*16):
  print("  .word 0x%08x" % genRandValue())
print("stm_table_end:")


