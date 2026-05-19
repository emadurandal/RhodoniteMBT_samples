# RhodoniteMBT_ex

MoonBit sample project for RhodoniteMBT.

This repository contains a minimal rotating cube sample built on:

- `emadurandal/rhodonite@0.1.6`
- `emadurandal/rhodonite_app_sdl3@0.1.6`

## Native SDL3/WebGPU build

```sh
./scripts/run-native.sh
```

The native sample uses SDL3. On Homebrew macOS environments, the script adds the SDL3 include path before invoking `moon run`.

For build-only checks:

```sh
CPATH=/opt/homebrew/include:/usr/local/include moon run cmd/native --target native --build-only
```

## Browser JS/WebGPU build

```sh
moon run cmd/browser --target js --build-only
python3 -m http.server 8080
```

Then open:

```text
http://localhost:8080/public/
```

The browser sample requires WebGPU support.
