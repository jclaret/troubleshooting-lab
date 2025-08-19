import subprocess
import time

MODULE = "hello"
MODULE_PATH = "/app/hello.ko"

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.STDOUT).decode().strip()
    except subprocess.CalledProcessError as e:
        return f"⚠️ Error: {e.output.decode().strip()}"

def check_and_manage_module():
    output = subprocess.check_output(["lsmod"]).decode()
    if MODULE in output:
        print(f"✅ Module '{MODULE}' is loaded. Unloading...")
        print(run_cmd(["rmmod", MODULE]) or f"🛑 Module '{MODULE}' unloaded.")
    else:
        print(f"❌ Module '{MODULE}' is NOT loaded. Loading...")
        print(run_cmd(["insmod", MODULE_PATH]) or f"📦 Module '{MODULE}' loaded.")

if __name__ == "__main__":
    while True:
        check_and_manage_module()
        time.sleep(5)
