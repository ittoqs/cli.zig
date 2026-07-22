import subprocess
import time
import os
import sys

proc = subprocess.Popen(['./zig-out/bin/cli-zig'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
time.sleep(0.5)

proc.stdin.write(b'echo "hello from cli" | sed "s/cli/zig/" > integration_out.txt\n')
proc.stdin.flush()
time.sleep(0.5)

proc.stdin.write(b"exit\n")
proc.stdin.flush()

proc.wait()

with open("integration_out.txt", "r") as f:
    content = f.read().strip()
    if content == "hello from zig":
        print("SUCCESS: Integration works!")
    else:
        print(f"FAILED: Expected 'hello from zig', got '{content}'")
        sys.exit(1)
