<p align="center">
  <img src="docs/images/banner.svg" alt="RICH LINUX — XFCE on Chrome Remote Desktop" width="900">
</p>

<p align="center">
  <a href="https://github.com/ArchDityaa/xfce-crd/actions/workflows/lint.yml"><img src="https://github.com/ArchDityaa/xfce-crd/actions/workflows/lint.yml/badge.svg" alt="Lint"></a>
  <a href="https://github.com/ArchDityaa/xfce-crd/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/runner-ubuntu--24.04-E95420.svg" alt="Runner: ubuntu-24.04 (XFCE 4.18)">
  <img src="https://img.shields.io/badge/session-up%20to%206%20hours-orange.svg" alt="Session: up to 6 hours">
  <img src="https://img.shields.io/badge/desktop-XFCE-4A86CF.svg" alt="Desktop: XFCE">
  <img src="https://img.shields.io/badge/compositor-OFF-111827.svg" alt="Compositor: off">
  <img src="https://img.shields.io/badge/resolution-1280x720-111827.svg" alt="Resolution: 1280x720">
  <img src="https://img.shields.io/badge/access-Chrome%20Remote%20Desktop-4285F4.svg" alt="Access: Chrome Remote Desktop">
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs welcome">
</p>

Run a **lightweight XFCE desktop** in the cloud for free — just **fork this repo**.
Access it from any browser through Chrome Remote Desktop, with nothing to install locally.

[Bahasa Indonesia →](README.md)

> ⚡ **Built for speed:** no compositor, animations disabled, background services masked,
> and a trimmed desktop package set. Every performance figure is measured by the
> workflow itself and written to the Job Summary — see
> [**docs/performance.md**](docs/performance.md).

## Table of Contents

- [Good for](#good-for)
- [At a glance](#at-a-glance)
- [What you get](#what-you-get)
- [Why XFCE (and why it is lighter)](#why-xfce-and-why-it-is-lighter)
- [Desktop variants](#desktop-variants)
- [Requirements](#requirements)
- [Usage (5 steps)](#usage-5-steps)
- [After you connect](#after-you-connect)
- [Limitations & important notes](#limitations--important-notes)
- [Quick troubleshooting](#quick-troubleshooting)
- [Repository layout](#repository-layout)
- [Contributing](#contributing)
- [Credits](#credits)
- [Developer](#developer)

---

## Good for

- Running a **full XFCE desktop environment** in the cloud for experiments.
- Testing / running **GUI tools** (Chrome, terminal, editor, xarchiver, Thunar).
- Learning Linux and desktop environments without touching your own machine.
- Needing a **VM inside a VM** (KVM + virt-manager are included).
- **Lightweight, stable sessions:** small footprint, fast builds, automatic watchdog.

## At a glance

[![Workflow: fork repo, enable Actions, run workflow, form URL, authorize, paste command, device registered, connect, desktop live](docs/images/workflow-en.svg)](docs/images/workflow-en.svg)

> **Important:** the Chrome Remote Desktop auth code is **no longer requested upfront**.
> The workflow waits until the desktop is ready, then shows a web form. The code you
> create afterwards is used immediately, so it never expires during installation.

---

## What you get

One **Ubuntu** virtual machine (4 vCPU / 16 GB RAM) with a fully configured
**XFCE 4.18** desktop, alive for up to **6 hours**, then shut down automatically.
Every run is a clean environment — done, gone.

| Included | Details |
| --- | --- |
| **XFCE Desktop** | Full `xfce4-session` (X11), not just a WM — no lightdm, no GNOME, no Mutter |
| **No compositor** | `xfwm4` compositing **off**: no composite pass, no GL shadows, low idle CPU |
| **Google Chrome** | Ready to log in with your Google account |
| **OpenCode CLI** | Available system-wide (`/usr/local/bin/opencode`) plus a desktop shortcut |
| **Chrome Remote Desktop** | The primary access path |
| **xfce4-terminal + Thunar** | XFCE's terminal and file manager |
| **virt-manager + libvirt/QEMU** | For running nested VMs |
| **Catppuccin Macchiato + Mauve** | GTK + **xfwm4** theme, Papirus icons, cursors, JetBrainsMono Nerd Font, terminal palette |
| **1280x720** | Set through CRD's own `CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES`, automatic fallback to 1024x768 |
| **safe-upgrade** | Drop-in replacement for `apt upgrade` that never drops your session |

Plus: **WIB (Asia/Jakarta)** timezone, screensaver & lock **not installed at all**, and
every timer/service that could disturb a session is masked.

## Why XFCE (and why it is lighter)

This repo exists for one reason: **a remote desktop that stays light and stable**.
These are the levers used:

| Lever | Effect |
| --- | --- |
| **Compositor off** (`xfwm4`) | No per-frame composite pass, no llvmpipe work for shadows/alpha. Lower idle CPU, cheaper frame capture for CRD. |
| **GTK animations off** | No repeated redraws when opening menus and windows in software rendering. |
| **Trimmed desktop packages** | No `xfce4-goodies`, power-manager, screensaver, tumbler, or polling panel plugins. |
| **Minimal autostart** | Only `xfwm4`, `xfsettingsd`, `xfce4-panel`, `xfdesktop`, `xfce4-notifyd`. No `Thunar --daemon`. |
| **Timers & services masked** | `apt-daily`, `unattended-upgrades`, `motd-news`, `man-db` — the usual suspects behind "the session froze". |
| **Lock removed entirely** | No locker package, so no dialog can ever hang the session. |
| **No display manager** | No lightdm/GDM adding services and startup time. |
| **GitHub `.deb` cache** | Re-runs after a failure are fast because ~1 GB is not downloaded again. |
| **Watchdog + metrics** | Sessions recover automatically; every run is measured automatically. |

> Concrete numbers (build time, idle RAM, idle CPU, package count) are **measured** by
> the workflow and written to the **Job Summary** on every run. See
> [`docs/performance.md`](docs/performance.md) for the methodology.

## Desktop variants

| | **XFCE 24.04** |
| --- | --- |
| Workflow | `.github/workflows/xfce.yml` |
| Runner | `ubuntu-24.04` |
| Desktop | XFCE 4.18 (X11, `xfce4-session`) |
| CRD device | `xfce` |
| File manager | Thunar |
| Resolution | 1280x720 (fallback 1024x768) |
| Compositor | Disabled |

## Requirements

- A **GitHub** account (free). Public runners mean unlimited Actions minutes.
- A **Google** account (for Chrome Remote Desktop).
- A Chrome/Chromium browser (to open the Remote Access page).
- No Cloudflare account needed — the workflow creates a quick tunnel automatically.

No credit card, no server, no self-hosted runner.

---

## Usage (5 steps)

### 1. Fork this repository

Click **Fork** in the top-right corner → **Create fork**.

### 2. Enable Actions on your fork

> **This is the most commonly missed step.** GitHub disables workflows on forked repos.

> **Settings** → **Actions** → **General** → choose **Allow all actions and reusable workflows** → **Save**.

### 3. Run the workflow (no auth input)

1. Open the **Actions** tab on your fork.
2. Pick **XFCE 24.04** in the left sidebar.
3. Click **Run workflow** (top right).
4. Leave the **crd_host_command** field **empty** — it is only a fallback.
5. Click the green **Run workflow** button.

**Optional — change the PIN:** create a `CRD_PIN` secret under **Settings → Secrets and variables → Actions → New repository secret** (at least 6 digits). Default PIN is `123456`.

### 4. Open the auth form and authorize

Once installation finishes (**~8–15 minutes**), the log shows:

```
[OK] FORM OTORISASI SIAP
```

The form URL also appears in the run's **Job Summary**. Open it (from your phone or another network is fine). If Cloudflare returns **1033/502**, wait ~15 seconds and refresh — the tunnel is warming up.

Then:

1. In another tab, open [https://remotedesktop.google.com/headless](https://remotedesktop.google.com/headless) and sign in with your Google account.
2. Click **Begin** → **Next** → **Authorize**.
3. Under **"Set up another computer" / "Debian Linux"**, copy the **entire** command. It looks like:

```
DISPLAY= /opt/google/chrome-remote-desktop/start-host --code="4/0Ab..." --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$(hostname)
```

4. Paste it into the form and submit.

The form shows live status. If registration fails (wrong, expired, or already-used code), grab a **fresh** command from the headless page and submit again to the same form — **no workflow re-run needed** while the 30-minute window is open.

The form uses a responsive two-column layout, a **monochrome grayscale** theme with *Auto / Light / Dark* modes, an **ID / EN** language toggle, a 4-step guide, a countdown, a progress bar, and command format validation. Commands and OAuth codes are **never stored** in your browser.

> **Never share the form URL.** It contains a random token that acts as a temporary credential for ~30 minutes.

### 5. Wait & connect

When the log shows:

```
[OK] CHROME REMOTE DESKTOP READY
```

open [https://remotedesktop.google.com/access](https://remotedesktop.google.com/access), pick the device named **xfce**, and enter your PIN.

|  |  |
| --- | --- |
| **User** | `runner` (password: `root`) |
| **PIN** | `123456` (or your own `CRD_PIN` secret) |
| **Device** | `xfce` |
| **Duration** | up to ~6 hours, then the VM is shut down |

---

## After you connect

- **Terminal:** `Ctrl+Alt+T`, the terminal icon in the panel, or the **Terminal** desktop shortcut.
- **File manager:** **Thunar** (folder icon in the panel, or the **File Manager** desktop shortcut).
- **Application launcher:** `Super` (Whisker Menu) or `Super+P` (Application Finder).
- **OpenCode CLI:** the **OpenCode** desktop shortcut, or run `opencode` in a terminal.
- **Upgrade packages safely:**

```
sudo safe-upgrade
```

  There is also a **Safe Upgrade** desktop shortcut. **Do not** run plain `sudo apt upgrade -y` — it can restart Chrome Remote Desktop and drop your session.

- **Run VMs (KVM):** open `virt-manager` from the application menu. x86 runners expose KVM, so guests run with hardware acceleration.
- **Desktop settings:** the **Settings** desktop shortcut (Xfce Settings Manager).
- **Theme:** Catppuccin Macchiato + Mauve is preinstalled (GTK + xfwm4 + icons + cursors + fonts + terminal).

> ⚠ **Important security notice**

> The authorization form URL contains a **random 128-bit token** that acts as a temporary credential for ~30 minutes. Anyone who opens it can send a registration command to your desktop. **Never share the form URL**, and close the form tab when you are done. On a **public** repo, logs and the Job Summary are visible to anyone while a run is active — use a **private fork** if that matters to you.

## Limitations & important notes

- **6 hours max per run.** That is the GitHub-hosted job limit. Plan your work and save results to GitHub/cloud, because the VM disappears afterwards.
- **Ephemeral instances.** No persistent storage between runs.
- **No compositor.** This is intentional (performance), but it means no blurred/translucent panel or window shadows. The window manager uses the Catppuccin theme with shadows disabled.
- **Animations are off.** Menus and windows appear instantly, without transitions. A deliberate performance choice.
- **30-minute authorization window.** After the desktop is ready, the form only accepts commands for 30 minutes. After that, re-run the workflow (the `.deb` cache makes it much faster).
- **Cloudflare quick tunnels have no SLA.** The URL is random and may need a refresh when first opened. If the tunnel dies, the workflow retries up to 3 times and shows a new URL.
- **Audio** runs through PipeWire (PulseAudio compatibility layer). The mixer lives in the panel.
- **Follow the GitHub Actions ToS.** This repo is meant for *experimentation and tool testing*; do not use it for general hosting/computing or crypto mining.
- **Save bandwidth:** forks do not receive upstream updates automatically. Use **Sync fork** on GitHub.

## Quick troubleshooting

| Problem | Cause & fix |
| --- | --- |
| Workflow missing from the Actions tab | The fork has not enabled Actions → **Settings → Actions → General → Allow all actions**. |
| Form URL never appears | Check the **Authorize & Register Chrome Remote Desktop (Web UI)** step. The `.deb` cache is reused, so a re-run is much faster. |
| Cloudflare 1033/502 on the form | The tunnel is warming up. Wait ~15 seconds and refresh. |
| Registration via the form fails | The OAuth code expired or was already used. Fetch a **new** command from [remotedesktop.google.com/headless](https://remotedesktop.google.com/headless) and resubmit to the same form. |
| The 30-minute window expired | The workflow stops. Re-run it; the `.deb` cache makes installation much faster. |
| Blank desktop / missing panel | `xfce4-panel` may have failed to start. Check `~/.xsession-errors` or run `xfce4-panel &` in a terminal. |
| Resolution stays at 1024x768 | The dummy driver refused the 1280x720 mode → automatic fallback to 1024x768 (normal, not fatal). |
| Session dropped during a package update | You used plain `apt upgrade`. Use `sudo safe-upgrade`. |
| `virt-manager`: "Permission denied" on libvirt | Log out and back in, or run `virsh -c qemu:///session`. |
| `Cannot access KVM` | KVM is available on x86 runners. Check `ls -l /dev/kvm`; if it exists but still fails, open an issue with the run log. |

Full guide: [`docs/troubleshooting.md`](docs/troubleshooting.md) · FAQ: [`docs/faq.md`](docs/faq.md) · Performance: [`docs/performance.md`](docs/performance.md) · Architecture: [`docs/architecture.md`](docs/architecture.md)

---

## Repository layout

```
.
├── .github/
│   ├── workflows/
│   │   ├── xfce.yml             # main XFCE workflow (Ubuntu 24.04, X11)
│   │   └── lint.yml             # CI: actionlint + yamllint + shellcheck
│   ├── ISSUE_TEMPLATE/
│   └── dependabot.yml
├── scripts/
│   ├── xfce/                    # one script per workflow step
│   │   ├── 01-prepare-system.sh
│   │   ├── 02-install-xfce-desktop.sh
│   │   ├── ...
│   │   ├── 18-keep-alive.sh
│   │   ├── set-resolution.sh    # 1280x720 helper (falls back to 1024x768)
│   │   ├── set-wallpaper.sh     # runtime wallpaper helper
│   │   ├── xfce-performance-guard.sh  # forces compositor/animations off at start
│   │   └── lib/metrics.sh       # metric collection helpers
│   ├── crd-web-auth.py          # authorization form server (token + status)
│   └── safe-upgrade.sh          # session-safe upgrade helper
├── assets/xfce/                 # static content: apt pins, xfconf, session, autostart, systemd, .desktop, terminalrc
├── docs/
│   ├── images/banner.svg
│   ├── images/workflow-id.svg
│   ├── images/workflow-en.svg
│   ├── images/badges/           # social icons (Simple Icons, CC0)
│   ├── faq.md
│   ├── troubleshooting.md
│   ├── performance.md
│   ├── architecture.md
│   └── adding-screenshots.md
├── .yamllint.yml                # YAML linter configuration
├── README.md                    # Bahasa Indonesia
├── README.en.md                 # This document
├── CHANGELOG.md
└── LICENSE
```

Every substantive `run:` block in the workflow calls exactly one script from
`scripts/xfce/`. Static content (apt pins, xfconf configuration, session template,
`.desktop` files, `terminalrc`) lives in `assets/xfce/` so the YAML stays short and
readable.

## Contributing

Pull requests are very welcome. All YAML, workflows, and scripts are validated
automatically by the **Lint** CI job on every push to `main` and every pull request.

Run the same linters locally before pushing:

```
pip install yamllint
yamllint .
# shellcheck reads the repo rules from .shellcheckrc (SC2016/SC2034/SC2012
# are intentional); -x follows sourced files.
find scripts assets -name '*.sh' -print0 | xargs -0 shellcheck -x
python3 -m py_compile scripts/crd-web-auth.py
# actionlint: https://github.com/rhysd/actionlint
actionlint -ignore SC2016 -ignore SC2034 -ignore SC2012
```

## Credits

- [Catppuccin](https://github.com/catppuccin) — GTK/xfwm4 theme, cursors, terminal, wallpaper
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) — icon theme
- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) — JetBrainsMono
- Google Chrome Remote Desktop
- [Simple Icons](https://simpleicons.org/) — social icons (CC0)

## Developer

### ArchDityaa

Developer & maintainer · [masadityaaa.vercel.app](https://masadityaaa.vercel.app) (Portfolio: masadityaaa.vercel.app)

[![ArchDityaa](https://github.com/ArchDityaa.png?size=100)](https://github.com/ArchDityaa "GitHub: ArchDityaa") [![Instagram](docs/images/badges/instagram.svg)](https://www.instagram.com/aaaditz_ "Instagram: aaaditz_") [![TikTok](docs/images/badges/tiktok.svg)](https://www.tiktok.com/@kiraadityaa "TikTok: kiraadityaa") [![WhatsApp](docs/images/badges/whatsapp.svg)](https://wa.me/6281553362795 "WhatsApp: 0815-5336-2795")

© ArchDityaa · [MIT License](LICENSE) · [Back to top ↑](#table-of-contents)
