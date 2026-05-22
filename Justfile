set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
    just --list

validate:
    uv run python scripts/validate_skills.py

fmt:
    uv run ruff format scripts

lint:
    uv run ruff check scripts

ci: fmt lint validate

