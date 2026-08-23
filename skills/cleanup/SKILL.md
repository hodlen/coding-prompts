---
name: cleanup
description: "Pre-merge and mid-work guardrail: a clean agent checks the diff against the request, /simplify cleans what remains, then durable artifacts are scrubbed. Invoked by /ship before review; also runs standalone at any checkpoint."
---

# Cleanup

Passes A and C run in a clean agent carrying none of this session's context. Give it only: the diff, the user's original request verbatim, the plan file if one exists, and the explicit user constraints collected so far. Never inject prior agent output.

**A. Scope and constraints.** Check the diff against the request: restore touched files the request never needed (format-only churn included), delete unrequested features with their tests, drop guards for states the types already exclude, verify claimed deletions by grep, confirm GitHub bodies carry no mid-paragraph hard wraps, and check the diff against every explicit user constraint. Apply mechanical fixes; report judgment calls.

**B. `/simplify`** on the same target; its review agents are already context-free.

**C. Durable artifacts.** Remove session-only references, move point-in-time evidence out of living artifacts, and rewrite debate residue as durable mechanisms, invariants, constraints, or tradeoffs. Preserve meaning, and report ambiguity instead of resolving it. Skip this pass mid-work when no durable artifacts exist yet.
