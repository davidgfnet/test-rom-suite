
This test ROM performs some tests on the memory instructions of the GBA CPU
to verify the behaviour of the memory subsystem. Since each memory bank has
a slightly different behaviour (depending on whether they have a 16 bit bus,
or whether they allow byte writes, their mirroring schemes, etc) it is
important to verify that these small quirks are well emulated.

The following behaviours are tested:

 * Unaligned memory operations, particularly:
     * Unaligned loads must rotate operand
     * Unaligned signed 16 bit load does sign extend the MSB byte
     * Unaligned stores ignore the LSB
 * Memory mirrors:
     * Check that mirrors do work at the right boundary
     * VRAM last bank mirror is not tested (its behaviour depends on PPU mode)
 * Bus size mismatches:
     * Palette byte writes perform 16 bit writes (with replicated byte value)

