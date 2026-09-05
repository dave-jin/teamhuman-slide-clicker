# Slide Auto Clicker

페차쿠차 / 이그나이트용 macOS 슬라이드 자동 넘김 앱.

슬라이드별 초를 설정한 뒤 **시작**하면 Glass HUD가 뜨고, 시간이 끝날 때마다 Space(또는 선택한 키)를 보냅니다. 발표자는 넘기는 타이밍을 신경 쓰지 않고 말하는 데만 집중하면 됩니다.

## 요구 사항

- macOS 13 이상
- 손쉬운 사용(Accessibility) 권한

## 빌드·실행

```bash
git clone https://github.com/dave-jin/slide-auto-clicker.git
cd slide-auto-clicker
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open "dist/Auto Clicker.app"
```

빌드 스크립트는 ad-hoc 서명만 하므로, 처음 열 때 Gatekeeper 경고가 뜨면 **우클릭 → 열기**로 실행합니다.

개발 중 빠른 실행:

```bash
swift run
```

## 사용법

1. 프리셋(PechaKucha 20×20 / Ignite 20×15 / Custom)을 고르거나 슬라이드별 초를 직접 편집합니다.
2. Advance key를 고릅니다 (Space / → / Page Down).
3. 하단의 **시작**을 누르면 Setup 창이 숨고 HUD에 **Play**가 뜹니다.
4. 발표 앱(Keynote 등)을 앞으로 가져온 뒤 HUD의 **Play**를 눌러 카운트다운을 시작합니다.
5. 실행 중에 HUD를 클릭하면 일시정지되고, **재개**와 **정지(메뉴로)**를 고를 수 있습니다.
6. 단축키 — ⌘R 시작 대기 · ⌘P Play/일시정지·재개 · ⌘. 정지

### HUD 위치 옮기기

HUD는 처음에 우하단에 뜨지만 **아무 곳이나 잡아서 끌면 화면 어디로든 옮길 수 있습니다.** 짧게 누르면 클릭(Play·일시정지)이고, 3pt 넘게 끌면 이동입니다. 옮긴 자리는 저장되므로 다음에 시작할 때 그 자리에 다시 뜹니다. 모니터가 여러 대면 화면을 넘나들 수 있고, 화면 밖으로 완전히 나가지는 않습니다.

## 권한 (중요: 비슷한 이름의 화면이 두 개입니다)

잘못된 곳: 시스템 설정 → **손쉬운 사용** (자막·실시간 말하기 등 기능 목록)

올바른 곳:

1. 시스템 설정
2. **개인정보 보호 및 보안** (왼쪽, 파란 손 아이콘)
3. **손쉬운 사용**
4. 목록에서 **Auto Clicker** 토글 ON
   (없으면 `+`로 `Auto Clicker.app` 추가)
5. 앱 재실행

앱의 **개인정보 보호 설정 열기** 버튼을 누르면 위 화면으로 바로 갑니다.

## QA 체크리스트

- [ ] Custom 프리셋(10장)으로 시작 → HUD 표시, Setup 창 숨김
- [ ] TextEdit을 앞에 두고 Space가 간격마다 입력되는지 확인
- [ ] Keynote 발표자 보기·전체화면 위에 HUD가 보이는지
- [ ] HUD를 드래그해 옮긴 뒤 재시작하면 그 자리에 뜨는지
- [ ] 드래그한 뒤 손을 떼도 Play·일시정지가 잘못 눌리지 않는지
- [ ] 일시정지(⌘P / HUD 클릭) 후 재개하면 남은 초부터 이어지는지
- [ ] 정지(⌘. / HUD의 정지) 시 Setup으로 돌아오는지
- [ ] 프로필 저장·불러오기

## 라이선스

MIT. 자세한 내용은 [LICENSE](LICENSE)를 참고하세요.
