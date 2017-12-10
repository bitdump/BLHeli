# set current revision
REVISION ?= REV16_7

# targets
TARGETS      = A B C D E F G H I J K L M N O P Q R S T U V W
MCUS         = H L
FETON_DELAYS = 0 5 10 15 20 25 30 40 50 70 90

# example single target
VARIANT     ?= A
MCU         ?= H
FETON_DELAY ?= 5

# configure the script to use the wine installation delivered with
# SimplicityStudio. these wine settings are quite important. if you get
#  ERROR L250: CODE SIZE LIMIT IN RESTRICTED VERSION EXCEEDED
# you messed up your simplicity studio install/path settins below:
SIMPLICITY_PATH ?= ~/local/SimplicityStudio_v4/
WINE_PREFIX     ?= ~/.config/SimplicityStudio/v4/studio-wine
WINE_BIN        ?= $(SIMPLICITY_PATH)/support/common/wine/usr/bin/wine
WINE            = export WINEPREFIX=`realpath $(WINE_PREFIX)`; $(WINE_BIN)

# path to the keil binaries
KEIL_PATH       = $(SIMPLICITY_PATH)/developer/toolchains/keil_8051/9.53/BIN

# some directory config
OUTPUT_DIR     ?= build
OUTPUT_DIR_HEX ?= $(OUTPUT_DIR)/hex
LOG_DIR        ?= $(OUTPUT_DIR)/log

# define the assembler/linker scripts
AX51_BIN = $(KEIL_PATH)/AX51.exe
LX51_BIN = $(KEIL_PATH)/LX51.exe
OX51_BIN = $(KEIL_PATH)/Ohx51.exe
AX51 = $(WINE) $(AX51_BIN)
LX51 = $(WINE) $(LX51_BIN)
OX51 = $(WINE) $(OX51_BIN)

# set up flags
AX51_FLAGS = DEBUG MACRO NOMOD51 COND SYMBOLS PAGEWIDTH(120) PAGELENGTH(65)
LX51_FLAGS = PAGEWIDTH (120) PAGELENGTH (65)

# set up sources
ASM_SRC = BLHeli_S.asm
ASM_INC = $(TARGETS:=.inc) BLHeliBootLoad.inc BLHeliPgm.inc SI_EFM8BB1_Defs.inc SI_EFM8BB2_Defs.inc

# check that wine/simplicity studio is available
EXECUTABLES = $(WINE_BIN) $(AX51_BIN) $(LX51_BIN) $(OX51_BIN) 
DUMMYVAR := $(foreach exec, $(EXECUTABLES), \
		$(if $(wildcard $(exec)),found, \
		$(error "Could not find $(exec). Make sure to set the correct paths to the simplicity install location")))

# make sure the list of obj files is expanded twice
.SECONDEXPANSION:
OBJS = 

define MAKE_OBJ
OBJS += $(OUTPUT_DIR)/$(1)_$(2)_$(3)_$(REVISION).OBJ
$(OUTPUT_DIR)/$(1)_$(2)_$(3)_$(REVISION).OBJ : $(ASM_SRC) $(ASM_INC)
	$(eval _ESC         := $(1))
	$(eval _ESC_INT     := $(shell printf "%d" "'${_ESC}"))
	$(eval _ESCNO       := $(shell echo $$(( $(_ESC_INT) - 65 + 1))))
        $(eval _MCU_48MHZ   := $(subst L,0,$(subst H,1,$(2))))
	$(eval _FETON_DELAY := $(3))
	$(eval _LOG         := $(LOG_DIR)/$(1)_$(2)_$(3)_$(REVISION).log)
	@mkdir -p $(OUTPUT_DIR)
	@mkdir -p $(LOG_DIR)
	@echo "AX51 : $$@"
	@$(AX51) $(ASM_SRC) \
		"DEFINE(ESCNO=$(_ESCNO)) " \
                "DEFINE(MCU_48MHZ=$(_MCU_48MHZ)) "\
                "DEFINE(FETON_DELAY=$(_FETON_DELAY)) "\
                "OBJECT($$@) "\
                "$(AX51_FLAGS)" >> $(_LOG) 2>&1; test $$$$? -lt 2 || tail $(_LOG)

endef

HEX_TARGETS = $(OBJS:.OBJ=.HEX)

EFM8_LOAD_BIN  ?= efm8load.py
EFM8_LOAD_PORT ?= /dev/ttyUSB0
EFM8_LOAD_BAUD ?= 57600

SINGLE_TARGET_HEX = $(OUTPUT_DIR)/$(VARIANT)_$(MCU)_$(FETON_DELAY)_$(REVISION).HEX

single_target : $(SINGLE_TARGET_HEX)

all : $$(HEX_TARGETS)
	@echo "\nbuild finished. built $(shell ls -l $(OUTPUT_DIR_HEX) | wc -l) hex targets\n"

# create all obj targets using macro expansion
$(foreach _e,$(TARGETS), \
	$(foreach _m, $(MCUS), \
		$(foreach _f, $(FETON_DELAYS), \
			$(eval $(call MAKE_OBJ,$(_e),$(_m),$(_f))))))
	

$(OUTPUT_DIR)/%.OMF : $(OUTPUT_DIR)/%.OBJ
	$(eval LOG         := $(LOG_DIR)/$(basename $(notdir $@)).log)
	@echo "LX51 : linking $< to $@"
	@$(LX51) "$<" TO "$@" "$(LX51_FLAGS)" >> $(LOG) 2>&1; test $$? -lt 2 || tail $(LOG)

$(OUTPUT_DIR)/%.HEX : $(OUTPUT_DIR)/%.OMF
	$(eval LOG         := $(LOG_DIR)/$(basename $(notdir $@)).log)
	@mkdir -p $(OUTPUT_DIR_HEX)
	@echo "OHX  : generating hex file $@"
	@$(OX51) "$<" "HEXFILE ($@)" "H386" >> $(LOG) 2>&1; test $$? -lt 2 || tail $(LOG)
	@cp $@ $(OUTPUT_DIR_HEX)/$(notdir $@)

help:
	@echo ""
	@echo "usage examples:"
	@echo "================================================================="
	@echo "make all                              # build all targets"
	@echo "make VARIANT=A MCU=H FETON_DELAY=5    # to build a single target" 
	@echo

clean:
	@rm -rf $(LOG_DIR)/*
	@rm -rf $(OUTPUT_DIR)/*

efm8load: single_target
	$(EFM8_LOAD_BIN) -p $(EFM8_LOAD_PORT) -b $(EFM8_LOAD_BAUD) -w $(SINGLE_TARGET_HEX)


.PHONY: all clean help efm8load

