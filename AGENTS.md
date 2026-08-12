---
id: unity-ai-agent-instructions
title: 통합 AI 에이전트 작업 지침
version: 1
supersedes: AGENTS.md(이전 버전), articles/integrated-ai-harness-instructions.md(v3)
---

# Unity AI 에이전트 작업 지침

이 문서는 AI 에이전트가 이 Unity 프로젝트에서 작업할 때 따라야 하는 지침의 **단일 원본**이다. 이전에는 `AGENTS.md`(실행 지침)와 `.unity-kb/articles/integrated-ai-harness-instructions.md`(행동 제어 하네스)로 내용이 나뉘어 있었으나, 하나로 합쳤다. 그 하네스 문서는 참고용으로만 남겨두며, 실제 최신 내용은 이 문서를 기준으로 한다.

이 문서(및 이 저장소 전체)의 원본은 `https://github.com/supervanz/unity-ai-instructions.git`이다. 이 저장소를 프로젝트에 반영/동기화하는 방법은 `.unity-kb/README.md`(또는 이 저장소의 `README.md`)를 참고한다.

## 0. 문서 우선순위

이 문서 내에서 **앞쪽 장이 뒤쪽 장보다 우선**한다: 1~4장(안전/우회금지, 실행·검증 루프, 자체 감사, 응답 형식)은 행동 제어 규칙이고, 5장 이후(공유 패키지, Unity 공식 skills, 문서 관리)는 그 규칙 아래에서 적용되는 도메인별 세부 절차다. 두 내용이 충돌하면 앞쪽 장을 따른다.

## 1. 우회 작업 금지 및 승인 게이트 (No-Detour & Approval Gate)

### 1.1 스코프 확장 중단 트리거

**목적**: 원래 지시받은 작업(예: 3D 메쉬 생성)이 어떤 이유로 정상 수행 불가능할 때, 이를 우회하기 위해 점점 더 크고 본질과 무관한 대체 작업을 벌여 시간/토큰을 낭비하는 것을 막기 위함.

다음 상황에서 즉시 작업 중단 및 승인 요청:
- 원래 요청한 접근 방식/API/기능이 실패 또는 불가능하다고 판단되어, 이를 우회할 대체 경로를 도입하려는 시점이며
- 그 대체 경로가 다음 중 하나 이상에 해당하는 경우:
  - 수정 대상 파일 3개 초과
  - 기존 함수/API 시그니처 변경
  - 신규 외부 의존성(패키지, 라이브러리) 추가
  - 기존 아키텍처 구조 변경(클래스 계층, 데이터 흐름 변경 등)

(참고: 사용자가 애초에 다중 파일/구조 변경을 포함하는 작업을 명시적으로 요청한 경우는 "우회용 확장"이 아니므로 이 트리거 대상이 아님.)

### 1.2 임의 대체 금지
- 사용자가 "생성"을 요청한 결과물에 대해 사전 동의 없이 기존 임시/더미 리소스를 배치한 후 생성 결과물로 보고하는 행위 금지.

### 1.3 재시도 한계 (Max 2 Retries)
- 재시도 동일성 판단 기준: 동일 파일 + 동일 함수/API 호출 + 동일 에러 유형(스택트레이스 최상위 프레임 기준) 일치 시 "동일 문제"로 간주.
- 동일 문제 해결 시도는 최대 2회까지 허용.
- 2회 초과 시, 또는 우회 방식 도입이 필요하다고 판단되는 즉시 작업 중단(HALT).

### 1.4 장애 보고 서식
작업 중단 시 아래 서식으로 즉시 보고:

- 🛑 블로커: (실패 원인 및 에러 내역)
- 🔍 시도 내역: (실행 도구 및 코드 수정 내역, 회차별 구분)
- 💡 대안:
  - 옵션 A: (원인 해결에 필요한 추가 정보/권한)
  - 옵션 B: (우회 방식의 이점/비용)
- ❓ 승인 요청: "위 대안 중 진행 방식 승인 요청"

### 1.5 대기 상태
- 보고서 제출 후 사용자 승인 또는 명시적 지시 전까지 후속 작업 금지.

## 2. 실행 및 검증 루프 (Execution & Verification Loop)

### 2.0 Unity Editor 상호작용 준비
- Unity Editor 조작은 Unity CLI/Pipeline 명령으로만 수행한다. 관련 없는 자동화로 live Editor 상태를 건드리지 않는다.
- Editor 작업을 시작하기 전 `unity command`를 실행해 연결된 Pipeline 버전이 제공하는 명령을 확인한다.
- 그다음 `unity command editor_status`를 실행하고, 결과가 `status: ready`일 때만 진행한다.
- 호스트 Unity 프로세스를 조사할 권한으로 `unity command ...`를 실행한다 — 샌드박스된 프로세스 탐색이 살아있는 Pipeline descriptor를 stale로 잘못 분류해 제거하고 서버가 unreachable한 것처럼 보이게 할 수 있다.
- discovery가 실패하면 `unity pipeline list`를 확인한다. Pipeline 패키지가 설치된 실행 중인 프로젝트인데 PID/서버 포트/서버 연결이 없다면 대개 프로세스 검증 실패나 서버 시작 문제다.
- 명령/파라미터를 임의로 가정하지 말고 discovery로 얻은 명령 목록에서 고른다.

### 2.1 사전 조사
- 코드/에셋 수정 전 관련 스크립트, 파일 간 종속성, 프로젝트 설정(Input System, Render Pipeline 등) 확인.

### 2.2 단계별 사고 순서
- 사전 조사 → 위험성 평가(1.1 트리거 해당 여부 포함) → 실행 계획 → 검증 방식 순으로 진행.

### 2.3 결과 검증 - 코드
- Editor/프로젝트 변경 후에는 컴파일과 도메인 리로드가 끝날 때까지 기다리고 `editor_status`가 ready인지 재확인한다.
- `unity command get_console_logs --severity Error --limit 100`으로 컴파일 에러, 런타임 경고를 확인한다.
- 예시: `unity command screenshot --view game --output <absolute-workspace-path>.png --width 1280 --height 720`로 Game view를 캡처하고, 보고 전에 직접 확인한다.
- 컴파일 실패, 콘솔 에러, 스크린샷 실패, 예상과 다른 시각적 결과는 성공으로 포장하지 않고 있는 그대로 보고한다.

### 2.4 결과 검증 - 3D 에셋 생성 (도메인 세부 절차)

#### 2.4.0 적용 대상 판단 (프리미티브 vs 3D 생성 모델)
- 구조/건축 요소(마루, 천장, 벽, 기둥 등 평면·직육면체·단순 형태로 근사 가능한 오브젝트)는 프리미티브(Cube, Plane, Cylinder 등)로 배치 가능.
- 유기적 형태/캐릭터/장식 조형물(나무, 사람, 동물, 조각상 등 프리미티브 조합으로 실루엣·디테일을 원본 의도대로 표현할 수 없는 오브젝트)는 반드시 3D 생성 모델(2.4.2 파이프라인)을 거쳐야 함. 프리미티브 조합으로 임의 대체 금지.
- 판단 기준: 해당 오브젝트의 실루엣/디테일을 프리미티브 조합으로 원본 의도 훼손 없이 표현 가능한지 여부. 애매한 경우 진행 전 사용자에게 확인.
- 이 기준을 우회할 목적으로 프리미티브로 먼저 배치한 뒤 "임시"임을 밝히지 않고 완성된 결과물처럼 보고하는 행위는 1.2(임의 대체 금지) 위반으로 간주.

#### 2.4.1 원칙
- 복잡한 원본 이미지에서 대상을 직접 크롭하여 3D 입력값으로 사용 금지(경계면 잡영, 하반신 누락, 부유물 구워짐 유발).
- 전신 형태 완전성 제약: Full body, head-to-toe, standing pose, complete legs and feet, isolated transparent background 명시.
- 상반신만 생성되거나 하반신 누락 시 품질 미달로 판정, 씬 배치 중단.

#### 2.4.2 파이프라인
0. 입력 이미지 사전 판단: 레퍼런스 이미지가 이미 배경과 분리된 단일 피사체의 깨끗한 전신 이미지라면 1~2단계를 건너뛰고 3단계로 직행. 배경과 인물이 겹쳐 있거나 뒤섞인 복합 이미지일 때만 1~2단계 필수.
1. 대상 분석 및 프롬프트화: 성별, 의상, 외형, 색상 스타일 추출. 배경/장식물/무관 요소 제외.
2. 투명 배경 2D 전신 이미지 생성: Full body portrait, head to toe, front view, standing pose, clean isolated transparent background, game asset style. 절단 없이 온전한지 확인.
3. Image-to-3D Mesh 변환: (0단계에서 재사용 판정된 이미지 또는 2단계 결과물을) 레퍼런스로 Image-to-3D 실행(waitForCompletion=true).
4. 메시 품질 검증(배치 전 필수):
   - 사지 누락 여부(Bounds Y-Extent, 하단 절단면 확인)
   - 아티팩트 합성 여부(배경/장식물 구워짐 확인)
   - 접지 및 포즈 상태(발끝 정방향 지면 배치 가능 여부)

#### 2.4.3 씬 배치 후 검증
- 결과물이 벽/다른 오브젝트에 가려지지 않고 명확히 보이는 각도를 최소 1개 이상 찾아 스크린샷 캡처 후 검증.
- 정면/측면/조감도는 참고용 기본값일 뿐 고정 필수값이 아님 — 씬 구조상 특정 각도가 가려진다면 생략하고, 결과를 실제로 판별 가능한 각도를 우선.
- 검증 목적은 "여러 각도를 찍었는가"가 아니라 "찍은 스크린샷으로 결과물의 정상 여부를 실제로 판단할 수 있는가"임.

### 2.5 직접 씬 작성 지침 (Direct Scene Creation)

#### 2.5.1 원칙
- 씬 구성/작성 작업에서 `[MenuItem]`, `EditorWindow`, `Custom Inspector` 등 에디터 확장용 커스텀 메뉴 스크립트 작성 및 경유 금지.
- 씬 생성 요청 시 C# API/RunCommand로 `GameObject` 생성, 컴포넌트 추가, 프리팹/에셋 배치, 라이팅 및 환경 설정을 씬에 직접 반영.

#### 2.5.2 검증 절차 (필수, 배치 완료 후 즉시 수행)
- **금지 항목 검사**: 작업 중 신규 생성/수정된 `.cs` 파일 전체를 대상으로 다음 패턴 검색.
  - `[MenuItem(`
  - `: EditorWindow`
  - `[CustomEditor(`
  - 1개 이상 매칭 시 2.5.1 위반으로 판정, 3.3 절차(불일치 대응)에 따라 처리.
- **직접 반영 검사**: Scene Hierarchy 조회로 요청된 `GameObject`/컴포넌트/프리팹이 씬에 실제 존재하는지 확인. 존재하지 않으면 미완료로 판정.
- 위 두 항목 결과를 3.2 감사 체크리스트에 포함하여 보고 전 대조.

### 2.6 실행 안전 수칙
- 파괴적인 Pipeline 명령에 dry-run/confirmation 파라미터가 있으면 사용한다.
- 작업이 명시적으로 요구하지 않는 한 기존 씬/에셋을 보존한다.
- 검증용으로 생성한 아티팩트(스크린샷 등)는 프로젝트 워크스페이스 하위, 가능하면 `Temp/`에 저장한다(사용자가 다른 위치를 요청하지 않는 한).

## 3. 보고 전 자체 감사 (Self-Audit)

### 3.1 필수 순서
- 모든 결과 보고는 3.2 감사를 통과한 후에만 작성 가능. 감사 없이 작성된 보고는 무효로 간주하고 재작성.

### 3.2 사실 확인
- 보고 내용(실행 결과, 파일 수정 여부, 에러 해결 여부)을 실제 조회 도구(Console Log, File Reader, Scene Inspection)로 직접 대조.
- 씬 작성 작업 포함 시 2.5.2 검증 절차(금지 항목 검사, 직접 반영 검사) 결과를 대조 항목에 포함.

### 3.3 불일치 대응
- 감사 결과 보고 내용과 실제 상태 불일치 시(예: 수정 명시했으나 파일 미반영, 해결 명시했으나 콘솔 에러 잔존) 즉시 보고 중단, 원인 파악.
- 원인 해결 재시도는 1.3의 전체 재시도 한계 내에서만 수행.

### 3.4 해결 불가 시 처리
- 재시도 한계 도달 또는 해결 불가 시, 미완성/실패 상태를 성공으로 포장 금지. 1.4 서식에 맞춰 실제 상태 그대로 보고.

### 3.5 거짓 보고 금지
- 미실행 작업을 실행했다고 보고 금지.
- 미검증 결과를 사실처럼 작성 금지.
- 위반 시 즉시 정정 보고.

## 4. 응답 형식 (Response Format)

### 4.1 어조
- 주관적/과장 형용사(완벽한, 정밀한, 최종적인, 아름다운, 강력한, 최적의 등) 사용 금지.
  - 근거: 과장된 표현은 작업 결과에 대한 오해를 유발할 수 있음 — 사실 기반 커뮤니케이션 유지가 목적.

### 4.2 근거
- 객관적 사실(컴포넌트명, 파일 경로, API 명칭, 콘솔 에러 로그, 수치)에 근거해서만 서술.

### 4.3 구조
- 서론 없이 본론 즉시 진입.
- 핵심 정보, 작업 항목, 수정 코드는 불릿 리스트로 작성.

## 5. 공유 패키지 재사용

(배경/취지/전체 구조는 `packages/ARCHITECTURE.md`, 로컬 사본은 `D:\UnityCustomPackage\ARCHITECTURE.md` 참고)

새로운 공용 시스템(파티클 이펙트, 프리팹, 공용 스크립트 등)이 필요한 작업을 시작하기 전에 아래 "알려진 공유 패키지" 목록을 확인한다. 이미 있는 패키지로 요구사항을 충족할 수 있으면 새로 만들지 말고, 해당 프로젝트의 `Packages/manifest.json`에 git URL로 추가해서 사용한다. 목록에 없는 새 공용 시스템을 패키지로 만들지 여부는 사용자가 직접 지시하거나 승인한 경우에만 진행한다 — 이 판단은 AI가 임의로 하지 않는다. 사용자 승인을 받아 패키지를 만들고 GitHub push까지 마쳤다면, 그 결과를 이 목록(및 `D:\UnityCustomPackage\ARCHITECTURE.md`, `unity-ai-instructions` 저장소의 이 템플릿)에 등록하는 것은 AI가 직접 해도 된다 — 이미 승인된 결정을 표에 반영하는 기계적 작업이기 때문이다.

**알려진 공유 패키지**

| 패키지 | 저장소 | 설명 |
|---|---|---|
| com.custom.snowglobe | `https://github.com/supervanz/com.custom.snowglobe.git` | GPU 기반 SPH 유체 파티클 시뮬레이션, 모바일 터치/자이로 흔들기 인터랙션. 유리구/밀폐 용기 안 파티클 연출에 사용 |
| com.custom.planar-reflection | `https://github.com/supervanz/com.custom.planar-reflection.git` | 평면 반사(planar reflection) 컴포넌트, URP 평면 반사 셰이더, 샘플 머티리얼. 바닥/거울면 반사 연출에 사용 |
| com.custom.volumetricfog | `https://github.com/supervanz/com.custom.volumetricfog.git` | URP Render Graph 기반 볼류메트릭 안개 이펙트 |
| com.generic.crowd | `https://github.com/supervanz/com.generic.crowd.git` | NavMeshAgent 기반 경량 NPC 배회/모션 오버라이드 시스템. 군중/배경 캐릭터 연출에 사용 |

## 6. Unity 공식 AI skills

`Unity-Technologies/skills`(Unity 공식 Claude Code Skill 모음)를 이 저장소의 `vendor/unity-technologies-skills/skills/`에 벤더링해 두었다. 프로젝트의 `.claude/skills/`에 필요한 스킬 폴더가 설치되어 있으면 `/스킬이름`으로 직접 호출한다(예: `unity-package-management`, `unity-cli`, `new-unity-project`, `ui`, `ui-uitk`, `ui-ugui`, `ui-imgui`, `build-live-game`, `implement-in-app-purchases`, `levelplay-unity-integration`). 설치/갱신 절차는 이 저장소의 `README.md` 참고.

## 7. 문서 관리 (Knowledge Base Registration)

### 7.1 포맷 및 위치
- 포맷: .md
- 위치:
  - 개인용: `.unity-kb/articles/private/`
  - 프로젝트 공유용: `.unity-kb/articles/projects/<project_id>/`
  - 조직 공유용: `.unity-kb/articles/orgs/<org_id>/`

### 7.2 YAML Front-matter
- 모든 문서 상단에 id, title, version 포함.

### 7.3 색인 등록
- 해당 Scope 루트의 index.md에 상대 경로, 제목, 한 줄 설명 추가.

### 7.4 관리 주체
- KB 문서(이 문서, 하네스 문서, 패키지/skills 목록 등) 추가/수정/삭제는 사용자가 직접 수행하거나 승인한 것만 반영한다. AI는 5장 규칙(사용자 승인을 받은 패키지 등록)처럼 명시적으로 허용된 범위 밖에서는 KB 문서를 임의로 고치지 않는다.
