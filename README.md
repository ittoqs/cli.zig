# cli.zig
Konsol sederhana, dirancang untuk menjadi aplikasi Command Line Interface (CLI) multiplatform.

## Persyaratan
- Zig (minimal v0.13.0 disarankan)

## Cara Kompilasi dan Menjalankan

Kamu bisa mengompilasi dan menjalankan program menggunakan Zig build system:

```bash
# Untuk menjalankan langsung
zig build run

# Menjalankan dengan argumen
zig build run -- "Nama Kamu"
```

## Pengujian (Testing)

Proyek ini dilengkapi dengan unit test. Untuk menjalankannya:

```bash
zig build test
```

## Cross-Compilation

Salah satu kekuatan Zig adalah dukungannya untuk kompilasi lintas platform secara mudah.

```bash
# Kompilasi untuk Windows (x86_64)
zig build -Dtarget=x86_64-windows

# Kompilasi untuk Linux (x86_64)
zig build -Dtarget=x86_64-linux

# Kompilasi untuk macOS (aarch64)
zig build -Dtarget=aarch64-macos
```

File eksekusi hasil kompilasi akan berada di dalam folder `zig-out/bin/`.
