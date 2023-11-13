
#define __get16(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, ...) a15
#define argcnt(...) __get16(dummy, ## __VA_ARGS__, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)

#define screen_print_N(fmt, ypos, ...) \
  push {r0, r1};        \
  push {__VA_ARGS__};   \
  mov r0, $0x2000000;   \
  ldr r1, =fmt;         \
  bl printfn;           \
  add sp, sp, $(4 * argcnt(__VA_ARGS__));  \
  mov r1, $(ypos);      \
  bl write_text;        \
  pop {r0, r1};        \

#define screen_print(strreg, ypos) \
  push {r0, r1}; \
  mov r0, strreg;   \
  mov r1, $(ypos);      \
  bl write_text;        \
  pop {r0, r1}; \

#define progress_bar(amount) \
  push {lr}; \
  mov r0, $0x2000000; \
  mov r1, $(amount); mov r2, $0x7f; \
  99: strb r2, [r0], #1; subs r1, r1, $1; bgt 99b; \
  mov r2, $0; strb r2, [r0], #1; \
  mov r0, $0x2000000; \
  mov r1, $152; \
  bl write_text; \
  pop {lr};

#define progress_bar_r1() \
  push {lr}; \
  mov r0, $0x2000000; \
  mov r2, $0x7f; \
  99: strb r2, [r0], #1; subs r1, r1, $1; bgt 99b; \
  mov r2, $0; strb r2, [r0], #1; \
  mov r0, $0x2000000; \
  mov r1, $152; \
  bl write_text; \
  pop {lr};

#define run_test(testfn, testname)  \
  adr lr, 20f; \
  screen_print(lr, 45); \
  b 15f; \
  20: .ascii "> " testname; .asciz " ..."; \
  .align 4; \
  15: \
  adr lr, 10f; \
  b testfn;    \
  .asciz testname; \
  .align 4; \
  10: \
  cmp r7, $0; \
  bne testfail; \




