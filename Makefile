all: compile crunch disk clean run

compile:
	bin/acme --format cbm -v3 -o build/insane.prg source/main.asm
crunch:
	bin/pucrunch -x0x0801 -c64 -g55 -fshort build/insane.prg build/insane.prg
disk:
	c1541 -format insane,42 d64 build/insane.d64 -attach build/insane.d64 -write build/insane.prg insane
run:
	x64sc build/insane.d64
clean:
	rm build/insane.prg
