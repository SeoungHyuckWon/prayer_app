# 감사와 기도제목 앱 개발 계획

## 📱 앱 개요
감사와 기도제목을 작성하고 관리할 수 있는 Flutter 앱입니다. Firebase Firestore를 데이터베이스로 사용하여 데이터를 클라우드에 저장합니다.

## 🎯 주요 기능

### 1. 감사 작성 및 관리
- 감사 제목과 내용 작성
- 감사 목록 조회 (최신순/오래된순 정렬)
- 감사 수정 및 삭제
- 감사 검색 기능
- 날짜별 필터링

### 2. 기도제목 작성 및 관리
- 기도제목 작성
- 기도제목 목록 조회
- 기도제목 수정 및 삭제
- 기도제목 상태 관리 (진행중/응답받음/보류)
- 기도제목 검색 기능
- 날짜별 필터링

### 3. 통계 및 인사이트
- 작성한 감사 개수 통계
- 기도제목 상태별 통계
- 월별/주별 작성 현황

## 📊 데이터 모델

### 감사 (Gratitude)
```dart
{
  id: String (자동 생성)
  title: String (제목)
  content: String (내용)
  createdAt: Timestamp (작성일시)
  updatedAt: Timestamp (수정일시)
  userId: String (사용자 ID - 추후 인증 추가 시)
}
```

### 기도제목 (Prayer)
```dart
{
  id: String (자동 생성)
  title: String (제목)
  content: String (내용)
  status: String (진행중/응답받음/보류)
  createdAt: Timestamp (작성일시)
  updatedAt: Timestamp (수정일시)
  answeredAt: Timestamp? (응답받은 날짜 - nullable)
  userId: String (사용자 ID - 추후 인증 추가 시)
}
```

## 🏗️ 앱 구조

### 화면 구성
1. **홈 화면 (HomeScreen)**
   - 감사와 기도제목을 탭으로 구분
   - 최근 작성한 항목 미리보기
   - 빠른 작성 버튼

2. **감사 목록 화면 (GratitudeListScreen)**
   - 감사 목록 표시
   - 검색 및 필터 기능
   - 새 감사 작성 버튼

3. **감사 작성/수정 화면 (GratitudeFormScreen)**
   - 제목 및 내용 입력 폼
   - 저장 및 취소 버튼

4. **기도제목 목록 화면 (PrayerListScreen)**
   - 기도제목 목록 표시
   - 상태별 필터링
   - 검색 기능
   - 새 기도제목 작성 버튼

5. **기도제목 작성/수정 화면 (PrayerFormScreen)**
   - 제목, 내용, 상태 입력 폼
   - 저장 및 취소 버튼

6. **통계 화면 (StatisticsScreen)** (선택사항)
   - 작성 통계 표시
   - 차트 및 그래프

## 🔧 기술 스택

### 필수 패키지
- `firebase_core`: Firebase 초기화
- `cloud_firestore`: Firestore 데이터베이스
- `flutter/material`: UI 구성
- `intl`: 날짜 포맷팅

### 추가 고려 패키지
- `provider` 또는 `riverpod`: 상태 관리
- `flutter_slidable`: 스와이프 삭제 기능
- `flutter_staggered_grid_view`: 그리드 레이아웃
- `charts_flutter`: 통계 차트 (통계 화면 사용 시)

## 📁 프로젝트 구조

```
lib/
├── main.dart
├── models/
│   ├── gratitude.dart
│   └── prayer.dart
├── screens/
│   ├── home_screen.dart
│   ├── gratitude_list_screen.dart
│   ├── gratitude_form_screen.dart
│   ├── prayer_list_screen.dart
│   ├── prayer_form_screen.dart
│   └── statistics_screen.dart
├── services/
│   └── firestore_service.dart
├── widgets/
│   ├── gratitude_card.dart
│   ├── prayer_card.dart
│   └── empty_state.dart
└── utils/
    ├── date_formatter.dart
    └── constants.dart
```

## 🚀 구현 단계

### Phase 1: 기본 설정
1. ✅ Firebase 프로젝트 생성 및 설정
2. ✅ Firebase 패키지 추가 및 초기화
3. ✅ 프로젝트 폴더 구조 생성
4. ✅ 기본 테마 및 상수 설정

### Phase 2: 데이터 모델 및 서비스
1. ✅ Gratitude 모델 클래스 작성
2. ✅ Prayer 모델 클래스 작성
3. ✅ FirestoreService 클래스 작성 (CRUD 작업)

### Phase 3: 감사 기능
1. ✅ 감사 목록 화면 구현
2. ✅ 감사 작성/수정 화면 구현
3. ✅ 감사 카드 위젯 구현
4. ✅ 감사 검색 및 필터 기능

### Phase 4: 기도제목 기능
1. ✅ 기도제목 목록 화면 구현
2. ✅ 기도제목 작성/수정 화면 구현
3. ✅ 기도제목 카드 위젯 구현
4. ✅ 기도제목 상태 관리 기능
5. ✅ 기도제목 검색 및 필터 기능

### Phase 5: UI/UX 개선
1. ✅ 홈 화면 구현
2. ✅ 빈 상태 위젯 구현
3. ✅ 로딩 상태 처리
4. ✅ 에러 처리 및 사용자 피드백
5. ✅ 애니메이션 및 전환 효과

### Phase 6: 추가 기능 (선택)
1. ⬜ 통계 화면 구현
2. ⬜ 데이터 내보내기 기능
3. ⬜ 다크 모드 지원
4. ⬜ 알림 기능

## 🔐 Firebase 설정

### Firestore 보안 규칙 (초기)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 감사 컬렉션
    match /gratitudes/{gratitudeId} {
      allow read, write: if true; // 개발 단계 - 추후 인증 추가
    }
    
    // 기도제목 컬렉션
    match /prayers/{prayerId} {
      allow read, write: if true; // 개발 단계 - 추후 인증 추가
    }
  }
}
```

### Firestore 컬렉션 구조
- `gratitudes`: 감사 문서들
- `prayers`: 기도제목 문서들

## 🎨 UI/UX 디자인 원칙

1. **심플하고 깔끔한 디자인**
   - 불필요한 요소 제거
   - 명확한 정보 계층 구조

2. **직관적인 네비게이션**
   - 하단 네비게이션 바 또는 탭 사용
   - 명확한 액션 버튼

3. **감성적인 디자인**
   - 따뜻한 색상 팔레트
   - 부드러운 애니메이션

4. **접근성 고려**
   - 적절한 폰트 크기
   - 명확한 터치 영역

## 📝 다음 단계

1. Firebase 프로젝트 생성 및 설정 파일 추가
2. 필요한 패키지 설치
3. 기본 프로젝트 구조 생성
4. 데이터 모델 및 서비스 레이어 구현
5. UI 화면 구현 시작

---

**참고사항**
- 초기 버전은 인증 없이 구현 (추후 Firebase Authentication 추가 가능)
- 오프라인 지원은 Firestore의 자동 캐싱 기능 활용
- 데이터 백업을 위해 주기적으로 내보내기 기능 고려



