
#include "emu.h"

// Util stuff

inline unsigned popcnt(unsigned short x) {
  static const char bcnt[] = {
    0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8
  };

  return bcnt[x >> 8] + bcnt[x & 0xff];
}

// LDM instruction emulation

inline unsigned emulate_ldm(
  unsigned basereg, unsigned reglist, unsigned *regvalues,
  bool pre_increment, bool base_increment, bool writeback
) {

  // Calcualte base address.
  unsigned numops = popcnt(reglist);
  unsigned base = regvalues[basereg];
  unsigned address = base & ~3U;
  int addr_off = base_increment ? 4 : -4;  // Address incr/decr amount.
  unsigned endaddr = base + addr_off * numops;

  if (writeback)
    regvalues[basereg] = endaddr;

  for (unsigned i = 0; i < 16; i++)  {
    unsigned regnum = base_increment ? i : 15 - i;
    if ((reglist >> regnum) & 0x01) {
      // Update address for pre-update mode.
      if (pre_increment)
        address += addr_off;

      volatile unsigned *memptr = (unsigned *)address;
      regvalues[regnum] = *memptr;

      // Update address for post-update mode.
      if (!pre_increment)
        address += addr_off;
    }
  }

  // Returns the LDM instruction properly encoded.
  return 0xE8100000 | reglist | (basereg << 16) |
         (pre_increment  ? 0x01000000 : 0) |
         (base_increment ? 0x00800000 : 0) |
         (writeback      ? 0x00200000 : 0);
}

// Format emulate_ldm_{pre/post}_{up/down}_{wb/nwb}()  // 1/0
unsigned emulate_ldm_pre_up_wb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_ldm(basereg, reglist, regvalues, true, true, true);
}
unsigned emulate_ldm_pre_up_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_ldm(basereg, reglist, regvalues, true, true, false);
}
unsigned emulate_ldm_pre_down_wb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_ldm(basereg, reglist, regvalues, true, false, true);
}
unsigned emulate_ldm_pre_down_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_ldm(basereg, reglist, regvalues, true, false, false);
}
unsigned emulate_ldm_post_up_wb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_ldm(basereg, reglist, regvalues, false, true, true);
}
unsigned emulate_ldm_post_up_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_ldm(basereg, reglist, regvalues, false, true, false);
}
unsigned emulate_ldm_post_down_wb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_ldm(basereg, reglist, regvalues, false, false, true);
}
unsigned emulate_ldm_post_down_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_ldm(basereg, reglist, regvalues, false, false, false);
}


// STM instruction emulation

inline unsigned emulate_stm(
  unsigned basereg, unsigned reglist, unsigned *regvalues,
  bool pre_increment, bool base_increment, bool writeback
) {

  // Calcualte base address.
  unsigned numops = popcnt(reglist);
  unsigned base = regvalues[basereg];
  unsigned address = base & ~3U;
  int addr_off = base_increment ? 4 : -4;  // Address incr/decr amount.
  unsigned endaddr = base + addr_off * numops;

  // If base is in the reglist and writeback is enabled, the value of the
  // written register depends on the write cycle (ARM7TDM manual 4.11.6).
  // If the register is the first, the written value is the original value,
  // otherwise the update base register is written. For LDM loaded date
  // takes always precendence.
  bool wrbck_base = (1 << basereg) & reglist;
  bool base_first = (((1 << basereg) - 1) & reglist) == 0;
  bool wb_first = !(wrbck_base && base_first);

  if (writeback && wb_first)
    regvalues[basereg] = endaddr;

  for (unsigned i = 0; i < 16; i++)  {
    unsigned regnum = base_increment ? i : 15 - i;
    if ((reglist >> regnum) & 0x01) {
      // Update address for pre-update mode.
      if (pre_increment)
        address += addr_off;

      volatile unsigned *memptr = (unsigned *)address;
      *memptr = regvalues[regnum];

      // Update address for post-update mode.
      if (!pre_increment)
        address += addr_off;
    }
  }

  if (writeback && !wb_first)
    regvalues[basereg] = endaddr;

  // Returns the STM instruction properly encoded.
  return 0xE8000000 | reglist | (basereg << 16) |
         (pre_increment  ? 0x01000000 : 0) |
         (base_increment ? 0x00800000 : 0) |
         (writeback      ? 0x00200000 : 0);
}

// Format emulate_stm_{pre/post}_{up/down}_{wb/nwb}()  // 1/0
unsigned emulate_stm_pre_up_wb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_stm(basereg, reglist, regvalues, true, true, true);
}
unsigned emulate_stm_pre_up_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_stm(basereg, reglist, regvalues, true, true, false);
}
unsigned emulate_stm_pre_down_wb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_stm(basereg, reglist, regvalues, true, false, true);
}
unsigned emulate_stm_pre_down_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_stm(basereg, reglist, regvalues, true, false, false);
}
unsigned emulate_stm_post_up_wb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_stm(basereg, reglist, regvalues, false, true, true);
}
unsigned emulate_stm_post_up_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_stm(basereg, reglist, regvalues, false, true, false);
}
unsigned emulate_stm_post_down_wb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_stm(basereg, reglist, regvalues, false, false, true);
}
unsigned emulate_stm_post_down_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues) {
  return emulate_stm(basereg, reglist, regvalues, false, false, false);
}





