# Agent Instructions

## First thing
Before starting work, read `.unity-kb/articles/integrated-ai-harness-instructions.md`.
If scope index files exist (`.unity-kb/articles/{private,projects/<id>,orgs/<id>}/index.md`), also check those for additional relevant articles.

## Unity Editor operations

- Use the Unity CLI and Unity Pipeline commands for all Unity Editor operations. Do not edit live Editor state through unrelated automation.
- Before beginning Editor work, run `unity command` to discover the commands exposed by the connected Pipeline version.
- Then run `unity command editor_status` and proceed only when the result reports `status: ready`.
- Run `unity command ...` with permission to inspect the host Unity process. Sandboxed process discovery can misclassify the live Pipeline descriptor as stale, remove it, and make the server appear unreachable.
- If discovery fails, inspect `unity pipeline list`. A running project with the Pipeline package installed but no PID, server port, or reachable server usually indicates failed process validation or a server startup problem.
- Prefer commands from the discovered command list instead of assuming command names or parameters.

## Required verification

- After making Editor or project changes, wait until compilation and domain reloads finish and confirm `editor_status` is ready.
- Check the Unity console for errors with `unity command get_console_logs --severity Error --limit 100`.
- Capture the Game view through Pipeline, for example: `unity command screenshot --view game --output <absolute-workspace-path>.png --width 1280 --height 720`
- Visually inspect the captured screenshot before reporting completion.
- Report compilation failures, console errors, screenshot failures, or unexpected visual results rather than claiming success.

## 공유 패키지 재사용

(배경/취지/전체 구조는 `D:\UnityCustomPackage\ARCHITECTURE.md` 참고)

새로운 공용 시스템(파티클 이펙트, 프리팹, 공용 스크립트 등)이 필요한 작업을 시작하기 전에 아래 "알려진 공유 패키지" 목록을 확인한다. 이미 있는 패키지로 요구사항을 충족할 수 있으면 새로 만들지 말고, 해당 프로젝트의 `Packages/manifest.json`에 git URL로 추가해서 사용한다. 목록에 없는 새 공용 시스템을 패키지로 만들었다면, 작업 완료 보고 시 사용자에게 이 목록에 등록해달라고 요청한다(AI가 이 목록을 직접 수정하지는 않음 — 짧은 목록이라 사용자가 직접 관리).

**알려진 공유 패키지**

| 패키지 | 저장소 | 설명 |
|---|---|---|
| com.custom.snowglobe | `https://github.com/supervanz/com.custom.snowglobe.git` | GPU 기반 SPH 유체 파티클 시뮬레이션, 모바일 터치/자이로 흔들기 인터랙션. 유리구/밀폐 용기 안 파티클 연출에 사용 |
| com.custom.planar-reflection | `https://github.com/supervanz/com.custom.planar-reflection.git` | 평면 반사(planar reflection) 컴포넌트, URP 평면 반사 셰이더, 샘플 머티리얼. 바닥/거울면 반사 연출에 사용 |
| com.custom.volumetricfog | `https://github.com/supervanz/com.custom.volumetricfog.git` | URP Render Graph 기반 볼류메트릭 안개 이펙트 |

## Safety

- Use dry-run and confirmation parameters when exposed by destructive Pipeline commands.
- Preserve existing scenes and assets unless the task explicitly requires changing or deleting them.
- Store generated verification artifacts under the project workspace, preferably `Temp/`, unless the user requests another location.

