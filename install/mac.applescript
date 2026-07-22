-- Mac OS Automator Quick Action Script
-- Instructions:
-- 1. Open Automator.
-- 2. Create a new "Quick Action".
-- 3. Set "Workflow receives current" to "folders" in "Finder".
-- 4. Drag and drop the "Run AppleScript" action.
-- 5. Paste this code and save it.

on run {input, parameters}
    tell application "Terminal"
        activate
        set p to POSIX path of item 1 of input
        -- Ubah "/path/to/cli-zig" dengan lokasi ekseskutor cli-zig anda
        do script "\"/path/to/cli-zig\" " & quoted form of p
    end tell
    return input
end run
