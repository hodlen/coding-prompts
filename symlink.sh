#!/usr/bin/env bash

set -ex

mkdir -p ~/.claude/ && ln -sfn AGENTS.md  ~/.claude/CLAUDE.md && ln -sfn skills ~/.claude/skills
mkdir -p ~/.codex/ && ln -sfn AGENTS.md ~/.codex/prompts && ln -sfn skills ~/.codex/skills
