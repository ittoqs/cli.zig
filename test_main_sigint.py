import subprocess
import time
import signal
import sys
import os

proc = subprocess.Popen(['./zig-out/bin/cli-zig'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
time.sleep(0.5)

# Write sleep command
proc.stdin.write(b"sleep 10\n")
proc.stdin.flush()

time.sleep(0.5)
# Send SIGINT to the process group / process
proc.send_signal(signal.SIGINT)

# Wait 0.5s and read output or just check if proc is alive
time.sleep(0.5)
if proc.poll() is None:
    print("SUCCESS: CLI survived SIGINT")
    proc.terminate()
else:
    print("FAILED: CLI terminated")
    sys.exit(1)
