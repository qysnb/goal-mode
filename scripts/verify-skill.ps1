# goal-mode repo: generate per-agent variants from canonical SKILL.md and verify all.
# Usage:  pwsh scripts/verify-skill.ps1
# Flags:  -SkipGenerate  (only verify, do not regenerate variants)
param([switch]$SkipGenerate)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$canonicalPath = Join-Path $repo 'SKILL.md'
$fail = 0

function Get-Fm([string]$raw, [string]$key) {
    $r = [regex]::Match($raw, "(?m)^$key\s*:\s*(.+)$")
    if ($r.Success) { return $r.Groups[1].Value.Trim() }
    return $null
}
function Check($cond, [string]$label) {
    if ($cond) { Write-Host "  [PASS] $label" }
    else { Write-Host "  [FAIL] $label"; $script:fail = 1 }
}

$content = Get-Content -LiteralPath $canonicalPath -Raw -Encoding utf8
$m = [regex]::Match($content, '(?s)^---\r?\n(.*?)\r?\n---\r?\n?')
if (-not $m.Success) { Write-Host "[FAIL] canonical SKILL.md has no valid frontmatter"; exit 1 }
$fmRaw = $m.Groups[1].Value
$body = $content.Substring($m.Length)

$name  = Get-Fm $fmRaw 'name'
$desc  = Get-Fm $fmRaw 'description'

Write-Host "== Canonical (root SKILL.md) =="
Check ($name -eq 'goal-mode') "name == goal-mode (got: $name)"
Check ($null -ne $desc -and $desc.Length -gt 50) "description present (len=$($desc.Length))"
$keys = ([regex]::Matches($fmRaw, '(?m)^([A-Za-z0-9_-]+)\s*:') | ForEach-Object { $_.Groups[1].Value })
$extraKeys = $keys | Where-Object { $_ -notin @('name', 'description') }
Check ($extraKeys.Count -eq 0) "frontmatter has ONLY name+description (extra: $($extraKeys -join ','))"
Check ($body -match 'Phase 0') "body contains Phase 0"
Check ($body -match 'Phase 5') "body contains Phase 5"
Check ($body -match '关键规则') "body contains 关键规则"
Check ($body -match 'GOAL_STATE\.json') "state file is neutral GOAL_STATE.json"

$variants = @(
    @{ dir = 'agents\opencode';       extra = @('argument-hint: "<目标描述> | resume"', 'allowed-tools: Bash(*), Read, Write, Edit, Glob, Grep, Task, Skill, WebFetch, WebSearch') },
    @{ dir = 'agents\claude-code';    extra = @('argument-hint: "<目标描述> | resume"') }
)

if (-not $SkipGenerate) {
    foreach ($v in $variants) {
        $d = Join-Path $repo $v.dir
        New-Item -ItemType Directory -Force -Path $d | Out-Null
        $fm = "name: $name`r`ndescription: $desc`r`n" + (($v.extra | ForEach-Object { "$_`r`n" }) -join '')
        $out = "---`r`n$fm---`r`n$body"
        [System.IO.File]::WriteAllText((Join-Path $d 'SKILL.md'), $out, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "  generated $($v.dir)/SKILL.md"
    }
}

Write-Host "== Variants =="
foreach ($v in $variants) {
    $p = Join-Path $repo (Join-Path $v.dir 'SKILL.md')
    if (-not (Test-Path -LiteralPath $p)) { Check $false "$($v.dir)/SKILL.md exists"; continue }
    $c = Get-Content -LiteralPath $p -Raw -Encoding utf8
    $mm = [regex]::Match($c, '(?s)^---\r?\n(.*?)\r?\n---\r?\n?')
    if (-not $mm.Success) { Check $false "$($v.dir): valid frontmatter"; continue }
    $fm2 = $mm.Groups[1].Value
    Check ((Get-Fm $fm2 'name') -eq 'goal-mode') "$($v.dir): name ok"
    Check ((Get-Fm $fm2 'description') -eq $desc) "$($v.dir): description identical to canonical"
    $body2 = $c.Substring($mm.Length)
    Check ($body2 -eq $body) "$($v.dir): body identical to canonical"
}

Write-Host ""
if ($fail -eq 1) { Write-Host "RESULT: FAIL"; exit 1 }
Write-Host "RESULT: ALL PASS"; exit 0