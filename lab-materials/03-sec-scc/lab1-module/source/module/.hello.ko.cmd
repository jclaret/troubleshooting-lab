cmd_/build/hello.ko := ld -r -m elf_x86_64 --build-id=sha1  -T scripts/module.lds -o /build/hello.ko /build/hello.o /build/hello.mod.o;  true
