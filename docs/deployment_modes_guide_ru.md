# Гайд по запуску: 1 ПК и 3 ПК

Ниже два рабочих режима для одного и того же проекта.

## Вариант A: все 3 контейнера на одном ПК

Используется основной compose-файл: `docker-compose.yml`.

Что поднимется:
- `frontend` (Nginx) на `8080`
- `app-llm` (Ruby + Ollama)
- `xml-db` (BaseX) на `8984`

Запуск:

```bash
docker compose up -d --build
```

Проверка:

```bash
docker compose ps
```

Открыть в браузере:
- `http://localhost:8080`
- `http://localhost:8080/reports/visualisation.html`

Остановка:

```bash
docker compose down
```

---

## Вариант B: по одному Docker-сервису на каждом ПК (или VM)

Схема:
- `ПК1` -> `frontend`
- `ПК2` -> `app-llm`
- `ПК3` -> `xml-db`

Пример IP в одной сети:
- `ПК1`: `10.10.10.11`
- `ПК2`: `10.10.10.12`
- `ПК3`: `10.10.10.13`

### Шаг 1. ПК3 (`xml-db`)

```bash
docker compose -f docker-compose.vm3-xml-db.yml up -d
```

### Шаг 2. ПК2 (`app-llm`)

Создай env-файл:

```bash
cp .env.vm2.example .env.vm2
```

Проверь адрес XML БД в `.env.vm2`:

```env
XML_DB_BASE_URL=http://10.10.10.13:8984
```

Собери и запусти pipeline:

```bash
docker compose --env-file .env.vm2 -f docker-compose.vm2-app-llm.yml build
docker compose --env-file .env.vm2 -f docker-compose.vm2-app-llm.yml run --rm app-llm
```

После выполнения на `ПК2` появятся:
- `output/visualisation.html`
- `output/tickets_summary.csv`

### Шаг 3. Копирование отчета с ПК2 на ПК1

На `ПК2`:

```bash
scp output/visualisation.html output/tickets_summary.csv <user_pc1>@10.10.10.11:/path/to/rb_tkts/output/
```

### Шаг 4. ПК1 (`frontend`)

```bash
docker compose -f docker-compose.vm1-frontend.yml up -d --build
```

Открыть:
- `http://10.10.10.11:8080`
- `http://10.10.10.11:8080/reports/visualisation.html`

---

## Что показывать на экзамене

Быстрый сценарий демонстрации:
1. Поднять `xml-db` на ПК3.
2. Запустить pipeline (`app-llm`) на ПК2.
3. Перекинуть отчеты на ПК1 через `scp`.
4. Открыть отчет через `frontend` на ПК1 в браузере.
