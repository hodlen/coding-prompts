#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["tomlkit>=0.13"]
# ///
"""Install the shared agent configuration and pinned global quality tools.

Run ./install.py from any directory with uv on PATH. Existing JSON settings
are merged, TOML comments are preserved, and unchanged files are left alone.
Skills are linked individually so unrelated installations remain available.
Worktree-local .metrics directories are added to the user's global Git ignores.
"""

import json
import os
from pathlib import Path
import subprocess
from tempfile import NamedTemporaryFile

import tomlkit


def main() -> None:
    """Install tools and merge configuration for the current user's home.

    Tool installation and parser downloads may use the network. Failures and
    malformed configurations propagate; each changed config file is replaced
    atomically. Existing links and files at managed link destinations are
    replaced, while real directories at those destinations cause an error.
    """
    repo = Path(__file__).resolve().parent
    user_dir = Path.home()
    state = Path(os.environ.get("XDG_STATE_HOME") or user_dir / ".local/state") / "agents"
    revisions = {
        "crapper": "6fd92c4c9bcc56efb64a2f8743d5a2993bcfd42d",
        "dryer": "66ff6d21a42c04afcad89c78a80066176d1294b0",
        "mutator": "a5a0cb803b66e0cdb8bf471b3b08af701d424a41",
    }
    packages = {
        name: f"{name} @ git+https://github.com/unclebob/{name}@{revision}"
        for name, revision in revisions.items()
    }
    # mutator imports crapper; exporting all three from one environment keeps
    # that undeclared upstream dependency available without sibling checkouts.
    subprocess.run([
        "uv", "tool", "install", "--python", ">=3.11",
        "--with-executables-from", packages["crapper"],
        "--with-executables-from", packages["dryer"], packages["mutator"],
    ], check=True)
    tool_dir = Path(subprocess.check_output(["uv", "tool", "dir"], text=True).strip())
    # Preload grammars during installation so analysis can run without downloads.
    subprocess.run([
        str(tool_dir / "mutator/bin/python"), "-c",
        "import tree_sitter_language_pack as t; "
        "t.download(['python', 'java', 'go', 'typescript', 'tsx', 'javascript', 'rust', 'clojure'])",
    ], check=True)
    subprocess.run(["uv", "tool", "update-shell"], check=True)

    def write_if_changed(path: Path, content: str) -> None:
        if path.exists() and path.read_text(encoding="utf-8") == content:
            return
        path.parent.mkdir(parents=True, exist_ok=True)
        with NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent, delete=False) as output:
            output.write(content)
        Path(output.name).replace(path)

    def read_json(path: Path) -> dict:
        return json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}

    excludes = subprocess.run(
        ["git", "config", "--global", "--path", "--get", "core.excludesFile"],
        text=True, capture_output=True,
    )
    if excludes.returncode == 1:
        config_home = Path(os.environ.get("XDG_CONFIG_HOME") or user_dir / ".config")
        ignore_path = config_home / "git/ignore"
    else:
        excludes.check_returncode()
        ignore_path = Path(excludes.stdout.rstrip("\n"))
    # Follow an existing symlink so installing does not replace the user's link.
    ignore_path = ignore_path.resolve()
    ignored = ignore_path.read_text(encoding="utf-8") if ignore_path.exists() else ""
    if "/.metrics/" not in ignored.splitlines():
        separator = "\n" if ignored and not ignored.endswith("\n") else ""
        write_if_changed(ignore_path, ignored + separator + "/.metrics/\n")

    def default_if_null(settings: dict, key: str, empty):
        if settings.get(key) is None:
            settings[key] = empty
        return settings[key]

    def merge_hooks(settings: dict) -> None:
        command = str(repo / "hooks/cleanup-gate.sh")
        hooks = default_if_null(settings, "hooks", {})
        for event in ("SessionStart", "Stop"):
            groups = default_if_null(hooks, event, [])
            if not any(
                hook.get("command") == command
                for group in groups for hook in (group.get("hooks") or [])
            ):
                groups.append({"matcher": "", "hooks": [{"type": "command", "command": command, "timeout": 10}]})

    claude_path = user_dir / ".claude/settings.json"
    claude = read_json(claude_path)
    permissions = default_if_null(claude, "permissions", {})
    denied = default_if_null(permissions, "deny", [])
    if not isinstance(denied, list):
        raise TypeError("permissions.deny must be an array")
    for rule in json.loads((repo / "settings/claude-deny.json").read_text(encoding="utf-8")):
        if rule not in denied:
            denied.append(rule)
    directories = default_if_null(permissions, "additionalDirectories", [])
    if str(state) not in directories:
        directories.append(str(state))
    merge_hooks(claude)
    write_if_changed(claude_path, json.dumps(claude, indent=2, ensure_ascii=False) + "\n")

    hooks_path = user_dir / ".codex/hooks.json"
    hooks = read_json(hooks_path)
    merge_hooks(hooks)
    write_if_changed(hooks_path, json.dumps(hooks, indent=2, ensure_ascii=False) + "\n")

    config_path = user_dir / ".codex/config.toml"
    config = tomlkit.parse(config_path.read_text(encoding="utf-8") if config_path.exists() else "")
    sandbox = config.setdefault("sandbox_workspace_write", tomlkit.table())
    roots = sandbox.setdefault("writable_roots", tomlkit.array())
    if str(state) not in roots:
        roots.append(str(state))
    write_if_changed(config_path, tomlkit.dumps(config))

    def link(source: Path, destination: Path) -> None:
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.is_symlink() and destination.readlink() == source:
            return
        destination.unlink(missing_ok=True)
        destination.symlink_to(source, target_is_directory=source.is_dir())

    state.mkdir(parents=True, exist_ok=True)
    link(repo / "AGENTS.md", user_dir / ".claude/CLAUDE.md")
    link(repo / "AGENTS.md", user_dir / ".codex/AGENTS.md")
    link(repo / "settings/codex-deny.rules", user_dir / ".codex/rules/coding-prompts.rules")
    for source in sorted((repo / "skills").iterdir()):
        if source.is_dir() and not source.name.startswith("."):
            link(source, user_dir / ".claude/skills" / source.name)
            link(source, user_dir / ".agents/skills" / source.name)
    for source in sorted((repo / "skills/.portable").iterdir()):
        if source.is_dir() and not source.name.startswith("."):
            link(source, user_dir / ".agents/skills" / source.name)
    for source in sorted((repo / "commands").glob("*")):
        if not source.name.startswith("."):
            link(source, user_dir / ".claude/commands" / source.name)


if __name__ == "__main__":
    main()
