# golang-migrate

เครื่องมือจัดการ **database migration**: เก็บการเปลี่ยนแปลง schema เป็นไฟล์ SQL ที่มีเลขเวอร์ชัน แล้วสั่งรันไปข้างหน้า (`up`) หรือย้อนกลับ (`down`) ได้

> เทียบกับ Node: คล้าย `prisma migrate` / `drizzle-kit migrate` แต่**เขียน SQL เองทั้งหมด** ไม่มีการ diff schema ให้

---

## 1. ติดตั้ง (WSL / Linux)

ในวิดีโอใช้ `brew install golang-migrate` (macOS) ส่วนบน WSL ติดตั้งผ่าน Go:

```bash
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
```

| ส่วนของคำสั่ง | ความหมาย |
| --- | --- |
| `go install` | ดาวน์โหลด, build แล้ววาง binary ไว้ที่ `~/go/bin` (คล้าย `npm install -g`) |
| `-tags 'postgres'` | build พร้อม driver ของ Postgres **ถ้าไม่ใส่จะเจอ `unknown driver postgres`** |
| `.../cmd/migrate` | path ของตัว CLI ภายใน repo |
| `@latest` | เวอร์ชันล่าสุด |

### เพิ่ม `~/go/bin` เข้า PATH (ทำครั้งเดียว)

```bash
echo 'export PATH="$PATH:$(go env GOPATH)/bin"' >> ~/.bashrc
source ~/.bashrc
migrate -version
```

- `go env GOPATH` ได้ค่า `~/go` ส่วน binary จะอยู่ใน `~/go/bin`
- `>> ~/.bashrc` ต่อบรรทัดท้ายไฟล์ ทำให้ทุก terminal ที่เปิดใหม่มี PATH นี้
- `source ~/.bashrc` โหลด PATH ใหม่ใน terminal ปัจจุบันทันที
- `migrate -version` ถ้าแสดงเลขเวอร์ชันแปลว่าติดตั้งสำเร็จ

---

## 2. สร้างไฟล์ migration

```bash
mkdir -p db/migration
migrate create -ext sql -dir db/migration -seq init_schema
```

| flag | ความหมาย |
| --- | --- |
| `create` | สร้างไฟล์ migration คู่ใหม่ (up + down) |
| `-ext sql` | นามสกุลไฟล์ `.sql` |
| `-dir db/migration` | โฟลเดอร์ที่เก็บไฟล์ |
| `-seq` | ใช้เลขเรียงลำดับ `000001`, `000002`, ... (ถ้าไม่ใส่จะใช้ timestamp) |
| `init_schema` | ชื่อ migration (ตั้งให้สื่อว่าทำอะไร) |

ผลลัพธ์:

```
db/migration/000001_init_schema.up.sql     ← เปลี่ยน schema ไปข้างหน้า
db/migration/000001_init_schema.down.sql   ← ย้อนสิ่งที่ up ทำ
```

### เขียนอะไรในแต่ละไฟล์

**up**: คัดลอก SQL ทั้งหมดจาก `simple_bank.sql` (export จาก dbdiagram) มาใส่

**down**: ต้อง**ย้อนทุกอย่าง**ที่ up ทำ โดย drop ตารางที่มี FK ชี้ออกไปก่อน:

```sql
DROP TABLE IF EXISTS entries;
DROP TABLE IF EXISTS transfers;
DROP TABLE IF EXISTS accounts;
```

> ถ้า drop `accounts` ก่อนจะ error เพราะ `entries`/`transfers` ยังมี FK ชี้มาที่ตารางนี้

---

## 3. รัน migration

```bash
migrate -path db/migration \
  -database "postgresql://user_postgres:pass_postgres@localhost:5432/simple_bank?sslmode=disable" \
  -verbose up
```

| ส่วน | ความหมาย |
| --- | --- |
| `-path db/migration` | โฟลเดอร์ไฟล์ migration |
| `-database "..."` | connection string ไปที่ DB |
| `-verbose` | แสดง log ละเอียด |
| `up` | รันทุก migration ที่ยังไม่ได้รัน |
| `down` | ย้อนกลับ (จะถามยืนยันก่อน, ใส่ `-all` เพื่อย้อนทั้งหมด) |
| `up 1` / `down 1` | รันหรือย้อนทีละ N ขั้น |

### อ่าน connection string

```
postgresql://user_postgres:pass_postgres@localhost:5432/simple_bank?sslmode=disable
             └── user ──┘ └─ password ─┘ └─ host ─┘ └port┘ └─ db ─┘ └─ ปิด SSL ─┘
```

- ค่า user/password/db ต้องตรงกับ `docker-compose.yml` (ในวิดีโอใช้ `root:secret` ซึ่งไม่ตรงกับของเรา)
- ใช้ **`localhost`** เพราะ `migrate` รันจากเครื่องเรา ไม่ได้รันใน container (ถ้ารันใน container ต้องใช้ชื่อ service `postgres`)
- **`sslmode=disable`** จำเป็น เพราะ Postgres ใน docker ไม่ได้เปิด SSL

---

## 4. ตาราง `schema_migrations`

หลัง `up` ครั้งแรกจะมีตารางนี้เพิ่มขึ้นมา migrate ใช้จำว่ารันถึงเวอร์ชันไหนแล้ว (คล้าย `_prisma_migrations`)

| คอลัมน์ | ความหมาย |
| --- | --- |
| `version` | เลข migration ล่าสุดที่รันแล้ว |
| `dirty` | `true` = migration ล่าสุดรัน**ไม่สำเร็จ**กลางทาง |

**อย่าแก้หรือลบตารางนี้ด้วยมือ** ยกเว้นตอนแก้สถานะ dirty (ดูหัวข้อ 7)

---

## 5. Makefile (ย่อคำสั่ง)

คล้าย `npm scripts` เพื่อจะได้ไม่ต้องพิมพ์คำสั่งยาวทุกครั้ง:

```makefile
DB_URL=postgresql://user_postgres:pass_postgres@localhost:5432/simple_bank?sslmode=disable

createdb:
	docker exec -it db-postgres createdb --username=user_postgres --owner=user_postgres simple_bank

dropdb:
	docker exec -it db-postgres dropdb --username=user_postgres simple_bank

migrateup:
	migrate -path db/migration -database "$(DB_URL)" -verbose up

migratedown:
	migrate -path db/migration -database "$(DB_URL)" -verbose down

.PHONY: createdb dropdb migrateup migratedown
```

- บรรทัดคำสั่งใต้ target ต้องย่อหน้าด้วย **Tab** เท่านั้น ใช้ space ไม่ได้ (ถ้าใช้ space จะเจอ `missing separator`)
- `.PHONY` บอก make ว่าชื่อพวกนี้เป็นคำสั่ง ไม่ใช่ชื่อไฟล์
- ใช้งาน: `make createdb`, `make migrateup`, `make migratedown`, `make dropdb`

### `createdb` / `dropdb`

| ส่วน | ความหมาย |
| --- | --- |
| `docker exec -it db-postgres` | รันคำสั่งใน container `db-postgres` (ในวิดีโอใช้ `postgres12`) |
| `createdb` / `dropdb` | โปรแกรมของ Postgres สำหรับสร้างและลบ database (มีอยู่ใน container แล้ว) |
| `--username=user_postgres` | user ที่ใช้เชื่อมต่อ |
| `--owner=user_postgres` | กำหนดเจ้าของ DB ที่สร้างใหม่ |
| `simple_bank` | ชื่อ database |

- **ปกติไม่ต้องรัน `createdb`** เพราะ `POSTGRES_DB: simple_bank` ใน compose สร้าง DB ให้แล้วตอนที่ volume ยังว่าง (ในวิดีโอใช้ `docker run` แบบไม่มี env นี้ จึงต้องสร้างเอง)
- ใช้ตอนอยากล้าง DB แล้วเริ่มใหม่ โดยไม่ต้องลบ volume:
  ```bash
  make dropdb && make createdb && make migrateup
  ```
- `dropdb` จะลบ**ทั้ง database** รวมถึงข้อมูลทั้งหมด ซึ่งต่างจาก `migratedown` ที่ลบเฉพาะตารางตามไฟล์ down

---

## 6. psql (เข้าไปดู DB ผ่าน terminal)

`psql` คือ CLI ของ Postgres ใช้รัน SQL และดูโครงสร้าง DB ได้ (ทำงานแบบ Adminer แต่ใช้ใน terminal)

### วิธีที่ 1: ใช้ psql ใน container (แนะนำ ตรงกับคอร์ส)

```bash
docker exec -it db-postgres psql -U user_postgres simple_bank
```

| ส่วน | ความหมาย |
| --- | --- |
| `docker exec` | รันคำสั่งใน container ที่ทำงานอยู่ |
| `-it` | interactive + terminal (ถ้าไม่ใส่จะพิมพ์โต้ตอบไม่ได้) |
| `db-postgres` | ชื่อ container (ในวิดีโอใช้ `postgres12`) |
| `psql -U user_postgres` | login ด้วย user นี้ |
| `simple_bank` | DB ที่จะเข้า |

- ไม่ต้องติดตั้งอะไรเพิ่ม เพราะ image Postgres มี `psql` มาให้แล้ว
- ไม่ต้องใส่ password เพราะการเชื่อมต่อจาก**ภายใน container**ผ่านได้โดยไม่ต้องใส่รหัส
- ถ้าพิมพ์ `psql` ตรงๆ บน WSL แล้วเจอ `command not found` ถือว่าปกติ เพราะยังไม่ได้ติดตั้งไว้บนเครื่อง

ใส่ใน Makefile ได้เหมือนกัน:

```makefile
psql:
	docker exec -it db-postgres psql -U user_postgres simple_bank
```

### วิธีที่ 2: ติดตั้ง psql บน WSL (ถ้าอยากพิมพ์ `psql` ตรงๆ)

```bash
sudo apt update
sudo apt install postgresql-client
psql "postgresql://user_postgres:pass_postgres@localhost:5432/simple_bank"
```

- ติดตั้งแค่ **`postgresql-client`** เท่านั้น
- **อย่า**ติดตั้งแพ็กเกจ `postgresql` เต็มตัว เพราะจะได้ Postgres server มาอีกตัวที่ใช้ port 5432 แล้วจะชนกับตัวใน docker
- ใช้ `localhost` เพราะ psql ตัวนี้รันบนเครื่องเรา ไม่ได้รันใน container

### คำสั่ง psql ที่ใช้บ่อย

| คำสั่ง | ความหมาย |
| --- | --- |
| `\l` | ดูรายชื่อ database |
| `\c simple_bank` | สลับไปใช้ DB นี้ |
| `\dt` | ดูรายชื่อตาราง |
| `\d accounts` | ดูโครงสร้างของตาราง (คอลัมน์, index, FK) |
| `SELECT * FROM schema_migrations;` | ดู version ของ migration ปัจจุบัน |
| `\q` | ออกจาก psql |

- คำสั่งที่ขึ้นต้นด้วย `\` เป็นคำสั่งของ psql เอง ไม่ต้องปิดด้วย `;`
- คำสั่ง SQL ปกติ**ต้องปิดด้วย `;`** ถ้าลืม psql จะรอให้พิมพ์ต่อ (prompt จะเปลี่ยนเป็น `simple_bank-#`)

---

## 7. ปัญหาที่เจอบ่อย

| อาการ | สาเหตุ / วิธีแก้ |
| --- | --- |
| `migrate: command not found` | `~/go/bin` ยังไม่อยู่ใน PATH ให้ทำหัวข้อ 1 อีกครั้ง |
| `unknown driver postgres` | ติดตั้งโดยไม่ได้ใส่ `-tags 'postgres'` ให้ติดตั้งใหม่ |
| `SSL is not enabled on the server` | ลืมใส่ `?sslmode=disable` |
| `password authentication failed` | user/password ไม่ตรงกับ compose หรือเคยเปลี่ยน env หลังจากมี volume แล้ว (env มีผลแค่ครั้งแรกเท่านั้น) |
| `relation "accounts" already exists` | มีตารางที่สร้างเองจาก Adminer อยู่แล้ว ให้ drop ก่อนหรือ `docker compose down -v` |
| `psql: command not found` | ยังไม่ได้ติดตั้ง psql บน WSL ให้ใช้ผ่าน `docker exec` แทน (หัวข้อ 6) |
| `database "simple_bank" does not exist` | ถูก `dropdb` ไปแล้ว ให้รัน `make createdb` ก่อน `migrateup` |
| `database "simple_bank" already exists` (ตอน `createdb`) | compose สร้างไว้ให้แล้ว ไม่ต้องรันคำสั่งนี้ |
| `Dirty database version N` | migration ล้มกลางทาง ให้แก้ SQL ให้ถูกก่อน แล้วรัน `migrate ... force N-1` เพื่อตั้งเวอร์ชันกลับ จากนั้นรัน `up` ใหม่ |

---

## สรุปขั้นตอน

```bash
# ครั้งแรก
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
migrate create -ext sql -dir db/migration -seq init_schema
# เขียน up.sql / down.sql
make migrateup

# ทุกครั้งที่จะเปลี่ยน schema
migrate create -ext sql -dir db/migration -seq <ชื่อการเปลี่ยนแปลง>
# เขียน up.sql / down.sql
make migrateup
```

> หลักสำคัญ: **ห้ามแก้ไฟล์ migration ที่รันไปแล้ว** (โดยเฉพาะไฟล์ที่ขึ้น production แล้ว) ถ้าต้องการเปลี่ยน schema ให้สร้างไฟล์ migration ใหม่เสมอ
