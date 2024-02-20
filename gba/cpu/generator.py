
# We generate a test for every instruction type (data processing)
# with every possible mode (set flag and don't set flag), CPSR
# flags, a variety of interesting inputs (zero, negative...), and also
# every possible shift operation and interesting operand value.

import random, math, sys

def ror32(val, sa):
  sa = sa << 1
  return ((val >> sa) | (val << (32 - sa))) & 0xffffffff

def op2ror(val, sa, cpsr0):
  res = ror32(val, sa)
  c = (cpsr0 >> 29) & 1
  if sa != 0:
    c = (val >> (sa*2-1)) & 1
  return (res, (cpsr & 0xD0000000) | (c << 29))

## ARM emulation bits ##

def _cpsr(n, z, c, v):
  return (((1 if n else 0) << 31) | ((1 if z else 0) << 30) | ((1 if c else 0) << 29) | ((1 if v else 0) << 28))

def _cpsrlo(res, cpsr):
  z = 1 if res == 0 else 0
  n = 1 if res & 0x80000000 else 0
  return ((cpsr & 0x30000000) | ((1 if n else 0) << 31) | ((1 if z else 0) << 30))

# Immediate Op2. Can only really affect carry flag
def oplsr_imm(op, imm, cpsr0):
  if imm == 0:
    r = 0
    c = (op >> 31) & 1
  else:
    r = op >> imm
    c = (op >> (imm-1)) & 1
  return (r, _cpsr(cpsr0 & 0x80000000, cpsr0 & 0x40000000, c, cpsr0 & 0x10000000))

def oplsl_imm(op, imm, cpsr0):
  return oplsl(op, imm, cpsr0)

def opasr_imm(op, imm, cpsr0):
  if imm == 0:
    imm = 32
  for i in range(imm):
    c = op & 1
    op = (op >> 1) | (op & 0x80000000)
  return (op, _cpsr(cpsr0 & 0x80000000, cpsr0 & 0x40000000, c, cpsr0 & 0x10000000))

def opror_imm(op, imm, cpsr0):
  if imm == 0:
    c0 = (cpsr0 >> 29) & 1
    r = (op >> 1) | (c0 << 31)
    c = op & 1
  else:
    r = ((op >> imm) | (op << (32-imm))) & 0xffffffff
    c = (op >> (imm-1)) & 1

  return (r, _cpsr(cpsr0 & 0x80000000, cpsr0 & 0x40000000, c, cpsr0 & 0x10000000))



def oplsr(a, b, cpsr0):
  r = a >> b
  if b == 0:
    c = (cpsr0 >> 29) & 1
  else:
    c = (a >> (b-1)) & 1
  return (r, _cpsr((r & 0x80000000) != 0, r == 0, c, (cpsr0 >> 28) & 1))

def oplsl(a, b, cpsr0):
  r = (a << b) & 0xffffffff
  if b == 0:
    c = (cpsr0 >> 29) & 1
  else:
    c = 1 if (a << (b-1)) & 0x80000000 else 0
  return (r, _cpsr((r & 0x80000000) != 0, r == 0, c, (cpsr0 >> 28) & 1))

def opasr(a, b, cpsr0):
  if b == 0:
    c = (cpsr0 >> 29) & 1
  else:
    for i in range(b):
      c = a & 1
      a = (a >> 1) | (a & 0x80000000)
  return (a, _cpsr((a & 0x80000000) != 0, a == 0, c, (cpsr0 >> 28) & 1))

def opror(a, b, cpsr0):
  if b == 0:
    c = (cpsr0 >> 29) & 1
  else:
    b = b & 31
    b1 = (b - 1 + 32) & 31
    c = (a >> b1) & 1
  a = ((a >> b) | (a << (32-b))) & 0xffffffff
  return (a, _cpsr((a & 0x80000000) != 0, a == 0, c, (cpsr0 >> 28) & 1))

def arm_and(a, b, cpsr0): return (a & b, cpsr0)
def arm_orr(a, b, cpsr0): return (a | b, cpsr0)
def arm_eor(a, b, cpsr0): return (a ^ b, cpsr0)
def arm_bic(a, b, cpsr0): return (a & ~b, cpsr0)

def arm_ands(a, b, cpsr0): r = a &  b; return (r, _cpsrlo(r, cpsr0))
def arm_orrs(a, b, cpsr0): r = a |  b; return (r, _cpsrlo(r, cpsr0))
def arm_eors(a, b, cpsr0): r = a ^  b; return (r, _cpsrlo(r, cpsr0))
def arm_bics(a, b, cpsr0): r = a & ~b; return (r, _cpsrlo(r, cpsr0))

def arm_add(a, b, cpsr0):
  r = (a + b) & 0xffffffff
  return (r, cpsr0)

def arm_adds(a, b, cpsr0):
  rf = (a + b)
  r = rf & 0xffffffff
  v = (((a ^ r) & (~a ^ b)) >> 31) == 1
  return (r, _cpsr((r & 0x80000000) != 0, r == 0, rf >= 0x100000000, v))

def arm_adc(a, b, cpsr0):
  r = (a + b + ((cpsr0 >> 29) & 1)) & 0xffffffff
  return (r, cpsr0)

def arm_adcs(a, b, cpsr0):
  rf = (a + b + ((cpsr0 >> 29) & 1))
  r = rf & 0xffffffff
  v = (((a ^ r) & (~a ^ b)) >> 31) == 1
  return (r, _cpsr((r & 0x80000000) != 0, r == 0, rf >= 0x100000000, v))

def arm_sub(a, b, cpsr0):
  r = (a + ~b + 1) & 0xffffffff
  return (r, cpsr0)

def arm_subs(a, b, cpsr0):
  r = (a + ~b + 1) & 0xffffffff
  v = (((a ^ b) & (~b ^ r)) >> 31)
  return (r, _cpsr((r & 0x80000000) != 0, r == 0, 1 if b <= a else 0, v))

def arm_sbc(a, b, cpsr0):
  r = (a + ~b + ((cpsr0 >> 29) & 1)) & 0xffffffff
  return (r, cpsr0)

def arm_sbcs(a, b, cpsr0):
  c = ((cpsr0 >> 29) & 1)
  r = (a + ~b + c) & 0xffffffff
  v = (((a ^ b) & (~b ^ r)) >> 31)
  return (r, _cpsr((r & 0x80000000) != 0, r == 0, 1 if b+1-c <= a else 0, v))

def arm_rsb(a, b, cpsr0): return arm_sub(b, a, cpsr0)
def arm_rsbs(a, b, cpsr0): return arm_subs(b, a, cpsr0)
def arm_rsc(a, b, cpsr0): return arm_sbc(b, a, cpsr0)
def arm_rscs(a, b, cpsr0): return arm_sbcs(b, a, cpsr0)

def arm_cmp(a, b, cpsr0):
  r = (a + ~b + 1) & 0xffffffff
  v = (((a ^ b) & (~b ^ r)) >> 31)
  return _cpsr((r & 0x80000000) != 0, r == 0, 1 if b <= a else 0, v)

def arm_cmn(a, b, cpsr0):
  rf = (a + b)
  r = rf & 0xffffffff
  v = (((a ^ r) & (~a ^ b)) >> 31) == 1
  return _cpsr((r & 0x80000000) != 0, r == 0, rf >= 0x100000000, v)

def arm_tst(a, b, cpsr0):
  r = a & b
  return _cpsrlo(r, cpsr0)

def arm_teq(a, b, cpsr0):
  r = a ^ b
  return _cpsrlo(r, cpsr0)

def arm_mov(a, cpsr0):  return (a, cpsr0)
def arm_mvn(a, cpsr0):  a = (~a) & 0xffffffff; return (a, cpsr0)
def arm_neg(a, cpsr0):  return arm_sub(0, a, cpsr0)
def arm_movs(a, cpsr0): return (a, _cpsrlo(a, cpsr0))
def arm_mvns(a, cpsr0): a = (~a) & 0xffffffff; return (a, _cpsrlo(a, cpsr0))
def arm_negs(a, cpsr0): return arm_subs(0, a, cpsr0)

def arm_mul(a, b, cpsr0): return ((a * b) & 0xffffffff, cpsr0)
def arm_muls(a, b, cpsr0):
  r = (a * b) & 0xffffffff
  return (r, _cpsrlo(r, cpsr0))

def arm_mla(a, b, c, cpsr0): return ((a * b + c) & 0xffffffff, cpsr0)
def arm_mlas(a, b, c, cpsr0):
  r = (a * b + c) & 0xffffffff
  return (r, _cpsrlo(r, cpsr0))

def arm_umull(a, b, cpsr0):
  r = (a * b)
  rhi = (r >> 32) & 0xffffffff
  rlo = (r      ) & 0xffffffff
  return (rlo, rhi, cpsr0)

def arm_umulls(a, b, cpsr0):
  r = (a * b)
  rhi = (r >> 32) & 0xffffffff
  rlo = (r      ) & 0xffffffff
  return (rlo, rhi, (cpsr & 0x30000000) | ((1 if rhi & 0x80000000 else 0) << 31) | ((1 if r == 0 else 0) << 30))

def arm_smull(a, b, cpsr0):
  sa = a >> 31; sb = b >> 31;
  if sa: a = ((~a) + 1) & 0xffffffff
  if sb: b = ((~b) + 1) & 0xffffffff
  r = (a * b)
  if sa ^ sb: r = ((~r) + 1) & 0xffffffffffffffff
  rhi = (r >> 32) & 0xffffffff
  rlo = (r      ) & 0xffffffff
  return (rlo, rhi, cpsr0)

def arm_smulls(a, b, cpsr0):
  rlo, rhi, _ = arm_smull(a, b, cpsr0)
  return (rlo, rhi, (cpsr & 0x30000000) | ((1 if rhi & 0x80000000 else 0) << 31) | ((1 if (rlo|rhi) == 0 else 0) << 30))

def genInterestingShifts():
  return [0, 1, 2, 30, 31, 32, 33, 34]

def genInterestingShifts15():
  return [0, 1, 14, 15, 16, 29, 30, 31]

def genInterestingImm12():
  for sa in range(16):
    for imm8 in [0x55, 0x0, 0xFF, 0x7E, 0x7F, 0x80, 0xFE, 0xAA]:
      yield (sa, imm8)

def genInterestingRandom(it=1):
  yield 0
  yield 1
  yield 2
  yield 0xFFFFFFFF
  yield 0xFFFFFFFE
  yield 0xFFFFFFFD
  yield 0x7FFFFFFF
  yield 0x7FFFFFFE
  yield 0x80000000
  yield 0x80000001
  yield 0xBFFFFFFF
  yield 0xBFFFFFFE

  for _ in range(it):
    bn = random.randint(0, (1<<32)-1)
    yield bn | 0x80000000
    yield bn & 0x7FFFFFFF
    yield bn & 0x7FFFFFFE
    yield bn & 0xFFFFFFFE

def compress(res_array):
  rcode, rword = [], []
  for elem in res_array:
    if elem in rword[-255:]:
      rcode.append(len(rword[-255:]) - rword[-255:].index(elem))
    else:
      rcode.append(0)
      rword.append(elem)
  return (rcode, rword)

# Reg alloc:
# r0-r2 Input operands
# r3-r4 Outputs
# r5 Output CPSR
# r6 Input CPSR
# r7 temporary reg + return error code
# r8 Decompressor table pointer
# r9 Expected CPSR value
# r10-r11 Expected outputs
# r12 test counter

class ASMTest(object):
  def __init__(self, test_name, cpsr_input, input_tables,
               cpsrmask=0xF0, checkres=1, thumbmode=False, isimm=False, isimm5=False):
    self._resdata = []
    self._rescpsr = []
    self._test_name = test_name
    self._input_tables = input_tables
    self._casecnt = 0
    self._checkres = checkres
    self._thumbmode = thumbmode
    self._isimm = isimm
    self._isimm5 = isimm5
    self._cpsr_input = cpsr_input
    self._cpsrmask = cpsrmask
    self._datasize = 0
    self._cdatasize = 0
    self.insts = []
    assert not (isimm and isimm5)

  def addInst(self, inst):
    self.insts.append(inst)

  def addTestCase(self, cpsr0, res, cpsrd):
    self._casecnt += 1
    # Annotate results
    if res is not None:
      if isinstance(res, tuple):
        self._resdata.append(res[0])
        self._resdata.append(res[1])
      else:
        self._resdata.append(res)
    self._rescpsr.append(cpsrd >> 24)

  def compression_stats(self):
    return (self._datasize, self._cdatasize)

  def finalize(self, tc, ttotal):
    insts = []

    # Test prologue, setup pointers and counters
    insts.append(".align 4")
    insts.append(".arm")
    insts.append("%s:" % self._test_name)
    insts.append("push {lr}")
    insts.append("progress_bar(%d)" % ((tc*30)//ttotal))
    insts.append("ldr r8, =%s_resdata_words" % (self._test_name))
    insts.append("mov r12, $0")

    # We copy the following function to IWRAM for speed (<200 bytes!)
    insts.append("ldr r0, =0x03000100")
    insts.append("ldr r1, =1f")
    insts.append("mov r2, $(11f - 1f)")
    insts.append("3:")
    insts.append("ldr r3, [r1], #4")
    insts.append("str r3, [r0], #4")
    insts.append("subs r2, r2, $4")
    insts.append("bhs 3b")
    insts.append("ldr r0, =0x03000100")
    insts.append("bx r0")

    insts.append("1:")
    # Load inputs and expected ouputs
    insts.append("ldr r7, =%s_rescpsr" % self._test_name)
    insts.append("ldrb r9, [r7, r12]")  # expected CPSR
    insts.append("lsl r9, r9, $24")
    insts.append("and r9, r9, $((0x%x) << 24)" % self._cpsrmask)

    # Results loaded in r10 and r11
    for i in range(self._checkres):
      insts.append("ldr r7, =(%s_resdata + %d)" % (self._test_name, i))
      insts.append("ldrb r7, [r7, r12, lsl #%d]" % (self._checkres-1))
      insts.append("cmp r7, $0")
      insts.append("ldr r%d, [r8, -r7, lsl #2]" % (i+10))
      insts.append("addeq r8, r8, $4")

    # Initial CPSR value in r6
    insts.append("and r6, r12, $0xf")
    insts.append("ldr r7, =%s" % self._cpsr_input)
    insts.append("ldr r6, [r7, r6, lsl #2]")
    insts.append("msr cpsr_f, r6")

    ashift = 4
    # Operands loaded in r0, r1 and r2
    for i, tblidx in enumerate(self._input_tables):
      isize = len(input_table[tblidx])
      szlg = int(math.log2(isize))
      assert isize & (isize-1) == 0
      insts.append("ldr r7, =operand_table_%d" % tblidx)
      insts.append("lsr r%d, r12, $%d" % (i, ashift))
      insts.append("and r%d, r%d, $0x%x" % (i, i, isize-1))
      insts.append("ldr r%d, [r7, r%d, lsl #2]" % (i, i))
      ashift += szlg

    # Load instruction addr to jump to it
    insts.append("ldr r7, =55f")

    if self._isimm:
      # Copy the instructions to IWRAM, then patch them too
      insts.append("mov r5, $0x03000000")
      insts.append("ldr r3, [r7], #4")
      insts.append("bic r3, r3, $0xff")   # Only the 8 LSB are non-zero
      insts.append("orr r3, r3, r1")
      insts.append("str r3, [r5], #4")
      insts.append("ldr r3, [r7], #4")    # Copy any return instruction
      insts.append("str r3, [r5], #4")
      insts.append("mov r7, $0x03000000")
    elif self._isimm5:
      insts.append("mov r5, $0x03000000")
      insts.append("ldr r3, [r7], #4")
      insts.append("bic r3, r3, $0xF80")   # Imm5 goes in bits [11..7]
      insts.append("orr r3, r3, r2, lsl #7")
      insts.append("str r3, [r5], #4")
      insts.append("ldr r3, [r7], #4")    # Copy any return instruction
      insts.append("str r3, [r5], #4")
      insts.append("mov r7, $0x03000000")

    if self._thumbmode:
      insts.append("mov r3, r0")      # Only two operands!
      insts.append("orr r7, r7, $1")  # Ensure we go thumb

    # Execution resumes after the BX, with checks
    insts.append("mov lr, pc")
    insts.append("bx r7")
    insts.append("mrs r5, CPSR")
    insts.append("and r5, $((0x%x) << 24)" % self._cpsrmask)

    insts.append("mov r7, $1")     # Assume error
    for i in range(self._checkres):
      insts.append("cmp r%d, r%d" % (3+i, 10+i))
      insts.append("popne {pc}")
    insts.append("cmp r5, r9")
    insts.append("popne {pc}")

    insts.append("add r12, r12, $1")
    insts.append("ldr r7, =%d" % self._casecnt)
    insts.append("cmp r7, r12")
    insts.append("bne 1b")

    insts.append("mov r7, $0")   # No error
    insts.append("pop {pc}")

    # Here comes the actual instruction test stub
    if self.insts:
      insts.append(".thumb" if self._thumbmode else ".arm")
      insts.append("55:")
      insts += self.insts
      insts.append("bx lr")    # Valid in both arm and thumb

    insts.append(".pool\n")
    insts.append("11:\n")

    insts.append(".align 4\n")
    bcodes, words = compress(self._resdata)
    self._datasize = 4 * len(self._resdata)
    self._cdatasize = len(bcodes) + 4 * len(words)
    insts.append("%s_resdata_words:" % self._test_name)
    for i in range(0, len(words), 8):
      insts.append(".word " + ",".join("0x%x" % x for x in words[i:i+8]))
    insts.append("%s_resdata:" % self._test_name)
    for i in range(0, len(bcodes), 16):
      insts.append(".byte " + ",".join("%d" % x for x in bcodes[i:i+16]))
    insts.append("%s_rescpsr:" % self._test_name)
    for i in range(0, len(self._rescpsr), 16):
      insts.append(".byte " + ",".join("%d" % self._rescpsr[i+j] for j in range(16)))
    insts.append(".align 4\n")
    return "# Test case begin\n" + "\n".join(insts) + "\n"

# Generate pseudo-random inputs tables
print(".align 4")
print("allcpsr:")
allcpsr = [i << 28 for i in range(16)]
for cpsr in allcpsr:
  print(".word 0x%x" % cpsr)

input_table = []
for i in range(4):
  input_table.append([])
  print("operand_table_%d:" % i)
  for op in genInterestingRandom(5):
    input_table[i].append(op)
    print(".word 0x%x" % op)

input_table.append([])
print("operand_table_4:")
for op in genInterestingShifts():
  input_table[4].append(op)
  print(".word 0x%x" % op)

input_table.append([])
print("operand_table_5:")
for op in genInterestingImm12():
  input_table[5].append(op)
  print(".word 0x%x   @ 0x%x" % ((op[0] << 8) | op[1], ror32(op[1], op[0])))

input_table.append([])
print("operand_table_6:")
for op in genInterestingShifts15():
  input_table[6].append(op)
  print(".word 0x%x" % op)

alltests = []


# Thumb mode tests

if "thumb" in sys.argv[1:]:
  for op, fnop in [ ("cmp", arm_cmp), ("cmn", arm_cmn), ("tst", arm_tst) ]:
    t = ASMTest("thtest_" + op, "allcpsr", [0, 1], thumbmode=True, checkres=0)
    t.addInst(" %s r3, r1" % op)
    for opB in input_table[1]:
      for opA in input_table[0]:
        for cpsr in allcpsr:
          cpsrres = fnop(opA, opB, cpsr)
          t.addTestCase(cpsr, None, cpsrres)
    alltests.append(t)

  for op, fnop in [("mvn", arm_mvns), ("neg", arm_negs)]:
    t = ASMTest("thtest_" + op, "allcpsr", [4], thumbmode=True)
    t.addInst(" %s r3, r0" % op)
    for opA in input_table[4]:
      for cpsr in allcpsr:
        res, cpsrres = fnop(opA, cpsr)
        t.addTestCase(cpsr, res, cpsrres)
    alltests.append(t)

  for op, fnop in [("lsr", oplsr), ("lsl", oplsl), ("asr", opasr), ("ror", opror)]:
    t = ASMTest("thtest_" + op, "allcpsr", [0, 4], thumbmode=True)
    t.addInst(" %s r3, r1" % op)
    for opB in input_table[4]:
      for opA in input_table[0]:
        for cpsr in allcpsr:
          res, cpsrres = fnop(opA, opB, cpsr)
          t.addTestCase(cpsr, res, cpsrres)
    alltests.append(t)

  for op, fnop in [
    ("add", arm_adds), ("sub", arm_subs), ("adc", arm_adcs), ("sbc", arm_sbcs),
    ("and", arm_ands), ("orr", arm_orrs), ("eor", arm_eors), ("bic", arm_bics),
    ("mul", arm_muls),
  ]:
    cpsrmask = 0xC0 if op == "mul" else 0xF0
    t = ASMTest("thtest_" + op, "allcpsr", [0, 1], thumbmode=True, cpsrmask=cpsrmask)
    t.addInst(" %s r3, r1" % op)
    for opB in input_table[1]:
      for opA in input_table[0]:
        for cpsr in allcpsr:
          res, cpsrres = fnop(opA, opB, cpsr)
          t.addTestCase(cpsr, res, cpsrres)
    alltests.append(t)

# ARM mode tests

# Immediate mode (12 bit)
if "arm_imm" in sys.argv[1:]:
  for op, fnop, rorflg in [
    ("tst", arm_tst, True),  ("teq", arm_teq, True),
    ("cmp", arm_cmp, False), ("cmn", arm_cmn, False),
  ]:
    t = ASMTest("test_imm_" + op, "allcpsr", [0, 5], isimm=True, checkres=0)
    t.addInst(" %s r0, $0x55" % op)
    for opB in input_table[5]:
      for opA in input_table[0]:
        for cpsr in allcpsr:
          opBval, cpsr1 = op2ror(opB[1], opB[0], cpsr)
          cpsrres = fnop(opA, opBval, cpsr1 if rorflg else cpsr)
          t.addTestCase(cpsr, None, cpsrres)
    alltests.append(t)

  for op, fnop, updflag in [
    ("tst", arm_tst, True),  ("teq", arm_teq, True),
    ("cmp", arm_cmp, False), ("cmn", arm_cmn, False),
  ]:
    for op2, fnop2 in [("lsr", oplsr_imm), ("lsl", oplsl_imm), ("asr", opasr_imm), ("ror", opror_imm)]:
      t = ASMTest("test_imm_" + op + "_" + op2, "allcpsr", [0, 1, 6], isimm5=True, checkres=0)
      t.addInst(" %s r0, r1, %s $0x5" % (op, op2))
      for opC in input_table[6]:
        for opB in input_table[1]:
          for opA in input_table[0]:
            for cpsr in allcpsr:
              operand2, cpsrint = fnop2(opB, opC, cpsr)
              cpsrres = fnop(opA, operand2, cpsrint if updflag else cpsr)
              t.addTestCase(cpsr, None, cpsrres)
      alltests.append(t)

  for op, fnop, rorflg in [
    ("and", arm_and, False), ("ands", arm_ands, True),
    ("orr", arm_orr, False), ("orrs", arm_orrs, True),
    ("eor", arm_eor, False), ("eors", arm_eors, True),
    ("bic", arm_bic, False), ("bics", arm_bics, True),
    ("add", arm_add, False), ("adds", arm_adds, False),
    ("adc", arm_adc, False), ("adcs", arm_adcs, False),
    ("sub", arm_sub, False), ("subs", arm_subs, False),
    ("sbc", arm_sbc, False), ("sbcs", arm_sbcs, False),
    ("rsb", arm_rsb, False), ("rsbs", arm_rsbs, False),
    ("rsc", arm_rsc, False), ("rscs", arm_rscs, False),
  ]:
    t = ASMTest("test_imm_" + op, "allcpsr", [0, 5], isimm=True)
    t.addInst(" %s r3, r0, $0x55" % op)
    for opB in input_table[5]:
      for opA in input_table[0]:
        for cpsr in allcpsr:
          opBval, cpsr1 = op2ror(opB[1], opB[0], cpsr)
          res, cpsrres = fnop(opA, opBval, cpsr1 if rorflg else cpsr)
          t.addTestCase(cpsr, res, cpsrres)
    alltests.append(t)

  for op, fnop, updflag in [
    ("and", arm_and, False), ("ands", arm_ands, True),
    ("orr", arm_orr, False), ("orrs", arm_orrs, True),
    ("eor", arm_eor, False), ("eors", arm_eors, True),
    ("bic", arm_bic, False), ("bics", arm_bics, True),

    ("add", arm_add, False), ("adds", arm_adds, False),
    ("sub", arm_sub, False), ("subs", arm_subs, False),
    ("adc", arm_adc, False), ("adcs", arm_adcs, False),
    ("sbc", arm_sbc, False), ("sbcs", arm_sbcs, False),
    ("rsb", arm_rsb, False), ("rsbs", arm_rsbs, False),
    ("rsc", arm_rsc, False), ("rscs", arm_rscs, False),
  ]:
    for op2, fnop2 in [("lsr", oplsr_imm), ("lsl", oplsl_imm), ("asr", opasr_imm), ("ror", opror_imm)]:
      t = ASMTest("test_imm_" + op + "_" + op2, "allcpsr", [0, 1, 6], isimm5=True)
      t.addInst(" %s r3, r0, r1, %s $0x5" % (op, op2))
      for opC in input_table[6]:
        for opB in input_table[1]:
          for opA in input_table[0]:
            for cpsr in allcpsr:
              operand2, cpsrint = fnop2(opB, opC, cpsr)
              res, cpsrres = fnop(opA, operand2, cpsrint if updflag else cpsr)
              t.addTestCase(cpsr, res, cpsrres)
      alltests.append(t)

if "arm_reg" in sys.argv[1:]:
  for op, fnop, upflg in [
    ("lsr", oplsr, False), ("lsrs", oplsr, True),
    ("lsl", oplsl, False), ("lsls", oplsl, True),
    ("asr", opasr, False), ("asrs", opasr, True),
    ("ror", opror, False), ("rors", opror, True),
  ]:
    t = ASMTest("test_" + op, "allcpsr", [0, 4])
    t.addInst(" %s r3, r0, r1" % op)
    for opB in input_table[4]:
      for opA in input_table[0]:
        for cpsr in allcpsr:
          res, cpsrres = fnop(opA, opB, cpsr)
          t.addTestCase(cpsr, res, cpsrres if upflg else cpsr)
    alltests.append(t)

  for op, fnop in [
    ("mov", arm_mov), ("movs", arm_movs),
    ("mvn", arm_mvn), ("mvns", arm_mvns),
  ]:
    t = ASMTest("test_" + op, "allcpsr", [4])
    t.addInst(" %s r3, r0" % op)
    for opA in input_table[4]:
      for cpsr in allcpsr:
        res, cpsrres = fnop(opA, cpsr)
        t.addTestCase(cpsr, res, cpsrres)
    alltests.append(t)

  for op, fnop in [
    ("and", arm_and), ("ands", arm_ands),
    ("orr", arm_orr), ("orrs", arm_orrs),
    ("eor", arm_eor), ("eors", arm_eors),
    ("bic", arm_bic), ("bics", arm_bics),
    ("add", arm_add), ("adds", arm_adds),
    ("adc", arm_adc), ("adcs", arm_adcs),
    ("sub", arm_sub), ("subs", arm_subs),
    ("sbc", arm_sbc), ("sbcs", arm_sbcs),
    ("rsb", arm_rsb), ("rsbs", arm_rsbs),
    ("rsc", arm_rsc), ("rscs", arm_rscs),
    ("mul", arm_mul), ("muls", arm_muls),
  ]:
    cpsrmask = 0xC0 if op[:3] == "mul" else 0xF0
    t = ASMTest("test_" + op, "allcpsr", [0, 1], cpsrmask=cpsrmask)
    t.addInst(" %s r3, r0, r1" % op)
    for opB in input_table[1]:
      for opA in input_table[0]:
        for cpsr in allcpsr:
          res, cpsrres = fnop(opA, opB, cpsr)
          t.addTestCase(cpsr, res, cpsrres)
    alltests.append(t)

  for op, fnop in [
    ("umull", arm_umull), ("umulls", arm_umulls),
    ("smull", arm_smull), ("smulls", arm_smulls),
  ]:
    t = ASMTest("test_" + op, "allcpsr", [0, 1], checkres=2, cpsrmask=0xC0)
    t.addInst(" %s r3, r4, r0, r1" % op)
    for opB in input_table[1]:
      for opA in input_table[0]:
        for cpsr in allcpsr:
          reslo, reshi, cpsrres = fnop(opA, opB, cpsr)
          t.addTestCase(cpsr, (reslo, reshi), cpsrres)
    alltests.append(t)

  for op, fnop in [
    ("mla", arm_mla), ("mlas", arm_mlas),
  ]:
    t = ASMTest("test_" + op, "allcpsr", [0, 1, 2], cpsrmask=0xC0)
    t.addInst(" %s r3, r0, r1, r2" % op)
    for opC in input_table[2]:
      for opB in input_table[1]:
        for opA in input_table[0]:
          for cpsr in allcpsr:
            res, cpsrres = fnop(opA, opB, opC, cpsr)
            t.addTestCase(cpsr, res, cpsrres)
    alltests.append(t)

  for op, fnop, updflag in [
    ("and", arm_and, False), ("ands", arm_ands, True),
    ("orr", arm_orr, False), ("orrs", arm_orrs, True),
    ("eor", arm_eor, False), ("eors", arm_eors, True),
    ("bic", arm_bic, False), ("bics", arm_bics, True),

    ("add", arm_add, False), ("adds", arm_adds, False),
    ("sub", arm_sub, False), ("subs", arm_subs, False),
    ("adc", arm_adc, False), ("adcs", arm_adcs, False),
    ("sbc", arm_sbc, False), ("sbcs", arm_sbcs, False),
    ("rsb", arm_rsb, False), ("rsbs", arm_rsbs, False),
    ("rsc", arm_rsc, False), ("rscs", arm_rscs, False),
  ]:
    for op2, fnop2 in [("lsr", oplsr), ("lsl", oplsl), ("asr", opasr), ("ror", opror)]:
      t = ASMTest("test_" + op + "_" + op2, "allcpsr", [0, 1, 4])
      t.addInst(" %s r3, r0, r1, %s r2" % (op, op2))
      for opC in input_table[4]:
        for opB in input_table[1]:
          for opA in input_table[0]:
            for cpsr in allcpsr:
              operand2, cpsrint = fnop2(opB, opC, cpsr)
              res, cpsrres = fnop(opA, operand2, cpsrint if updflag else cpsr)
              t.addTestCase(cpsr, res, cpsrres)
      alltests.append(t)

  for op, fnop, upflg in [
    ("mov", arm_mov, False), ("movs", arm_movs, True),
    ("mvn", arm_mvn, False), ("mvns", arm_mvns, True),
  ]:
    for op2, fnop2 in [("lsr", oplsr), ("lsl", oplsl), ("asr", opasr), ("ror", opror)]:
      t = ASMTest("test_" + op + "_" + op2, "allcpsr", [0, 4])
      t.addInst(" %s r3, r0, %s r1" % (op, op2))
      for opB in input_table[4]:
        for opA in input_table[0]:
          for cpsr in allcpsr:
            operand2, cpsrint = fnop2(opA, opB, cpsr)
            res, cpsrres = fnop(operand2, cpsrint if upflg else cpsr)
            t.addTestCase(cpsr, res, cpsrres)
      alltests.append(t)

  for op, fnop, updflag in [
    ("cmp", arm_cmp, False),
    ("cmn", arm_cmn, False),
    ("tst", arm_tst, True),
    ("teq", arm_teq, True),
  ]:
    for op2, fnop2 in [("lsr", oplsr), ("lsl", oplsl), ("asr", opasr), ("ror", opror)]:
      t = ASMTest("test_" + op + "_" + op2, "allcpsr", [0, 1, 4], checkres=0)
      t.addInst(" %s r0, r1, %s r2" % (op, op2))
      for opC in input_table[4]:
        for opB in input_table[1]:
          for opA in input_table[0]:
            for cpsr in allcpsr:
              operand2, cpsrint = fnop2(opB, opC, cpsr)
              cpsrres = fnop(opA, operand2, cpsrint if updflag else cpsr)
              t.addTestCase(cpsr, None, cpsrres)
      alltests.append(t)

totcnt = sum(t._casecnt for t in alltests)
print("@ Total number of tests: %d" % totcnt)

tdatasize, tcdatasize = 0, 0
tcount = 0
for t in alltests:
  print("@ Case num %d" % tcount)
  print(t.finalize(tcount, totcnt))
  tcount += t._casecnt
  # Calculate compression stats
  s = t.compression_stats()
  tdatasize += s[0]
  tcdatasize += s[1]

print('Test data size: %d bytes, compressed: %d bytes (%f%% size)' % (tdatasize, tcdatasize, (100 * tcdatasize) / tdatasize), file=sys.stderr)

