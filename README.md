# RhodoniteMBT_ex

MoonBit sample project for RhodoniteMBT.

This repository contains a minimal rotating cube sample built on:

- `emadurandal/rhodonite@0.1.6`
- `emadurandal/rhodonite_app_sdl3@0.1.6`

## Native SDL3/WebGPU build

```sh
pnpm native
```

The native sample uses SDL3. On Homebrew macOS environments, the script adds the SDL3 include path before invoking `moon run`.

For build-only checks:

```sh
pnpm native:build
```

## Browser JS/WebGPU build

```sh
pnpm browser
```

Then open:

```text
http://localhost:8081/public/
```

The browser sample requires WebGPU support.
