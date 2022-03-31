
all:
	arm-none-eabi-gcc -o main.elf main.S -nostdlib -T../linkscript -I../common
	arm-none-eabi-objcopy --output-target=binary main.elf bios-test.gba

