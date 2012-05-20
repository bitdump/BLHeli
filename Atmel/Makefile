AVRASM:=wine "avrasm2/avrasm2.exe"

ASMFLAGS =  -fI

ESCS := WalkeraWST10LT Feigao6 HC5A1SA48V HC5A1SA8

MAIN_FW := $(addsuffix .main.hex, $(ESCS))
TAIL_FW := $(addsuffix .tail.hex, $(ESCS))

FW = $(MAIN_FW) $(TAIL_FW)

all: $(FW)

$(MAIN_FW) : %.main.hex : %.inc BLHeli.asm 
	 $(AVRASM) $(ASMFLAGS) -o $@ -i main.inc -i $< BLHeli.asm

$(TAIL_FW) : %.tail.hex : %.inc BLHeli.asm 
	 $(AVRASM) $(ASMFLAGS) -o $@ -i tail.inc -i $< BLHeli.asm
	
clean:
	rm -rf *.hex *.lst *.map *.obj
