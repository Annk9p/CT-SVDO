# เชื่อม Google Sheets API กับ Dashboard

หน้าเว็บรองรับการอ่านสดผ่าน **Google Sheets API v4** แล้ว เหลือแค่ใส่ API key

## ขั้นตอน (ทำครั้งเดียว ~5 นาที)

1. เปิด <https://console.cloud.google.com/> → สร้างโปรเจกต์ใหม่ เช่น `content-dashboard`
2. **APIs & Services → Library** → ค้นหา **Google Sheets API** → กด **Enable**
3. **APIs & Services → Credentials → Create credentials → API key** → คัดลอกคีย์
4. กด **Edit API key** แล้วจำกัดการใช้งาน (สำคัญ เพราะคีย์จะอยู่ในหน้าเว็บสาธารณะ)
   - **Application restrictions** → *Websites* → เพิ่ม
     - `https://annk9p.github.io/*`
     - `http://localhost:8765/*` (ไว้ทดสอบในเครื่อง)
   - **API restrictions** → *Restrict key* → เลือก **Google Sheets API** อย่างเดียว
5. ใส่คีย์ใน `index.html` บรรทัด `const GOOGLE_API_KEY = '';` → `const GOOGLE_API_KEY = 'AIza…';`
6. commit + push → GitHub Pages deploy → กดปุ่ม "รีเฟรชข้อมูล" จะเห็นข้อมูลสดทันที

ชีตต้องยังแชร์แบบ **"ทุกคนที่มีลิงก์ดูได้"** เพราะ API key ใช้อ่านได้เฉพาะไฟล์สาธารณะ

## หน้าเว็บทำงานอย่างไร

ลำดับการอ่านข้อมูล (`loadSheet` ใน `index.html`):

| ลำดับ | วิธี | ได้อะไร |
|---|---|---|
| 1 | **Sheets API v4** (ถ้ามี `GOOGLE_API_KEY`) | สดทันที ครบทุกแถวรวมแถวที่ยุบกลุ่ม |
| 2 | `PUB_CSV_URL` (เผยแพร่เป็น CSV) | สด ครบทุกแถว |
| 3 | `data_sheet.js` snapshot จาก GitHub Actions | ช้าได้ถึง 10 นาที |
| 4 | gviz JSONP | สด แต่เห็นเฉพาะแถวที่ไม่ยุบกลุ่ม |

เรียกจริง 2 คำขอต่อชีต:

```
GET /v4/spreadsheets/{id}?fields=sheets.properties(sheetId,title)&key=…   → หาชื่อแท็บจาก gid
GET /v4/spreadsheets/{id}/values/'ชื่อแท็บ'?majorDimension=ROWS&valueRenderOption=FORMATTED_VALUE&key=…
```

A1 notation ใช้ **ชื่อแท็บ** ไม่ใช่ gid จึงต้องขอ metadata ก่อน (ผลลัพธ์ถูก cache ไว้ในหน่วยความจำต่อการโหลดหนึ่งครั้ง)
`FORMATTED_VALUE` ทำให้วันที่ออกมาเป็น `M/D/YYYY` เหมือน CSV เดิม โค้ด parse เดิมจึงใช้ได้ทันที
API ตัดเซลล์ว่างท้ายแถวทิ้ง โค้ดเลยเติมความกว้างให้ทุกแถวเท่ากันก่อนส่งเข้า `parseRows`

ถ้าอ่านผ่าน API ไม่สำเร็จ หน้าเว็บจะขึ้นแถบเหลืองบอกสาเหตุ แล้วใช้ข้อมูลสำรองลำดับถัดไปโดยอัตโนมัติ

## โควต้า

Sheets API ฟรี: อ่าน 300 คำขอ/นาที ต่อโปรเจกต์ และ 60 คำขอ/นาที ต่อผู้ใช้
หน้านี้ใช้ 4 คำขอต่อการโหลด (2 ชีต × 2 คำขอ) และรีโหลดอัตโนมัติทุก 15 นาที จึงห่างจากลิมิตมาก

## ถ้าต้องการให้ชีตเป็นส่วนตัว หรือให้เว็บเขียนกลับชีตได้

API key ทำไม่ได้ ต้องเลือกอย่างใดอย่างหนึ่ง:

- **Service account** (อ่านอย่างเดียว ชีตเป็นส่วนตัวได้) — สร้าง service account → แชร์ชีตให้อีเมลของมัน → เก็บ JSON key เป็น GitHub secret → ให้ `update_data.sh` ใน GitHub Actions ใช้ token แทน CSV ข้อมูลยังมาทาง snapshot (ช้าได้ถึง 10 นาที) แต่ชีตไม่ต้องเปิดสาธารณะ
- **OAuth (Google Identity Services)** — ผู้ใช้กด "เชื่อมบัญชี Google" บนหน้าเว็บ แล้วเว็บเขียนกลับชีตได้ในสิทธิ์ของคนนั้น เหมาะกับการบันทึกแผนจากหน้าปฏิทินลงชีตโดยตรง ใช้ scope `spreadsheets` และ OAuth client แบบ Web application (ไม่มี client secret ในหน้าเว็บ)
- **Google Apps Script Web App** — ทางที่เร็วที่สุดสำหรับการเขียนกลับ ไม่ต้องตั้ง Google Cloud project
