PEANO_INSTALL_DIR=${ROCM_HOME}/apps/aie
CC = ${PEANO_INSTALL_DIR}/bin/clang
TARGET_TRIPLE_XDNA1=aie2-none-unknown-elf
TARGET_TRIPLE_XDNA2=aie2p-none-unknown-elf
APP_NAME_SUFFIX_XDNA1=xdna1
APP_NAME_SUFFIX_XDNA2=xdna2
APP_NAME_FULL_XDNA1=fivepi_${APP_NAME_SUFFIX_XDNA1}
APP_NAME_FULL_XDNA2=fivepi_${APP_NAME_SUFFIX_XDNA2}

generate_ll:
	${CC} -O2 --target=${TARGET_TRIPLE} -I${PEANO_INSTALL_DIR}/lib/clang/18/include -S main.cpp -emit-llvm -o main_${APP_NAME_SUFFIX}.ll
	
generate_elf:
	${CC} -O2 --target=${TARGET_TRIPLE} main_${APP_NAME_SUFFIX}.ll -ccc-install-dir ${PEANO_INSTALL_DIR}/bin -Wl,-T main.ld.script -o ${APP_NAME_FULL}.elf
	
main_${APP_NAME_SUFFIX_XDNA1}.ll:
	APP_NAME_SUFFIX=${APP_NAME_SUFFIX_XDNA1} TARGET_TRIPLE=${TARGET_TRIPLE_XDNA1} make generate_ll

main_${APP_NAME_SUFFIX_XDNA2}.ll:
	APP_NAME_SUFFIX=${APP_NAME_SUFFIX_XDNA2} TARGET_TRIPLE=${TARGET_TRIPLE_XDNA2} make generate_ll

${APP_NAME_FULL_XDNA1}.elf: main_${APP_NAME_SUFFIX_XDNA1}.ll
	APP_NAME_SUFFIX=${APP_NAME_SUFFIX_XDNA1} TARGET_TRIPLE=${TARGET_TRIPLE_XDNA1} APP_NAME_FULL=${APP_NAME_FULL_XDNA1} make generate_elf

${APP_NAME_FULL_XDNA2}.elf: main_${APP_NAME_SUFFIX_XDNA2}.ll
	APP_NAME_SUFFIX=${APP_NAME_SUFFIX_XDNA2} TARGET_TRIPLE=${TARGET_TRIPLE_XDNA2} APP_NAME_FULL=${APP_NAME_FULL_XDNA2} make generate_elf

clean:
	rm -f *.ll
	rm -f *.elf
	rm -f *.json
	rm -f *.bif
	rm -f *.xclbin
	rm -f *.pdi
	rm -f *.bin

all: clean ${APP_NAME_FULL_XDNA1}.elf ${APP_NAME_FULL_XDNA2}.elf

.DEFAULT_GOAL := all
