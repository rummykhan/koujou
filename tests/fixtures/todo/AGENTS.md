# Agent Instructions

<!-- BEGIN SOFTWARE FACTORY — managed block. Edit through the factory (/factory-setup, /factory-run); keep these markers. -->
## How work gets done here

This project is delivered through the software factory. The project profile is [`FACTORY.md`](FACTORY.md). Read it before changing code.

- **Tasks live in beads** (`bd ready`, `bd show <id>`). Every task has acceptance criteria written before the code; work to them.
- **Nobody closes their own work.** A task is done when its acceptance tests pass, an independent review passes and the gate (`npm run gate`) is green.

## System design

_As built at the fixture's first commit_

### Purpose
A to-do list kept in memory and served over HTTP as JSON.

### Components
| Component | Responsibility | Where |
|---|---|---|
| Store | Holds todos; assigns ids | `src/store.js` |
| Server | Routes, validation, JSON errors | `src/server.js` |
| Entry point | Reads `PORT`, starts the server on 127.0.0.1 | `src/main.js` |

### Data model
`todo = { id: positive integer, title: string (1 to 200 chars, trimmed), done: boolean }`

### Interfaces
- `GET /health` → 200 `{ok:true}`
- `GET /todos` → 200 `{todos:[todo]}`
- `POST /todos` `{title}` → 201 todo | 400 `{error:"invalid_title"}`
- Unknown path → 404 `{error:"not_found"}`; wrong method → 405 `{error:"method_not_allowed"}`

### In progress
<!-- END SOFTWARE FACTORY -->
