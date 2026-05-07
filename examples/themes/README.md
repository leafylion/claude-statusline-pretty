# Custom theme starters

Drop one of these JSON files at `~/.claude/statusline-theme.json` and set `THEME = 'custom'` (or run the installer with `--theme custom` / `-Theme custom`) to use it. Edit any color number to taste — it's a [256-color](https://www.ditig.com/256-colors-cheat-sheet) palette.

## Schema

All 13 keys are required. Each value is a 256-color number (0–255).

```json
{
  "model":    183,   // model name on line 1
  "session":  247,   // session name in quotes
  "dir":      81,    // directory (after the › / ❯ / » glyph)
  "branch":   121,   // git branch (after the ⎇ / ⊢ / ↳ glyph)
  "effort":   117,   // effort:high/medium/low/xhigh
  "ctx_ok":   152,   // context % below 50%
  "ctx_wn":   215,   // context % 50–79%
  "ctx_er":   174,   // context % 80–100%
  "cache":    80,    // cache hit %
  "duration": 244,   // session running time
  "cost":     147,   // per-model cost breakdown
  "total":    219,   // grand total ($X total)
  "sep":      238    // the · / │ / • separator dots
}
```

If any key is missing or the file is malformed, the script silently falls back to the bundled `cool-pastel` theme.
