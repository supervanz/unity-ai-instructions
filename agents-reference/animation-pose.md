---
id: unity-ai-agent-instructions-animation-pose
title: 애니메이션·포즈 생성 작업 절차
version: 1
parent: 상위 지침 문서 (5의 표 등재)
---

# 애니메이션·포즈 생성 작업 절차

**로드 조건**: `GenerateHumanoidAnimation` 등 AI 생성 서비스로 캐릭터의 동작(motion) 또는 정지 포즈(pose)를 만드는 작업일 때만 이 문서를 읽는다. 호출 메커니즘(fire & poll, 파라미터 일반 규약)은 [ai-generation.md](ai-generation.md)를 따르고, 이 문서는 애니메이션·포즈 생성에 고유한 판단 기준만 다룬다.

이 문서는 상위 지침 문서(프로젝트 루트: `AGENTS.md`/`CLAUDE.md`, .unity-kb 원본: `HARNESS.md`) §1~4의 행동 규칙 아래에서 적용되는 도메인 절차다. 충돌 시 그 문서(§0~4)가 우선한다.

**v1 근거**: T-Pose 캐릭터 생성 → `RigMesh` → `GenerateHumanoidAnimation` → Humanoid 리타겟 파이프라인을 실제로 완주한 시범(디저트 바 씬, 여름 드레스 캐릭터)에서 얻은 결과를 반영했다.

## 1. 먼저 구분한다 — 동작(motion)인가, 정지 포즈(pose)인가

- **동작**(걷기, 인사하기, 손 흔들기 등 지속적으로 움직이는 행위)을 만드는 작업이면 일반적인 서술형 프롬프트로 진행한다. 아래 §2의 seamless loop 요구는 이 경우 대상이 아니다(동작 자체가 반복 가능한 사이클을 내포하는지는 별도 실측 없음 — 필요하면 §3의 수치 검증 방법으로 매번 확인한다).
- **정지 포즈**(앉기, 서 있기, 특정 자세 유지처럼 한 자세를 유지시키는 것이 목적인 경우)를 만드는 작업이면 **반드시 §2를 적용한다.**

## 2. 정지 포즈 생성 시 필수 — 프롬프트 텍스트에 "seamless loop"를 명시한다

**실측(같은 프롬프트, 변수 하나만 다르게 두 번 생성 비교, 모델 `uthana-text-to-motion-3`):**

| 시도 | 방식 | 시작-끝 힙 위치 차이 | 시작-끝 힙 회전 차이 | 시작-끝 무릎 회전 차이 |
|---|---|---|---|---|
| v3 | JSON 파라미터 `loop: true`만 추가, 프롬프트 텍스트는 동작 서술만 | 0.54m | 20.1° | 66.5° |
| v4 | 프롬프트 **텍스트 안에** "a seamless looping animation ... holding this exact seated pose motionlessly from the first frame to the last frame so the loop has no visible seam" 명시 | 0.125m | 0.22° | 1.02° |

- **JSON `loop` 파라미터만으로는 부족하다.** `GetModels` 조회에서 이 계열 텍스트-투-모션 모델(`uthana-text-to-motion-3`, `unity-text-to-motion`)은 `SupportsTextPrompt`만 표시하고, 사운드 모델(`elevenlabs-sound-effects-v2`)에 있는 `SupportsAudioLooping` 같은 루프 지원 플래그가 없다 — 이 모델들이 `loop` 파라미터 자체를 반영하는지 불확실하다.
- **프롬프트 텍스트에 seamless loop를 서술로 명시하면 개선된다.** 시작-끝 무릎 회전 차이가 66.5° → 1.02°로 줄었다.
- **잔차는 남는다.** 힙 위치 12.5cm 차이는 완전한 제로가 아니다. 정밀한 루프가 필요하면 클립 전체를 반복 재생하지 말고, 포즈가 안정된 구간(예: 클립 길이의 60~70% 지점)에서 고정하거나 그 구간만 트림해서 쓰는 것으로 보완한다.

## 3. 판정은 수치로 한다 — 원거리 스크린샷으로 포즈를 오판하지 않는다

**실측 실패 사례**: 1280×720 광각(전신 씬 전체가 담기는) 스크린샷만으로 "앉았는지"를 판정해 "서 있다"고 오판했다. 실제로는 무릎이 굽혀진 정상 착석 포즈였으나, 캐릭터가 화면에서 차지하는 비중이 작아 다리 굽힘이 육안으로 구분되지 않았다. 카메라를 캐릭터에 근접시켜서야 정정할 수 있었다.

AGENTS.md §3.2의 수치 검증 원칙을 애니메이션 자세 판정에도 그대로 적용한다:

- **Play 모드 진입 없이 `UnityEditor.AnimationMode.SampleAnimationClip(gameObject, clip, time)`으로 클립의 임의 시점을 직접 샘플링**할 수 있다. `AnimationMode.StartAnimationMode()` → `BeginSampling()` → 원하는 시점마다 `SampleAnimationClip` → 본 Transform 값 읽기 → `EndSampling()` → `StopAnimationMode()` 순서.
- 시작/중간/끝 등 여러 시점에서 `Animator.GetBoneTransform(HumanBodyBones.Hips)` 등 핵심 본의 위치·회전을 뽑아 `Vector3.Distance` / `Quaternion.Angle`로 차이를 수치화한다.
- 스크린샷은 수치 검증을 보조하는 용도로만 쓰고, 캐릭터가 화면에서 작게 나오면(광각 전신 씬 샷 등) 근접 촬영으로 별도 확인한다.

## 4. Humanoid 리깅 실측 부기 — "isHuman=True"는 본 매핑 정확도를 보장하지 않는다

- `RigMesh`로 생성한 리그가 Unity의 Humanoid Avatar로 인식(`avatar.isValid && avatar.isHuman == true`)되는 것은 실측으로 확인됐다(fbx `ModelImporter.animationType`을 `Human`으로 전환한 뒤).
- **다만 이 인식이 본 이름 매핑의 해부학적 정확도까지 보장하지는 않는다.** 생성된 애니메이션 클립을 Animator/AnimatorController 경유로 재생하는 리타겟은 정상 동작했지만, `Animator.GetBoneTransform(HumanBodyBones.LeftUpperLeg)` 등으로 개별 본을 직접 찾아 회전시켜 수동으로 포즈를 만드는 시도는 다리가 굽혀지는 대신 캐릭터 전체가 바닥으로 붕괴되는 결과로 나타났다 — 이는 자동 매핑이 통과 판정만 받고 세부 대응이 실제 관절 위치와 어긋났을 가능성을 시사한다.
- 따라서 **정지 포즈가 필요하면 개별 본 수동 조작보다 §2의 방식(생성 클립 + seamless loop 프롬프트)을 우선한다.** 개별 본 조작은 이 리그에 대해 검증되지 않은 경로다.

## 5. 도구 이름 함정 — MCP 툴 이름에 해시 접미사가 붙을 수 있다

`Unity_AssetGeneration_ConvertSpriteSheetToAnimationClip`, `Unity_AssetGeneration_CreateAnimatorControllerFromClip` 같은 이름을 문서·설명에서 그대로 써도 실제 `McpToolRegistry`에는 **이름이 잘리고 해시가 붙어 등록**되어 있을 수 있다(실측: `Unity_AssetGeneration_CreateAnima_40e1a9ab`). `ExecuteToolAsync` 호출이 "tool not found"로 실패하면, 에러 메시지에 포함된 `Available tools` 목록에서 정확한 이름을 찾아 재시도한다(이 재시도는 AGENTS.md §1.3의 재시도 한계에 포함되지 않는 이름 확인 성격의 실패다).

또한 `CreateAnimatorControllerFromClip` 계열 툴의 클립 경로 파라미터 이름은 `clipAssetPath`가 아니라 **`animationClipPath`**다(실측).
