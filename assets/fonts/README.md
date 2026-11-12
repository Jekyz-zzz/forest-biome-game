# Ganti Font UI

Semua teks game memakai satu theme global: `assets/ui_theme.tres`.

## Cara cepat (drop-in)

1. Taruh file font `.ttf` atau `.otf` di folder ini.
2. Beri nama salah satu dari:
   - `ui_font.ttf`
   - `ui_font.otf`
   - `UI_Font.ttf`
   - `UI_Font.otf`
3. Jalankan game. Font otomatis dipakai untuk seluruh UI.

## Cara lewat Theme

1. Buka `assets/ui_theme.tres` di Godot.
2. Di Inspector, isi properti **Default Font** dengan file font-mu.
3. Simpan scene/proyek.

Kalau dua-duanya dipakai, file drop-in di folder ini yang menang.

Catatan: `MagicSound.ttf` dipakai khusus untuk tombol menu utama
(`scripts/main_menu.gd`), bukan sebagai font global. Mengganti nama file itu
akan membuat menu kembali memakai font theme.

Ukuran font per komponen tetap diatur lewat kode/Inspector, jadi mengganti
font tidak akan mengubah tata letak besar-besaran.
