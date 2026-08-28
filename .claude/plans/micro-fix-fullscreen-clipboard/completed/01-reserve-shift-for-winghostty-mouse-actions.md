# Reserve Shift for Winghostty Mouse Actions

**Sequence:** 1 of 1
**Status:** complete
**Acceptance criteria:** Shift-drag selects natively and Shift-right-click opens the context menu.
**Depends on:** none
**Parallel-safe with:** none

## Goal

Shift-modified mouse actions always stay with Winghostty instead of being captured by fullscreen terminal applications.

## Approach

Use Winghostty's permanent Shift mouse-capture override in the tracked terminal config.

## Verification

- Reload Winghostty's config.
- In fullscreen Pi, Shift-drag text and paste it elsewhere.
- In fullscreen Pi, Shift-right-click and confirm the context menu opens.
