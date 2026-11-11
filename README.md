# omp-skills

Skills and extensions for [omp (oh-my-pi)](https://github.com/can1357/oh-my-pi).

| Name | Type | What it does |
|---|---|---|
| `fable-orchestration` | skill + extension | Delegation policy for a Claude Fable 5.2 main loop: the work is routed by difficulty to Opus, Sonnet and Haiku subagents. The extension injects it automatically while the main session runs on a Fable model. |

## Kurulum / Install

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/ataberkus/omp-skills/main/install.ps1 | iex
```

**macOS / Linux:**

```sh
curl -fsSL https://raw.githubusercontent.com/ataberkus/omp-skills/main/install.sh | sh
```

**Klonlayarak / From a clone:**

```sh
git clone https://github.com/ataberkus/omp-skills.git
cd omp-skills
powershell -ExecutionPolicy Bypass -File install.ps1   # Windows
sh install.sh                                          # macOS / Linux
```

Installers copy:

- `skills/<name>/` → `~/.omp/agent/skills/<name>/`
- `extensions/*.js` → `~/.omp/agent/extensions/`

Another agent dir: set `OMP_AGENT_DIR` before running. Running the installer again updates the files in place.

**Manuel / Manual:** copy the two folders above to the same places by hand.

After installing, **restart omp** (a running session does not load newly added extensions). Edits to `SKILL.md` apply from the next message without a restart.

## fable-orchestration

### Ne yapar / What it does

The main loop (Fable) writes the plan, the briefs, the hard calls and the final synthesis. Everything else goes to the cheapest tier that can carry it:

| Work | Model |
|---|---|
| Medium-high difficulty: multi-file implementation, debugging, review | `anthropic/claude-opus-5-5:high` |
| Second opinion (fresh instance, peer-style brief) | `anthropic/claude-opus-5-5:high` |
| Simple-medium scoped work | `anthropic/claude-sonnet-5-5:medium` |
| Step-by-step execution of a decided plan | `anthropic/claude-sonnet-5-5:medium` |
| Very large data cleanup | `anthropic/claude-haiku-5-5:high` (Sonnet when the rules need care) |

Every subagent call (`task` items, eval `agent()` / `workpool()`) gets an explicit `model`. Full policy: [`skills/fable-orchestration/SKILL.md`](skills/fable-orchestration/SKILL.md).

### Otomatik açılma / Auto-activation

`extensions/fable-orchestration.js` hooks `before_agent_start`. When the main session's model id or name contains `fable`, it appends the skill body as the last system-prompt block (wrapped in `<fable-orchestration-policy>`), so the earlier prompt-cache prefix stays intact. Subagents and other models are left alone.

### Kullanım / Usage

```sh
omp --model anthropic/claude-fable-5-2
```

or switch with `/model` inside omp. With another main model, load the policy by hand: `/skill:fable-orchestration`.

Check that it is active:

```sh
omp -p --no-session --model anthropic/claude-fable-5-2 "Is a fable-orchestration-policy block in your system prompt? Answer YES or NO."
```

### Model id'leri / Model ids

omp accepts only exact model ids in `model`. If your provider names them differently, edit the ids in `SKILL.md`.

## Credits

`fable-orchestration` is adapted from [avenoxai/avenoxskills](https://github.com/avenoxai/avenoxskills/blob/main/skills/fable-orchestration/SKILL.md) (MIT): the GPT/Codex tiers are replaced with Claude Opus, Sonnet and Haiku, and the policy is adapted to omp's tools.

## License

MIT, see [LICENSE](LICENSE).
