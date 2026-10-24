# Slide Auto Clicker

[**Team Human**](https://withteamhuman.com)이 만들고 배포합니다. · Built and released by [**Team Human**](https://withteamhuman.com).

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

1. Setup에서 프리셋(PechaKucha 20×20 / Ignite 20×15 / Custom)과 Advance key·슬라이드 초를 맞춥니다. **시작 전에만** 전체 설정을 합니다.
2. **시작**을 누르면 Setup 창이 숨고 Glass 미니 메뉴(HUD)에 **Play**가 뜹니다. 세션 중 Setup은 자동으로 다시 열리지 않습니다.
3. 발표 앱(Keynote 등)을 앞으로 가져온 뒤 HUD의 **Play**를 눌러 카운트다운을 시작합니다.
4. 실행 중 HUD를 클릭하면 일시정지됩니다. 잠시 커진 미니 메뉴에서 **재개** / **다시 시작**(같은 설정으로 1장부터, Setup은 닫힌 채) / **리셋**(세션 종료 후 Setup으로 복귀)을 고릅니다.
5. 마지막 슬라이드 타이머가 끝나면 화면이 살짝 어두워지며 「발표가 끝났습니다」 카드가 뜹니다. **다시 시작** 또는 **리셋**을 고를 때까지 유지됩니다.
6. 단축키 — ⌘R 시작 대기 · ⌘P Play/일시정지·재개 · ⌘. 리셋(설정으로)

앱 화면 맨 아래에서 **한국어와 English를 전환**할 수 있습니다. 처음 실행할 때는 시스템 언어를 따르고, 한 번 고르면 그 선택을 기억합니다. 설정 창과 HUD가 함께 바뀝니다.

### HUD 위치 옮기기

HUD는 처음에 우하단에 뜨지만 **아무 곳이나 잡아서 끌면 화면 어디로든 옮길 수 있습니다.** 짧게 누르면 클릭(Play·일시정지)이고, 3pt 넘게 끌면 이동입니다. 옮긴 자리는 저장되므로 다음에 시작할 때 그 자리에 다시 뜹니다. 모니터가 여러 대면 화면을 넘나들 수 있고, 화면 밖으로 완전히 나가지는 않습니다.

## 디자인

macOS의 **Liquid Glass**를 그대로 쓰고, 색은 [Team Human](https://withteamhuman.com)의 팔레트를 따릅니다. 강조색은 테라코타 `#C45C26`이고 본문은 `#37210D`, 바탕은 `#F1F1ED`입니다. 라이트와 다크 두 모드에 각각의 값을 두었으므로 시스템 설정을 어느 쪽으로 두든 읽힙니다.

**HUD는 카운트다운 중에는 작게(136×64pt) 유지하고, 일시정지할 때만 세로로 조금 늘어납니다.** 발표 중에는 시야를 가리지 않고, 멈췄을 때만 재개·다시 시작·리셋이 드러납니다. 시간 숫자는 카운트다운과 일시정지에서 같은 자리에 있으므로 멈춰도 읽기가 흔들리지 않습니다.

**카운트다운 중에는 유리가 훨씬 투명해집니다.** 이때 HUD는 남의 슬라이드 위에 얹혀 있으므로 최대한 비켜서야 합니다. 유리판만 흐리게 하고 숫자는 그대로 두었기 때문에, 뒤가 비쳐 보이면서도 시간은 또렷하게 읽힙니다. 눌러야 하는 Play 대기와 일시정지는 반대로 또렷한 유리로 둡니다.

macOS 26 미만에서는 Liquid Glass 대신 같은 모양의 재질(material)로 그립니다.

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
- [ ] 일시정지 시 HUD가 세로로 늘어나고 재개·다시 시작·리셋이 보이는지
- [ ] 다시 시작 시 Setup 없이 1장 Play 대기로 돌아가는지
- [ ] 리셋(⌘. / HUD·종료 카드) 시 Setup으로 돌아오고 설정이 유지되는지
- [ ] 마지막 슬라이드 종료 후 딤+종료 카드가 뜨고, 버튼 전에는 사라지지 않는지
- [ ] 시스템 설정을 라이트·다크로 바꿔가며 글자가 모두 읽히는지
- [ ] 프로필 저장·불러오기

## 만든 팀 — Team Human

이 앱은 [Team Human](https://withteamhuman.com)이 만들고 배포합니다.

Team Human은 **좋은 기술이 공감과 창의성과 사람 사이의 진짜 연결에서 시작한다고 믿는 빌더 커뮤니티**입니다. 2025년 6월부터 해커톤과 밋업을 열어 왔습니다. 가장 최근인 2026년 6월 서울 AI 허브 해커톤에서는 빌더 166명이 하루에 AI 서비스 29개를 만들어 내놓았습니다.

팀이 지키는 것은 넷입니다. 사용자가 아니라 **사람을 먼저 이해하고**(Empathy First), 이상해 보여도 **대담한 아이디어를 응원하며**(Creative Courage), 경쟁보다 **함께 자라고**(Community Over Competition), AI가 무엇이든 만들어 주는 시대일수록 **사람의 손을 거친 것을 귀하게 여깁니다**(Craft Matters).

> **For product makers, by product makers**

### About Team Human

Team Human is a community of builders who believe the best tech starts with empathy, creativity, and real human connection. We have been running hackathons and meetups since June 2025 — most recently at Seoul AI Hub in June 2026, where 166 builders shipped 29 AI services in a single day.

| | |
|---|---|
| 행사 · Events | 8 |
| 하루 만에 제품을 낸 팀 · Teams that shipped in one day | 83 |
| 현장 빌더 · Builders on site | 200+ |
| 우승 15팀에 돌아간 Cursor 크레딧 · Cursor credits to 15 winning teams | $30,000 |

**지난 행사 · Past events**

- Hackathon vol.1 — 2026년 2월, 한국투자액셀러레이터
- Eurekathon vol.2 — 2026년 4월, 강변 스파랜드
- Hackathon vol.3 — 2026년 6월, 서울 AI 허브

**연결되기 · Get in touch**

- 홈페이지 · Website — <https://withteamhuman.com>
- LinkedIn — <https://www.linkedin.com/company/113454183>
- 카카오톡 오픈채팅 · KakaoTalk open chat — <https://open.kakao.com/o/pyheuCui>

## 라이선스 · License

MIT. 자세한 내용은 [LICENSE](LICENSE)를 참고하세요. See [LICENSE](LICENSE) for details.
