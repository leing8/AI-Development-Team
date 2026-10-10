$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-HookJson([string]$Json) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $bytes = $utf8.GetBytes($Json + "`n")
    $stdout = [Console]::OpenStandardOutput()
    $stdout.Write($bytes, 0, $bytes.Length)
    $stdout.Flush()
}

function Get-StatePath([string]$ConversationId) {
    if ([string]::IsNullOrWhiteSpace($ConversationId)) { $ConversationId = 'unknown' }
    $safe = [regex]::Replace($ConversationId, '[^a-zA-Z0-9_-]', '_')
    $dir = Join-Path $PSScriptRoot 'state'
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    return Join-Path $dir "$safe.json"
}

function Read-EditedFiles([string]$Path) {
    if (-not (Test-Path $Path)) { return @() }
    try {
        $data = Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($null -eq $data.files) { return @() }
        return @($data.files)
    } catch {
        return @()
    }
}

function Clear-EditedFiles([string]$Path) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, '{"files":[]}', $utf8)
}

function Normalize-RepoPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
    return (($Path -replace '\\', '/') -replace '^\./', '')
}

function Test-SourceFile([string]$Path) {
    $normalized = Normalize-RepoPath $Path
    if ($normalized -match '(^|/)\.cursor(/|$)') { return $false }
    if ($normalized -match '(^|/)\.team(/|$)') { return $false }
    if ($normalized -match '(^|/)(node_modules|target)(/|$)') { return $false }
    $extension = [System.IO.Path]::GetExtension($normalized).ToLowerInvariant()
    $sources = @(
        '.go', '.java', '.kt', '.kts', '.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs',
        '.py', '.rs', '.cs', '.vue', '.sql', '.xml', '.yml', '.yaml', '.json',
        '.gradle', '.properties', '.php', '.rb', '.swift'
    )
    return $sources -contains $extension
}

function Test-VerificationFile([string]$Path) {
    $normalized = Normalize-RepoPath $Path
    return $normalized -match '(^|/)\.team/engagements/[^/]+/verification\.md$'
}

try {
    $raw = [Console]::In.ReadToEnd()
    $hook = $null
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
        $hook = $raw | ConvertFrom-Json
    }
    $loop = 0
    $conversation = 'unknown'
    $status = 'completed'
    if ($null -ne $hook) {
        if ($null -ne $hook.loop_count) { $loop = [int]$hook.loop_count }
        if (-not [string]::IsNullOrWhiteSpace([string]$hook.conversation_id)) {
            $conversation = [string]$hook.conversation_id
        } elseif (-not [string]::IsNullOrWhiteSpace([string]$hook.conversationId)) {
            $conversation = [string]$hook.conversationId
        } elseif (-not [string]::IsNullOrWhiteSpace([string]$hook.session_id)) {
            $conversation = [string]$hook.session_id
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$hook.status)) {
            $status = [string]$hook.status
        }
    }
    $statePath = Get-StatePath $conversation
    if ($status -eq 'aborted' -or $status -eq 'error' -or $loop -ge 1) {
        Clear-EditedFiles $statePath
        Write-HookJson '{}'
        exit 0
    }
    $files = @(Read-EditedFiles $statePath)
    $sources = @($files | Where-Object { Test-SourceFile $_ })
    $verified = @($files | Where-Object { Test-VerificationFile $_ })
    if ($sources.Count -eq 0 -or $verified.Count -gt 0) {
        Clear-EditedFiles $statePath
        Write-HookJson '{}'
        exit 0
    }
    $shown = @($sources | Select-Object -First 8)
    $list = ($shown | ForEach-Object { Normalize-RepoPath $_ }) -join '、'
    $message = "本轮改了代码（$list），但没有更新该需求的 verification.md。请派出只读的 verifier，对照 prd.md、impact.md 和 .team/capabilities.md 验收。由你把结论写入 verification.md，结论行必须是「结论: 通过」或「结论: 不通过」。在写出通过结论之前，不要告诉用户功能已经完成。"
    $payload = @{ followup_message = $message }
    Write-HookJson ($payload | ConvertTo-Json -Compress -Depth 4)
    exit 0
} catch {
    Write-HookJson '{}'
    exit 0
}
