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

try {
    $raw = [Console]::In.ReadToEnd()
    $command = ''
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
        $hook = $raw | ConvertFrom-Json
        $command = [string]$hook.command
    }
    $isResetHard = $command -match '(?i)\bgit(\.exe)?\b' -and $command -match '(?i)\breset\b' -and $command -match '(?i)(^|\s)--hard(\s|$)'
    $isForcePush = $command -match '(?i)\bgit(\.exe)?\b' -and $command -match '(?i)\bpush\b' -and (
        $command -match '(?i)(^|\s)--force(\s|$)' -or $command -match '(?i)(^|\s)-f(\s|$)'
    )
    if ($isResetHard -or $isForcePush) {
        $payload = @{
            permission    = 'ask'
            user_message  = '这条命令会改写远程历史或丢掉本地改动，确认后才会执行。'
            agent_message = '钩子要求确认后才能执行 git push --force 或 git reset --hard。'
        }
        Write-HookJson ($payload | ConvertTo-Json -Compress -Depth 4)
        exit 0
    }
    Write-HookJson '{"permission":"allow"}'
    exit 0
} catch {
    Write-HookJson '{"permission":"allow"}'
    exit 0
}
