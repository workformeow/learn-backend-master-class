postgres:
	docker compose up -d postgres

createdb:
	docker exec -it db-postgres createdb --username=user_postgres --owner=user_postgres simple_bank

dropdb:
	docker exec -it db-postgres dropdb --username=user_postgres simple_bank

migrateup:
	migrate -path db/migration -database "postgresql://user_postgres:pass_postgres@localhost:5432/simple_bank?sslmode=disable" -verbose up

migratedown:
	migrate -path db/migration -database "postgresql://user_postgres:pass_postgres@localhost:5432/simple_bank?sslmode=disable" -verbose down

.PHONY: postgres createdb dropdb migrateup migratedown