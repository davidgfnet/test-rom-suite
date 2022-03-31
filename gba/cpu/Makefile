
all:
	pypy3 generator.py > test.autogen.h
	arm-none-eabi-gcc -o main.elf main.S -nostdlib -T../linkscript -I../common/
	arm-none-eabi-objcopy --output-target=binary main.elf cpu-test.gba

