#include <linux/module.h>
#include <linux/kernel.h>

int init_module(void) {
    printk(KERN_INFO "Hello kernel! Module loaded.\n");
    return 0;
}

void cleanup_module(void) {
    printk(KERN_INFO "Goodbye kernel! Module unloaded.\n");
}

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Workshop");
MODULE_DESCRIPTION("Simple hello world kernel module");
