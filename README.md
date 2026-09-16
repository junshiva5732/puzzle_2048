# 2048 퍼즐 (puzzle_2048)

클래식 2048 숫자 퍼즐 게임. AdMob 광고(배너 / 전면 / 보상형)로 수익화.
Flutter 로 작성, Android + iOS 대상.

## 구조

```
lib/
  main.dart                    앱 진입, 테마 (세로 고정), 스크린샷용 LOCALE 강제
  l10n/strings.dart            문자열 en/ko/ja (시스템 언어 자동, 미지원 언어는 영어)
  ads/ad_ids.dart              AdMob 광고 단위 ID  ← 출시 전 교체
  ads/ad_manager.dart          전면·보상형 광고 로드/노출 싱글톤
  widgets/banner_ad_widget.dart 하단 적응형 배너
  game/game.dart               순수 게임 로직 (이동/합치기/스폰/되돌리기/이어하기/직렬화)
  services/game_storage.dart   최고 점수·진행 중 게임 저장 (SharedPreferences)
  theme/game_colors.dart       보드·타일 색상 (라이트/다크)
  widgets/board_widget.dart    4x4 보드, AnimatedPositioned 슬라이드
  widgets/tile_widget.dart     타일 등장·합치기 팝 애니메이션
  screens/game_screen.dart     게임 화면 (점수, 되돌리기, 새 게임, 게임오버/승리 오버레이)
test/game_test.dart            게임 로직 유닛 테스트
```

## 광고 노출 지점

| 위치 | 종류 | 동작 |
|---|---|---|
| 화면 하단 | 배너 | 항상 표시 |
| "새 게임" 시작 (게임오버 후 또는 진행 중 재시작) | 전면 | 매번 1회 (`AdManager.interstitialEvery = 1`), 로드 안 됐으면 광고 없이 진행 |
| 게임오버 "광고 보고 이어하기" | 보상형 | 항상 노출. 끝까지 시청 시 가장 작은 타일 4개 제거(`Game.revive`), 점수 유지 |
| 되돌리기 (게임당 3회 무료 소진 후) | 보상형 | 끝까지 시청 시 3회 충전 후 즉시 되돌리기 |

전면 빈도·이어하기 제거 개수는 출시 후 이탈률을 보고 조정. 값은 `ad_manager.dart`, `game.dart` 상수 하나씩.

## 개발 빌드

```bash
flutter pub get
flutter test
flutter build apk --debug
```

에뮬레이터: 이 프로젝트 전용 AVD `Puzzle2048_API_35` (다른 프로젝트 세션과 간섭 방지).
`flutter emulators --launch Puzzle2048_API_35` 후 `flutter run`. 방향키로도 조작 가능.

언어 확인: `flutter run --dart-define=LOCALE=ja` (디버그 전용, ko/en/ja).
스토어 스크린샷: `bash tool/capture_screens.sh <ko|en|ja> [adb serial]` → `python tool/make_store_assets.py`.

## 현지화
시스템 언어를 따라 한국어 / 영어 / 일본어. 그 외 언어는 영어. 앱 이름도 언어별
(`android/app/src/main/res/values*/strings.xml`, iOS 는 기본 "2048 Puzzle").
문자열은 전부 `lib/l10n/strings.dart` 한 파일.

### 이 PC 전용 메모
Java 의 AF_UNIX 소켓이 `%TEMP%` 아래에서 실패해 Gradle 이 "Unable to establish loopback connection" 으로
죽는 문제가 있어, `android/gradle.properties` 와 `android/gradlew.bat` 에
`-Djdk.net.unixdomain.tmpdir=C:/tmp` 를 넣어 두었다. `C:\tmp` 폴더가 있어야 한다.

## 출시 체크리스트

### 1. AdMob
- [x] AdMob Android 앱 "2048 Puzzle" 등록 (App ID `ca-app-pub-7493209423244427~3163274362`, 2026-09-16). 스토어 연결은 Play 게시 후 "앱 스토어 연결"로.
- [x] 광고 단위 3개: 배너 `/4532196356`, 전면 `/9191917089`, 보상형 `/4340624668` (iOS 는 iOS 앱 등록 후 별도)
- [x] `lib/ads/ad_ids.dart` `_androidReal` 실제 ID 반영, `AndroidManifest.xml` APPLICATION_ID 교체 (versionCode 3)
- [ ] `ios/Runner/Info.plist` 의 `GADApplicationIdentifier` 교체
- [ ] 개발 중 실제 ID로 광고 클릭 금지 (계정 정지 사유). 테스트 기기 등록 권장.
- [ ] AdMob 결제 정보 + 세금 정보 입력 (오늘의 운세와 같은 계정이면 이미 완료)

### 2. 개인정보 / 정책
- [x] 개인정보처리방침: https://junshiva5732.github.io/puzzle_2048/privacy-policy.html (원본 `docs/privacy-policy.html`, GitHub Pages `main` / `/docs`)
- [ ] iOS: ATT(앱 추적 투명성) 팝업 — `Info.plist` 에 문구는 넣어둠. 필요 시 `app_tracking_transparency` 패키지로 요청.
- [ ] EU 대상이면 UMP(동의 메시지) 설정 — `google_mobile_ads` 의 `ConsentInformation` API.

### 3. Android 출시
- [x] 릴리즈 서명 키: `android/upload-keystore.jks` + `android/key.properties` (git 제외 — **반드시 백업**, 별칭 `upload`, PKCS12)
- [x] 앱 아이콘: `tool/make_icon.py` → `dart run flutter_launcher_icons`
- [x] `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab` (업로드 키 서명 확인됨)
- [x] Play Console 앱 생성(앱 ID 4972327766453903926), 등록정보 3개 언어, 앱 콘텐츠 선언 10개, 콘텐츠 등급 전체이용가, 테스터 목록 완료
- [x] 내부 테스트 출시 완료 (2026-09-16). 현재 활성 버전 1.0.0 (versionCode 3, 실제 AdMob ID, targetSdk 36). 테스터 참여 링크: https://play.google.com/apps/internaltest/4701527852991593287 (테스터 목록 "Internal testers")
- [x] 비공개 테스트 트랙(Alpha) 생성: 177개국, 버전 3, 2026-09-16 검토 제출. 옵트인 링크·테스터 안내문은 `store/closed-testing.md`
- [ ] 테스터 12명 옵트인 → 14일 유지 → 프로덕션 액세스 신청
- [ ] 비공개 테스트 완료 후 프로덕션 출시 → AdMob "앱 스토어 연결"로 앱 검토 진행
- [x] 스토어 등록 정보: `store/listing.md` — ko/en/ja 설명문(ASO 키워드 반영), 카테고리, 데이터 보안 양식 답변
- [x] 그래픽: `store/icon-512.png`, `store/<ko|en|ja>/feature-graphic.png`, `store/<lang>/screenshots/01~04.png`
- [x] Play Console 기본 언어 en-US + 번역 ko-KR, ja-JP (텍스트만, 그래픽은 en 상속)

### 4. iOS 출시 (Mac 필요)
- [ ] Apple Developer Program 가입 (연 $99)
- [ ] Xcode 에서 Bundle ID / 팀 설정, `pod install`
- [ ] `flutter build ipa` → Transporter 또는 Xcode 로 App Store Connect 업로드
- [ ] 심사 시 광고 사용 여부 "예" 표시

### 5. 출시 후 확장 아이디어
- [ ] 효과음 / 사운드 토글
- [ ] 5x5 · 3x3 보드 크기 선택
- [x] 다국어 (영어·일본어)
