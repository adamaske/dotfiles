# setup-remote-ssh.ps1 — turn this desktop into the SSH host for herdr.
#
# Goal: reach this machine's running herdr server from a laptop/phone over SSH.
#   Network : Tailscale only (firewall scoped to the 100.64.0.0/10 CGNAT range —
#             NOT exposed to the LAN or the public internet).
#   Auth    : public-key only (password auth disabled).
#   Shell   : SSH sessions land in pwsh (loads the profile + `herd`/`herdr`).
#
# RUN ELEVATED (it edits services, HKLM, sshd_config, the firewall). Idempotent —
# safe to re-run. Tailscale itself is installed separately (see Set-Up notes / GUIDE §13).

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

function Say($m){ Write-Host "[ssh-setup] $m" -ForegroundColor Cyan }

# --- 1. Ensure OpenSSH Server present ----------------------------------------
# Get-WindowsCapability (DISM) often throws "Class not registered" under
# PowerShell 7. Prefer the binary check; only fall back to DISM if it's missing.
if (Test-Path 'C:\Windows\System32\OpenSSH\sshd.exe') {
    Say "OpenSSH Server present (sshd.exe found)."
} else {
    Say "sshd.exe missing; installing OpenSSH.Server via DISM (Windows PowerShell)..."
    powershell.exe -NoProfile -Command "Add-WindowsCapability -Online -Name (Get-WindowsCapability -Online -Name 'OpenSSH.Server*').Name" | Out-Null
}

# --- 2. Services: sshd + ssh-agent automatic & running -----------------------
Set-Service -Name sshd      -StartupType Automatic
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent
Start-Service sshd
Say "sshd + ssh-agent set Automatic and started."

# --- 3. Default shell for SSH sessions = pwsh (stable execution-alias path) ---
$pwsh = "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe"
if (-not (Test-Path $pwsh)) { $pwsh = (Get-Command pwsh).Source }
if (-not (Test-Path 'HKLM:\SOFTWARE\OpenSSH')) { New-Item -Path 'HKLM:\SOFTWARE\OpenSSH' -Force | Out-Null }
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value $pwsh -PropertyType String -Force | Out-Null
Say "DefaultShell -> $pwsh"

# --- 4. Are we an admin account? Picks the authorized_keys file & ACLs --------
# Windows OpenSSH ignores ~/.ssh/authorized_keys for members of Administrators
# and uses C:\ProgramData\ssh\administrators_authorized_keys (locked-down ACL).
$adminSid  = 'S-1-5-32-544'
$userSid   = ([Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
$isAdmin   = (Get-LocalGroupMember -SID $adminSid | Where-Object { $_.SID.Value -eq $userSid }).Count -gt 0

if ($isAdmin) {
    $akFile = 'C:\ProgramData\ssh\administrators_authorized_keys'
    Say "Account is an Administrator -> keys go in $akFile"
} else {
    $akFile = "$env:USERPROFILE\.ssh\authorized_keys"
    New-Item -ItemType Directory -Force -Path (Split-Path $akFile) | Out-Null
    Say "Standard account -> keys go in $akFile"
}
if (-not (Test-Path $akFile)) { New-Item -ItemType File -Force -Path $akFile | Out-Null }

# Correct ACLs (OpenSSH refuses keys on loosely-permissioned files).
# Use SIDs, not names — built-in group names are localized (e.g. "Administratorer"
# on Norwegian Windows) and name-based icacls grants silently fail.
# *S-1-5-18 = SYSTEM, *S-1-5-32-544 = Administrators.
if ($isAdmin) {
    icacls $akFile /inheritance:r /grant '*S-1-5-18:F' '*S-1-5-32-544:F' | Out-Null
} else {
    icacls $akFile /inheritance:r /grant "*$userSid:F" '*S-1-5-18:F' '*S-1-5-32-544:F' | Out-Null
}

# --- 5. Harden sshd_config: pubkey only, no passwords ------------------------
$cfg = 'C:\ProgramData\ssh\sshd_config'
if (Test-Path $cfg) {
    $c = Get-Content $cfg -Raw
    # Drop the default catch-all that points admins' keys elsewhere only if we
    # rely on it (we keep the platform default — administrators_authorized_keys).
    $c = $c -replace '(?m)^\s*#?\s*PasswordAuthentication\s+.*$', 'PasswordAuthentication no'
    $c = $c -replace '(?m)^\s*#?\s*PubkeyAuthentication\s+.*$',   'PubkeyAuthentication yes'
    if ($c -notmatch '(?m)^PasswordAuthentication\s+no')  { $c += "`r`nPasswordAuthentication no" }
    if ($c -notmatch '(?m)^PubkeyAuthentication\s+yes')   { $c += "`r`nPubkeyAuthentication yes" }
    Set-Content -Path $cfg -Value $c -Encoding ascii
    Say "sshd_config hardened (PasswordAuthentication no, PubkeyAuthentication yes)."
} else { Say "WARN: $cfg not found yet; start sshd once then re-run." }

# --- 6. Firewall: inbound TCP/22 ONLY from the Tailscale CGNAT range ----------
$ruleName = 'herdr-ssh (Tailscale only)'
Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow `
    -Protocol TCP -LocalPort 22 -RemoteAddress '100.64.0.0/10' | Out-Null
# Make sure no broad "allow 22 from anywhere" rule is left enabled.
Get-NetFirewallRule -DisplayName 'OpenSSH SSH Server*' -ErrorAction SilentlyContinue |
    Where-Object Enabled -eq 'True' | Disable-NetFirewallRule
Say "Firewall: TCP/22 allowed only from 100.64.0.0/10 (Tailscale); broad OpenSSH rule disabled."

# --- 7. Restart to apply ------------------------------------------------------
Restart-Service sshd
Say "Done. From another Tailscale device:  ssh adama@<this-machine-tailscale-name>  then run: herdr"
Write-Host ""
Write-Host "NEXT: add a device public key with (elevated, on this box):" -ForegroundColor Yellow
Write-Host "  Add-Content '$akFile' 'ssh-ed25519 AAAA... your-device'" -ForegroundColor Yellow
