#!/usr/bin/env bash
# 페이퍼팩로그 Hugo → Quartz 동기화 + GitHub Pages 배포 스크립트
# 사용: bash sync-and-deploy.sh

set -e

HUGO_DIR="/Users/ai/projects/paper-packaging-blog"
QUARTZ_DIR="/Users/ai/projects/paperpacklog-quartz"

cd "$QUARTZ_DIR"

echo "▶ 1/5 Hugo 콘텐츠 → Quartz 복사"
rm -rf content/ko content/en content/images
mkdir -p content/ko content/en
cp "$HUGO_DIR"/content/ko/posts/*.md content/ko/
cp "$HUGO_DIR"/content/en/posts/*.md content/en/
cp -R "$HUGO_DIR"/static/images/posts content/images/

echo "▶ 2/5 이미지 경로 변환 + cover 본문 주입 (Quartz용)"
python3 <<'PY'
import glob, re
for p in glob.glob('content/**/*.md', recursive=True):
    with open(p) as f: t = f.read()
    n = t.replace('](/images/posts/', '](../images/posts/').replace('image: /images/posts/', 'image: ../images/posts/')
    # frontmatter에서 cover 정보 추출
    fm_match = re.match(r'^---\n(.*?)\n---\n', n, re.DOTALL)
    if fm_match:
        fm = fm_match.group(1)
        cover_match = re.search(r'cover:\s*\n\s*image:\s*([^\s\n]+)\s*\n\s*alt:\s*"([^"]+)"', fm)
        if cover_match:
            cover_path = cover_match.group(1)
            cover_alt = cover_match.group(2)
            cover_md = f'![{cover_alt}]({cover_path})\n\n'
            # 본문 시작에 이미 같은 cover가 있는지 확인
            body_start = fm_match.end()
            if cover_path not in n[body_start:body_start+500]:
                n = n[:body_start] + cover_md + n[body_start:]
    if n != t:
        open(p, 'w').write(n)
PY

echo "▶ 3/5 Quartz 빌드"
npx quartz build

echo "▶ 4/5 main 브랜치 콘텐츠 푸시"
git checkout main
git add -A
git diff --cached --quiet || git -c user.email='ai@ysung.com' -c user.name='AI Assistant' commit -m "sync: Hugo 블로그 콘텐츠 동기화 ($(date '+%Y-%m-%d %H:%M'))"
git push origin main

echo "▶ 5/5 gh-pages 브랜치에 빌드 결과 배포"
git checkout gh-pages 2>/dev/null || git checkout --orphan gh-pages
git rm -rf . 2>/dev/null || true
cp -R public/* .
touch .nojekyll
git add -A
git diff --cached --quiet || git -c user.email='ai@ysung.com' -c user.name='AI Assistant' commit -m "deploy: $(date '+%Y-%m-%d %H:%M')"
git push origin gh-pages
git checkout main

echo "✅ 완료: https://jipyung-a11y.github.io/paperpacklog-quartz/"
