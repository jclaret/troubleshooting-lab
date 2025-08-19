cmd_/build/modules.order := {   echo /build/hello.ko; :; } | awk '!x[$$0]++' - > /build/modules.order
