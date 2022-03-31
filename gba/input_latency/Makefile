
all:
	arm-none-eabi-gcc -o main.elf main.S -nostdlib -T../linkscript
	arm-none-eabi-objcopy --output-target=binary main.elf input-latency-test.gba

