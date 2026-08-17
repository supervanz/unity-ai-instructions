---
id: unity-ai-agent-instructions-3d-asset-pipeline
title: 3D 에셋 생성 검증 절차
version: 2
parent: AGENTS.md (2.4의 분리본)
---

# 3D 에셋 생성 검증 절차

**로드 조건**: 3D 모델을 새로 생성하거나 씬에 배치하는 작업일 때만 이 문서를 읽는다. 프리미티브(Cube/Plane 등)만으로 구조/건축 요소를 배치하는 작업, 또는 이미 있는 에셋/패키지를 붙이는 작업에는 이 문서가 필요 없다.

이 문서는 [AGENTS.md](../AGENTS.md) §1~4의 행동 규칙 아래에서 적용되는 도메인 절차다. 충돌 시 AGENTS.md가 우선한다.

**v2 변경**: §0(도구 및 파이프라인 수단 구분)을 추가했다. `Unity.GenerateSceneCodeFromImage`가 `unity command` CLI가 아닌 어시스턴트 도구 체계에 속한다는 점, 그리고 Texture2D 에셋 컨텍스트 경유 호출이 실패한다는 점을 구분하지 못해 생성과 조립을 섞어 시도하는 사례가 있었다.

## 0. 도구 및 파이프라인 수단 구분 (필수)
- **AI 어시스턴트 도구**: `Unity.GenerateSceneCodeFromImage`는 `unity command` CLI 명령어가 아닌 어시스턴트 도구 체계에 속함.
  - 채팅 메시지에 이미지 파일이 직접 첨부된 경우: `Unity.GenerateSceneCodeFromImage()`로 직접 Three.js 코드 도출 가능.
  - Project 패널의 Texture2D 에셋 컨텍스트(`instance_id`)를 통한 호출: 현재 에디터 파이프라인의 `GetImageAssetContent` API 미지원으로 텍스처 데이터 인출 시 실패함.
- **대응 절차**:
  - Texture2D 에셋 기반 작업 시 생성(`GenerateAssetTool.GenerateAsset`)과 조립(`unity command` / C# RunCommand)을 분리 수행.
  - 이미지 파일 직접 첨부 시 `Unity.GenerateSceneCodeFromImage()` 사용 가능.

## 적용 대상 판단 (프리미티브 vs 3D 생성 모델)
- 구조/건축 요소(마루, 천장, 벽, 기둥 등 평면·직육면체·단순 형태로 근사 가능한 오브젝트)는 프리미티브(Cube, Plane, Cylinder 등)로 배치 가능.
- 유기적 형태/캐릭터/장식 조형물(나무, 사람, 동물, 조각상 등 프리미티브 조합으로 실루엣·디테일을 원본 의도대로 표현할 수 없는 오브젝트)는 반드시 3D 생성 모델(파이프라인 절)을 거쳐야 함. 프리미티브 조합으로 임의 대체 금지.
- 판단 기준: 해당 오브젝트의 실루엣/디테일을 프리미티브 조합으로 원본 의도 훼손 없이 표현 가능한지 여부. 애매한 경우 진행 전 사용자에게 확인.
- 이 기준을 우회할 목적으로 프리미티브로 먼저 배치한 뒤 "임시"임을 밝히지 않고 완성된 결과물처럼 보고하는 행위는 AGENTS.md §1.2(임의 대체 금지) 위반으로 간주.

## 원칙
- 복잡한 원본 이미지에서 대상을 직접 크롭하여 3D 입력값으로 사용 금지(경계면 잡영, 하반신 누락, 부유물 구워짐 유발).
- 전신 형태 완전성 제약: Full body, head-to-toe, standing pose, complete legs and feet, isolated transparent background 명시.
- 상반신만 생성되거나 하반신 누락 시 품질 미달로 판정, 씬 배치 중단.

## 파이프라인
0. 입력 이미지 사전 판단: 레퍼런스 이미지가 이미 배경과 분리된 단일 피사체의 깨끗한 전신 이미지라면 1~2단계를 건너뛰고 3단계로 직행. 배경과 인물이 겹쳐 있거나 뒤섞인 복합 이미지일 때만 1~2단계 필수.
1. 대상 분석 및 프롬프트화: 성별, 의상, 외형, 색상 스타일 추출. 배경/장식물/무관 요소 제외.
2. 투명 배경 2D 전신 이미지 생성: Full body portrait, head to toe, front view, standing pose, clean isolated transparent background, game asset style. 절단 없이 온전한지 확인.
3. Image-to-3D Mesh 변환: (0단계에서 재사용 판정된 이미지 또는 2단계 결과물을) 레퍼런스로 Image-to-3D 실행(waitForCompletion=true).
4. 메시 품질 검증(배치 전 필수):
   - 사지 누락 여부(Bounds Y-Extent, 하단 절단면 확인)
   - 아티팩트 합성 여부(배경/장식물 구워짐 확인)
   - 접지 및 포즈 상태(발끝 정방향 지면 배치 가능 여부)

## 씬 배치 후 검증
- 결과물이 벽/다른 오브젝트에 가려지지 않고 명확히 보이는 각도를 최소 1개 이상 찾아 스크린샷 캡처 후 검증.
- 정면/측면/조감도는 참고용 기본값일 뿐 고정 필수값이 아님 — 씬 구조상 특정 각도가 가려진다면 생략하고, 결과를 실제로 판별 가능한 각도를 우선.
- 검증 목적은 "여러 각도를 찍었는가"가 아니라 "찍은 스크린샷으로 결과물의 정상 여부를 실제로 판단할 수 있는가"임.
