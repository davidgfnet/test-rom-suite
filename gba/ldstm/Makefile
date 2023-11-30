
all:
	pypy3 generator.py > test.autogen.h
	arm-none-eabi-g++ -c -o emu.o emu.cc -O2 -mcpu=arm7tdmi -mthumb-interwork -mthumb
	arm-none-eabi-gcc -o main.elf main.S util.c emu.o -O2 -nostdlib -lgcc -T../linkscript -I../common/ -mthumb-interwork
	arm-none-eabi-objcopy --output-target=binary main.elf ldstm-test.gba

