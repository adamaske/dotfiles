# Remote dev — reach herdr on this desktop from anywhere

This desktop (**`slegge`**) is the SSH host. Its persistent **herdr** server keeps
your panes, tabs, and Claude agents alive; you SSH in from a laptop or phone over
**Tailscale**, attach herdr, and pick up exactly where you left off. Detach (your
`prefix+q` = `ctrl+a q`) from one device and reattach from another.

> Why herdr and not tmux: herdr already does persistent detach/reattach *and*
> remote SSH (it's "tmux for agents"). Same reboot caveat as tmux — see below.

---

## Architecture

| Piece | Where | Notes |
|---|---|---|
| Network | **Tailscale** | Firewall scopes SSH to `100.64.0.0/10` only — not LAN, not public internet. |
| Auth | **Public-key only** | Password auth disabled. Keys in `C:\ProgramData\ssh\administrators_authorized_keys` (admin account → special file). |
| Shell | **pwsh** | `HKLM\SOFTWARE\OpenSSH\DefaultShell` → pwsh, so SSH sessions load the profile + `herd`/`herdr`. |
| Server | **OpenSSH `sshd`** | Service `Automatic`, listening on TCP/22. |
| herdr | headless server | Already running at login (komorebi startup → `herdr server` + `Herd-Init`). |

Host identity: Tailscale name **`slegge`**, IP **`100.105.195.41`**.

---

## Connect (from any Tailscale device)

```bash
ssh adama@slegge          # or: ssh adama@100.105.195.41
herdr                     # attach the running session
# herd <name>             # or jump straight to a workspace (dev/config/nw/ce/ae)
```

Phone SSH clients (Termius, Blink, etc.) work the same — detaching with
`ctrl+a q` leaves everything running on the desktop.

---

## Adding a new device (one-time per device)

1. **On the client device**, generate a keypair:
   ```bash
   ssh-keygen -t ed25519 -C "<device-name>"
   cat ~/.ssh/id_ed25519.pub        # Windows: Get-Content ~/.ssh/id_ed25519.pub
   ```
   (Phone apps: use their "Keys" section to generate + show the public key.)
   The **private** key (`id_ed25519`, no `.pub`) never leaves the device.

2. **On this desktop**, append the public line (must be elevated — the file is
   admin-only):
   ```powershell
   # run in an elevated pwsh
   Add-Content 'C:\ProgramData\ssh\administrators_authorized_keys' 'ssh-ed25519 AAAA... <device-name>'
   ```

3. Install Tailscale on the new device and `tailscale up` (same tailnet).

---

## Persistence — what survives (same as tmux)

| Event | Processes | Layout | Agent convo |
|---|---|---|---|
| **Detach / reattach** (any device) | ✅ kept | ✅ | ✅ |
| **Server stop / reboot** | ❌ gone | ✅ shape restored | resume only |

After a reboot herdr restores the workspace *shape* (empty pwsh shells); login
runs **`Herd-Init`** to re-issue nvim/claude/dev-server commands. There is no
reboot-survival of running processes in either herdr or tmux.

---

## Rebuild / re-run the host setup

Idempotent, version-controlled in this repo — run **elevated**:

```powershell
& 'C:\Users\adama\.config\herdr\setup-remote-ssh.ps1'
```

It ensures OpenSSH Server, sets `sshd`/`ssh-agent` Automatic, points DefaultShell
at pwsh, picks the right `authorized_keys` file with correct (SID-based) ACLs,
hardens `sshd_config` (pubkey-only), and scopes the firewall to Tailscale.

### Gotchas baked into the script
- `Get-WindowsCapability`/`Add-WindowsCapability` (DISM) throw **"Class not
  registered"** under PowerShell 7 → the script checks for `sshd.exe` instead and
  only falls back to DISM via Windows PowerShell 5.1.
- Built-in group names are **localized** ("Administratorer" on this Norwegian
  Windows) → ACLs are granted by **SID** (`*S-1-5-32-544`, `*S-1-5-18`), not name,
  or `icacls` silently no-ops and sshd then rejects the keys file.

---

## Troubleshoot

```powershell
Get-Service sshd                                   # Running / Automatic?
Get-NetTCPConnection -LocalPort 22 -State Listen   # listening?
icacls C:\ProgramData\ssh\administrators_authorized_keys   # only Administratorer:(F) + SYSTEM:(F)
& 'C:\Program Files\Tailscale\tailscale.exe' status        # both devices online?
Get-Content C:\ProgramData\ssh\logs\sshd.log -Tail 40      # auth failures
```

Common cause of "Permission denied (publickey)": wrong ACL on the keys file, or
the key landed in `~/.ssh/authorized_keys` instead of the admin file (admin
accounts only read `administrators_authorized_keys`).
