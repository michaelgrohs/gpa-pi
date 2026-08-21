# Running n8n locally

This gets you a working n8n instance on your own machine — free, no account, no Docker —
so you can import and run the workflows in this folder (`purchase-approval-workflow.json`,
`email-triage-workflow.json`). Do this once at the start, then come back to
[`README_purchase-order.md`](README-purchase-order.md) / [`README-email-triage.md`](README-email-triage.md) for
the actual workflow exercises.

## Prerequisites

**Node.js 22.22 or later** (this is what n8n itself requires). Check what you have:

```bash
node -v
```

If you don't have Node, or have an older version, install it from
[nodejs.org](https://nodejs.org) — pick the "LTS" build — or via a version manager like
[nvm](https://github.com/nvm-sh/nvm) (`nvm install --lts`). The install script also checks
this for you and tells you exactly what's missing.

You do **not** need a Docker install, an n8n Cloud account, or a global `npm install -g n8n`.

## Run it

**macOS / Linux / Windows with WSL or Git Bash:**

```bash
cd 04_RPA-in-Action/n8n
./install-and-run.sh
```

**Windows (PowerShell), no WSL:**

```powershell
cd 04_RPA-in-Action\n8n
.\install-and-run.ps1
```

The first run installs n8n (pinned to version `2.32.6` — the exact version the workflows in
this repo were verified against, so what you see on screen matches the READMEs) into a local
`.n8n-runtime/` folder next to the script. **This can take 10-15 minutes** — a couple of n8n's
dependencies (`isolated-vm`, `ssh2`) compile native code from source, which is slow even when
it's working correctly; don't interrupt it just because it looks stuck for a few minutes at a
time. Every run after that skips straight to starting n8n and takes only a few seconds.

Once you see `Editor is now accessible via:` in the terminal, open **http://localhost:5678**
in your browser. Leave the terminal window open — that's the running n8n server; closing it
(or `Ctrl+C`) stops n8n.

## Where your data lives

Everything — n8n itself, your workflows, credentials, and execution history — is stored
inside `.n8n-runtime/` next to the script. Nothing is written to your home directory or to
any global npm location. That means:

- Your work (imported workflows, credentials you create) **persists** across runs — stopping
  and re-running the script picks up where you left off.
- To start completely fresh (e.g. you made a mess of a workflow and want a clean slate),
  either delete the `.n8n-runtime/data` folder yourself, or run:

  ```bash
  ./install-and-run.sh reset       # macOS/Linux
  .\install-and-run.ps1 -Reset     # Windows PowerShell
  ```

  This wipes your workflows/credentials but keeps n8n itself installed, so the next start is
  fast.
- `.n8n-runtime/` is machine-specific generated state (like `node_modules`) — it's already
  covered by this repo's `.gitignore`, so don't commit it.

## Troubleshooting

**`npm install` fails while compiling a native module.** A couple of n8n's dependencies ship
native (C/C++) addons — `isolated-vm` (sandboxes the Code node) and `ssh2` (the SSH/SFTP
nodes) are the ones most likely to trigger this — and they need to compile from source if npm
can't find a prebuilt binary for your exact platform/Node version. This is expected to take
several extra minutes even when it succeeds (`isolated-vm` in particular compiles dozens of
C++ files one at a time). Fixes if it actually fails outright:

- **macOS:** install the Xcode Command Line Tools, then re-run the script:
  ```bash
  xcode-select --install
  ```
- **Linux (Debian/Ubuntu):**
  ```bash
  sudo apt-get install -y build-essential python3
  ```
- **Windows (PowerShell, no WSL):** install the Visual Studio Build Tools ("Desktop
  development with C++" workload), or simply switch to running `install-and-run.sh` under
  WSL instead, which avoids this entirely.

After installing the missing tool, just re-run the script — npm resumes the install rather
than starting over.

**Windows: script execution policy.** If PowerShell refuses to run `install-and-run.ps1`
with an error like "running scripts is disabled on this system," it's PowerShell's default
security policy blocking unsigned local scripts. Allow it for just this file:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-and-run.ps1
```

**Port 5678 already in use.** Something else on your machine is already using n8n's default
port (possibly another n8n instance you started earlier and forgot about — check for a
leftover terminal window). Either close that process, or run this instance on a different
port:

```bash
N8N_PORT=5679 ./install-and-run.sh   # then open http://localhost:5679 instead
```

**Nothing happens / browser can't connect after "Editor is now accessible via:".** Make sure
you're opening `http://localhost:5678` (not `https://`), and that no other tool (VPN,
firewall, antivirus) is blocking local connections on that port.

## What the script is doing, briefly

`install-and-run.sh` / `install-and-run.ps1` do the same three things:

1. Check that Node.js is installed and new enough.
2. `npm install` a pinned version of `n8n` into a local `.n8n-runtime/node_modules` — scoped
   to this folder, not installed globally, so it can't conflict with anything else on your
   system or need admin/sudo permissions.
3. Start it (`npx n8n start`) with its data folder pointed at `.n8n-runtime/data`, and a few
   optional features (telemetry, update checks, the online template browser) turned off since
   they're not needed for these exercises.
