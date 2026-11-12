# Competition Service

경진대회 플랫폼을 위한 백엔드 마이크로서비스입니다. Spring Boot 기반으로 REST API를 제공하며, Azure Container Apps에 배포됩니다.

## 기술 스택

| 구성요소 | 기술 |
|----------|------|
| 언어 | Kotlin 2.2.0 |
| JDK | Java 21 |
| 프레임워크 | Spring Boot 3.5.6 |
| 빌드 도구 | Gradle 8.14.3 |
| 데이터베이스 | PostgreSQL |
| ORM | Spring Data JPA + QueryDSL 6.11 |
| API 문서 | SpringDoc OpenAPI (Swagger) |
| 모니터링 | Azure Application Insights |
| CI/CD | GitHub Actions |
| 배포 | Azure Container Apps |

## 프로젝트 구조

```
src/main/kotlin/com/aifactory/competition/
├── CompetitionApplication.kt         # 메인 애플리케이션
├── config/
│   ├── SecurityConfig.kt             # Spring Security 설정
│   ├── SwaggerConfig.kt              # OpenAPI/Swagger 설정
│   └── QueryDslConfig.kt             # QueryDSL 설정
└── controller/
    └── TestController.kt             # 테스트 엔드포인트
```

## 시작하기

### 사전 요구사항

- Java 21+
- PostgreSQL
- Gradle 8.14+

### 환경변수

| 변수명 | 설명 | 필수 |
|--------|------|------|
| `SPRING_PROFILES_ACTIVE` | 활성 프로필 (`local`, `dev`, `prod`) | X (기본: local) |
| `DB_URL` | 데이터베이스 JDBC URL | O |
| `DB_USERNAME` | 데이터베이스 사용자명 | O |
| `DB_PASSWORD` | 데이터베이스 비밀번호 | O |
| `AZURE_MONITOR_CONNECTION_STRING` | Application Insights 연결 문자열 | X |
| `SERVER_PORT` | 서버 포트 | X (기본: 8080) |

### 로컬 실행

```bash
./gradlew bootRun --args='--spring.profiles.active=local'
# 포트 8082에서 실행
```

### 빌드

```bash
./gradlew bootJar    # JAR 빌드
./gradlew build      # 전체 빌드
./gradlew test       # 테스트 실행
```

### Docker

```bash
docker build -t competition:latest .
docker run -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e DB_URL="jdbc:postgresql://..." \
  -e DB_USERNAME="user" \
  -e DB_PASSWORD="pass" \
  competition:latest
```

## API 문서

Swagger UI를 통해 API 문서를 확인할 수 있습니다.

| 환경 | URL |
|------|-----|
| 로컬 | `http://localhost:8082/swagger-ui.html` |
| API Docs | `/api-docs` |

## 프로필별 설정

| 프로필 | 포트 | 용도 |
|--------|------|------|
| `local` | 8082 | 로컬 개발 |
| `prod` | 8080 | 운영 환경 |

- **로컬/개발**: 콘솔 텍스트 로깅, SQL DEBUG 로깅 활성화
- **운영**: JSON 포맷 로깅 (Logstash Encoder), 비동기 로깅

## Kubernetes / Azure 배포

**Azure Container Apps**에 배포되며, 주요 구성:

- **컨테이너 레지스트리**: Azure Container Registry (aifprodacr)
- **베이스 이미지**: eclipse-temurin:21-jre-alpine
- **Non-root 사용자** 실행 (appuser, UID 1001)
- **JVM 최적화**: G1GC, 문자열 중복 제거, 컨테이너 지원
- **헬스체크**: `/actuator/health`

## CI/CD

GitHub Actions 워크플로우 (`.github/workflows/deploy.yml`)가 `main` 브랜치 푸시 시 실행:

1. Gradle로 JAR 빌드
2. Docker 이미지 빌드 후 Azure Container Registry에 푸시
3. Azure Container Apps 업데이트
4. 레지스트리 정리 (최신 10개 이미지만 유지)

## 보안 설정

- **CORS**: localhost, auth-prod, gateway-prod 허용
- **CSRF**: 비활성화 (API 중심)
- **인증**: Spring Security 기반 (현재 모든 요청 허용)
