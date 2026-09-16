#!/bin/sh
# ดึงแท็บ "Tiktok Post Plan" ทั้งหมด (รวมแถวที่ยุบกลุ่ม) จาก Google Sheet → data_sheet.js
# ใช้: sh update_data.sh   (ต้องมี python3)
cd "$(dirname "$0")"
URL="https://docs.google.com/spreadsheets/d/139OFW8jnXZ6PgelZ6zEVo9Fp0bRUbnbaVvvaM56jBuA/export?format=csv&gid=456905298"
curl -sL "$URL" -o /tmp/tiktok_post_plan.csv || { echo "ดาวน์โหลดไม่สำเร็จ"; exit 1; }
python3 - <<'PY'
import csv, json, datetime
rows = list(csv.reader(open('/tmp/tiktok_post_plan.csv', encoding='utf-8')))
snap = {"fetched_at": datetime.datetime.now().strftime('%Y-%m-%d %H:%M'), "rows": rows}
open('data_sheet.js', 'w', encoding='utf-8').write('window.SHEET_SNAPSHOT = ' + json.dumps(snap, ensure_ascii=False) + ';\n')
print(f"เขียน data_sheet.js แล้ว: {len(rows)} แถว ณ {snap['fetched_at']}")
PY

# push snapshot ขึ้น GitHub Pages (ถ้าตั้ง remote ไว้แล้ว) — เว็บจะเห็นข้อมูลใหม่ภายใน ~1-2 นาที
if git remote get-url origin >/dev/null 2>&1; then
  git add data_sheet.js && git commit -qm "sync $(date '+%Y-%m-%d %H:%M')" 2>/dev/null && git push -q origin HEAD 2>&1 | tail -1
fi
