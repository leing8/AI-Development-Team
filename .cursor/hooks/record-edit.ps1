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

function Write-EditedFiles([string]$Path, [string[]]$Files) {
    $items = @($Files | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    if ($items.Count -eq 0) {
        $json = '{"files":[]}'
    } else {
        $encoded = @($items | ForEach-Object {
            '"' + ($_.Replace('\', '\\').Replace('"', '\"')) + '"'
        })
        $json = '{ "files": [' + ($encoded -join ',') + '] }'
    }
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $json, $utf8)
}

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        Write-HookJson '{}'
        exit 0
    }
    $hook = $raw | ConvertFrom-Json
    $conversation = [string]$hook.conversation_id
    if ([string]::IsNullOrWhiteSpace($conversation)) { $conversation = [string]$hook.conversationId }
    if ([string]::IsNullOrWhiteSpace($conversation)) { $conversation = [string]$hook.session_id }
    $filePath = [string]$hook.file_path
    if ([string]::IsNullOrWhiteSpace($filePath)) { $filePath = [string]$hook.path }
    if ([string]::IsNullOrWhiteSpace($filePath)) { $filePath = [string]$hook.filePath }
    if ([string]::IsNullOrWhiteSpace($filePath)) {
        Write-HookJson '{}'
        exit 0
    }
    $statePath = Get-StatePath $conversation
    $files = @(Read-EditedFiles $statePath)
    $files += $filePath
    Write-EditedFiles $statePath @($files)
    Write-HookJson '{}'
    exit 0
} catch {
    Write-HookJson '{}'
    exit 0
}
