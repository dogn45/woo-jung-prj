# 두 사람 협업 안내

## 동근님: visuals/만 편집

- visuals/customer/CustomerVisual.tscn: 손님 외형, 재질, AnimationPlayer의 idle/walk/run 모션
- visuals/customer/face.png: 얼굴 사진, 동일 이름으로 교체 가능
- visuals/player/PlayerBody.tscn: 플레이어 몸과 다리
- visuals/player/LeftHand.tscn, RightHand.tscn: 양손과 손가락
- visuals/player/Skin.tres, Sleeve.tres: 팔 피부와 옷 재질
- visuals/player/UpperArmMesh.tres, ForeArmMesh.tres: 팔 형태
- visuals/player/MovementTuning.tres: 걷기/달리기 속도, FOV, 보폭 주기, 다리 흔들림, 시점 흔들림
- visuals/environment/EnvironmentVisual.tscn: 매장/계산대 외형, 바깥 건물, 산, 나무, 보도. Godot 3D 편집기에서 수정

씬을 더블클릭해 Godot에서 수정하고 Ctrl+S. .gd 코드를 수정할 필요가 없습니다
비주얼 씬 역시 .tscn 형식이므로 확장자가 아니라 폴더로 담당을 구분합니다
현재 플레이어 움직임은 절차적 방식이고 MovementTuning으로 조절합니다. 정교한 리깅 GLB로 교체하려면 어댑터 작업이 필요합니다

## 친구: gameplay/와 scripts/의 행동/시스템 코드

- gameplay/customer/Customer.tscn: 손님 행동 씬, Visual 연결, 이벤트 노드 추가
- gameplay/customer/customer.gd: 등장/이동/대기/결제/퇴장, 경로, 이벤트
- scripts/game.gd: 상호작용, UI, 업무 및 이벤트 연동
- scripts/player.gd: 플레이어 이동과 손 조작 시스템
- scripts/world_builder.gd: 상호작용 물체와 문/조명 생성
- main.tscn: 게임 시작 씬

새 이벤트는 gameplay/events/에 .tscn/.gd로 추가하고 gameplay/customer에서 연결하세요
visuals/ 내부를 변경하지 마세요. 애니메이션은 customer.set_motion("idle"/"walk"/"run")으로 요청합니다

## 유지할 연결 규칙

Customer.tscn의 Visual 노드명 유지
CustomerVisual의 CustomerFace, LeftLeg, RightLeg, Carry, AnimationPlayer 노드명 유지
앞 방향 -Z, 발바닥 Y=0, 단위 미터 유지
AnimationPlayer의 idle/walk/run 이름 유지
PlayerBody의 LeftLeg/RightLeg 이름 유지
씬이나 모델 구조를 바꾸려면 양쪽이 연결 규칙을 함께 갱신해야 합니다

## 맵을 변경할 때

배경 씬에는 정적 충돌도 포함됩니다. 벽/계산대 이동 시 해당 StaticBody3D 부모를 함께 옮기세요
POS, 스캐너, 문, 진열 칸 등 기능성 물체는 scripts/world_builder.gd가 위치를 결정합니다
계산대 외형을 옮기면 친구에게 알려 기능성 기기 위치와 손님 경로도 함께 옮기세요
환경 씬에 POS/문을 새로 장식용으로 복제해도 기능은 자동으로 생기지 않습니다
기존 scenes/store_editable.tscn은 구버전이며 사용하지 않습니다

## GitHub 흐름

동근님은 visual 브랜치, 친구는 events 브랜치에서 작업
시작 전에 main의 최신 변경 받기. 작업 후 실행 확인, Commit, Push
Pull Request로 서로 확인하고 main에 합치기
.godot/은 자동 생성 캐시라 올리지 않습니다
GitHub 설정/브랜치 생성은 아직 수행하지 않았습니다
