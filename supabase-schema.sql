-- Supabase SQL Editor에 이 내용을 그대로 붙여넣고 Run 하세요.
-- (프로젝트 대시보드 왼쪽 메뉴 -> SQL Editor -> New query)

-- 1) 수행평가 메모: 과목 이름마다 한 줄. 누구나 같은 과목명을 보고, 덮어써서 수정할 수 있어요.
create table if not exists evaluations (
  subject text primary key,
  content text default '',
  deadline date,
  keywords text default '',
  updated_at timestamptz default now()
);

-- 2) 오늘의 소식: 대회/공모전 게시글. 여러 명이 여러 개를 등록할 수 있어요.
create table if not exists news (
  id bigint generated always as identity primary key,
  title text not null,
  deadline date,
  description text default '',
  created_at timestamptz default now()
);

-- 이 프로젝트는 로그인 기능이 없는 "같은 반 친구들끼리 쓰는" 용도라
-- Row Level Security(행 단위 접근 제한)를 켜지 않았어요 (기본값 = 꺼짐).
-- 즉, 이 anon key와 테이블 이름만 알면 누구나 읽고 쓸 수 있어요 — 학교 소규모
-- 프로젝트에는 적당하지만, 민감한 정보는 절대 넣지 마세요.
--
-- 나중에 더 안전하게 만들고 싶다면 (선택):
--   alter table evaluations enable row level security;
--   alter table news enable row level security;
--   create policy "누구나 읽기" on evaluations for select using (true);
--   create policy "누구나 쓰기" on evaluations for insert with check (true);
--   create policy "누구나 수정" on evaluations for update using (true);
--   (news 테이블에도 동일하게)
