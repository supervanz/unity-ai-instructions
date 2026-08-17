---
id: unity-ai-agent-instructions-ai-generation
title: AI 생성 서비스 사용 절차
version: 1
parent: AGENTS.md (5의 표 등재)
---

# AI 생성 서비스 사용 절차

**로드 조건**: Unity AI 생성 서비스로 에셋(이미지, 스프라이트, 메시, 머티리얼, 사운드, 애니메이션, 큐브맵 등)을 새로 생성하거나 기존 에셋을 편집하는 작업일 때만 이 문서를 읽는다. 이미 생성된 에셋을 씬에 배치하기만 하는 작업, 프리미티브·절차적 생성으로 해결되는 작업에는 이 문서가 필요 없다.

이 문서는 [AGENTS.md](../AGENTS.md) §1~4의 행동 규칙 아래에서 적용되는 도메인 절차다. 충돌 시 AGENTS.md가 우선한다.

3D 모델의 **품질 기준과 프리미티브/생성 판단**은 [3d-asset-pipeline.md](3d-asset-pipeline.md)가 담당한다. 이 문서는 **호출 메커니즘**을 담당한다.

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

생성은 보통 20~40초, 메시는 그 이상 걸린다. 폴링은 백그라운드로 돌린다.

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

### 커맨드별 주의

| 커맨드 | 확인된 특성 |
|---|---|
| `GenerateSprite` / `GenerateImage` | `modelId` 유효. 배경은 불투명하게 나온다 — 투명이 필요하면 별도 단계 필요 |
| `RemoveImageBackground` | **`modelId`를 무시**하고 `photoroom-bg-removal`에 하드 라우팅. 모델 교체로 우회 불가 |
| `EditImageWithPrompt` | **`savePath`를 무시**하고 `targetAssetPath`에 in-place로 덮어쓴다. 해상도도 바뀔 수 있다(1024→1008 실측). 실행 전 원본 백업 필수 |
| `GenerateMesh` | 레퍼런스 이미지에 **실제 알파 채널을 강제**한다. 단색·검정 배경은 거부된다. 산출물은 파일이 아니라 메시+머티리얼이 포함된 **Prefab** |
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

## 6. `ManageInterrupted` 운용

`command`는 `List` / `Resume` / `Discard` 세 가지뿐이고 **개별 에셋 지정 수단이 없다 — 전체 일괄 처리만 된다.**

- 목록에 **다른 작업의 미완 생성이 섞여 있으면 `Resume`/`Discard` 모두 사용자 승인이 필요하다.** `Resume`은 남의 에셋에 포인트를 쓰고 `Discard`는 남의 작업을 폐기한다.
- **`Discard`는 에셋 파일을 삭제하지 않는다.** 대기 상태 기록만 지우며 파일은 바이트 단위로 보존된다(실측 확인).
- 목록을 건드리지 않고 새 생성만 진행하려면 `forceGeneration: true`. 단 이는 "중단 건이 있음" 검사만 우회하며, **대상 에셋 자신이 중단 상태이면 통하지 않는다** — 그때는 `Discard`가 필요하다.

## 7. 3D 입력 이미지 프롬프트 규약

`GenerateMesh`에 넣을 시트를 생성할 때 아래를 프롬프트에 명시한다. 각 항목은 실제 결함을 막기 위한 것이다.

- **배경**: `isolated on a pure solid black background, no ground plane, no floor, no cast shadow, no reflection`
  검은 배경은 바닥 그림자를 배경에 묻어 없애고 외곽선 대비를 최대화한다.
- **어두운 의복 보호**: `even frontal studio lighting so that the boots and all dark garments remain clearly brighter than the black background`
  이 문구가 없으면 어두운 신발·의복이 배경에 뭉개져 실루엣이 침식된다.
- **프레이밍**: `the complete figure including both hands and both feet must be fully inside the frame with generous empty margin on all four sides, nothing touches or is cropped by the image border, the figure occupies only the central 70 percent of the canvas`
  T-포즈는 정사각 프레임에서 팔 스팬이 폭을 초과해 손이 잘린다. 실제로 여백 지시 없이 생성했을 때 오른손이 이미지 끝에 잘렸다.

**함정**: 프롬프트로 `transparent background`를 요구하면 알파 채널이 만들어지는 게 아니라 **투명을 표현하는 체커보드 무늬가 불투명 픽셀로 그려진다.** 눈으로 보면 투명해 보이지만 알파는 전부 255다. 알파가 필요하면 `RemoveImageBackground`를 써야 한다.

## 8. 수치 검증 기준

AGENTS.md §3.2대로 시각 판단을 금지한다. 생성 이미지는 아래를 측정해 판정한다.

| 판정 항목 | 측정 방법 | 합격 기준 |
|---|---|---|
| 투명 배경 여부 | `alpha == 0` 픽셀 비율 | 0%면 알파 없음 = 불합격 |
| 사지 잘림 | 피사체 bbox가 이미지 테두리에 접촉하는지 | 사면 모두 여백 존재 |
| 발 실루엣 보존 | bbox 하단 14% 영역의 최저·평균 휘도 vs 배경 휘도 | 배경 대비 충분한 마진 |

이미지는 `System.IO.File.ReadAllBytes` + `UnityEngine.ImageConversion.LoadImage`로 디코딩해 `GetPixels32()`로 직접 측정한다. 이 경로는 파이프라인의 `GetImageAssetContent` 미지원 제약을 받지 않는다.

메시는 [3d-asset-pipeline.md](3d-asset-pipeline.md)의 검증 절차(Bounds Y-Extent, 하단 절단면, 아티팩트 구워짐)를 따른다.

## 9. 정수 instance id 획득

`referenceImageInstanceId`는 정수를 요구하는데, Unity 6.6에서 `Object.GetInstanceID()`는 deprecated이고 eval은 경고를 에러로 처리하므로 **호출할 수 없다.** `GetEntityId()`는 `"54850:2304"` 형태의 복합 문자열이라 그대로 쓸 수 없다.

**생성 툴 응답의 `FileInstanceID` 값을 사용한다.** 생성이 성공하면 응답 `data`에 `AssetName`, `AssetPath`, `AssetGuid`와 함께 `FileInstanceID`가 정수로 들어 있다. 이 값을 다음 단계의 `referenceImageInstanceId`로 넘긴다.
