# Claude Code Approval Notifier — 프로젝트 프롬프트

## 배경

나는 Antigravity 프록시를 통해 Claude Code를 사용하고 있고, 동시에 여러 터미널 세션에서 Claude Code를 실행한다.
각 세션에서 tool 사용 승인 요청(파일 편집, Bash 실행 등)이 발생하면, 해당 터미널 창으로 직접 가서 승인해야 한다.
세션이 3~5개 이상이면 어떤 세션에서 승인 대기 중인지 파악하기 어렵고, 전환하는 데 시간이 낭비된다.

## 목표

macOS 환경에서 **모든 Claude Code 세션의 승인 요청을 한 곳에서 확인하고 승인/거부**할 수 있는 도구를 만든다.

## 요구사항

### 핵심 기능
1. 여러 Claude Code 세션의 승인 요청을 **실시간 감지**
2. macOS **Notification 또는 메뉴바**로 승인 요청 알림
3. 알림에서 바로 **Allow / Deny** 가능
4. 승인하면 해당 Claude Code 세션에 **응답이 자동 전달**

### UX 시나리오
```
[터미널 1] Claude Code 세션 A: "Edit main.py" 승인 대기
[터미널 2] Claude Code 세션 B: "Bash: npm install" 승인 대기
[터미널 3] Claude Code 세션 C: 작업 중 (승인 필요 없음)

→ macOS 알림:
  ┌─────────────────────────────────────┐
  │ 🔵 Claude Code — 세션 A             │
  │ Edit: main.py (line 42-55)          │
  │                                     │
  │     [Allow]  [Deny]  [View Detail]  │
  └─────────────────────────────────────┘

→ 또는 메뉴바:
  ⚡ 2  ← 승인 대기 2건
  클릭하면:
  ┌─────────────────────────────────┐
  │ 세션 A: Edit main.py    [✓] [✗]│
  │ 세션 B: Bash npm install [✓] [✗]│
  └─────────────────────────────────┘
```

## 기술 조사 결과

### Claude Code 승인 시스템 구조 (3계층)

| 계층 | 역할 | 파일 |
|------|------|------|
| **Configuration** | 정적 allow/deny 규칙 | `~/.claude/settings.json` |
| **Hook** | 도구 실행 전/후 스크립트 (차단 가능) | hooks.json (`PreToolUse`, `PostToolUse`) |
| **Prompt** | 대화형 사용자 확인 (stdin) | `--permission-prompt-tool stdio` |

### 핵심 발견사항

1. **승인은 stdin으로 처리됨**: `--permission-prompt-tool stdio` 파라미터로 대화형 입력
2. **프로그래밍적 승인 API 없음**: 외부에서 동적으로 승인/거부하는 공식 API 미존재
3. **Hook은 차단만 가능**: `PreToolUse` hook에서 exit code 2로 차단은 되지만, "승인 후 진행"은 불가
4. **Permission mode 옵션 존재**: `default`, `acceptEdits`, `bypassPermissions`, `dontAsk`, `plan`
5. **디버그 로그**: `~/.claude/debug/{session-id}.txt`에 권한 적용 내역 기록

### `--permission-prompt-tool` 파라미터

이것이 핵심 진입점일 수 있다:
- 현재 값: `stdio` (터미널 대화형)
- **커스텀 prompt tool을 지정할 수 있는지 조사 필요**
- 만약 커스텀 도구를 지정할 수 있다면, 승인 요청을 외부 프로세스로 라우팅 가능

## 구현 접근법 후보

### 접근법 A: PTY (Pseudo-Terminal) 래퍼
```
[Claude Code] ←→ [PTY 래퍼] ←→ [실제 터미널]
                    ↓
              승인 요청 감지
                    ↓
            [macOS 알림/메뉴바]
                    ↓
              사용자 응답
                    ↓
            [PTY에 키 입력 전달]
```
- Claude Code를 직접 실행하는 대신, PTY 래퍼를 통해 실행
- 출력을 파싱하여 승인 프롬프트 감지
- 사용자 응답을 stdin으로 주입
- **장점**: Claude Code 수정 불필요
- **단점**: 출력 파싱이 fragile, 터미널 호환성 이슈

### 접근법 B: 커스텀 Permission Prompt Tool
```
claude --permission-prompt-tool /path/to/custom-approver.sh
                    ↓
            [custom-approver.sh]
                    ↓
              승인 요청 → Unix socket/HTTP → [macOS 앱]
                    ↓
              사용자 응답 ← [macOS 앱]
                    ↓
            stdout으로 응답 반환
```
- `--permission-prompt-tool`에 커스텀 스크립트 지정
- 스크립트가 macOS 앱과 통신 (Unix socket 또는 localhost HTTP)
- **장점**: 가장 깔끔한 구조, Claude Code 설계 의도에 부합
- **단점**: `--permission-prompt-tool`의 커스텀 지원 여부 확인 필요

### 접근법 C: Hook + 설정 파일 동적 조작
```
[PreToolUse Hook] → 승인 요청을 파일/소켓으로 전송 → [macOS 앱]
                                                        ↓
                                                   사용자 응답
                                                        ↓
                  settings.json에 allow 규칙 동적 추가 → [다음 실행에 적용]
```
- PreToolUse hook에서 승인 요청 정보를 외부로 전달
- 사용자 승인 시 settings.json의 allow 목록에 규칙 추가
- **장점**: 기존 시스템 활용
- **단점**: 실시간 승인이 아닌 "다음부터 허용" 방식

### 접근법 D: Terminal 키 입력 자동화 (AppleScript/Accessibility)
```
[파일 감시] ~/.claude/debug/*.txt → 승인 요청 감지
                    ↓
            [macOS 알림]
                    ↓
            사용자 Allow 클릭
                    ↓
            [AppleScript] → 해당 터미널 탭에 키 입력 전송
```
- 디버그 로그를 감시하여 승인 대기 상태 감지
- AppleScript로 해당 터미널 창에 키 입력 자동 전송
- **장점**: 구현이 상대적으로 단순
- **단점**: Accessibility 권한 필요, 터미널 앱 의존성

## 우선 조사 사항

1. **`--permission-prompt-tool`의 커스텀 지원 여부**: `stdio` 외에 다른 값(실행 파일 경로 등)을 받을 수 있는지
2. **승인 프롬프트의 정확한 형식**: stdout에 어떤 텍스트가 출력되는지, 어떤 입력을 기대하는지
3. **세션 식별**: 여러 세션을 구분할 수 있는 고유 ID나 메타데이터
4. **Antigravity 프록시와의 호환성**: 프록시 환경에서도 동작하는지

## 기술 스택 (예상)

- **macOS 앱**: Python + rumps (메뉴바) 또는 Swift/SwiftUI
- **통신**: Unix domain socket 또는 localhost HTTP (Flask/FastAPI)
- **프로세스 관리**: launchd (자동 시작)
- **알림**: macOS UserNotifications framework (또는 rumps.notification)

## 성공 기준

- [ ] Claude Code 세션 3개 이상 동시 실행 시, 모든 승인 요청이 한 곳에 모임
- [ ] 알림에서 1클릭으로 승인/거부 가능
- [ ] 승인 후 해당 세션이 즉시 진행됨
- [ ] 응답 지연 2초 이내
- [ ] 기존 Claude Code 사용 방식(터미널에서 직접 승인)과 공존 가능
