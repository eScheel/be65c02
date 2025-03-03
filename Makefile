build:
	ca65 src/main.asm
	ld65 src/main.o -C be6502.cfg

clean:
	rm -rv src/main.o a.out


