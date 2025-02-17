

void arm_ldm_fmt(char *out, unsigned base_reg, unsigned mode, unsigned mask);
void arm_stm_fmt(char *out, unsigned base_reg, unsigned mode, unsigned mask);
void thumb_ldm_fmt(char *out, unsigned base_reg, unsigned mode, unsigned mask);
void thumb_stm_fmt(char *out, unsigned base_reg, unsigned mode, unsigned mask);

void reg_err_fmt(char *out, unsigned mis_reg);
void mem_err_fmt(char *out);


