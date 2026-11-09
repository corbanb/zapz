# First-run redesign: personas for 2027

**Status:** draft for review, round 2. Nothing here is built yet.
**Checked:** every Homebrew name below was confirmed in Homebrew's cask and
core repositories on 2026-11-09. App Store IDs still need confirming on a Mac.

## Decisions so far

| Question | Decision |
|---|---|
| Recommended terminal | **Ghostty** (iTerm2, Warp and Terminal offered) |
| Language versions | **mise** for Node, Python, Bun, Go… (replaces nvm) |
| Containers | **OrbStack** (Docker Desktop offered) |
| Security step | **Yes**: Touch ID for sudo, firewall on, FileVault check |
| Personas | Multi-select; each adds to the essentials. 9 personas + 4 add-on packs |
| Raycast | Optional (offered in essentials, not installed by default) |
| Local AI models | Optional add-on pack |
| Video editors | The user chooses: DaVinci Resolve, Final Cut Pro, Premiere Pro, Edits |

## Principles for the experience

1. **Say what will happen before it happens.** Every screen ends with what
   the next step does and how long it takes.
2. **Recommend, don't interrogate.** Each question has a marked
   recommendation and a one-line reason. Enter always means "the
   recommended thing".
3. **Be honest about what zapz can't do.** App Store sign-ins, licenses and
   registration-walled downloads are listed up front and turned into a
   checklist at the end, not silent failures.
4. **Everything is reversible.** Backups, marked blocks, and
   `zapz --configure` to change your mind.

## How things get installed

Not everything comes from Homebrew. Each item has one of four kinds, and the
plan screen says which:

| Kind | Example | What zapz does |
|---|---|---|
| **Homebrew** | `figma`, `ffmpeg` | Installs it |
| **App Store** | Final Cut Pro | Installs with `mas` if you're signed in and own it; otherwise opens the App Store page and adds a checklist item |
| **Guided download** | Edits, DaVinci Resolve, Premiere Pro | Opens the download page at the end; checklist item |
| **Setup command** | Paperclip (`npx paperclipai@latest onboard --yes`) | Runs it after its dependencies (Node via mise) are installed |

## Essentials (everyone)

| Area | Installed | Why |
|---|---|---|
| Foundation | Command Line Tools, Homebrew, `git`, `gh`, `git-lfs` | Everything else builds on these |
| Identity | git name/email, SSH key (Keychain), GitHub sign-in | Ready to clone and push on day one |
| Security | Touch ID for `sudo`, firewall on, FileVault check | Safer defaults with no extra effort |
| Everyday apps | `1password`, `the-unarchiver`, `appcleaner` | Passwords, archives, clean uninstalls |
| Browser (choose one) | `google-chrome`, `firefox`, `brave-browser`, or Safari only | Arc is discontinued (Homebrew disables it Dec 22) |
| Command line | `jq ripgrep fd fzf bat eza zoxide btop tlrc mas wget` | Modern, fast versions of everyday tools |
| Font | `font-jetbrains-mono-nerd-font` | Icons and ligatures in the terminal and editor |
| macOS | Dock, Finder and key-repeat defaults; `~/Pictures/Screenshots` | Less clutter, faster keyboard |
| Updates | Weekly background updates (launchd) | Stays current without thinking about it |

**Optional essentials** (offered, unticked): `raycast` (launcher, window
snapping, clipboard; replaces Spotlight), `google-drive`, `dropbox`.

## Terminal and shell

**Your terminal** (single choice)

| Option | Cask | One-line pitch |
|---|---|---|
| **Ghostty** (recommended) | `ghostty` | Fast, native and free. zapz sets the font and a theme. |
| iTerm2 | `iterm2` | The classic, with the most features (profiles, triggers, tmux). |
| Warp | `warp` | AI built into the terminal. Needs an account on first open. |
| Keep Terminal | (none) | Apple's built-in Terminal, with the font set. |

**Your shell** (single choice)

| Option | What it installs |
|---|---|
| **Recommended** | Oh My Zsh, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `starship` prompt, fzf and zoxide key bindings, `eza`/`bat` aliases |
| Light | `starship` prompt only |
| Leave it alone | Nothing |

All shell changes go in zapz's marked blocks, so they're easy to remove.
Optional: `atuin` (searchable shell history, synced across Macs).

## Personas

Pick any combination. "Core" is installed when you pick the persona;
"optional" items are offered on a follow-up screen with recommendations
ticked.

### 1. Software developer
> *"I write and ship code."*

| Core | Optional |
|---|---|
| `visual-studio-code` | `cursor`, `zed`, `jetbrains-toolbox` |
| `orbstack` (or `docker-desktop`) | `postman`, `bruno` |
| `mise` → Node LTS, Python, Bun | `deno`, Go, Rust (via mise) |
| `uv`, `pnpm` | `tableplus`, `dbeaver-community` |

### 2. AI builder
> *"I build with AI and run coding agents."*

| Core | Optional |
|---|---|
| `claude` (desktop), `claude-code` | `codex`, `gemini-cli`, `opencode`, `cursor-cli` |
| `chatgpt` | `perplexity` |
| `cursor` | **Agent orchestration:** `conductor` (parallel Claude Code/Codex agents in git worktrees), `t3-code` (one app for Claude Code, Codex and Cursor agents), **Paperclip** (setup command: runs AI agents as a company; needs Node 24.11+) |
| `uv` + Python (via mise), `jupyterlab` | `llm` CLI, `mstystudio`, `jan` |

Local models are in the **Local AI** add-on pack.

### 3. Mobile developer
> *"I build iPhone and Android apps."*

| Core | Optional |
|---|---|
| `xcodes-app` + `xcodes` → Xcode (needs an Apple ID sign-in) | `flutter` |
| `android-studio`, `android-platform-tools` | Expo / EAS CLI (via mise Node) |
| `cocoapods`, `watchman`, `fastlane` | `visual-studio-code` or `cursor` |

### 4. Game developer
> *"I make games."*

| Core | Optional |
|---|---|
| `unity-hub` | `epic-games` (Unreal Engine) |
| `godot` | `blockbench`, `tiled` |
| `git-lfs` (large assets) | **Aseprite** (guided: Steam or itch.io purchase) |
| | `blender` (Homebrew plans to deprecate it on 2027-07-01; revisit) |

### 5. Data scientist
> *"I analyze data and build models."*

| Core | Optional |
|---|---|
| `positron` (data science IDE for Python and R) | `rstudio`, `r-app` |
| `jupyterlab`, `uv` + Python (via mise) | `miniconda` (Anaconda is discontinued) |
| `duckdb`, `dbeaver-community` | `quarto`, `tableau` |

### 6. Video editor
> *"I cut and finish video."*

**Which editors do you use?** (multi-select, none ticked by default)

| Editor | Kind | Notes |
|---|---|---|
| DaVinci Resolve | Guided download | Free; Blackmagic requires sign-up |
| Final Cut Pro | App Store | Paid; needs App Store sign-in |
| Premiere Pro | Guided via `adobe-creative-cloud` | Installs Creative Cloud; sign in and install Premiere from there |
| Edits (Instagram) | Guided download | Free; Mac app launched Nov 5, 2026; Apple Silicon only |

| Core | Optional |
|---|---|
| `handbrake-app`, `iina`, `ffmpeg` | `vlc`, `yt-dlp` |

### 7. Content creator and streamer
> *"I record, stream and publish."*

| Core | Optional |
|---|---|
| `obs` | `elgato-stream-deck`, `elgato-camera-hub`, `elgato-wave-link` |
| `descript`, `capcut` | **Edits (Instagram)** (guided download) |
| `canva` | `loopback`, `audio-hijack` (Rogue Amoeba, paid), `audacity` |
| `shottr`, `kap` (screenshots, GIFs) | `loom`, **Premiere Pro** (via Creative Cloud) |

### 8. Designer
> *"I design products, brands and visuals."*

| Core | Optional |
|---|---|
| `figma` | `framer`, `spline` |
| `affinity` (free; replaces Designer/Photo) | `adobe-creative-cloud` |
| `imageoptim`, `fontbase` | **Pixelmator Pro** (App Store) |

### 9. Team collaboration
> *"I work with a team."*

`slack`, `zoom`, `notion`, `notion-calendar`, `obsidian`, `discord`

**Not yet a persona:** podcaster/musician (Logic Pro, Loopback, Audio Hijack)
and maker (`bambu-studio`, `karabiner-elements`, `hammerspoon`). Their tools
can come in through add-ons for now.

## Add-on packs (any persona)

People use these whatever their job, so they're offered to everyone after
the personas.

### Meeting notes and recording

| App | Kind | License | Notes |
|---|---|---|---|
| `granola` | Homebrew | Paid (free tier) | AI notes from meetings, no bot joins the call |
| `meetily` | Homebrew | Open source (MIT) | Records and transcribes on your Mac; summaries via Ollama or a cloud model |
| `anarlog` | Homebrew | Open source | AI meeting notepad (formerly Hyprnote); on-device transcription |
| `krisp` | Homebrew | Paid (free tier) | Noise cancellation and meeting notes |

Otter and Fireflies are web services without Mac apps in Homebrew; mention
them, don't install them.

### Voice dictation

| App | Kind | License | Notes |
|---|---|---|---|
| `wispr-flow` | Homebrew | Paid | Dictation with AI auto-editing, works in any app |
| `superwhisper` | Homebrew | Paid | Dictation with model and mode choices |
| `aqua-voice` | Homebrew | Paid | Fast dictation |
| `macwhisper` | Homebrew | Freemium | File and meeting transcription |
| `voiceink` | Homebrew | Open source (GPLv3) | Local dictation (Whisper, Parakeet); Apple Silicon |
| `handy` | Homebrew | Open source (MIT) | Free, offline, cross-platform |
| `openwhispr` | Homebrew | Open source | Private dictation with AI agents |
| `buzz` | Homebrew | Open source | Transcribe audio and video files |

Suggested grouping on screen: **Paid, polished** (Wispr Flow, Superwhisper)
and **Free and private** (VoiceInk, Handy).

### Local AI models

`ollama-app`, `lm-studio`. Several GB each once you download models; zapz
installs the apps only, never models.

### Collaboration

Same as persona 9, for people who pick it as an extra rather than a role.

## Things zapz can't install by itself

| App | Why | What zapz does |
|---|---|---|
| Final Cut Pro, Logic Pro, Pixelmator Pro | App Store purchase + sign-in | Installs with `mas` if you're signed in and own it; otherwise a checklist item opens the App Store page |
| DaVinci Resolve | Download requires registration | Opens the download page; checklist item |
| Edits (Instagram) | Not in Homebrew; downloaded from edits.instagram.com | Opens the download page; checklist item |
| Premiere Pro | Installed through Creative Cloud | Installs Creative Cloud; checklist: sign in, install Premiere |
| Xcode | Needs an Apple ID | `xcodes` asks you to sign in; checklist item if skipped |
| Aseprite | Paid on Steam / itch.io | Opens the store page; checklist item |
| Paperclip | A Node app, set up by command | Runs its onboarding after Node is installed |
| Licenses and sign-ins (1Password, Adobe, OrbStack, Warp, Wispr Flow) | Need you | Listed on the finish screen; each opens the app |

## The flow and its copy (draft)

**1. Welcome**
> **Let's get your Mac ready.**
> Three steps: tell me a little about you (about 3 minutes), review the
> plan, then let it run (usually 20–45 minutes). Nothing changes until you
> say go.

**2. About you**
> **First, who's setting up this Mac?**
> Name: Corban Baxter *(from your Mac account)*
> Email for git commits: ________

**3. What you do**
> **What will you use this Mac for?** Pick all that apply, e.g. `1 2 6`.
> You can change this any time with `zapz --configure`.
>
>   1  Software development   editors, containers, languages
>   2  AI building            Claude, ChatGPT, Cursor, agent tools
>   3  Mobile apps            Xcode, Android Studio, Flutter
>   4  Game development       Unity, Godot, Unreal
>   5  Data science           Positron, Jupyter, DuckDB
>   6  Video editing          Resolve, Final Cut, Premiere, Edits
>   7  Content & streaming    OBS, Descript, CapCut, Canva
>   8  Design                 Figma, Affinity, Pixelmator Pro
>   9  Team collaboration     Slack, Zoom, Notion

**4. Extras for everyone**
> **A few extras people love.** Pick any, or press Enter to skip.
>
>   1  Meeting notes          Granola, or open-source Meetily
>   2  Voice dictation        Wispr Flow, or open-source VoiceInk
>   3  Local AI models        Ollama, LM Studio
>   4  Raycast                a faster Spotlight with window snapping

**5. Your picks** (one short screen per persona that has choices)
> **Video editing: which editors do you use?**
>   [ ] DaVinci Resolve (free)   [ ] Final Cut Pro (App Store)
>   [ ] Premiere Pro (Creative Cloud)   [ ] Edits by Instagram (free)

> **AI building: run several coding agents at once?**
>   [x] Conductor   [ ] T3 Code   [ ] Paperclip

> **Voice dictation: which one?**
>   Paid, polished:  [x] Wispr Flow   [ ] Superwhisper
>   Free & private:  [ ] VoiceInk   [ ] Handy

**6. Terminal, shell, browser**: one screen each, as above.

**7. The plan**
> **Here's your Mac.** About 30 minutes and 18 GB.
> *(grouped by category; "already installed" shown dimmed; guided and App
> Store items marked)*
>
> **You'll need to:** sign in to the App Store for Final Cut Pro · download
> Edits and DaVinci Resolve (we'll open the pages) · sign in to Creative
> Cloud for Premiere.
>
> Continue? [Y/n]

**8. Running**: same as today, with category headers.

**9. Finish**
> **Your Mac is ready. ⚡**
> 4 things only you can do. Press Enter to open each:
>   1  Sign in to 1Password
>   2  Download Edits by Instagram
>   3  Finish installing DaVinci Resolve
>   4  Turn on FileVault (System Settings → Privacy & Security)

## Build notes (for later)

- Persona and pack files merge: `essentials.yml` + each chosen persona and
  pack (lists concatenated, de-duplicated).
- Optional items live in the persona file with `recommended: true|false`,
  so the picks screen can tick recommendations.
- New config sections: `apps.mas` (App Store IDs), `apps.guided` (name,
  URL, note), `setup_commands` (name, command, needs), `terminal`, `shell`,
  `security`.
- Terminal UI for multi-select: numbers separated by spaces is the
  baseline; consider arrow-key checkboxes when the terminal supports it.
- New steps: **Terminal & shell**, **Security**, and a **Guided installs**
  checklist at the end. `mise` replaces the nvm module (with a migration
  note for existing nvm users).
- Plan screen: estimated time and size per item (rough, from a lookup
  table).
- Existing presets (`essentials`, `webdev`, `minimal`) become the new
  essentials and developer persona.
- A "last checked" date and a CI job that re-checks every Homebrew name in
  the persona files weekly, so retired apps (like Arc) are caught early.
