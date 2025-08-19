cmd_/build/hello.mod := printf '%s\n'   hello.o | awk '!x[$$0]++ { print("/build/"$$0) }' > /build/hello.mod
