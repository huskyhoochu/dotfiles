# Web search

You have no built-in web search tool. The ONLY way to search the web is running this command with the bash tool:

```bash
python3 ~/dotfiles/claude/.claude/skills/web-research/scripts/tavily_search.py search "<query>" --max=5 --answer
```

Use it whenever the user asks about current information (news, schedules, prices, recent events). It prints JSON; summarize the `answer` and `results` fields in Korean with source links. If it prints `{"error": ...}`, relay the error instead of guessing.
