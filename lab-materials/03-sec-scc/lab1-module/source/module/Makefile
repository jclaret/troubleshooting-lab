obj-m += hello.o

all:
	make -C /lib/modules/5.14.0-427.50.1.el9_4.x86_64/build M=$(PWD) modules
clean:
	make -C /lib/modules/5.14.0-427.50.1.el9_4.x86_64/build M=$(PWD) clean
