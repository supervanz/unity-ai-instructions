# unity-ai-instructions

여러 Unity 프로젝트(그리고 여러 PC/Mac)에서 공통으로 쓰는 AI 에이전트 작업 규칙/지침을 모아두는 **중앙 저장소**다. 개별 프로젝트에 흩어져 있던 `AGENTS.md`, `.unity-kb` 하네스 지침, 공유 패키지 시스템 배경 문서를 여기로 통합했다.

## 이 저장소가 유일한 원본이다

**규칙을 고칠 때는 이 저장소에서 고치고 push한다. 각 프로젝트에 있는 로컬 사본(`AGENTS.md`, `.unity-kb/`)을 직접 고치지 않는다.** 로컬 사본은 이 저장소의 복사본/체크아웃일 뿐이다.

머신이나 프로젝트가 바뀌어도 항상 다음 순서를 따른다:
1. 작업 시작 전: 이 저장소를 최신으로 pull한다.
2. 프로젝트의 `.unity-kb/`가 이 저장소의 git 체크아웃이면 그 폴더 안에서 `git pull`.
3. 프로젝트의 `AGENTS.md`가 이 저장소의 `AGENTS.md`보다 오래됐으면 덮어써서 갱신한다.
4. 규칙을 바꿔야 하면, 로컬 사본이 아니라 이 저장소를 고친 뒤 commit/push하고, 그다음에 각 프로젝트로 다시 동기화한다.

## 구조

```
unity-ai-instructions/
├── AGENTS.md                                    # 각 프로젝트 루트 AGENTS.md의 원본 템플릿
├── articles/
│   └── integrated-ai-harness-instructions.md    # AI 행동 제어 하네스 지침 (.unity-kb/articles/ 원본)
└── packages/
    └── ARCHITECTURE.md                          # 공유 UPM 패키지 시스템 배경 문서
```

## 이 저장소를 프로젝트에 반영하는 방법

**어떤 Unity 프로젝트든 다음 절차로 이 저장소의 규칙을 반영한다:**

```bash
# 프로젝트 루트에서 실행
# 1. .unity-kb를 이 저장소의 git 체크아웃으로 설정
git clone https://github.com/supervanz/unity-ai-instructions.git .unity-kb

# 2. AGENTS.md를 프로젝트 루트에 복사
cp .unity-kb/AGENTS.md ./AGENTS.md
```

이렇게 하면 프로젝트의 `.unity-kb` 폴더 자체가 이 저장소의 독립적인 git 체크아웃이 된다. 이후 규칙이 갱신되면 그 폴더 안에서 `git pull` 한 번으로 최신화되고, `AGENTS.md`는 필요할 때 다시 복사해서 맞추면 된다.

새 시스템(공유 패키지 등)이 추가되면 `AGENTS.md`의 "알려진 공유 패키지" 표에 항목을 추가하고, 이 저장소에 commit/push한 뒤 각 프로젝트에 반영한다.

## 이력

- 초기 통합: 여러 프로젝트에 개별적으로 존재하던 `AGENTS.md`/`.unity-kb` 지침을 이 저장소로 통합. 이전에 `.unity-kb/.kb-sync`를 관리하던 외부 동기화 도구는 더 이상 쓰이지 않는 것으로 확인되어 git으로 완전히 대체.
