# 공유 UPM 패키지 시스템 — 배경 및 구조

이 문서는 `D:\UnityCustomPackage` 아래의 공유 패키지 시스템이 왜/어떻게 만들어졌는지 정리한 것이다. 어떤 Unity 프로젝트, 어떤 머신(PC/Mac), 어떤 Claude 세션/계정에서 이 시스템을 이어서 다루게 될 때 배경 지식 없이도 이해할 수 있도록 작성했다.

## 1. 목적

여러 Unity 프로젝트/씬에서 반복적으로 필요한 요소(파티클 이펙트, 인터랙션 스크립트, 셰이더 등)를 AI 에이전트가 매번 처음부터 새로 만드는 대신, 이미 만들어둔 시스템이 있으면 그것을 찾아서 재사용하도록 하는 것이 목적이다. "어떤 프로젝트에서 만든 파티클 효과를 다른 씬, 다른 프로젝트에서도 다시 만들지 않고 그대로 가져다 쓴다"가 핵심 시나리오.

## 2. 검토했던 대안과 최종 결정 (왜 이 구조인가)

처음에는 다음과 같은 무거운 구조를 검토했다:
- 패키지별 독립 git 저장소 + semver 태그
- `.unity-kb`(AI 하네스/지식베이스 시스템)의 org 스코프에 재사용 카탈로그 문서를 등록
- AGENTS.md에 "AI가 KB 문서를 직접 쓸 수 있다"는 권한 예외 조항 추가

검토 결과 규모(패키지 몇 개, 개인 작업)에 비해 과도하게 복잡하다고 판단해 **KB 카탈로그 체계는 버리고**, 재사용 지침을 각 프로젝트의 `AGENTS.md`(일반 프로젝트 지시 파일, `.unity-kb`가 아님) 안에 표 형태로 직접 넣는 방식으로 단순화했다.

패키지 저장 방식은 두 단계를 거쳐 확정됐다:
1. 처음엔 "로컬 폴더 하나에 모아두고 `file:` 경로로 참조"하는 가장 단순한 방식을 검토.
2. 그런데 PC와 Mac 등 **여러 머신을 함께 쓴다는 점**이 확인되면서 `file:` 참조는 머신마다 경로가 달라 깨진다는 문제가 부각됨 — 실제로 한 프로젝트의 `manifest.json`에서 다른 머신(macOS)의 절대경로를 가리키는 **깨진 `file:` 참조**가 발견되어, 이 문제가 실물로 확인됨.
3. 그래서 최종적으로 **git 저장소 기반**으로 결정: 로컬 폴더는 "편집 스테이징" 용도로만 쓰고, 실제 프로젝트가 참조하는 건 GitHub의 git URL(태그 고정) — 문자열 자체가 머신에 의존하지 않으므로 어느 PC/Mac에서 프로젝트를 열어도 동일하게 동작함.

## 3. 현재 구조

### 로컬 스테이징 디렉토리
- `D:\UnityCustomPackage\` (Windows 기준 경로) — 패키지를 만들고 편집하는 곳. **Unity 프로젝트가 직접 참조하는 대상이 아니다.** 다른 머신(Mac 등)에서는 이 경로가 아니어도 상관없다 — 편집할 때만 clone해서 쓰면 됨.
- 이 디렉토리 자체는 git 저장소가 아니다. 그 안의 **하위 폴더 각각이 독립된 git 저장소**다.

### 등록된 패키지 (모두 git 저장소, GitHub `supervanz` 계정, private, `v1.0.0` 태그)

| 패키지 id | 로컬 경로 | GitHub 저장소 | 설명 |
|---|---|---|---|
| `com.custom.snowglobe` | `D:\UnityCustomPackage\com.custom.snowglobe` | `https://github.com/supervanz/com.custom.snowglobe.git` | GPU 기반 SPH 유체 파티클 시뮬레이션, 모바일 터치/자이로 흔들기 인터랙션, specularity. 유리구/밀폐 용기 안 파티클 연출에 사용 |
| `com.custom.planar-reflection` | `D:\UnityCustomPackage\com.custom.planar-reflection` | `https://github.com/supervanz/com.custom.planar-reflection.git` | 평면 반사(planar reflection) 컴포넌트, URP 평면 반사 셰이더, 샘플 머티리얼. 바닥/거울면 반사 연출에 사용 |
| `com.custom.volumetricfog` | `D:\UnityCustomPackage\com.custom.volumetricfog` | `https://github.com/supervanz/com.custom.volumetricfog.git` | URP Render Graph 기반 볼류메트릭 안개 이펙트 |

각 패키지 폴더는 표준 UPM 구조(`package.json`, `Runtime/`, 필요시 `Samples~/`)를 따른다. `com.custom.snowglobe`가 가장 완성된 예시(스크립트/셰이더/데모 씬 포함)이며, 새 패키지를 만들 때 이 구조를 그대로 템플릿으로 따르면 된다.

### 각 프로젝트의 재사용 지침 (AGENTS.md)

이 시스템을 쓰는 모든 프로젝트의 `AGENTS.md`에는 "공유 패키지 재사용" 섹션이 있고, 위 표와 동일한 패키지 목록 및 아래 지침을 담고 있다(정확한 문구는 `unity-ai-instructions` 저장소의 `AGENTS.md` 템플릿이 원본):

> 새로운 공용 시스템(파티클 이펙트, 프리팹, 공용 스크립트 등)이 필요한 작업을 시작하기 전에 목록을 확인한다. 이미 있는 패키지로 요구사항을 충족할 수 있으면 새로 만들지 말고 해당 프로젝트의 `Packages/manifest.json`에 git URL로 추가해서 사용한다. 목록에 없는 새 공용 시스템을 패키지로 만들었다면, 작업 완료 보고 시 사용자에게 이 목록에 등록해달라고 요청한다(AI가 이 목록을 직접 수정하지는 않음).

**이 문서(ARCHITECTURE.md)와 AGENTS.md의 역할 분리**: AGENTS.md는 각 프로젝트에서 AI 에이전트가 매번 자동으로 읽는 "실행용 지침 + 현재 패키지 목록"이고, 이 문서는 "왜 이렇게 만들어졌는지"에 대한 배경 설명이다. 패키지 목록이 갱신되면 AGENTS.md(및 `unity-ai-instructions` 저장소의 템플릿)가 최신 상태를 반영하고, 이 문서는 그대로 두어도 된다(다만 새 패키지 추가 절차나 구조 자체가 바뀌면 이 문서도 갱신 필요).

## 4. 프로젝트에서 기존 패키지를 사용하는 방법

해당 프로젝트의 `Packages/manifest.json`에 아래 형태로 한 줄 추가:

```json
"com.custom.snowglobe": "https://github.com/supervanz/com.custom.snowglobe.git#v1.0.0"
```

- **태그(`#v1.0.0`)로 고정한다.** 브랜치 고정(`#main`)은 하지 않는다 — 재현성이 없고, 저장소가 나중에 바뀌면 조용히 내용이 달라질 수 있다.
- 새 버전이 필요하면 저장소에 새 태그가 push된 뒤, 이 문자열의 태그 부분만 바꾸면 된다.
- Unity Editor가 열려 있다면 Package Manager가 자동으로 git에서 fetch해서 resolve한다.

## 5. 새 패키지를 추가하는 절차

1. `D:\UnityCustomPackage\com.custom.<system-name>\` 폴더 생성, 그 안에 표준 UPM 구조(`package.json`, `Runtime/` 등)로 시스템을 정리한다. 이미 어떤 씬/프로젝트에 만들어져 있는 것을 옮기는 경우, **Unity 에디터의 Project 창에서 드래그 앤 드롭으로 이동**해야 GUID/`.meta`가 보존되어 기존 씬 참조가 깨지지 않는다(파일시스템에서 직접 옮기지 말 것).
2. 해당 폴더에서:
   ```bash
   git init
   git add -A
   git commit -m "Initial import: com.custom.<system-name>"
   git tag v1.0.0
   gh repo create supervanz/com.custom.<system-name> --private --source=. --remote=origin --push
   git push origin v1.0.0
   ```
   (`gh` CLI가 `supervanz` 계정으로 로그인/`credential.helper` 연결까지 이미 완료된 머신에서는 그대로 실행 가능. 다른 머신에서는 `gh auth login`부터 다시 필요.)
3. 필요한 프로젝트의 `Packages/manifest.json`에 4번 항목 형태로 git URL 추가.
4. 이 시스템을 쓰는 모든 프로젝트의 `AGENTS.md`(및 `unity-ai-instructions` 저장소의 `AGENTS.md` 템플릿)의 "알려진 공유 패키지" 표에 새 항목 한 줄 추가.
5. 이 문서(`ARCHITECTURE.md`, 로컬 사본은 `D:\UnityCustomPackage\ARCHITECTURE.md`, 원본은 `unity-ai-instructions` 저장소의 `packages/ARCHITECTURE.md`)의 3번 섹션 표에도 동일하게 추가.

## 6. 알려진 제약 / 아직 안 한 것

- **GitHub 인증은 이 작업을 처음 진행한 Windows 머신에만 설정돼 있다.** `gh` CLI를 설치하고 `gh auth login`(device flow)으로 `supervanz` 계정 로그인 후 `gh auth setup-git`으로 git credential helper를 연결했다. 다른 PC/Mac에서 push하려면 그 머신에서 동일하게 `gh auth login`을 다시 해야 한다(계정 자체는 GitHub에 이미 있으니 로그인만 하면 됨).
- 일부 프로젝트에는 여전히 패키지의 임베디드 사본이 그대로 남아 있을 수 있다 — 즉 해당 프로젝트가 GitHub 버전을 git URL로 참조하도록 바뀌지 않고, 프로젝트 폴더 안에 직접 들어있는 사본을 계속 쓰는 상태. 이걸 git 참조로 바꾸려면 Unity Editor(Pipeline)가 연결된 상태에서 매니페스트 교체 후 Package Manager가 정상 resolve되는지 검증해야 한다 — 연결이 없으면 검증 없이 위험하게 바꾸지 말고 보류할 것.
- 새로 만든 패키지가 아직 어떤 프로젝트의 `manifest.json`에도 git 참조로 연결되지 않은 경우, 각 프로젝트의 원본 위치에는 여전히 원래 스크립트가 그대로 남아 있고 패키지로 교체되지 않은 상태일 수 있다.
- 패키지의 `package.json`에 적힌 `unity` 최소 버전이 실제 사용 중인 에디터 버전과 다를 수 있다 — 요청받지 않았다면 임의로 정리하지 말 것(범위를 벗어나는 작업).
- 패키지 저장소는 모두 **private**로 만드는 것을 기본으로 한다(별도 지시가 없으면 보수적으로 선택).

## 7. 관련 저장소 — AI 작업 규칙 통합 시스템

이 문서가 다루는 "공유 UPM 패키지" 시스템과는 별개로, `AGENTS.md` 템플릿과 `.unity-kb` harness 지침 문서 자체도 git으로 중앙 관리한다:

- 저장소: `https://github.com/supervanz/unity-ai-instructions.git` (private)
- 담고 있는 것: `AGENTS.md` 원본 템플릿, `.unity-kb/articles/integrated-ai-harness-instructions.md` 원본, 이 문서(`ARCHITECTURE.md`)의 사본
- 어떤 프로젝트든 아래 한 줄로 규칙을 받아올 수 있다:
  ```bash
  git clone https://github.com/supervanz/unity-ai-instructions.git .unity-kb
  cp .unity-kb/AGENTS.md ./AGENTS.md
  ```
- 이렇게 하면 프로젝트의 `.unity-kb` 폴더 자체가 이 저장소의 독립 git 체크아웃이 되어, 이후엔 그 폴더 안에서 `git pull`만 하면 최신 규칙을 받는다.
- 규칙을 고칠 때는 각 프로젝트의 로컬 사본이 아니라 **이 저장소를 고치고 push**한 뒤, 각 프로젝트에서 pull/재복사한다(자세한 동기화 원칙은 그 저장소의 `README.md` 참고).
- 이 두 시스템(패키지 저장소들 / unity-ai-instructions)은 서로 독립적이지만 같은 원칙(git 저장소 기반, `supervanz` 계정, 태그/버전으로 상태 고정)을 공유한다.

## 8. 다른 Claude 세션/계정에서 이어서 작업할 때

- 새 프로젝트에서 이 시스템을 쓰려면: 이 문서를 읽고 → 필요한 패키지를 4번 항목 방식으로 `manifest.json`에 추가 → 그 프로젝트에도 `AGENTS.md`가 없으면 `unity-ai-instructions` 저장소의 템플릿으로 만들어준다(자세한 건 `unity-ai-instructions` 저장소의 README 참고).
- 다른 GitHub 계정으로 관리하고 싶다면, 이미 push된 저장소를 그대로 두고 새 계정 아래로 fork/transfer하거나, 이 문서와 각 프로젝트 `AGENTS.md`의 URL을 일괄 교체하면 됨 — 구조 자체는 계정에 종속되지 않음.
- 패키지 목록은 사람이 직접 관리하는 것을 원칙으로 한다(AI가 새 패키지를 추출했을 때는 사용자에게 "목록에 등록해달라"고 요청하고, 목록 파일 자체를 임의로 고치지 않는다).
