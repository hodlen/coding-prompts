---
name: python-patterns
description: Python-specific patterns for backend services. Supplements general coding principles.
---

# Python Patterns

## Type System

- Use modern syntax: `str | None`, `list[str]`, `dict[str, int]` (not `Optional`, `Union`, `List`, `Dict`)
- Never use `Any` if you inspect the structure—define it with `TypedDict` or Pydantic
- Use `object` for opaque passthrough (not `Any`)

## Pydantic as Contract

- All API boundaries require Pydantic models with validators
- Use `BaseSettings` for configuration (reads from `.env`)
- Strict validation at edges, types propagate inward

## Error Handling

- Only catch exceptions with legitimate recovery strategy
- Let it crash fast—no `except Exception: return None`
- Catching specific exceptions for fallback is sound; catching to suppress is not

## State Management

- `@cache` wrapped functions for singleton object (not singleton classes)
- FastAPI `Depends` with `yield` for per-request resources
- Reserve classes for multiple instances or complex lifecycle

## Async

- In async context, never use sync I/O (`requests`, `psycopg2`, `open()`)
- Use async equivalents: `httpx`, `asyncpg`, `aiofiles`
- Background tasks must handle `asyncio.CancelledError` for graceful shutdown

## Database

- Schema changes only via migration files (dbmate)
- Leverage engine features (ClickHouse MergeTree ORDER BY for upserts) over application logic
- Direct SQL via client, not ORM for analytical databases

## Structure

- Group by domain, not layer (`api/inventory.py` not `controllers/inventory_controller.py`)
- Extract pure business logic to `utils/`—makes testing trivial
- FastAPI routers = thin handlers, dependencies = resource management, utils = logic

## Checklist

- [ ] No `Any` unless opaque passthrough
- [ ] Pydantic for boundaries
- [ ] Async libs in async context
- [ ] Migrations for schema changes
