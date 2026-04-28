## Tool Usage Policy: rtk

Always prefix shell commands with `rtk` for token compression unless the command is interactive (vim, less, ssh, sudo prompts) or already prefixed.

Examples:
- `git status` → `rtk git status`
- `ls -la` → `rtk ls -la`
- `cargo test` → `rtk cargo test`
- `rg "pattern"` → `rtk rg "pattern"`

Never bypass rtk to "see raw output" — if you need raw output, use `rtk proxy <cmd>`.
At session start, run `rtk gain` once to verify installation and show current savings.
