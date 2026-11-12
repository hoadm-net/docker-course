# docker-course

Companion code for the self-study book *Docker: from the first container to a production stack*.
The book holds the theory, diagrams and exercise statements; this repository holds all code.

## Requirements

Docker Engine 23+ (written against Engine 29) with the Compose plugin, `bash` and `curl`.
On Windows, run everything inside WSL2.

## Layout

| Path | Content |
|---|---|
| `app-v1/` | VietMart Catalog v1: a single Flask service with a file-based visit counter |
| `app-v2/` | v2: products in PostgreSQL, visit counter in Redis |
| `chNN_<topic>/solutions.sh` | Exercise solutions, one function per exercise (`ex_5_2` = exercise 5.2) |
| `ch04_dockerfile/`, `ch05_image_optimization/` | The Dockerfiles built step by step in the book |
| `ch08_compose/` | `compose.yaml` plus override files (reverse proxy, dev tools) |
| `ch10_security/` | Compose stack with file-based secrets and a hardened API |
| `ch11_operations/daemon.json` | Host-wide log rotation defaults |
| `ch12_cicd/` | GitHub Actions workflow, Kubernetes example, GPU Compose file |
| `ch13_capstone/` | Complete production-style stack and `verify.sh` |

Chapter 1 is theory only and has no folder.

## Running

Always run from the repository root.

```bash
bash ch04_dockerfile/solutions.sh                 # list the exercises of a chapter
bash ch04_dockerfile/solutions.sh ex_4_1          # run one
bash ch06_storage/solutions.sh ex_6_1 cleanup     # run several, then clean up
bash ch13_capstone/verify.sh up check down
```

Later chapters reuse images built earlier: `vietmart-api:1.0` (exercise 4.1) and
`vietmart-api:1.1` (exercise 5.1).

## Notes

- Secrets are never committed: copy `.env.example` to `.env` and
  `secrets/db_password.txt.example` to `secrets/db_password.txt` (the scripts do this for you).
- Ports 8000, 8080, 8081 and 5000 must be free.
- Try each exercise yourself before opening `solutions.sh`.
