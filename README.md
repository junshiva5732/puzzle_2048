# 2048 퍼즐 (puzzle_2048)

클래식 2048 숫자 퍼즐 게임. AdMob 광고(배너 / 전면 / 보상형)로 수익화.
Flutter 로 작성, Android + iOS 대상.

## 구조

```
lib/
  main.dart                    앱 진입, 테마 (세로 고정)
  ads/ad_ids.dart              AdMob 광고 단위 ID  ← 출시 전 교체
  ads/ad_manager.dart          전면·보상형 광고 로드/노출 싱글톤
  widgets/banner_ad_widget.dart 하단 적응형 배너
  game/game.dart               순수 게임 로직 (이동/합치기/스폰/되돌리기/직렬화)
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
| "새 게임" 시작 | 전면 | 2번 시작마다 1회 (`AdManager.interstitialEvery`), 로드 안 됐으면 광고 없이 진행 |
| 되돌리기 (게임당 3회 무료 소진 후) | 보상형 | 끝까지 시청 시 3회 충전 후 즉시 되돌리기. 게임오버 화면에서도 동일 |

## 개발 빌드

```bash
flutter pub get
flutter test
flutter build apk --debug
```

에뮬레이터: `flutter emulators --launch Small_Phone_API_35` 후 `flutter run`.
에뮬레이터/데스크톱에서는 방향키로도 조작 가능.

### 이 PC 전용 메모
Java 의 AF_UNIX 소켓이 `%TEMP%` 아래에서 실패해 Gradle 이 "Unable to establish loopback connection" 으로
죽는 문제가 있어, `android/gradle.properties` 와 `android/gradlew.bat` 에
`-Djdk.net.unixdomain.tmpdir=C:/tmp` 를 넣어 두었다. `C:\tmp` 폴더가 있어야 한다.

## 출시 체크리스트

### 1. AdMob
- [ ] https://admob.google.com 에서 앱 등록 (Android, iOS 각각) — 앱 이름 "2048 퍼즐", 패키지 `com.jun5731.puzzle_2048`
- [ ] 광고 단위 3개 생성: 배너 / 전면 / 보상형 (플랫폼별 → 총 6개)
- [ ] `lib/ads/ad_ids.dart` 의 `_androidReal` 을 실제 ID 로 교체 (지금은 테스트 ID 를 가리킴)
- [ ] `android/app/src/main/AndroidManifest.xml` 의 `APPLICATION_ID` 교체 (지금은 Google 샘플 App ID)
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
- [ ] Play Console 에 앱 생성 → 내부 테스트 트랙에 `.aab` 업로드
- [x] 스토어 등록 정보 초안: `store/listing.md` (설명문, 카테고리, 데이터 보안 양식 답변)
- [x] 그래픽: `store/icon-512.png`, `store/feature-graphic.png`, `store/screenshots/01~04.png` (`tool/make_store_assets.py`)

### 4. iOS 출시 (Mac 필요)
- [ ] Apple Developer Program 가입 (연 $99)
- [ ] Xcode 에서 Bundle ID / 팀 설정, `pod install`
- [ ] `flutter build ipa` → Transporter 또는 Xcode 로 App Store Connect 업로드
- [ ] 심사 시 광고 사용 여부 "예" 표시

### 5. 출시 후 확장 아이디어
- [ ] 효과음 / 사운드 토글
- [ ] 5x5 · 3x3 보드 크기 선택
- [ ] 다국어 (영어)
