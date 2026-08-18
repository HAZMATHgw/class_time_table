# 시간표+ 배포 가이드 (가입 없는 브라우저 AI + Supabase 공유 저장소 + GitHub Pages)

이번 버전에서 바뀐 점:
- **AI 검색어·아이디어 추천이 이제 서버도 API 키도 필요 없어요.** Gemini API가 성인 인증 문제로 막혀서, AI를 아예 **브라우저 안에서 직접 돌아가는 방식(WebLLM)**으로 바꿨어요. 아무도 가입하거나 키를 발급받을 필요가 없어요.
- 그 결과 **더 이상 Vercel도, 서버리스 함수도, 환경변수도 필요 없어졌어요.** 순수 정적 사이트라 **GitHub Pages 하나로 끝나요.**
- 수행평가 메모·오늘의 소식 공유는 이전과 동일하게 Supabase를 써요 (이것도 서버 없이 브라우저에서 직접 호출).

즉 지금부터는 **Node.js, npm, vercel, git 전부 몰라도** 진행할 수 있어요. 웹 브라우저만 있으면 돼요.

```
project/
├─ index.html          ← 프론트엔드 (시간표, 수행평가 메모+브라우저 AI, 겹강 조회, 소식, PDF 저장)
├─ data.js             ← 학교 시간표 엑셀에서 자동 변환된 데이터
├─ supabase-schema.sql ← Supabase에 붙여넣을 테이블 생성 SQL
├─ tools/
│  └─ build_data.py     ← 새 학기 엑셀이 오면 data.js를 다시 만드는 스크립트
├─ api/ai.js            ← (선택/레거시) 나중에 Gemini 키를 구할 수 있게 되면 쓸 수 있는 서버리스 함수. 지금은 안 씀
├─ package.json, .env.example  ← (선택/레거시) api/ai.js를 쓰게 될 때만 필요
└─ .gitignore
```

---

## 브라우저 AI(WebLLM)에 대해 알아두면 좋은 것

- 처음 "AI로 검색어·아이디어 받기" 버튼을 누르면 **AI 모델(약 1GB)을 그 자리에서 내려받아요.** 와이파이 상태에 따라 1~3분 정도 걸릴 수 있어요. 한 번 받으면 브라우저에 캐시되어서 **다음부터는 몇 초 안에 실행돼요.**
- **Chrome이나 Edge 최신 버전**에서만 동작해요 (WebGPU라는 기능이 필요해요). Safari나 오래된 브라우저에서는 "브라우저 AI를 지원하지 않아요"라는 안내가 떠요.
- 좀 오래된/저사양 노트북에서는 느릴 수 있어요. 그래도 무료이고 가입이 필요 없다는 게 가장 큰 장점이에요.
- 나중에 성인 인증이 되는 분(부모님/선생님)이 Gemini 키를 발급해줄 수 있게 되면, `api/ai.js`가 이미 준비되어 있으니 그때 다시 서버 방식으로 업그레이드할 수 있어요 (이 문서 맨 아래 참고).

---

## 0단계. 준비할 계정 2개 (전부 무료, 미성년자도 가입 가능)

| 계정 | 용도 | 가입 링크 |
|---|---|---|
| GitHub | 코드 저장소 + 사이트 호스팅 | https://github.com/join |
| Supabase | 반 전체가 공유하는 무료 데이터베이스 | https://supabase.com |

(Vercel, Google AI Studio는 이제 필요 없어요.)

---

## 1단계. Supabase 프로젝트 만들고 공유 테이블 준비하기

1. https://supabase.com 에서 GitHub 계정으로 로그인 → **New project**
2. 프로젝트 이름(예: `class-timetable`), 데이터베이스 비밀번호(아무거나 강력하게, 나중에 안 씀), 리전(가까운 곳, 예: Northeast Asia)을 정하고 **Create new project** — 1~2분 초기화 대기
3. 왼쪽 메뉴 **SQL Editor** → **New query**
4. 이 프로젝트의 `supabase-schema.sql` 파일 내용을 그대로 복사해서 붙여넣고 **Run**
5. 왼쪽 메뉴 **Settings → API** 이동 → 아래 두 값을 복사
   - **Project URL** (예: `https://abcdefghijk.supabase.co`)
   - **anon public** 키 (`eyJ...`로 시작하는 긴 문자열)
6. `index.html` 파일을 메모장으로 열어서(Ctrl+F로 `SUPABASE_URL` 검색하면 바로 찾아요) 이 두 줄을 방금 복사한 값으로 채우고 저장하세요:
   ```js
   const SUPABASE_URL = 'https://abcdefghijk.supabase.co';
   const SUPABASE_ANON_KEY = 'eyJ...';
   ```
   이 anon key는 공개돼도 되는 값이에요 (Supabase 설계상 그렇게 만들어져 있어요).

---

## 2단계. GitHub에 업로드

git이나 터미널 필요 없이, 웹에서 드래그만 하면 돼요.

1. https://github.com/new 에서 저장소 생성 (이름 예: `class-timetable`, Public으로), **"Add a README file" 체크하지 않기**
2. 저장소 페이지에서 **Add file → Upload files** 클릭
3. 압축 푼 `class-timetable-plus` 폴더 안의 파일/폴더를 통째로 드래그해서 올리기
   - `tools` 폴더 구조가 유지되는지 확인하세요 (없어도 사이트 동작에는 문제없어요, 나중에 시간표 데이터 갱신할 때만 필요)
4. **Commit changes** 클릭

---

## 3단계. GitHub Pages로 배포 (Vercel 필요 없음)

1. 저장소 페이지에서 **Settings** 탭 클릭
2. 왼쪽 메뉴에서 **Pages** 클릭
3. **Build and deployment → Source**에서 **Deploy from a branch** 선택
4. **Branch**를 `main` / `/ (root)`로 설정 → **Save**
5. 1~2분 기다리면 페이지 상단에 이런 안내가 떠요: **"Your site is live at https://내아이디.github.io/class-timetable/"**
6. 그 주소로 들어가서 확인:
   - 학생 이름 검색 → 시간표가 뜨는지 (과목마다 색이 다 다른지)
   - 과목 칸 클릭 → 같은 반 친구 목록이 뜨는지
   - "AI로 검색어·아이디어 받기" 버튼 → 첫 클릭이라 모델 다운로드가 좀 걸리는 게 정상이에요, 끝까지 기다려보기
   - "🖨️ PDF로 저장" 버튼
   - 수행평가 메모를 저장한 뒤, **다른 브라우저(시크릿 창)로 같은 주소에 들어가서도 그 메모가 보이는지** (Supabase가 잘 연결됐다면 여기서 보여야 진짜 공유되는 거예요)

---

## 4단계. 코드를 수정할 때마다

저장소 페이지에서 파일을 클릭 → 연필(편집) 아이콘 → 수정 → **Commit changes**. 몇십 초 안에 GitHub Pages가 자동으로 다시 배포해요. 파일을 통째로 바꾸고 싶으면 기존 파일 삭제 후 다시 Upload files 하면 돼요.

---

## (선택) 나중에 성인 인증이 되면: 서버 AI(Gemini)로 업그레이드

브라우저 AI는 가입이 필요 없다는 장점이 있지만, 작은 모델이라 Gemini보다 답변 품질이 떨어질 수 있어요. 나중에 부모님이나 선생님이 대신 Gemini 키를 발급해줄 수 있게 되면:

1. 이 저장소에 이미 있는 `api/ai.js`, `package.json`, `.env.example`을 그대로 활용
2. Vercel(vercel.com)에 이 GitHub 저장소를 Import
3. Environment Variables에 `GEMINI_API_KEY` 등록 후 Deploy
4. `index.html`의 `getAiIdeas()` 함수를 다시 `fetch('/api/ai', ...)` 호출 방식으로 되돌리기 (필요하면 이어서 요청해주세요, 코드를 다시 만들어드릴게요)

---

## 알아두면 좋은 것 / 한계

- 로그인 기능이 없어서, 사이트 주소와 Supabase anon key를 아는 사람은 누구나 메모를 읽고 쓸 수 있어요. 같은 반 친구들끼리 쓰는 용도로는 적당하지만, 민감한 정보는 올리지 마세요.
- 브라우저 AI는 노트북/PC의 최신 Chrome·Edge에서 가장 잘 동작해요. 학교 컴퓨터가 오래됐거나 사양이 낮으면 느리거나 안 될 수 있어요.
- 새 학기에 학교가 새 시간표 엑셀을 주면 `python tools/build_data.py "새파일.xlsx" data.js`로 다시 만들면 돼요 (이 단계만큼은 Python이 필요해요 — 매 학기 1번 정도라 부담은 적어요).
