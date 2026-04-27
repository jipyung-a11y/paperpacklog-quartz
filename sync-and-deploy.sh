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

echo "▶ 2/5 이미지 경로 변환 (/images/ → ../images/)"
python3 <<'PY'
import glob
for p in glob.glob('content/**/*.md', recursive=True):
    with open(p) as f: t = f.read()
    n = t.replace('](/images/posts/', '](../images/posts/').replace('image: /images/posts/', 'image: ../images/posts/')
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
