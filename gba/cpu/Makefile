
all:	cpu-test-thumb.gba cpu-test-arm-imm.gba cpu-test-arm-reg.gba

cpu-test-thumb.elf:	test.thumb.autogen.h
	arm-none-eabi-gcc -o $@ main.S -nostdlib -T../linkscript -I../common/ -DTESTS_THUMB

cpu-test-arm-imm.elf: test.arm_imm.autogen.h
	arm-none-eabi-gcc -o $@ main.S -nostdlib -T../linkscript -I../common/ -DTESTS_ARM_IMM

cpu-test-arm-reg.elf:	test.arm_reg.autogen.h
	arm-none-eabi-gcc -o $@ main.S -nostdlib -T../linkscript -I../common/ -DTESTS_ARM_REG

%.gba:	%.elf
	arm-none-eabi-objcopy --output-target=binary $? $@

test.thumb.autogen.h:	generator.py
	pypy3 generator.py thumb > test.thumb.autogen.h

test.arm_imm.autogen.h:	generator.py
	pypy3 generator.py arm_imm > test.arm_imm.autogen.h

test.arm_reg.autogen.h:	generator.py
	pypy3 generator.py thumb > arm_reg.arm_reg.autogen.h

clean:
	rm -f *.gba *.elf

