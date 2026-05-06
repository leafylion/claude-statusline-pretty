# claude-statusline-pretty

[Claude Code](https://claude.com/claude-code)용 2줄 상태표시줄 플러그인 — 모델별 누적 비용 추적 기능 포함.

🌐 [English](README.md) · 한국어

## 미리보기

```
Sonnet 4.6 · "Customize statusline icons" · › myproject · ⎇ main
effort:high · context 4% · cache 99% · 6m 56s · Sonnet $0.47 · Opus $0.12 · $0.59 total
```

**1줄** — 모델 · 세션명 · 디렉터리 · git 브랜치
**2줄** — effort 단계 · 컨텍스트 % · 캐시 적중률 · 세션 진행시간 · 모델별 비용 · 총합

## 주요 기능

- **컨텍스트 % 색상 변화** — 사용량이 늘어날수록 색이 점점 강해짐 (테마 4종 내장)
- **모델별 비용 추적** — 세션 중간에 모델을 바꿔도 Sonnet/Opus 각각의 사용 금액을 따로 집계
- **세션 간 누적** — `~/.claude/cost-tracker/<session_id>.json` 단위로 저장, 동시에 여러 창을 열어도 충돌 없음
- **크로스 플랫폼** — Windows는 PowerShell, macOS/Linux는 Bash + jq

## 설치

### 사전 요구사항

- **Windows:** PowerShell 5.1+ (기본 내장)
- **macOS:** `jq` — `brew install jq`
- **Linux:** `jq` — `sudo apt install jq` (Debian/Ubuntu) 또는 `sudo dnf install jq` (Fedora)

### 설치 절차

```text
/plugin marketplace add leafylion/claude-statusline-pretty
/plugin install claude-statusline-pretty
/install-statusline
```

설치 후 **Claude Code를 재시작**하세요. `settings.json`은 시작 시점에 한 번 읽기 때문에, 재시작이 있어야 새 상태표시줄이 적용됩니다.

`/install-statusline` 실행 시 색상 테마와 기호 스타일을 물어봅니다. 그냥 기본값을 원하면 "기본"이라고 답하면 됩니다.

### 설치 스크립트가 하는 일

`/install-statusline`은 `bin/install.ps1` (Windows) 또는 `bin/install.sh` (Unix)을 실행합니다. 이 스크립트는:

1. 플랫폼에 맞는 `statusline.{ps1,sh}`를 `~/.claude/`로 복사 (Unix는 `chmod +x`까지)
2. 사용자가 선택한 테마/스타일을 복사된 스크립트 상단의 변수에 적용
3. `~/.claude/settings.json`을 읽어 `statusLine` 키만 추가/교체 (다른 키는 그대로 유지)
4. 파일이 없으면 새로 만들고, JSON이 깨져 있으면 덮어쓰지 않고 중단

### 수동 설치

플러그인 시스템을 안 쓰고 싶으면 저장소를 클론한 뒤 직접 실행:

```bash
# macOS / Linux
./bin/install.sh

# Windows (PowerShell)
.\bin\install.ps1
```

## 테마 & 기호 스타일

설치 시점에 선택할 수 있고, 나중에 설치 스크립트를 다시 돌리거나 `~/.claude/statusline.{ps1,sh}` 상단의 변수를 직접 고쳐도 됩니다.

**색상 테마** (컨텍스트 % 표시 색상의 그라데이션):

| 테마          | 낮음 (OK)    | 중간 (warn)  | 높음 (>80%)   |
|---------------|--------------|--------------|----------------|
| `current`     | 밝은 골드    | 오렌지       | 코랄 레드      |
| `cool-pastel` | 은은한 청록  | 피치         | 더스티 로즈    | *(기본값)*
| `earthy`      | 탠           | 테라코타     | 로즈 레드      |
| `neutral`     | 라이트 그레이| 피치         | 코랄           |

**기호 스타일** (디렉터리 · 브랜치 · 구분자 글리프):

| 스타일    | 디렉터리 | 브랜치 | 구분자 | 분위기                     |
|-----------|----------|--------|--------|-----------------------------|
| `minimal` | `›`      | `⎇`    | `·`    | 기본값, 깔끔한 느낌         |
| `sharp`   | `❯`      | `⊢`    | `│`    | 세로 구분선, 개발도구 느낌  |
| `soft`    | `»`      | `↳`    | `•`    | 둥근 모양 위주              |

설치 스크립트에 옵션으로 넘기기:

```bash
# Unix
./bin/install.sh --theme cool-pastel --style minimal

# Windows
.\bin\install.ps1 -Theme cool-pastel -Style minimal
```

스킬을 통한 설치(`/install-statusline`)에서는 대화형으로 물어봅니다.

## 파일 구조

```
.claude-plugin/plugin.json       # 플러그인 매니페스트
bin/install.ps1                  # Windows 설치 스크립트
bin/install.sh                   # macOS / Linux 설치 스크립트
scripts/statusline.ps1           # Windows 상태표시줄
scripts/statusline.sh            # macOS / Linux 상태표시줄
skills/install-statusline/       # /install-statusline 스킬
```

설치 후 첫 실행 시점에 `~/.claude/cost-tracker/` 디렉터리가 자동으로 생성됩니다 (세션별 비용 데이터가 여기 저장됨).

## 제거

`~/.claude/settings.json`에서 `statusLine` 키를 지우고, `~/.claude/statusline.{ps1,sh}` 파일도 삭제하면 됩니다. (선택) 지금까지의 비용 기록도 지우고 싶으면 `~/.claude/cost-tracker/`도 삭제.

## 라이선스

MIT
