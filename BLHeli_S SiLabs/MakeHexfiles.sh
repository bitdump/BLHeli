#!/bin/bash
echo "***** Batch file for BlHeli_S (from 4712)  v.2         *****"
echo "***** All Messages will be saved to MakeHex_Result.txt *****"
echo "***** Start compile with any key  - CTRL-C to abort    *****"
read -n 1 -s || exit

LOG="MakeHex_Result.txt"
rm -f ${LOG}

REVISION="REV16_5"

# output directory
OUTPUT_DIR=OUTPUT
OUTPUT_HEX_DIR=${OUTPUT_DIR}/HEX

# configure the script to use the wine installation delivered with
# SimplicityStudio. these wine settings are quite important. if you get
#  ERROR L250: CODE SIZE LIMIT IN RESTRICTED VERSION EXCEEDED
# you messed up your simplicity studio install/path settins below:
SIMPLICITY_PATH=~/local/SimplicityStudio_v4/
WINE=${SIMPLICITY_PATH}/support/common/wine/usr/bin/wine 
WINE_PREFIX=~/.config/SimplicityStudio/v4/studio-wine
# path to the keil binaries
KEIL_PATH=${SIMPLICITY_PATH}/developer/toolchains/keil_8051/9.53/BIN


# abort function
abort()
{
	MSG=$1
	echo ""
	echo "ERROR: ${MSG}"
        echo "..."
        tail $LOG
	echo ""
	exit
}

# compile function
compile ()
{
	ESCNO=$1
	MCU=$2
	HL=$([ $MCU == 0 ] && echo "L" || echo "H" )
	VARIANT=$3
        FETON_DELAY=$4

	ESC="${VARIANT}_${HL}_"
	ESCNAME="${ESC}${FETON_DELAY}"

	echo "compiling ${ESCNAME}"
	echo "." >> $LOG
	echo "********************************************************************" >> $LOG
	echo "${ESCNAME}" >> $LOG
	echo "********************************************************************" >> $LOG
	${WINE} ${KEIL_PATH}/AX51.exe "BLHeli_S.asm" \
		"DEFINE(ESCNO=${ESCNO}) \
		DEFINE(MCU_48MHZ=${MCU}) \
		DEFINE(FETON_DELAY=${FETON_DELAY}) \
		OBJECT(${OUTPUT_DIR}/${ESCNAME}_${REVISION}.OBJ) \
		DEBUG MACRO NOMOD51 COND SYMBOLS PAGEWIDTH(120) PAGELENGTH(65)"  >> $LOG || abort "failed to run AX51"

	${WINE} ${KEIL_PATH}/LX51.exe "${OUTPUT_DIR}/${ESCNAME}_${REVISION}.OBJ" TO "${OUTPUT_DIR}/${ESCNAME}_${REVISION}.OMF" "PAGEWIDTH (120) PAGELENGTH (65)" >> $LOG #|| abort "failed to run LX51" #warnings let lx51 fail?!

	${WINE} ${KEIL_PATH}/Ohx51 "${OUTPUT_DIR}/${ESCNAME}_${REVISION}.OMF" "HEXFILE (${OUTPUT_DIR}/${ESCNAME}_${REVISION}.HEX)" "H386" >> $LOG || abort "failed to run Ohx51"

	mv ${OUTPUT_DIR}/${ESCNAME}_${REVISION}.HEX ${OUTPUT_HEX_DIR}/${ESCNAME}_${REVISION}.HEX || abort "failed to move hex file"
	echo "." >> $LOG
}


rm -rf ${OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}
mkdir -p ${OUTPUT_HEX_DIR}

echo "Revision: ${REVISION}" >> $LOG
echo "Path for Keil toolchain: ${KEIL_PATH}" >> $LOG
echo "Using wine: ${WINE}" >> $LOG
echo "Start compile ....." >> $LOG

export WINEPREFIX=${WINE_PREFIX}

ESCNO=1
for VARIANT in A B C D E F G H I J K L M N O P
do
	for MCU in 0 1
	do
		for FETON_DELAY in 0 5 10 15 20 25 30 40 50 70 90
		do
			compile $ESCNO $MCU $VARIANT $FETON_DELAY
		done
	done
	ESCNO=$[$ESCNO + 1]
done


