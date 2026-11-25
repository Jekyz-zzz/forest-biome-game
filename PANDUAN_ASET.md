# Panduan Ganti Aset & Atur Scene

## 1. Placeholder yang bisa diedit

Hampir semua latar dan properti sekarang berupa node **ColorRect** dengan
script `scripts/placeholder.gd` (class `Placeholder`). Blok warna ini bisa
langsung digeser, diubah ukurannya, dirotasi, dan diwarnai di editor Godot.

Cara memakai:

| Ingin dilakukan | Caranya |
| --- | --- |
| Geser / ubah ukuran | Pilih node di scene, lalu drag atau tarik handle di viewport 2D. |
| Ganti warna | Inspector → **Color**. |
| Ganti dengan gambar | Inspector → properti **Art** → *Load* PNG. Blok warna lama tetap tersimpan sebagai cadangan. |
| Atur warna gambar | Properti **Art Modulate**. |
| Kembali ke blok warna | Kosongkan properti **Art**. |

Catatan:

- Gambar **Art** ditampilkan oleh child `ArtPreview` yang dibuat otomatis saat
  game berjalan, jadi child itu tidak tersimpan di file `.tscn`.
- Filter tekstur placeholder memakai **Nearest**. Ganti lewat Inspector node
  bila ingin gambar halus.
- Jangan mengubah nama node yang dipakai skrip (daftar ada di bawah). Posisi,
  ukuran, warna, rotasi, dan **Art** aman diubah.

### Objek dinamis (rintangan, api, sampah, konfeti)

Objek yang muncul berkali-kali tidak dibuat dari kode, tetapi dari **prototipe**
di scene:

- Prototipe disembunyikan otomatis saat game berjalan, lalu diduplikasi.
- Ubah tampilan prototipe (warna/Art/ukuran) → semua objek yang muncul ikut
  berubah.
- Posisi kemunculan diatur lewat node **Marker2D** atau node **Spots**.

## 2. Menu Utama (`scenes/main_menu.tscn`)

| Yang ingin diubah | Caranya |
| --- | --- |
| Gambar latar | Timpa `assets/ui/main_menu_bg.png`. Rasio 45:32 (2880x2048). Jendela menu otomatis memakai rasio yang sama, jadi gambar tidak ter-crop. |
| Tombol PLAY / SETTING / EXIT | Node `Planks/PlayButton`, `Planks/SettingButton`, `Planks/ExitButton`. Area tombol menutupi seluruh papan (ekor sampai ujung panah) dan `rotation` mengikuti kemiringan papan; `pivot_offset` = tengah badan papan. Posisi teks di tengah badan papan diatur lewat metadata `text_margin_left` / `text_margin_right` (Inspector → Metadata). |
| Font tombol | `assets/fonts/MagicSound.ttf` (diatur di `scripts/main_menu.gd`). Ganti path `MENU_FONT_PATH` bila ingin font lain. |
| Ukuran font | Konstanta `PLANK_FONT_SIZE` (12) di `scripts/main_menu.gd`, seragam untuk ketiga papan; 12 dipilih agar SETTING muat di badan papan dengan margin. |
| Warna teks | Konstanta `INK`, `INK_HOVER`, `INK_PRESSED`, `CREAM_OUTLINE`, `SHADOW` di `scripts/main_menu.gd`. |
| Efek hover | `_on_plank_hover()` di `scripts/main_menu.gd`: tombol membesar (1.08x), menyala, dan bergoyang halus. Efek tekan ada di `_on_plank_down/up`. |
| Kredit | Tombol kecil `KREDIT` di kiri bawah; isi popup ada di `_open_credits()`. |

Catatan:

- Gambar latar sudah memuat judul **RIMBANA** dan papan kayu kosong, jadi teks
  tombol ditulis langsung di atas papan memakai Magic Sound.
- Jendela menu **1350 x 960** (area desain **640 x 455**). Saat masuk gameplay,
  jendela kembali ke **1440 x 810**.
- **SETTING** membuka popup musik/efek suara. **EXIT** menutup game.

## 3. Peta (`scenes/map.tscn`)

| Yang ingin diubah | Caranya |
| --- | --- |
| Gambar latar peta | Pilih node **Map** → Inspector → **Background** → *Load* gambar, atau timpa `assets/placeholders/map_background.png`. |
| Posisi zona | Pilih **Zones/ZoneHujan**, **ZoneSabana**, atau **ZoneMangrove** → drag di viewport. |
| Ukuran zona | Tarik handle, atau atur `offset_left/top/right/bottom`. |
| Gambar zona | Pilih zona → properti **Art** → *Load*, atau timpa `assets/placeholders/zone_hujan.png`, `zone_sabana.png`, `zone_mangrove.png`. |
| Judul / warna zona | Properti **Zone Title** dan **Accent**. |
| Tambah zona | Klik kanan **Zones** → *Instantiate Child Scene* → `scenes/biome_zone.tscn`, isi `Biome Id` dan `Zone Title`. |

Catatan:

- **Mangrove terkunci otomatis** sampai Hutan Hujan dan Hutan Sabana selesai
  (`GameState.is_biome_unlocked()`). Properti `Locked` hanya untuk pratinjau
  editor.
- Ikon gembok ada di node `LockOverlay/LockIcon`.

## 4. Penjelajahan (`scenes/explore.tscn`)

Semua latar, pohon, dan properti biome adalah node ColorRect di bawah
`Placeholders`:

| Grup node | Isi |
| --- | --- |
| `Sky`, `Hills/Hill1..8`, `Horizon` | Langit dan perbukitan. Warna di-tint otomatis sesuai biome. |
| `Soil`, `GroundTop`, `Water` | Tanah, permukaan tanah, dan air (khusus mangrove). |
| `GroundArt/Sabana` | Tanah bertekstur (`tiles/figma/tile_top_middle.png`, diulang sepanjang level, ikut bergulir). Tambah child bernama `Hujan`/`Mangrove` untuk bioma lain; `GroundTop` otomatis disembunyikan bila ada. |
| `GroundArt/Hujan` | Tanah 3 potong `tiles/ground_hujan_left/mid/right.png` (satuan anak = piksel gambar, skala di node `Hujan`). `Left` di awal level, `MidClip/Mid` diulang (texture repeat) 36x, `Right` di akhir setelah gerbang. `MidClip` memotong 12 baris teratas dan menutupi 24 kolom terakhir `Left` agar tidak muncul garis di sambungan. Garis rumput (baris 80 gambar) = permukaan collision y=324. |
| `Backdrop/Hujan`, `Backdrop/Sabana` | Latar diam (CanvasLayer di belakang dunia, tidak ikut bergulir). |
| `Mist/Mist1..6` | Kabut tipis. |
| `Decor/Decor01..14` | Pohon latar belakang (`Trunk`, `Canopy`, `Grass`). Satu set dipakai untuk semua biome dan di-tint otomatis. |
| `Props/Hujan`, `Props/Sabana`, `Props/Mangrove` | Properti khas tiap biome. Hanya grup biome aktif yang ditampilkan. |
| `Gate` | Gerbang akhir level: `Glow`, `PoleL`, `PoleR`. Posisi gerbang menentukan akhir level. |
| `GroundCollision`, `LeftWall`, `PlayerStart` | Collision dan titik awal pemain. Aman digeser. |

Catatan:

- Objek dialog (3 per biome) dibuat dari data di `scripts/biome_data.gd`; posisi
  x-nya diatur lewat `GameState`/`biome_data` dan area dialog.
- Panjang level dan posisi gerbang ada di konstanta `scripts/explore.gd`
  (`GATE_X`, panjang tanah). Kursor/tombol HUD tetap di layar.

## 5. Mini-game Hutan Hujan (`scenes/minigame_runner.tscn`)

Node yang bisa diedit:

| Node | Fungsi |
| --- | --- |
| `Placeholders/Sky`, `Ground`, `Moss`, `BgTrees` | Latar hutan, tanah, lumut, dan pohon belakang. |
| `Placeholders/TigerPrototype` | Bentuk harimau (diduplikasi saat game berjalan). |
| `Placeholders/RockPrototype`, `LogPrototype` | Bentuk rintangan batu dan kayu. |
| `PlayerStart`, `TigerStart`, `ObstacleSpawn` | Marker posisi awal pemain, harimau, dan munculnya rintangan. |
| `GroundCollision` | Collision tanah. Geser Y-nya untuk mengubah permukaan tanah. |

Inspector root **MinigameRunner**:

| Properti | Fungsi |
| --- | --- |
| `player_scene` | Scene pemain pengganti (default `scenes/player.tscn`). |
| `player_frames` | SpriteFrames animasi pemain pengganti. |
| `ground_top` | Posisi permukaan tanah (mengikuti `GroundCollision` saat mulai). |
| `obstacle_collision_size` | Ukuran kotak collision rintangan. |
| `base_speed`, `max_speed_bonus` | Kecepatan lari awal dan tambahannya. |
| `tiger_creep_base`, `tiger_creep_bonus` | Kecepatan harimau mendekat. |
| `jump_velocity` | Kekuatan lompat (makin negatif makin tinggi). |

## 6. Mini-game Api (`scenes/minigame_fire.tscn`)

| Node | Fungsi |
| --- | --- |
| `Placeholders/Sky`, `Sun`, `Hills/Hill1..4` | Langit, matahari, dan bukit sabana. |
| `Placeholders/Soil`, `DryGrass`, `Tufts/Tuft*` | Tanah kering dan rumput. |
| `Placeholders/FirePrototype` | Bentuk api (`Glow`, `Flame`, `Inner`), diduplikasi saat api muncul. |
| `Placeholders/Decals` | Tempat bekas terbakar ditambahkan saat game berjalan. |

Geser `FirePrototype` untuk mengubah bentuk api; skala api tumbuh otomatis
seiring waktu. Ikon kesehatan hutan digambar oleh skrip (`LeafIcon`).

## 7. Mini-game Sampah (`scenes/minigame_trash.tscn`)

| Node | Fungsi |
| --- | --- |
| `Placeholders/Sky`, `Water`, `Mud`, `MudTop` | Langit, air pasang, lumpur, dan garis pantai. |
| `Placeholders/Roots/Root1..9` | Akar bakau yang menjuntai. |
| `Placeholders/TrashSpots/Spot1..8` | Titik kemunculan sampah. Geser marker untuk memindahkan sampah. |
| `Placeholders/BottlePrototype` | Bentuk botol (`Body`, `Cap`). |
| `Placeholders/BagPrototype` | Bentuk kantong plastik (`Bag`, `Tie`). |

Sampah bisa diseret ke luar area akar untuk dibersihkan. Jumlah target ada di
konstanta `TOTAL_TRASH` di `scripts/minigame_trash.gd`.

## 8. Intro, Kuis, Toko, Hasil

| Scene | Node yang bisa diedit |
| --- | --- |
| `intro.tscn` | `Background`, `Sprout/Stem`, `Sprout/LeafL`, `Sprout/LeafR`, `StoryText`, `SkipButton`. |
| `quiz.tscn` | `Background/Base`, `Background/Rays/Ray1..5`, `Background/Leaves/Leaf1..10`, `Background/Shade`. Warna di-tint sesuai biome. |
| `shop.tscn` | `Background/Base`, `Background/Shelves/Shelf1..4`, `Background/Leaves/Leaf1..9`, `Background/Glow`. |
| `results.tscn` | `Background`, `ConfettiLeaf` (prototipe konfeti; diduplikasi saat hasil tampil). |

## 9. Font

- **Menu utama** memakai `assets/fonts/MagicSound.ttf`. Ukuran 12 dipilih agar
  teks SETTING muat di badan papan penunjuk arah.
- **UI lain** memakai theme global `assets/ui_theme.tres`.

Cara cepat mengganti font seluruh UI:

1. Taruh font `.ttf`/`.otf` di `assets/fonts/`.
2. Beri nama `ui_font.ttf` atau `ui_font.otf`.
3. Jalankan game; font otomatis dipakai di semua UI.

Cara lewat theme:

1. Buka `assets/ui_theme.tres`.
2. Isi **Default Font** di Inspector.
3. Simpan.

## 10. Resolusi & filter pixel

- Layar desain gameplay: **640 x 360**; jendela gameplay **1440 x 810**.
- Jendela menu **1350 x 960** dengan area desain **640 x 455** (45:32).
- Mode stretch: **canvas_items** dengan skala *fractional*.
- Tekan **F11** untuk fullscreen.
- Filter tekstur: **Nearest** (Project Settings → Rendering → Textures →
  Canvas Textures → Default Texture Filter, dan eksplisit di node gambar).
- Sprite karakter (pemain, harimau, batu, kayu) tetap pixel art dan diskalakan
  dengan Nearest. Untuk hasil paling rata, pakai jendela 1280x720 (2x) atau
  fullscreen 1920x1080 (3x).
