# RhodoniteMBT_examples

Samples for [RhodoniteMBT](https://github.com/emadurandal/RhodoniteMBT).

This repository contains a minimal rotating cube sample built on:

- `emadurandal/rhodonite@0.1.6`
- `emadurandal/rhodonite_app_sdl3@0.1.6`
- `rhodonite-mbt`

## Native SDL3/WebGPU build

```sh
pnpm native
```

The native sample uses SDL3. Homebrew macOS include and library paths are configured in `cmd/native/moon.pkg`.

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

## TypeScript/Vite WebGPU build

```sh
pnpm --dir samples/typescript install
pnpm typescript
```

Then open the Vite URL shown in the terminal.

For build-only checks:

```sh
pnpm typescript:build
```
