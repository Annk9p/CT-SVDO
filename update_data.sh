#!/bin/sh
# ดึงแท็บ "Tiktok Post Plan" ทั้งหมด (รวมแถวที่ยุบกลุ่ม) จาก Google Sheet → data_sheet.js
# ใช้: sh update_data.sh   (ต้องมี python3)
cd "$(dirname "$0")"
URL="https://docs.google.com/spreadsheets/d/139OFW8jnXZ6PgelZ6zEVo9Fp0bRUbnbaVvvaM56jBuA/export?format=csv&gid=456905298"
curl -sL "$URL" -o /tmp/tiktok_post_plan.csv || { echo "ดาวน์โหลดไม่สำเร็จ"; exit 1; }
# แท็บ YouTube plan (ชีตอีกไฟล์) → data_youtube.js
YT_URL="https://docs.google.com/spreadsheets/d/1PLRGfQnKLG8mUy3wjjE5IrA_L925N_HL6d3stWRr9Cw/export?format=csv&gid=1450311646"
curl -sL "$YT_URL" -o /tmp/youtube_plan.csv || echo "ดาวน์โหลด YouTube ไม่สำเร็จ"
python3 - <<'PY'
import csv, json, datetime, os
now = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
rows = list(csv.reader(open('/tmp/tiktok_post_plan.csv', encoding='utf-8')))
open('data_sheet.js', 'w', encoding='utf-8').write('window.SHEET_SNAPSHOT = ' + json.dumps({"fetched_at": now, "rows": rows}, ensure_ascii=False) + ';\n')
print(f"เขียน data_sheet.js แล้ว: {len(rows)} แถว ณ {now}")
if os.path.exists('/tmp/youtube_plan.csv') and os.path.getsize('/tmp/youtube_plan.csv') > 1000:
    yrows = list(csv.reader(open('/tmp/youtube_plan.csv', encoding='utf-8')))
    open('data_youtube.js', 'w', encoding='utf-8').write('window.YT_SNAPSHOT = ' + json.dumps({"fetched_at": now, "rows": yrows}, ensure_ascii=False) + ';\n')
    print(f"เขียน data_youtube.js แล้ว: {len(yrows)} แถว")
PY

# push snapshot ขึ้น GitHub Pages (ถ้าตั้ง remote ไว้แล้ว) — เว็บจะเห็นข้อมูลใหม่ภายใน ~1-2 นาที
if [ -z "$GITHUB_ACTIONS" ] && git remote get-url origin >/dev/null 2>&1; then
  git add data_sheet.js data_youtube.js && git commit -qm "sync $(date '+%Y-%m-%d %H:%M')" 2>/dev/null && git push -q origin HEAD 2>&1 | tail -1
fi
