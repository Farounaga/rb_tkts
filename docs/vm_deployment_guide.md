# Deployment Guide: 3 Docker Services on 3 VMs

This guide matches your exam scenario:
- `VM1` = `frontend`
- `VM2` = `app-llm` (Ruby pipeline + Ollama)
- `VM3` = `xml-db` (BaseX NoSQL XML)

## 1. Network Plan

Use static IPs in the same subnet (example):
- `VM1 frontend`: `10.10.10.11`
- `VM2 app-llm`: `10.10.10.12`
- `VM3 xml-db`: `10.10.10.13`

Open only needed ports:
- VM1: `18080/tcp` (for browser access)
- VM3: `8984/tcp` (allow from VM2 only)

## 2. Prerequisites (all VMs)

Install:
- Docker Engine
- Docker Compose v2
- Git (or copy project files)

Clone/copy the same project folder on each VM.

## 3. Start XML DB on VM3

From project root on `VM3`:

```bash
docker compose -f docker-compose.vm3-xml-db.yml up -d
```

Check:

```bash
docker compose -f docker-compose.vm3-xml-db.yml ps
```

## 4. Configure + Run app-llm on VM2

From project root on `VM2`:

```bash
cp .env.vm2.example .env.vm2
```

Edit `.env.vm2` and set the correct XML DB IP:

```env
XML_DB_BASE_URL=http://10.10.10.13:8984
```

Build image:

```bash
docker compose --env-file .env.vm2 -f docker-compose.vm2-app-llm.yml build
```

Run one full pipeline execution:

```bash
docker compose --env-file .env.vm2 -f docker-compose.vm2-app-llm.yml run --rm app-llm
```

Expected outputs on VM2:
- `output/visualisation.html`
- `output/tickets_summary.csv`

## 5. Copy generated reports from VM2 to VM1

From `VM2`, send files to project folder on `VM1`:

```bash
scp output/visualisation.html output/tickets_summary.csv <vm1_user>@10.10.10.11:/path/to/rb_tkts/output/
```

Replace:
- `<vm1_user>` with VM1 username
- `/path/to/rb_tkts` with real project path on VM1

## 6. Start frontend on VM1

From project root on `VM1`:

```bash
docker compose -f docker-compose.vm1-frontend.yml up -d --build
```

Check in browser:
- `http://10.10.10.11:18080`
- `http://10.10.10.11:18080/reports/visualisation.html`

## 7. Re-run flow (exam demo)

When you need fresh data:
1. Run pipeline on VM2 (`run --rm app-llm`)
2. Copy report files VM2 -> VM1 (`scp`)
3. Refresh browser on VM1 URL

## 8. Stop Services

VM1:

```bash
docker compose -f docker-compose.vm1-frontend.yml down
```

VM2:

```bash
docker compose --env-file .env.vm2 -f docker-compose.vm2-app-llm.yml down
```

VM3:

```bash
docker compose -f docker-compose.vm3-xml-db.yml down
```
