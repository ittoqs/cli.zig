# ⚡ zigman

> *Command Line* sederhana, cepat, dan ringan.

---

## 📌 Prasyarat

Telah terpasang compiler Zig:

* **Zig** (minimal versi `v0.13.0`)

---

## 🚀 Memulai (Getting Started)

Proyek ini menggunakan *Zig build system* bawaan. Dapat langsung dijalankan atau diuji tanpa langkah setup yang rumit.

### 1. Menjalankan

```bash
# Menjalankan langsung
zig build run

# Menjalankan dengan argumen tambahan
zig build run -- "Nama Kamu"
```

### 2. Pengujian (*Unit Testing*)

Proyek ini dilengkapi dengan *unit test* bawaan untuk memastikan stabilitas kode:

```bash
zig build test
```

---

## 🌐 Kompilasi Lintas Platform (*Cross-Compilation*)

Kemudahan *cross-compilation* tanpa memerlukan dependency tambahan.

```bash
# Kompilasi untuk Windows (x86_64)
zig build -Dtarget=x86_64-windows

# Kompilasi untuk Linux (x86_64)
zig build -Dtarget=x86_64-linux

# Kompilasi untuk macOS (Apple Silicon / aarch64)
zig build -Dtarget=aarch64-macos
```

📁 **Hasil Kompilasi:**  
Biner/file eksekusi yang telah dikompilasi akan tersimpan di direktori:
```text
zig-out/bin/
```

---
