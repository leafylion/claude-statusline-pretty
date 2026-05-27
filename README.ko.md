# claude-statusline-pretty

[Claude Code](https://claude.com/claude-code)용 2줄 상태표시줄 플러그인 — [ccusage](https://github.com/ryoppippi/ccusage) 기반 월별 비용 추적 기능 포함.

🌐 [English](README.md) · 한국어

## 미리보기

```
Sonnet 4.6 · "Customize statusline icons" · › myproject · ⎇ main
effort:high · context 4% · cache 99% · 6m 56s · month $42.18
```

**1줄** — 모델 · 세션명 · 디렉터리 · git 브랜치
**2줄** — effort 단계 · 컨텍스트 % · 캐시 적중률 · 세션 진행시간 · 이번 달 누적 비용

## 주요 기능

- **컨텍스트 % 색상 변화** — 사용량이 늘어날수록 색이 점점 강해짐 (테마 4종 내장)
- **월별 비용 합산** — 이번 달 이 머신의 모든 Claude Code 트랜스크립트 기준 API 환산 비용을 `ccusage`로 집계 (선택 의존성)
- **크로스 플랫폼** — Windows는 PowerShell, macOS/Linux는 Bash + jq

## 설치

### 사전 요구사항

- **Windows:** PowerShell 5.1+ (기본 내장)
- **macOS:** `jq` — `brew install jq`
- **Linux:** `jq` — `sudo apt install jq` (Debian/Ubuntu) 또는 `sudo dnf install jq` (Fedora)
- **선택 (전 플랫폼):** [`ccusage`](https://github.com/ryoppippi/ccusage) — `month $X.XX` 표시에 필요. `npm i -g ccusage`. PATH에 없으면 해당 요소만 조용히 빠짐.

### 설치 절차

```text
/plugin marketplace add leafylion/claude-statusline-pretty
/plugin install claude-statusline-pretty
/reload-plugins
/claude-statusline-pretty:install-statusline
```

`/reload-plugins` 는 `install` 직후 새 스킬을 Claude Code 가 인식하게 해주는 단계. 스킬은 플러그인 이름으로 namespace 가 붙어서 `/claude-statusline-pretty:install-statusline` 형태로 호출됩니다 (탭 자동완성 됨).

인스톨러가 끝나면 **Claude Code를 재시작**하세요. `settings.json` 은 시작 시점에 한 번 읽기 때문에, 재시작이 있어야 새 상태표시줄이 적용됩니다.

설치 시 색상 테마와 기호 스타일을 물어봅니다. 그냥 기본값을 원하면 "기본"이라고 답하면 됩니다.

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

**색상 테마** — 각 테마는 *13색 풀 팔레트*입니다. 테마를 바꾸면 컨텍스트 % 만이 아니라 라인 전체 색이 바뀝니다.

| 테마          | 분위기                                              |
|---------------|------------------------------------------------------|
| `current`     | 밝은 사이안/그린/마젠타 — 시끄럽고 클래식          |
| `cool-pastel` | 라일락/스카이블루/민트/라벤더 — 차분한 쿨톤        |
| `earthy`      | 베이지/세이지/올리브/러스트/로즈 — 따뜻한 흙색     |
| `neutral`     | 거의 회색 톤, 컨텍스트 경고일 때만 색상 등장      |
| `custom`      | 나만의 팔레트 — 아래 섹션 참고                     |

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

### 커스텀 팔레트

테마를 `custom`으로 고르면 `~/.claude/statusline-theme.json`을 읽어서 사용합니다 — 모든 13개 요소 색을 이 파일에서 가져옵니다:

```json
{
  "model": 183, "session": 247, "dir": 81, "branch": 121, "effort": 117,
  "ctx_ok": 152, "ctx_wn": 215, "ctx_er": 174,
  "cache": 80, "duration": 244, "cost": 147, "total": 219, "sep": 238
}
```

13개 키 모두 필수, 값은 [256-color](https://www.ditig.com/256-colors-cheat-sheet) 번호(0–255). 파일이 없거나 형식이 깨지면 자동으로 `cool-pastel` 로 폴백.

설치 스크립트가 `--theme custom`(또는 `-Theme custom`)으로 실행될 때 `~/.claude/statusline-theme.json` 이 없으면 `examples/themes/cool-pastel.json` 을 시드 파일로 복사해 줍니다 — 한 파일만 편집하면 됩니다.

시작점으로 쓰기 좋은 미리 만들어둔 팔레트: [`examples/themes/`](examples/themes/) 에 4개 (`current.json`, `cool-pastel.json`, `earthy.json`, `neutral.json`) 있음.

## 파일 구조

```
.claude-plugin/plugin.json       # 플러그인 매니페스트
bin/install.ps1                  # Windows 설치 스크립트
bin/install.sh                   # macOS / Linux 설치 스크립트
scripts/statusline.ps1           # Windows 상태표시줄
scripts/statusline.sh            # macOS / Linux 상태표시줄
skills/install-statusline/       # /install-statusline 스킬
examples/themes/                 # custom 팔레트 시작용 JSON 파일들
```

## 제거

`~/.claude/settings.json`에서 `statusLine` 키를 지우고, `~/.claude/statusline.{ps1,sh}` 파일도 삭제하면 됩니다. 이전 버전을 쓰다가 업그레이드한 경우 `~/.claude/cost-tracker/` 디렉터리는 더 이상 쓰이지 않으니 삭제해도 무방.

## 라이선스

MIT
