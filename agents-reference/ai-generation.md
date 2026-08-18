---
id: unity-ai-agent-instructions-ai-generation
title: AI 생성 서비스 사용 절차
version: 4
parent: 상위 지침 문서 (5의 표 등재)
---

# AI 생성 서비스 사용 절차

**로드 조건**: Unity AI 생성 서비스로 에셋(이미지, 스프라이트, 메시, 머티리얼, 사운드, 애니메이션, 큐브맵 등)을 새로 생성하거나 기존 에셋을 편집하는 작업일 때만 이 문서를 읽는다. 이미 생성된 에셋을 씬에 배치하기만 하는 작업, 프리미티브·절차적 생성으로 해결되는 작업에는 이 문서가 필요 없다.

이 문서는 상위 지침 문서(프로젝트 루트: `AGENTS.md`/`CLAUDE.md`, .unity-kb 원본: `HARNESS.md`) §1~4의 행동 규칙 아래에서 적용되는 도메인 절차다. 충돌 시 그 문서(§0~4)가 우선한다.

3D 모델의 **품질 기준과 프리미티브/생성 판단**은 [3d-asset-pipeline.md](3d-asset-pipeline.md)가 담당한다. 이 문서는 **호출 메커니즘**을 담당한다.

**v4 변경**: 프리미티브 구조물 + 생성 AI 인물 2체를 한 흐름으로 통합하는 실제 테스트(사막 바 씬)에서 얻은 결과를 반영했다. 핵심 정정 3건 — ① `RemoveImageBackground`는 `referenceImageInstanceId`를 아예 받지 않는다(§3 표, 이전 문서가 §9에서 이 커맨드에도 참조 ID가 쓰인다고 암시한 것은 틀렸다). ② `GenerateMesh`는 신규 생성이므로 `targetAssetPath`가 아니라 `savePath`를 써야 한다 — 반대로 넣으면 "Failed to find a valid GameObject asset"로 즉시 실패한다(§3). ③ §9의 "`GetEntityId()`는 복합 문자열이라 그대로 쓸 수 없다"는 서술이 틀렸다 — 콜론 앞 숫자가 deprecated `GetInstanceID()`와 정확히 일치한다는 것을 reflection 대조로 실측했다(§9). 추가로: §5의 Photoroom 사전 프로브 절차가 실제로는 참조 ID 없이 `targetAssetPath`만으로 동작해야 한다는 것, 부정 프롬프트("no X visible")가 신뢰할 수 없다는 실측(§7), 독립적인 생성 호출은 병렬 실행이 가능하다는 것(§1)을 반영했다.

**v3 변경**: 인물 1종(2D 시트 → 배경 제거 → 메시 → 씬 배치)을 실제로 완주하며 얻은 결과를 반영했다. 핵심은 **§7의 배경 규약을 검정에서 크로마키로 바꾼 것**이다 — 검정을 요구해도 모델이 비네트 그라디언트를 그리고, 어두운 의복이 배경보다 더 어두워져 색으로 분리할 수 없다는 것이 수치로 확인됐다. 배경 지정만 크로마키로 바꾸면 §10의 복구 절차 자체가 대부분 불필요해진다. 함께 반영한 것 — §5에 Photoroom 가용성 사전 프로브(포인트 0)와 승인 시 자체 구현이 정상 경로임을 명시, §8에 배경 평탄도 사전 측정과 **마스크 오차 허용 한계**(결손이 있어도 Tripo가 정상 메시를 만든다는 실측), §10에 검증된 자체 구현 절차와 기각된 방향.

**v2 변경**: Unity Assistant가 같은 파이프라인을 독립적으로 완주한 로그를 분석해 세 가지를 보강했다 — §9에 원본 덮어쓰기로 instance ID를 유지하는 수단, `meshFormat` 기본값이 fbx라는 실측, Assistant `RunCommand` 샌드박스가 `eval`보다 좁다는 점. 아울러 그 로그에서 프로바이더 실패를 자체 구현으로 메우고 보고에서 누락한 사례가 확인되어 §5에 명시적 금지를 추가했다.

## 1. 호출 경로

**`unity command` CLI에는 생성 명령이 없다.** Pipeline이 제공하는 명령 목록(약 137개)에 생성 관련 항목은 0개다. 생성 기능은 Unity가 자체 운영하는 **MCP 서버**(`Unity.AI.MCP.Editor.Bridge`)에 있고, `McpToolRegistry`에 54개 툴이 등록되어 있다. 그중 `Unity_AssetGeneration_*` 9개가 생성 계열이다.

| MCP 툴 | 용도 |
|---|---|
| `Unity_AssetGeneration_GenerateAsset` | 생성·편집 전반 (`command` 파라미터로 분기) |
| `Unity_AssetGeneration_GetModels` | 사용 가능 모델 조회 |
| `Unity_AssetGeneration_GetCompositionPatterns` | 머티리얼/터레인 컴포지션 패턴 |
| `Unity_AssetGeneration_ManageInterrupted` | 중단된 생성 관리 |
| `Unity_AssetGeneration_ConvertToMaterial` / `ConvertToTerrainLayer` | 이미지 → 머티리얼/터레인 레이어 |
| `Unity_AssetGeneration_ConvertSpriteSheetToAnimationClip` / `CreateAnimatorControllerFromClip` | 애니메이션 변환 |
| `Unity_AssetGeneration_EditAnimation` / `EditAudio` | 클립 편집 |

Assistant 채팅 창도, 외부 MCP 클라이언트 연결도 필요 없다. `unity command eval`에서 직접 호출한다:

```
unity command eval → McpToolRegistry.ExecuteToolAsync(toolName, JObject)
```

`GenerateAssetTool.GenerateAsset`의 첫 인자인 `ToolExecutionContext`는 **직접 다루지 않는다.** MCP 어댑터(`AgentToolMcpAdapter`)가 `[AgentTool]` 어트리뷰트가 붙은 메서드를 등록하면서 컨텍스트를 자체 구성한다.

### fire & poll 러너 (필수 패턴)

AGENTS.md §2.0대로 **메인 스레드를 막으면 안 된다.** `.Wait()`를 걸면 Editor 전체가 정지한다. 다음 형태로만 호출한다.

```csharp
// SessionState["gen_tool"], ["gen_args"], ["gen_key"] 를 미리 세팅해두고 실행
var ALL = System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.NonPublic
        | System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.Instance;
var mcpAsm = System.AppDomain.CurrentDomain.GetAssemblies()
    .First(a => a.GetName().Name == "Unity.AI.MCP.Editor");
var mr = mcpAsm.GetTypes().First(t => t.Name == "McpToolRegistry");
var exec = mr.GetMethod("ExecuteToolAsync", ALL);
var jobjType = exec.GetParameters()[1].ParameterType;

string argJson = UnityEditor.SessionState.GetString("gen_args", "");
string key     = UnityEditor.SessionState.GetString("gen_key", "gen_result");
string toolName= UnityEditor.SessionState.GetString("gen_tool", "Unity_AssetGeneration_GenerateAsset");

var args = jobjType.GetMethod("Parse", new[] { typeof(string) }).Invoke(null, new object[] { argJson });
UnityEditor.SessionState.SetString(key, "PENDING");
var t0 = UnityEditor.EditorApplication.timeSinceStartup;
var task = (System.Threading.Tasks.Task)exec.Invoke(null, new object[] { toolName, args });

UnityEditor.EditorApplication.CallbackFunction cb = null;
cb = () =>
{
    if (!task.IsCompleted) return;
    UnityEditor.EditorApplication.update -= cb;
    double secs = UnityEditor.EditorApplication.timeSinceStartup - t0;
    if (task.IsFaulted) {
        UnityEditor.SessionState.SetString(key, "FAULTED " + secs.ToString("F1") + "s: "
            + task.Exception.GetBaseException().Message);
        return;
    }
    var res = task.GetType().GetProperty("Result").GetValue(task);
    var s = Newtonsoft.Json.JsonConvert.SerializeObject(res);
    if (s.Length > 3000) s = s.Substring(0, 3000) + " ...[cut]";
    UnityEditor.SessionState.SetString(key, "DONE " + secs.ToString("F1") + "s :: " + s);
    UnityEditor.AssetDatabase.Refresh();
};
UnityEditor.EditorApplication.update += cb;
return "fired -> SessionState[" + key + "]";
```

회수는 별도 호출로: `unity command eval --code 'return UnityEditor.SessionState.GetString("<key>","NOT_SET");'`

생성은 보통 20~40초, 메시는 그 이상 걸린다. 폴링은 백그라운드로 돌린다. 실측(사막 바 테스트, 인물 2체): 전신 시트 생성 ~30초, 배경 제거 ~20~25초, `GenerateMesh` 82~88초. **서로 독립적인 생성 호출은 동시에 fire해도 된다** — 한쪽의 폴링을 기다리는 동안 다른 쪽을 fire해서 총 대기시간을 줄일 수 있음을 확인했다(한 캐릭터의 메시 생성과 다른 캐릭터의 시트 생성을 동시에 진행).

**실행 샌드박스 차이**: Unity Assistant의 `RunCommand`는 `unity command eval`보다 제약이 크다 — `System.Reflection` 등 일부 네임스페이스를 아예 차단한다. 두 경로 모두 컴파일 경고를 에러로 처리하며 `#pragma warning disable`이 통하지 않는다.

## 2. 착수 전 사전 점검 (필수)

생성을 시작하기 **전에** 아래를 확인한다. 뒤 단계에서 막히면 앞 단계 산출물이 통째로 무용지물이 된다.

1. **`ManageInterrupted(List)`** — 중단된 생성이 하나라도 있으면 새 생성이 거부된다. 목록을 비우거나 `forceGeneration: true`를 쓴다.
2. **의존 프로바이더 가용성** — 쓰려는 커맨드가 고정 프로바이더에 묶여 있는지, 그 프로바이더 쿼터가 살아 있는지. 특히 3D 경로는 `RemoveImageBackground`(Photoroom)에 종속된다.
3. **`com.unity.cloud.gltfast`** — 메시 산출물이 GLB일 때 이 패키지가 없으면 임포트되지 않는다.
4. **`set_autotick --enable true --interval_ms 100`** — Editor가 포커스를 잃어도 비동기가 진행되도록.

## 3. `GenerateAsset` 커맨드

`command` 하나만 필수. enum 23종:

```
GenerateHumanoidAnimation, GenerateCubemap, UpscaleCubemap, GenerateMaterial,
AddPbrToMaterial, GenerateMesh, GenerateSound, GenerateSprite, GenerateImage,
GenerateSpritesheet, RemoveSpriteBackground, RemoveImageBackground, UpscaleImage,
UpscaleSprite, RecolorImage, RecolorSprite, EditSpriteWithPrompt, EditImageWithPrompt,
GenerateTerrainLayer, AddPbrToTerrainLayer, RetopologyMesh, TextureMesh, RigMesh
```

주요 파라미터: `modelId`, `prompt`, `savePath`, `targetAssetPath`, `waitForCompletion`, `referenceImageInstanceId`, `referenceImageInstanceIds[]`, `referenceImageLabels[]`, `width`, `height`, `meshFormat`(`glb`|`fbx`), `durationInSeconds`, `loop`, `voiceName`, `forceGeneration`.

**`savePath` vs `targetAssetPath` — 신규 생성이냐 기존 에셋 편집이냐로 갈린다(실측 확인).** `GenerateSprite`/`GenerateImage`/`GenerateMesh`처럼 **새 에셋을 만드는** 커맨드는 `savePath`를 쓴다. `RemoveImageBackground`/`EditImageWithPrompt`/`RigMesh`/`TextureMesh`/`RetopologyMesh`처럼 **기존 에셋을 그 자리에서 고치는** 커맨드는 `targetAssetPath`를 쓴다. 반대로 넣으면(`GenerateMesh`에 `targetAssetPath`) "Failed to find a valid GameObject asset at the specified path"로 즉시 실패한다.

### 커맨드별 주의

| 커맨드 | 확인된 특성 |
|---|---|
| `GenerateSprite` / `GenerateImage` | `modelId` 유효. 배경은 불투명하게 나온다 — 투명이 필요하면 별도 단계 필요 |
| `RemoveImageBackground` | **`modelId`를 무시**하고 `photoroom-bg-removal`에 하드 라우팅. 모델 교체로 우회 불가. **`referenceImageInstanceId`를 받지 않는다**("A 'referenceImageInstanceId' cannot be used when removing a background") — `targetAssetPath`만 넘긴다 |
| `EditImageWithPrompt` | **`savePath`를 무시**하고 `targetAssetPath`에 in-place로 덮어쓴다. 해상도도 바뀔 수 있다(1024→1008 실측). 실행 전 원본 백업 필수 |
| `GenerateMesh` | 레퍼런스 이미지에 **실제 알파 채널을 강제**한다. 단색·검정 배경은 거부된다. 산출물은 파일이 아니라 메시+머티리얼이 포함된 **Prefab**. `meshFormat` 미지정 시 기본값은 **fbx**이며(실측 확인) 이 경우 gltfast를 거치지 않는다. `glb`가 필요하면 명시할 것 |
| `RigMesh` / `TextureMesh` / `RetopologyMesh` | 기존 메시 후처리. `targetAssetPath` 필요 |

## 4. 프로바이더 구조

Unity AI는 서드파티 애그리게이터다. `GetModels`로 조회되는 64개 모델이 Google(gemini, lyria), OpenAI(gpt-image), Black Forest Labs(flux), Photoroom, Tripo, Tencent(hunyuan), ElevenLabs, Scenario, Magnific, Kling, Seedance, Uthana, Meta 및 Unity 자체 모델로 나뉜다.

**쿼터는 프로바이더별로 독립이다.** 이미지 생성이 정상 동작하는 것과 특정 오퍼레이션이 동작하는 것은 별개다. 실제로 `gemini-3.0-pro` 생성은 성공하는데 `photoroom-bg-removal` 배경 제거만 계정 한도로 전면 차단된 사례가 있었다.

용도별 모델 (조회 시점 기준, 반드시 `GetModels`로 재확인할 것):

- **Model3d**: `model3d-tripo3-1`(+multiview), `model3d-tripo-p1`(+multiview), `model3d-hunyuan-3d-pro-3-1`(+multiview), `model3d-tripo-retopo`, `model3d-tripo-rigging-v1`
- **Tileable 텍스처**: `gemini-3.1-flash-texture`, `realistic-textures-3-0`, `hand-painted-textures-2-0`, `unity-texture2d`
- **이미지/스프라이트**: `gemini-3.0-pro`, `flux-2-pro`, `gpt-image-1-5`
- **배경 제거**: `photoroom-bg-removal` (선택 불가, 고정)

## 5. 실패 3분류

| 유형 | 예시 | 비용 | 잔여 상태 | 대응 |
|---|---|---|---|---|
| **검증 거부** | "must have a transparent background" | 없음 | 없음 | 입력 조건을 고쳐 재시도 |
| **프로바이더 실패** | `ProviderFailure: ... reached its image generation limit` | 시간 소모 | **대상 에셋이 중단 상태로 편입** | AGENTS.md §1.3 예외 — 재시도·우회 없이 즉시 §1.4 보고·정지 |
| **중단 상태 충돌** | "is still being generated, check back later" | 없음 | 유지 | `ManageInterrupted`로 정리 후 재시도 |

`success: false`인데 대상 파일이 이미 바뀐 경우가 있다. AGENTS.md §3.2대로 실패 후에도 상태를 확인한다.

**프로바이더 실패를 승인 없이 손수 구현해 메우지 않는다.** 예를 들어 `RemoveImageBackground`가 쿼터로 막혔을 때 C#으로 배경 제거를 직접 구현해 진행하는 것은, 승인이 없으면 AGENTS.md §1.2(임의 대체 금지)·§1.3(재시도 예외) 위반이다. 실제로 승인 없이 진행한 뒤 프로바이더 실패와 자체 구현 사실을 보고에서 누락한 사례가 있었다. 기술적으로 가능한지와 무관하게, 승인 없이 대체하지 않는다.

단 **사용자 승인을 받으면 자체 구현이 정상 경로다.** 절차와 검증된 구현은 §10에 있다. 승인 요청 시 §1.4 서식의 옵션으로 제시하고, 진행 후 보고에는 "프로바이더 실패 → 승인 하에 자체 구현" 사실을 반드시 명시한다.

**Photoroom 가용성 사전 프로브 (시트 생성 전 필수)**: 절차적으로 만든 128×128 더미 PNG 한 장을 프로젝트에 임포트하고, `RemoveImageBackground`를 `targetAssetPath`로 그 더미를 가리켜 1회 호출한다. **`referenceImageInstanceId`는 넣지 않는다** — 이 커맨드는 그 파라미터를 아예 받지 않으며(위 §3), 더미의 instance ID를 구하려 애쓸 필요 자체가 없다. 생성 포인트 0, 소요 약 19~25초로 쿼터 차단 여부가 확정된다. 실측 확인 — 이 프로브 없이 진행한 세션은 시트 3장을 만든 뒤 막힌 것을 발견해 전부 폐기했고, 프로브를 먼저 돌린 세션은 더미 960바이트로 같은 결론에 도달했다. 프로브가 실패하면 그 더미 에셋이 중단 목록에 편입되므로 `ManageInterrupted(Discard)`로 정리하고 더미를 삭제한다.

## 6. `ManageInterrupted` 운용

`command`는 `List` / `Resume` / `Discard` 세 가지뿐이고 **개별 에셋 지정 수단이 없다 — 전체 일괄 처리만 된다.**

- 목록에 **다른 작업의 미완 생성이 섞여 있으면 `Resume`/`Discard` 모두 사용자 승인이 필요하다.** `Resume`은 남의 에셋에 포인트를 쓰고 `Discard`는 남의 작업을 폐기한다.
- **`Discard`는 에셋 파일을 삭제하지 않는다.** 대기 상태 기록만 지우며 파일은 바이트 단위로 보존된다(실측 확인).
- 목록을 건드리지 않고 새 생성만 진행하려면 `forceGeneration: true`. 단 이는 "중단 건이 있음" 검사만 우회하며, **대상 에셋 자신이 중단 상태이면 통하지 않는다** — 그때는 `Discard`가 필요하다.

## 7. 3D 입력 이미지 프롬프트 규약

`GenerateMesh`에 넣을 시트를 생성할 때 아래를 프롬프트에 명시한다. 각 항목은 실제 결함을 막기 위한 것이다.

- **배경 — 크로마키 단색을 요구한다**: `isolated on a completely flat uniform chroma key background of fully saturated magenta (hex FF00FF), the background must be one single flat color with no gradient, no vignette, no lighting falloff, no ground plane, no floor, no cast shadow on the background, no reflection`
  키 색은 **피사체에 등장하지 않는 고채도 색**으로 고르고, 프롬프트에 hex를 함께 적는다. 피사체가 녹색 계열이면 마젠타, 붉은 계열이면 시안·녹색을 쓴다.
  이유(실측): 검정 배경을 요구하면 모델이 **순수 검정이 아니라 어두운 회색 비네트 그라디언트**를 그린다. 실측값 — 테두리 8px 밴드 휘도 min=4 / p50=12 / p99=28 / max=37, 배경 프로브 6.8~26.0. 이러면 전역 휘도 임계값으로 배경을 분리할 수 없다.
- **어두운 의복 보호 — 검정 배경에서는 이 문구로도 부족하다**: 검정 배경을 쓸 수밖에 없을 때만 `even frontal studio lighting so that the boots and all dark garments remain clearly brighter than the background`를 넣는다. 단 이 문구를 넣어도 실패한 사례가 있다 — 챙 아래 그림자 휘도 min=2, 구두 min=0으로 **배경(max 37)보다 피사체가 더 어두워졌다.** 휘도로도 채도로도(그림자 채도 1 vs 배경 채도 ≤7) 분리 불가였다. 크로마키를 쓰면 이 문제가 발생하지 않는다.
- **프레이밍**: `the complete figure including both hands and both feet must be fully inside the frame with generous empty margin on all four sides, nothing touches or is cropped by the image border, the figure occupies only the central 70 percent of the canvas`
  T-포즈는 정사각 프레임에서 팔 스팬이 폭을 초과해 손이 잘린다. 실제로 여백 지시 없이 생성했을 때 오른손이 이미지 끝에 잘렸다.

**함정**: 프롬프트로 `transparent background`를 요구하면 알파 채널이 만들어지는 게 아니라 **투명을 표현하는 체커보드 무늬가 불투명 픽셀로 그려진다.** 눈으로 보면 투명해 보이지만 알파는 전부 255다. 알파가 필요하면 `RemoveImageBackground` 또는 §10을 써야 한다.

**부정 지시는 신뢰할 수 없다(실측).** 프롬프트에 "no stool or chair visible, only the seated figure"처럼 명시적으로 넣어도, 모델이 의자를 포함시킨 채 생성한 사례가 있었다. 재시도로 해결하려 하지 말고(같은 프롬프트를 다시 돌려도 재현 보장이 없다), **씬 배치 단계에서 흡수할 계획을 세운다** — 예: 그 자리에 이미 놓아둔 프리미티브 소품을 제거하고 생성된 메시가 가져온 소품을 그대로 쓴다. 다만 프리미티브와 생성물의 소품 스타일(재질·색)이 어긋날 수 있으므로 최종 스크린샷에서 눈에 띄는 불일치가 없는지 확인한다.

## 8. 수치 검증 기준

AGENTS.md §3.2대로 시각 판단을 금지한다. 생성 이미지는 아래를 측정해 판정한다.

**배경 평탄도 사전 측정 (배경 제거 착수 전)**: 테두리 8px 밴드의 휘도 `min`/`p50`/`p99`/`max`와 채도 `max`를 먼저 낸다. `p99 - min`이 10 레벨을 넘으면 그라디언트 배경이므로 **전역 임계값 방식은 실패한다** — §10의 연결성 기반 방식으로 가거나 시트를 크로마키로 다시 생성한다.

| 판정 항목 | 측정 방법 | 합격 기준 |
|---|---|---|
| 투명 배경 여부 | `alpha == 0` 픽셀 비율 | 0%면 알파 없음 = 불합격 |
| 사지 잘림 | 피사체 bbox가 이미지 테두리에 접촉하는지 | 사면 모두 여백 존재 |
| 실루엣 연결성 | 불투명 픽셀의 4-연결 성분 개수(500px 이상만 계수) | 1개. 2개 이상이면 부위가 떠 있다 |
| 발 실루엣 보존 | bbox 하단 14% 영역의 행별 폭 추이 | 최하단에서 급증 후 완만 감소(발 형상). 균일하면 절단면 |

**마스크 오차 허용 한계 — 여기까지만 검증하고 더 다듬지 않는다.** 실측 확인: 챙이 10~15px 깊이로 톱니형 결손된 마스크(단일 성분, alpha0 84.48%)로 `model3d-tripo-p1`을 돌렸을 때 **챙이 온전한 정상 메시가 나왔다.** Tripo는 알파 실루엣만 보지 않고 RGB 내용으로 형상을 복원하므로 국소 결손을 흡수한다. 위 4개 항목이 통과하면 마스크 품질 개선 반복을 중단하고 §3단계로 진행한다. 임계값을 바꿔 재시도하는 것은 AGENTS.md §1.3의 재시도 한계를 소모할 뿐이다.

이미지는 `System.IO.File.ReadAllBytes` + `UnityEngine.ImageConversion.LoadImage`로 디코딩해 `GetPixels32()`로 직접 측정한다. 이 경로는 파이프라인의 `GetImageAssetContent` 미지원 제약을 받지 않는다.

메시는 [3d-asset-pipeline.md](3d-asset-pipeline.md)의 검증 절차(Bounds Y-Extent, 하단 절단면, 아티팩트 구워짐)를 따른다.

## 9. 정수 instance id 획득

`referenceImageInstanceId`는 정수를 요구하는데, Unity 6.6에서 `Object.GetInstanceID()`는 deprecated이고 eval은 경고를 에러로 처리하므로 **직접 호출하면 컴파일이 막힌다.**

**정정(실측, 이전 버전 오류)**: 이 문서는 한때 `GetEntityId()`가 `"54850:2304"` 형태의 복합 문자열이라 "그대로 쓸 수 없다"고 적었으나 **틀렸다.** 콜론 앞 숫자가 deprecated `GetInstanceID()`가 반환했을 값과 **정수 단위로 정확히 일치**한다 — reflection으로 두 메서드를 나란히 호출해 비교 확인했다(런타임 임시 오브젝트, 그리고 프로젝트에 저장된 실제 에셋 양쪽 모두). 즉:

```csharp
var eid = obj.GetEntityId();
int classicInstanceId = int.Parse(eid.ToString().Split(':')[0]);  // 예: "32607:1280" -> 32607
```

reflection 없이, 경고를 에러로 만드는 obsolete 호출 없이 값을 얻을 수 있다. 콜론 뒤 숫자(예 `1280`)는 세대/버전 카운터로 추정되나 검증하지 않았다.

**단, 이 값이 모든 곳에서 통하는 건 아니다(실측).** `RemoveImageBackground`가 애초에 `referenceImageInstanceId`를 받지 않는 것처럼(§3), 일부 생성 커맨드는 **자신이 발급한 생성 응답에서 나온 ID만 유효한 참조로 인정**하고, 이 방법으로 구한 "정확하지만 출처가 다른" ID는 "does not exist"로 거부할 수 있다 — 실제로 절차적으로 만든 더미 PNG에 이 방법으로 구한 ID를 `GenerateMesh`류 커맨드에 넘겼더니 거부당한 사례가 있다. 이 기법은 **`set_selection --instance_ids` 같은, 임의의 Unity 오브젝트를 가리키면 되는 다른 용도**에 우선 쓰고, AI 생성 커맨드의 참조 이미지는 아래 수단 1(생성 응답의 `FileInstanceID`)을 계속 우선한다.

**수단 1 — 생성 툴 응답의 `FileInstanceID`.** 생성이 성공하면 응답 `data`에 `AssetName`, `AssetPath`, `AssetGuid`와 함께 `FileInstanceID`가 정수로 들어 있다. 이 값을 다음 단계의 `referenceImageInstanceId`로 넘긴다.

**수단 2 — 원본 에셋에 덮어써서 기존 ID를 유지한다.** 중간 가공(배경 제거 등)으로 새 이미지 파일을 만들면 그 파일의 정수 ID를 구할 방법이 없다. 이때 새 파일을 참조하려 하지 말고 **가공 결과를 원본 에셋 경로에 덮어쓴다.** 그러면 수단 1로 이미 확보해 둔 ID가 그대로 유효하고, 그 ID가 가공된 이미지를 가리키게 된다.

```csharp
byte[] bytes = System.IO.File.ReadAllBytes(processedPath);
System.IO.File.WriteAllBytes(originalAssetPath, bytes);   // ID 유지
UnityEditor.AssetDatabase.Refresh();
```

원본이 소실되므로 **덮어쓰기 전 프로젝트 밖에 백업**하고, 원본을 잃는다는 사실을 사용자에게 보고한다.

실측 확인: 덮어쓴 뒤 `ImportAsset(ForceUpdate)`를 걸어도 생성 응답의 `FileInstanceID`는 유효했다. 그 ID를 `referenceImageInstanceId`로 넘긴 `GenerateMesh`가 정상 완료(90.2초)했다. ID는 int32를 넘는 64비트 값(`20890720959654`)이므로 `long`으로 다룬다 — 스키마에 `integer`로 적혀 있어도 그렇다.

## 10. 배경 제거 자체 구현 (사용자 승인 필요)

§5의 승인을 받은 뒤에만 쓴다. **크로마키 배경(§7)이면 채도 한 번으로 끝나므로 이 절이 거의 불필요하다.** 아래는 그라디언트 검정 배경으로 이미 시트를 만들어버린 경우의 복구 절차이며, 실제로 완주해 정상 메시를 얻은 구성이다.

임계값은 추측하지 않고 §8의 사전 측정에서 뽑는다. 실측 예시와 그때 정한 값:

| 측정 대상 | 실측 | 도출한 파라미터 |
|---|---|---|
| 배경 4영역 채도 max | 7 | `CHROMA_MAX = 8` |
| 발밑 그림자 채도 max | 8 | 그림자도 배경으로 분류됨(의도한 결과) |
| 테두리 밴드 휘도 max | 37 | `LUM_MAX = 45` |
| 코트 채도 p5 | 12 | `CHROMA_MAX=8`과 분리 확보 |

절차:

1. **배경 후보**: `chroma <= CHROMA_MAX && lum <= LUM_MAX`.
2. **테두리 시드 4-연결 플러드필**로 후보를 확정 배경으로 승격. **이 연결성 단계가 핵심이다** — 모자 내부·코트 솔기처럼 피사체 안쪽의 휘도 0~2 픽셀은 테두리에서 도달할 수 없어 보존된다. 전역 임계값만 쓰면 이들이 전부 뚫린다.
3. **모폴로지 클로징**으로 끊어진 부위를 잇는다. 반경은 고정값이 아니라 **성분 수가 1이 되는 최소 반경을 실측해서** 고른다(r=1~8을 순회하며 500px 이상 성분 수를 세는 것으로 충분하다). 실측 예 — 챙 아래 그림자로 모자가 몸통과 분리됐고 r=1~4는 2성분, r=5에서 1성분(면적 +1.6%).
4. **연결 성분 필터**: 500px 미만 조각 제거. 그림자 잔여·노이즈가 여기서 정리된다.
5. **이진 알파**: 피사체 alpha=255(원본 RGB 유지), 배경 `Color32(0,0,0,0)`. 페더링은 넣지 않는다 — 검증된 산출물의 `alphaPartial`은 0이었다.
6. 클로징이 추가한 픽셀에 원본 RGB를 복원하려면 **가공을 원본 백업에서 처음부터 다시 돌린다.** 이미 알파 처리한 파일 위에 클로징을 얹으면 그 픽셀이 순수 검정으로 남는다.

**하지 말 것 — 실측으로 기각된 방향**: 배경 그라디언트를 2차 다항으로 적합해 잔차로 판정하는 방식은 더 나빠진다. 테두리 40px 밴드 적합으로 실행했을 때 배경 잔차는 ±9 이내였지만 챙 그림자의 잔차 중앙값이 −4~−6으로 **그 대역 안에 들어와 분리에 실패**했고, 동시에 내부로 갈수록 적합이 발산해 배경을 대량 잔존시켰다(alpha0 84.48% → 71.31%, 피사체 면적 1.85배). 깊은 그림자는 배경과 색이 같으므로 per-pixel 규칙으로는 원리적으로 분리되지 않는다 — 연결성과 모폴로지로만 다룬다.
