---
id: unity-ai-agent-instructions-local-comfyui-stack
title: 로컬 ComfyUI 생성 스택 (특정 PC 전용)
version: 1
parent: 상위 지침 문서 (5의 표 등재)
---

# 로컬 ComfyUI 생성 스택 (특정 PC 전용)

**로드 조건**: 다음 **두 가지가 모두** 맞을 때만 이 문서를 읽는다.
① 사용자가 "로컬"·"ComfyUI"로 처리하라고 **명시**한 에셋·애니메이션 생성 작업이고,
② `H:\source\ComfyUI\CLAUDE.md` 파일이 **존재하는 PC**다.
하나라도 아니면 해당 없음이며 본문을 열지 않는다.

이 문서는 상위 지침 문서(프로젝트 루트: `AGENTS.md`/`CLAUDE.md`, .unity-kb 원본:
`HARNESS.md`) §1~4의 행동 규칙 아래에서 적용되는 도메인 절차다. 충돌 시 그 문서(§0~4)가
우선한다.

## 0. 이 문서는 PC 한 대에만 유효하다

로컬 GPU 스택은 이식되지 않는다. 다음이 전부 갖춰진 기계에서만 동작한다.

| 항목 | 값 |
| --- | --- |
| 판정 기준 (이것만 보면 된다) | `H:\source\ComfyUI\CLAUDE.md` 존재 여부 |
| 호스트 | `VANZHOMEPC` |
| GPU | NVIDIA GeForce RTX 5090 (sm_120) |
| 스택 | `H:\source\ComfyUI` · `H:\source\HY-Motion-1.0` · 로컬 모델 약 224GB |

**다른 PC에서는 이 문서를 무시하고 [ai-generation.md](ai-generation.md) 경로를 쓴다.**
경로가 없는데 "설치하면 되지 않나"로 넘어가지 않는다 — 모델 용량과 GPU 요구가 커서
설치는 사용자 결정 사항이다.

## 1. 무엇을 대체하는가

같은 목적(3D 에셋·애니메이션 생성)의 **다른 경로**다. 클라우드 생성 서비스를
대체하는 것이지, 배치·검증 규약을 대체하지 않는다.

| | 클라우드 경로 | 이 로컬 스택 |
| --- | --- | --- |
| 문서 | [ai-generation.md](ai-generation.md) | 이 문서 |
| 호출 | `GenerateAsset` 등 커맨드 | 로컬 CLI (`tools/pipeline.py`) |
| 산출 | Tripo 등 프로바이더 결과 | Chroma 이미지 → TRELLIS2 메시 → MIA 리깅 → HY-Motion 모션 |
| 비용 | 크레딧 | 없음 (전기·시간) |
| 소요 | 프로바이더에 따름 | 인물 3명 기준 23분 |

**배치·검증은 기존 문서를 그대로 따른다.** 씬 배치·접지·AABB 규약은
[3d-asset-pipeline.md](3d-asset-pipeline.md), 모션/포즈 판정 규약은
[animation-pose.md](animation-pose.md)가 계속 상위다. 이 문서는 **에셋을 만드는
구간까지만** 다룬다.

## 2. 경로 선택 규칙 (자동 라우팅 없음)

**에셋 생성의 기본 경로는 클라우드([ai-generation.md](ai-generation.md))다.**
사용자가 명시하지 않는 한 로컬로 보내지 않는다. 작업 내용이 로컬에 유리해 보인다는
이유로 임의 전환하지 않는다 — §1.2(임의 대체 금지)와 같은 성격이다.

| 사용자 발화 | 경로 |
| --- | --- |
| "로컬로", "ComfyUI로", "파이프라인으로" | 이 문서 |
| "클라우드로", 프로바이더명 지정 | [ai-generation.md](ai-generation.md) |
| 아무 언급 없음 | [ai-generation.md](ai-generation.md) |

**시작 전 한 줄 고지 (필수)**: 로컬 경로로 진행할 때는 착수 전에 그 사실과 비용·시간을
한 줄로 알린다. 승인은 받지 않는다.

> 로컬 ComfyUI 스택으로 진행합니다 (크레딧 소모 없음, 인물 10명 기준 약 25분).

**로컬이 명백히 유리한데 지정이 없으면**, 클라우드로 진행하되 보고에 한 줄로 대안을
언급한다 — 경로를 바꾸지는 않는다. 크레딧이 나가는 선택은 사용자 몫이다.

> (참고: 이 작업은 로컬 스택으로도 가능하며 크레딧이 들지 않습니다.)

### 로컬이 유리한 경우 (참고용 판단 재료)

- **군중용 인물 다수**. 속성 무작위화가 내장돼 있고 개수만 정하면 된다.
- 반복 생성·재생성이 예상될 때. 실패분 자동 폐기·재시도가 들어 있다.

반대로 **단발성 에셋 하나**는 클라우드가 대개 빠르고 손이 덜 간다. 로컬에서
임의 이미지 → 메시는 `pipeline.py` 한 줄로는 안 되고 `run_workflow.py` 수동 호출이다
(`trellis2_i23d_lowpoly`).

## 3. 호출

```
cd H:\source\ComfyUI
.venv\Scripts\python.exe tools\pipeline.py --count 10 --tag <배치이름> --unity <프로젝트경로>
```

프롬프트 → 이미지 → T-pose 게이트 → 메시 → 리깅 → 모션 → Unity 프리팹·컨트롤러·씬까지
한 번에 간다. 단계별 재실행은 `--from <단계>` / `--only <단계>`,
확인만 할 때는 `--dry-run`.

산출물:

- `H:\source\ComfyUI\output\figures\<tag>_NNNN.fbx` — mixamorig 스켈레톤 캐릭터
- 같은 폴더 `anim_*.fbx` — 애니메이션 클립
- Unity 쪽 `Assets/Generated/` — 모델·텍스처·머티리얼·프리팹·컨트롤러·씬

## 4. 반드시 지킬 것

- **대상 Unity 프로젝트를 에디터에서 닫아 둔다.** 파이프라인의 Unity 단계는 batchmode라
  프로젝트가 열려 있으면 락에 걸린다. 열려 있으면 시작 전에 걸러내고 사용자에게 알린다.
- **사용자가 열어 둔 프로젝트의 기존 FBX를 덮어쓰지 않는다.** 그 모델을 씬에 드래그해 둔
  프리팹 인스턴스가 깨지고 **에디터가 네이티브 크래시로 죽는다.** 다시 열어도 또 죽는다
  (`Library/LastSceneManagerSetup.txt`가 그 씬을 자동으로 연다).
  반복 수정 중인 에셋은 검증 전용 프로젝트에만 넣고, 확정된 결과만 실제 프로젝트로 옮긴다.
- **수치 검증만으로 완료 보고하지 않는다.** 아바타 유효·정점 수·metallic이 전부 정상인데
  텍스처가 하나도 안 붙고 메시가 페이싯인 상태였던 적이 있다. 임포트 후 반드시 렌더까지
  본다 (`Tools > Generated > Shots`). 이는 [animation-pose.md](animation-pose.md) §4
  ("isHuman=True는 본 매핑 정확도를 보장하지 않는다")와 같은 성격의 함정이다.
- **실패한 개체는 고치지 않고 폐기하고 다시 뽑는다.** 사용자 방침이다. 소수 불량을
  파라미터로 구제하려 들지 않는다 — 실측에서 매번 시드 재생성이 더 싸고 확실했다.

## 5. 상세는 스택 안의 문서를 읽는다

이 문서는 **진입점일 뿐이다.** 명령 인자, 실측 수치, 실패한 접근과 그 이유는 전부
스택 리포에 있고 그쪽이 원본이다. 여기에 복제하지 않는다 (두 개의 원본을 만들지 않는다).

| 읽을 것 | 언제 |
| --- | --- |
| `H:\source\ComfyUI\CLAUDE.md` | 이 경로로 작업하기로 정한 직후. 항상 |
| `H:\source\ComfyUI\docs\pipeline.md` | 이미지·메시·리깅·모션 단계에서 막혔을 때 |
| `H:\source\ComfyUI\docs\unity.md` | Unity 임포트·머티리얼·프리팹·씬에서 막혔을 때 |
| `H:\source\ComfyUI\docs\pitfalls.md` | 원인 불명의 조용한 실패를 만났을 때 |

스택 쪽 규칙과 이 저장소의 규칙이 충돌하면 **이 저장소(§0~4)가 우선한다.**
