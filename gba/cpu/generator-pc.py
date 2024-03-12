
# Generate a bunch of tests that use PC as a source value
# to validate the right PC offset is used.

import random, math, sys

RNDI = [ 0xDEADBEEF, 0x01020304, 0xABCDDCBA ]

def gentest(tname, inst, result, pc_loc=0x03000000):
  result &= 0xFFFFFFFF
  insts = []
  insts.append("test_%s:" % tname)
  insts.append("push {lr}")
  # We place the instruction in the pc_loc, and execute it there
  insts.append("ldr r3, =0x%08x" % pc_loc)
  insts.append("ldr r4, =(1f)")
  insts.append("ldr r0, [r4]")
  insts.append("str r0, [r3]")
  insts.append("ldr r0, [r4, #4]")
  insts.append("str r0, [r3, #4]")
  # Initialize registers
  insts.append("mov r0, $0")
  insts.append("msr cpsr_f, r0")
  insts.append("ldr r0, =0x%08x" % RNDI[0])
  insts.append("ldr r1, =0x%08x" % RNDI[1])
  insts.append("ldr r2, =0x%08x" % RNDI[2])
  insts.append("mov r4, $0")
  insts.append("mov r12, $0")
  # Execute the instruction
  insts.append("mov lr, pc")
  insts.append("bx r3")

  insts.append("mov r7, $0")
  if result is not None:
    insts.append("ldr r10, =0x%08x" % result)
    insts.append("cmp r3, r10")
    insts.append("movne r7, $1")

  insts.append("pop {pc}")
  insts.append("1:")  # Instruction + return code
  insts.append(inst)
  insts.append("bx lr")
  insts.append(".pool")
  return insts

DEFPC = 0x03000000

TESTS = [
  ("mov_pc",           "mov r3, pc",     DEFPC + 8),
  ("movs_pc",          "movs r3, pc",    DEFPC + 8),
  ("add_r0_pc",        "add r3, r0, pc", DEFPC + 8 + RNDI[0]),
  ("add_pc_r0",        "add r3, pc, r0", DEFPC + 8 + RNDI[0]),
  ("sub_r0_pc",        "sub r3, r0, pc", RNDI[0] - (DEFPC + 8)),
  ("sub_pc_r0",        "sub r3, pc, r0", DEFPC + 8 - RNDI[0]),
  ("add_pc_imm",       "add r3, pc, $0x3C0", DEFPC + 8 + 0x3C0),
  ("and_pc_imm",       "and r3, pc, $0x02000000", (DEFPC + 8) & 0x02000000),
  ("orr_pc_imm",       "orr r3, pc, $0x00088000", (DEFPC + 8) | 0x00088000),
  ("eor_pc_imm",       "eor r3, pc, $0x02000000", (DEFPC + 8) ^ 0x02000000),
]

def ror32(n, a):
  a &= 0x1f
  return ((n << (32 - a)) | (n >> a)) & 0xffffffff

def asr32(n, a):
  a = min(a & 0xff, 32)
  if n & 0x80000000:
    m = (1 << a) - 1
    return (n >> a) | (m << (32-a))
  else:
    return n >> a

for opn, opl in [
  ("and", lambda x, y: x & y),
  ("orr", lambda x, y: x | y),
  ("eor", lambda x, y: x ^ y),
  ("bic", lambda x, y: x & ~y),
  ("add", lambda x, y: x + y),
  ("adc", lambda x, y: x + y),   # CF is zero
  ("sub", lambda x, y: x - y),
  ("sbc", lambda x, y: x - y - 1),   # CF is zero
  ("rsb", lambda x, y: y - x),
  ("rsc", lambda x, y: y - x - 1),   # CF is zero
]:
  for subopn, subopl in [
    ("lsl", lambda x, a: x << (a & 0xFF)),
    ("lsr", lambda x, a: x >> (a & 0xFF)),
    ("ror", ror32),
    ("asr", asr32),
  ]:
    # By imm
    for a in range(32):
      TESTS += [
        ("%s_r0_pc_%s%d" % (opn, subopn, a),   "%s r3, r0, pc, %s #%d" % (opn,subopn, a), opl(RNDI[0], subopl(DEFPC + 8, a))),
        ("%s_pc_r0_%s%d" % (opn, subopn, a),   "%s r3, pc, r0, %s #%d" % (opn,subopn, a), opl(DEFPC + 8, subopl(RNDI[0], a))),
        ("%ss_r0_pc_%s%d" % (opn, subopn, a),  "%ss r3, r0, pc, %s #%d" % (opn,subopn, a), opl(RNDI[0], subopl(DEFPC + 8, a))),
        ("%ss_pc_r0_%s%d" % (opn, subopn, a),  "%ss r3, pc, r0, %s #%d" % (opn,subopn, a), opl(DEFPC + 8, subopl(RNDI[0], a))),
      ]
    # By reg
    TESTS += [
      ("%s_r0_pc_%s_r1" % (opn, subopn),   "%s r3, r0, pc, %s r1" % (opn,subopn), opl(RNDI[0], subopl(DEFPC + 12, RNDI[1]))),
      ("%s_pc_r0_%s_r1" % (opn, subopn),   "%s r3, pc, r0, %s r1" % (opn,subopn), opl(DEFPC + 12, subopl(RNDI[0], RNDI[1]))),
      ("%ss_r0_pc_%s_r1" % (opn, subopn),  "%ss r3, r0, pc, %s r1" % (opn,subopn), opl(RNDI[0], subopl(DEFPC + 12, RNDI[1]))),
      ("%ss_pc_r0_%s_r1" % (opn, subopn),  "%ss r3, pc, r0, %s r1" % (opn,subopn), opl(DEFPC + 12, subopl(RNDI[0], RNDI[1]))),
    ]

  # No op2, just register
  TESTS += [
    ("%s_r0_pc_r1" % opn,   "%s r3, r0, pc" % opn, opl(RNDI[0], DEFPC + 8)),
    ("%s_pc_r0_r1" % opn,   "%s r3, pc, r0" % opn, opl(DEFPC + 8, RNDI[0])),
    ("%ss_r0_pc_r1" % opn,  "%ss r3, r0, pc" % opn, opl(RNDI[0], DEFPC + 8)),
    ("%ss_pc_r0_r1" % opn,  "%ss r3, pc, r0" % opn, opl(DEFPC + 8, RNDI[0])),
  ]


print("run_pc_tests:")
print("push {lr}")
for tname, inst, res in TESTS:
  print("run_test(test_%s, \"%s\")" % (tname, inst))
print("pop {pc}")

for tname, inst, res in TESTS:
  print("\n".join(gentest(tname, inst, res)))


