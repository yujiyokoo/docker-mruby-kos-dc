export CC=sh-elf-gcc
#export CXX=sh-elf-g++
export LD=sh-elf-gcc

export PATH=/opt/toolchains/dc/sh-elf/bin:${PATH}
export PATH=/opt/toolchains/dc/sh-elf/libexec/gcc/sh-elf/4.7.3/:${PATH}

export CFLAGS="-H -std=gnu99"
export CFLAGS="${CFLAGS} -I/opt/toolchains/dc/kos/utils/dc-chain/newlib-2.0.0/newlib/libc/include/ -I/opt/toolchains/dc/kos/include/kos/ -I/opt/toolchains/dc/sh-elf/lib/gcc/sh-elf/4.7.3/include/ -I/opt/toolchains/dc/kos/include/"

# TODO: Some symbols (namely __kill_r and __getpid_r) are not found in libs. So they are adedd here at the end. Figure out why.
export LDFLAGS=" -lg -lm -Wl,--start-group -lkallisti_exports -lkallisti -lc -lgcc -Wl,--end-group -L/opt/toolchains/dc/sh-elf/sh-elf/lib/ -L/opt/toolchains/dc/kos/lib/dreamcast/ -L/opt/toolchains/dc/sh-elf/lib/gcc/sh-elf/4.7.3/ /opt/toolchains/dc/kos/kernel/build/newlib_kill.o /opt/toolchains/dc/kos/kernel/build/newlib_getpid.o"
