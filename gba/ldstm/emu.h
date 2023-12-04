
#ifdef __cplusplus
  extern "C" {
#endif

unsigned emulate_ldm_pre_up_wb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_ldm_pre_up_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_ldm_pre_down_wb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_ldm_pre_down_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_ldm_post_up_wb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_ldm_post_up_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_ldm_post_down_wb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_ldm_post_down_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues);

unsigned emulate_stm_pre_up_wb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_stm_pre_up_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_stm_pre_down_wb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_stm_pre_down_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_stm_post_up_wb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_stm_post_up_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_stm_post_down_wb(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_stm_post_down_nwb(unsigned basereg, unsigned reglist, unsigned *regvalues);

unsigned emulate_thumb_ldmia(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_thumb_pop(unsigned reglist, unsigned *regvalues);

unsigned emulate_thumb_stmia(unsigned basereg, unsigned reglist, unsigned *regvalues);
unsigned emulate_thumb_push(unsigned reglist, unsigned *regvalues);


#ifdef __cplusplus
  }
#endif


