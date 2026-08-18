# unity-ai-instructions 동기화 스크립트 (PowerShell).
# 프로젝트 루트에서 실행한다 (예: .unity-kb\sync.ps1).
# .unity-kb를 최신으로 pull한 뒤, 원본 HARNESS.md를 프로젝트 루트에
# AGENTS.md / CLAUDE.md 두 파일명으로 복사하고, agents-reference/도 맞춘다.

$ErrorActionPreference = "Stop"

$KbDir = $PSScriptRoot
$RootDir = Split-Path $KbDir -Parent

if (-not (Test-Path (Join-Path $KbDir "HARNESS.md"))) {
    Write-Error "오류: $KbDir\HARNESS.md 를 찾을 수 없다. .unity-kb가 unity-ai-instructions 저장소의 체크아웃인지 확인."
    exit 1
}

Write-Host "1. .unity-kb pull"
git -C $KbDir pull --ff-only

Write-Host "2. HARNESS.md -> AGENTS.md / CLAUDE.md"
Copy-Item (Join-Path $KbDir "HARNESS.md") (Join-Path $RootDir "AGENTS.md") -Force
Copy-Item (Join-Path $KbDir "HARNESS.md") (Join-Path $RootDir "CLAUDE.md") -Force

Write-Host "3. agents-reference/ 동기화"
$RefDest = Join-Path $RootDir "agents-reference"
if (Test-Path $RefDest) {
    Remove-Item $RefDest -Recurse -Force
}
Copy-Item (Join-Path $KbDir "agents-reference") $RefDest -Recurse -Force

Write-Host "완료. 프로젝트 루트의 AGENTS.md / CLAUDE.md / agents-reference/ 가 $KbDir\HARNESS.md 기준으로 갱신됨."
