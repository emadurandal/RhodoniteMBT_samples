# RhodoniteMBT_ex

MoonBit sample project for RhodoniteMBT.

This repository contains a minimal rotating cube sample built on:

- `emadurandal/rhodonite@0.1.6`
- `emadurandal/rhodonite_app_sdl3@0.1.6`

## Native SDL3/WebGPU build

```sh
moon run cmd/native --target native
```

The SDL3 package links against SDL3. On Homebrew macOS environments, use:

```sh
CPATH=/opt/homebrew/include LIBRARY_PATH=/opt/homebrew/lib moon run cmd/native --target native
```

If the build still reports unresolved `SDL_*` symbols while building `rhodonite_app_sdl3`, the dependency package's native-stub link step is not receiving `-lSDL3`; that needs to be fixed in `emadurandal/rhodonite_app_sdl3`.

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
