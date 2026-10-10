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
    $ignored = [Console]::In.ReadToEnd()
    $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $open = New-Object System.Collections.Generic.List[string]
    $engagements = Join-Path $root '.team\engagements'
    if (Test-Path $engagements) {
        Get-ChildItem -Path $engagements -Directory | ForEach-Object {
            $statusFile = Join-Path $_.FullName 'status.md'
            $closed = $false
            if (Test-Path $statusFile) {
                $text = Get-Content -Path $statusFile -Raw -Encoding UTF8
                if ($text -match '状态\s*[:：]\s*已关闭') { $closed = $true }
            }
            if (-not $closed) { $open.Add($_.Name) }
        }
    }
    if ($open.Count -eq 0) {
        $openText = '没有未关闭的需求。'
    } else {
        $openText = '未关闭的需求：' + ($open -join '、') + '。'
    }
    $context = "团队会话开始。${openText}涉及实现、改共享逻辑或已登记规则时，先读 .team/capabilities.md，再读对应需求目录里的 impact.md。没有影响清单不得改业务规则。"
    $payload = @{ additional_context = $context }
    Write-HookJson ($payload | ConvertTo-Json -Compress -Depth 4)
    exit 0
} catch {
    Write-HookJson '{}'
    exit 0
}
