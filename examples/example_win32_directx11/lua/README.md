# Lua UI migration

The migration is being done in stages so the existing Windows renderer remains
usable while UI ownership moves from C++ to Lua. The target boundary is:

- **Lua:** page composition, navigation, UI state, settings controls and page-level
  interactions.
- **Native C++ host:** Win32 window/events, DXGI desktop capture, Direct3D 11,
  HLSL glass rendering, audio/media capture, and a small UI bridge.

`ui.lua` is the Lua-owned entry point. It defines the page registry, state, lazy
page loading, navigation, and calls the native bridge through a deliberately
small `ui` table. Page modules must return a table with `draw(ui, state)`.

## Migration status

This commit establishes the Lua UI contract and page registry. The existing ImGui
UI is still the active renderer until the Lua runtime and native widget bridge are
integrated. The page implementations and custom widget kit have not yet been
ported; they must be migrated page-by-page before the native UI can be removed.

## Planned sequence

1. Add and test the embedded Lua runtime and ImGui widget bridge.
2. Port shared UI state, theme/style, cards, navigation, and dialogs.
3. Port the login and dashboard shell, then each page module.
4. Port overlays, command palette, profile menu, notifications, and showcase
   widgets; compare behavior against the existing UI.
5. Make the Lua renderer the default, remove the old C++ page/UI composition, and
   update Windows build/CI and documentation.

The bridge should pass plain values and callbacks only. Lua scripts must not own
COM pointers or call Win32/D3D APIs directly.
