# Git Commands (ที่ใช้บ่อย)

ใช้ git ผ่าน terminal ใน WSL ไม่ใช้ GitHub Desktop เพราะ GitHub Desktop บน Windows มองไม่เห็นหรือทำงานได้ไม่ดีกับโปรเจกต์ที่อยู่ใน WSL (`\\wsl$\...`)

---

## Flow ปกติ: แก้ไฟล์ → add → commit → push

```bash
git status                     # 1. ดูว่ามีไฟล์ไหนเปลี่ยน
git add .                      # 2. เลือกไฟล์ที่จะ commit
git commit -m "feat: ..."      # 3. บันทึกเป็น commit
git push                       # 4. ส่งขึ้น GitHub
```

---

## 1. `git status`: ดูสถานะ

```bash
git status
git status --short     # แบบย่อ
```

| สัญลักษณ์ (`--short`) | ความหมาย |
| --- | --- |
| `??` | ไฟล์ใหม่ที่ git ยังไม่ได้ track |
| `M` | ไฟล์ที่ถูกแก้ไข |
| `A` | ไฟล์ที่ add แล้ว รอ commit |
| `D` | ไฟล์ที่ถูกลบ |

---

## 2. `git add`: เลือกไฟล์เข้า staging

```bash
git add Makefile               # add ไฟล์เดียว
git add db/ docs/              # add ทั้งโฟลเดอร์
git add .                      # add ทุกไฟล์ที่เปลี่ยนในโฟลเดอร์ปัจจุบัน
```

- **staging** คือพื้นที่พักไฟล์ก่อน commit ใช้เลือกได้ว่า commit นี้จะเอาไฟล์ไหนไปบ้าง
- ก่อนใช้ `git add .` ควรดู `git status` ก่อน จะได้ไม่เผลอ add ไฟล์ที่ไม่ต้องการ (เช่น `.env`)

ยกเลิกการ add (ไฟล์ยังอยู่ แค่เอาออกจาก staging):

```bash
git restore --staged Makefile
```

---

## 3. `git commit`: บันทึก

```bash
git commit -m "feat: add init schema migration"
```

- `-m` = ข้อความ commit (message)
- commit เก็บไว้**ในเครื่องเราเท่านั้น** ยังไม่ขึ้น GitHub จนกว่าจะ `push`

### รูปแบบ message (Conventional Commits)

| prefix | ใช้เมื่อ |
| --- | --- |
| `feat:` | เพิ่มฟีเจอร์ใหม่ |
| `fix:` | แก้บั๊ก |
| `docs:` | แก้เอกสาร |
| `chore:` | งานจิปาถะ เช่น config, tool |
| `refactor:` | ปรับโค้ดโดยไม่เปลี่ยนการทำงาน |
| `test:` | เพิ่มหรือแก้ test |

---

## 4. `git push`: ส่งขึ้น GitHub

```bash
git push                       # push branch ปัจจุบัน
git push -u origin main        # ครั้งแรกของ branch ใหม่: -u ผูก branch ไว้ ครั้งต่อไปพิมพ์แค่ git push
```

- `origin` = ชื่อเรียกของ repo บน GitHub (ดูด้วย `git remote -v`)
- `main` = ชื่อ branch

---

## 5. ดูประวัติ

```bash
git log --oneline              # ดู commit แบบย่อ บรรทัดละ 1 commit
git log --oneline -5           # เฉพาะ 5 อันล่าสุด
git diff                       # ดูสิ่งที่แก้แต่ยังไม่ได้ add
git diff --staged              # ดูสิ่งที่ add แล้วแต่ยังไม่ได้ commit
```

---

## 6. ดึงของล่าสุดจาก GitHub

```bash
git pull
```

- ใช้เมื่อแก้โค้ดจากเครื่องอื่นหรือแก้บนเว็บ GitHub แล้วอยากได้ของล่าสุดมาที่เครื่องนี้
- ถ้า push ไม่ผ่านและเจอ `rejected ... fetch first` แปลว่าบน GitHub มี commit ที่เครื่องเรายังไม่มี ให้ `git pull` ก่อนแล้วค่อย `git push`

---

> เทียบกับ GitHub Desktop: ช่องติ๊กเลือกไฟล์ = `git add`, ปุ่ม Commit = `git commit`, ปุ่ม Push origin = `git push`
