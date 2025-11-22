---
name: typescript-react-patterns
description: React/TypeScript patterns for robust applications. Supplements general coding principles.
---

# React/TypeScript Patterns

## State Management

- **Derive, don't sync:** Use `useMemo` to compute from existing state, never `useEffect` to sync state
- **Storage-backed state:** `sessionStorage` for temporary (filters), `localStorage` for preferences
- **Single source of truth:** Derive all flags/computed values, no shadow state
- **Non-visual state:** Use `useRef` for timer IDs, DOM refs, previous values, mutable caches—anything that doesn't trigger re-render

## Context

- Always `useMemo` the value prop (every `<Context.Provider>` needs it)
- Split contexts by update frequency (don't bundle fast-changing with slow-changing)
- Custom hook pattern: `useTheme()` throws if outside provider

## Hook Dependencies

Only include reactive values (props, state, context, component-scoped variables):
- **Never include:** imports, `useRef` values, `setState` functions, constants
- Exception: none

## Component Structure

**Hook order:** context → state → refs → memos → callbacks → effects

**Early returns:** Handle loading/error/empty before main logic

**Pure props:** Components are pure functions of props—never create internal state that contradicts props

## Domain Logic

- Separate from React: write testable pure functions in `domain/` first
- Use `useMemo` to call domain functions, not inline logic
- Extract complex memos to named functions

## Config-Driven UI

- Column definitions, presets, layouts—all from data structures
- Use `.map()` for repetitive JSX
- Save/load entire configurations

## Type Safety

- Generate types from backend: `pydantic2zod` in build pipeline
- Runtime validation at boundaries: `z.array(Schema).parse(data)`
- No duplicate type definitions

## Decision Tree

**New data?**
- Computed from existing? → `useMemo`
- Affects rendering? → `useState`
- Tracking/caching? → `useRef`

**Callback?**
- Passed to child? → `useCallback`
- Local only? → regular function

**useEffect?**
- Syncing state? → STOP, derive instead
- Subscription/DOM? → OK

## Checklist

- [ ] Derived state uses `useMemo` (not `useState` + `useEffect`)
- [ ] Context values memoized
- [ ] Dependency arrays: only reactive values
- [ ] Non-visual state uses refs
- [ ] Domain logic separated from components
- [ ] Components pure functions of props
