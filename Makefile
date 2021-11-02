TARGET=ins-ml-gerp2022
all: clean compile crunch disk run

compile:
	bin/acme --format cbm -v3 -o build/$(TARGET).prg source/main.asm
crunch:
	bin/pucrunch -x0x0801 -c64 -g55 -fshort build/$(TARGET).prg build/$(TARGET).prg
disk:
	c1541 -format $(TARGET),42 d64 build/$(TARGET).d64 -attach build/$(TARGET).d64 -write build/$(TARGET).prg $(TARGET)
run:
	x64sc build/$(TARGET).prg
clean:
	rm -f build/$(TARGET).d64
	rm -f build/$(TARGET).prg
