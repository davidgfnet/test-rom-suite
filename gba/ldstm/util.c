
// String formatting

static char dec2hex(unsigned x) {
  if (x < 10)
    return '0' + x;
  return 'a' + x - 10;
}

void ldm_fmt(char *out, unsigned base_reg, unsigned mode, unsigned mask) {
  int cnt = 0;
  out[cnt++] = ' ';
  out[cnt++] = '>';
  out[cnt++] = ' ';
  out[cnt++] = 'L';
  out[cnt++] = 'D';
  out[cnt++] = 'M';

  out[cnt++] = mode & 2 ? 'D' : 'I';
  out[cnt++] = mode & 4 ? 'A' : 'B';
  out[cnt++] = ' ';
  out[cnt++] = 'r';
  if (base_reg >= 10)
    out[cnt++] = '0' + base_reg / 10;
  out[cnt++] = '0' + base_reg % 10;

  out[cnt++] = mode & 1 ? '!' : ' ';
  out[cnt++] = ',';
  out[cnt++] = ' ';
  out[cnt++] = '0';
  out[cnt++] = 'x';
  out[cnt++] = dec2hex(mask >> 12);
  out[cnt++] = dec2hex((mask >>  8) & 0xF);
  out[cnt++] = dec2hex((mask >>  4) & 0xF);
  out[cnt++] = dec2hex(mask & 0xF);
  out[cnt++] = 0;
}

void stm_fmt(char *out, unsigned base_reg, unsigned mode, unsigned mask) {
  int cnt = 0;
  out[cnt++] = ' ';
  out[cnt++] = '>';
  out[cnt++] = ' ';
  out[cnt++] = 'S';
  out[cnt++] = 'T';
  out[cnt++] = 'M';

  out[cnt++] = mode & 2 ? 'D' : 'I';
  out[cnt++] = mode & 4 ? 'A' : 'B';
  out[cnt++] = ' ';
  out[cnt++] = 'r';
  if (base_reg >= 10)
    out[cnt++] = '0' + base_reg / 10;
  out[cnt++] = '0' + base_reg % 10;

  out[cnt++] = mode & 1 ? '!' : ' ';
  out[cnt++] = ',';
  out[cnt++] = ' ';
  out[cnt++] = '0';
  out[cnt++] = 'x';
  out[cnt++] = dec2hex(mask >> 12);
  out[cnt++] = dec2hex((mask >>  8) & 0xF);
  out[cnt++] = dec2hex((mask >>  4) & 0xF);
  out[cnt++] = dec2hex(mask & 0xF);
  out[cnt++] = 0;
}


void reg_err_fmt(char *out, unsigned mis_reg) {
  int cnt = 0;
  out[cnt++] = ' ';
  out[cnt++] = 'R';
  out[cnt++] = 'e';
  out[cnt++] = 'g';
  out[cnt++] = ' ';
  out[cnt++] = 'M';
  out[cnt++] = 'i';
  out[cnt++] = 's';
  out[cnt++] = 'm';
  out[cnt++] = 'a';
  out[cnt++] = 't';
  out[cnt++] = 'c';
  out[cnt++] = 'h';
  out[cnt++] = ' ';
  out[cnt++] = 'r';

  if (mis_reg >= 10)
    out[cnt++] = '0' + mis_reg / 10;
  out[cnt++] = '0' + mis_reg % 10;
  out[cnt++] = 0;
}

void mem_err_fmt(char *out) {
  int cnt = 0;
  out[cnt++] = ' ';
  out[cnt++] = 'M';
  out[cnt++] = 'e';
  out[cnt++] = 'm';
  out[cnt++] = ' ';
  out[cnt++] = 'M';
  out[cnt++] = 'i';
  out[cnt++] = 's';
  out[cnt++] = 'm';
  out[cnt++] = 'a';
  out[cnt++] = 't';
  out[cnt++] = 'c';
  out[cnt++] = 'h';
  out[cnt++] = ' ';
  out[cnt++] = 0;
}

