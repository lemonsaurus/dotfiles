# Keep native Winghostty mouse actions available

**Linear:** none
**Branch:** `lemon/micro-fix/fullscreen-clipboard`
**Created:** 2026-08-28

## Summary

Reserve Shift-modified mouse input for Winghostty while fullscreen terminal applications capture ordinary mouse input.

## Acceptance Criteria

- [x] Shift-drag uses Winghostty's native selection and copy-on-select.
- [x] Shift-right-click opens Winghostty's context menu.

## Architectural Decisions

- **Mouse escape**: Set `mouse-shift-capture` to `never` so applications cannot override the Shift bypass.

## Commit Plan

1. Reserve Shift for native Winghostty mouse actions.
