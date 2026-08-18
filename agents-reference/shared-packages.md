---
id: unity-ai-agent-instructions-shared-packages
title: 공유 패키지 재사용
version: 1
parent: 상위 지침 문서 (5의 분리본)
---

# 공유 패키지 재사용

**로드 조건**: 새로운 공용 시스템(파티클 이펙트, 프리팹, 공용 스크립트 등)이 필요한 작업을 시작하기 전에 이 문서를 읽는다. 이미 프로젝트에 설치된 패키지를 그대로 쓰는 작업(예: 기존 컴포넌트를 GameObject에 추가하고 파라미터만 조정)에는 이 문서가 필요 없다 — `Packages/manifest.json`과 해당 패키지의 `README.md`만 확인하면 충분하다.

이 문서는 상위 지침 문서(프로젝트 루트: `AGENTS.md`/`CLAUDE.md`, .unity-kb 원본: `HARNESS.md`) §1~4의 행동 규칙 아래에서 적용되는 도메인 절차다. 충돌 시 그 문서(§0~4)가 우선한다.

(배경/취지/전체 구조는 `packages/ARCHITECTURE.md`, 로컬 사본은 `D:\UnityCustomPackage\ARCHITECTURE.md` 참고)

아래 "알려진 공유 패키지" 목록을 확인한다. 이미 있는 패키지로 요구사항을 충족할 수 있으면 새로 만들지 말고, 해당 프로젝트의 `Packages/manifest.json`에 git URL로 추가해서 사용한다. 목록에 없는 새 공용 시스템을 패키지로 만들지 여부는 사용자가 직접 지시하거나 승인한 경우에만 진행한다 — 이 판단은 AI가 임의로 하지 않는다. 사용자 승인을 받아 패키지를 만들고 GitHub push까지 마쳤다면, 그 결과를 이 목록(및 `D:\UnityCustomPackage\ARCHITECTURE.md`, `unity-ai-instructions` 저장소의 이 템플릿)에 등록하는 것은 AI가 직접 해도 된다 — 이미 승인된 결정을 표에 반영하는 기계적 작업이기 때문이다.

**알려진 공유 패키지**

| 패키지 | 저장소 | 설명 |
|---|---|---|
| com.custom.snowglobe | `https://github.com/supervanz/com.custom.snowglobe.git` | GPU 기반 SPH 유체 파티클 시뮬레이션, 모바일 터치/자이로 흔들기 인터랙션. 유리구/밀폐 용기 안 파티클 연출에 사용 |
| com.custom.planar-reflection | `https://github.com/supervanz/com.custom.planar-reflection.git` | 평면 반사(planar reflection) 컴포넌트, URP 평면 반사 셰이더, 샘플 머티리얼. 바닥/거울면 반사 연출에 사용 |
| com.custom.volumetricfog | `https://github.com/supervanz/com.custom.volumetricfog.git` | URP Render Graph 기반 볼류메트릭 안개 이펙트 |
| com.generic.crowd | `https://github.com/supervanz/com.generic.crowd.git` | NavMeshAgent 기반 경량 NPC 배회/모션 오버라이드 시스템. 군중/배경 캐릭터 연출에 사용 |
