class_name BiomeData
extends RefCounted
## Data statis semua bioma: teks dialog, kuis, warna, dan mini-game-nya.
## Semua teks diambil dari dokumen desain "KEBANGKITAN".

const BIOMES := {
	"hujan": {
		"name": "Hutan Hujan Tropis",
		"short_name": "Hutan Hujan",
		"hint": "Geser ke kanan untuk menjelajah. Dekati objek untuk mengenalnya.",
		"gate_text": "Hutan ini sedang diburu bahaya. Maukah kamu menyelamatkan penghuninya?",
		"briefing": "Lari dari terkaman Harimau Sumatera!",
		"tutorial": "Tap / tekan Spasi untuk melompat dan menghindar dari harimau!",
		"minigame_scene": "res://scenes/minigame_runner.tscn",
		"sky": Color("15352a"),
		"far": Color("1f4a37"),
		"ground": Color("3b2b1a"),
		"ground_top": Color("4f8c3f"),
		"accent": Color("66bb6a"),
		"objects": [
			{
				"name": "Pohon Meranti",
				"text": "Aku menjulang tinggi di tanah yang basah, hangat, dan lembap sepanjang tahun. Hujan nyaris tak pernah berhenti menyapuku, dan di bawah teduhku, ribuan kehidupan tumbuh.",
			},
			{
				"name": "Harimau Sumatera",
				"text": "Aku penjaga rimba yang hidup di Sumatera dan Kalimantan. Setiap jejakku menandakan hutan ini masih sehat. Jika rumahku hilang, aku pun ikut lenyap.",
			},
			{
				"name": "Rafflesia arnoldi",
				"text": "Aku bunga terbesar di dunia, tumbuh di rimba yang menjadi paru-paru dunia. Hutan ini menyaring udara dan menyimpan napas bagi kita semua.",
			},
		],
		"quiz": [
			{
				"q": "Apa pohon utama di Hutan Hujan Tropis?",
				"options": ["Meranti", "Akasia", "Bakau merah"],
				"answer": 0,
			},
			{
				"q": "Hewan apa yang menjadi penjaga rimba di hutan ini?",
				"options": ["Harimau Sumatera", "Bekantan", "Komodo"],
				"answer": 0,
			},
			{
				"q": "Bunga terbesar di dunia yang tumbuh di hutan hujan adalah...",
				"options": ["Rafflesia arnoldi", "Anggrek bulan", "Melati"],
				"answer": 0,
			},
			{
				"q": "Hutan hujan tropis dikenal sebagai...",
				"options": ["Paru-paru dunia", "Benteng abrasi pantai", "Lumbung pangan dunia"],
				"answer": 0,
			},
			{
				"q": "Di mana saja hutan hujan tropis banyak dijumpai di Indonesia?",
				"options": ["Sumatera dan Kalimantan", "NTT dan NTB", "Jawa saja"],
				"answer": 0,
			},
		],
	},
	"sabana": {
		"name": "Hutan Sabana",
		"short_name": "Hutan Sabana",
		"hint": "Geser ke kanan untuk menjelajah. Dekati objek untuk mengenalnya.",
		"gate_text": "Api mulai menjalar di padang. Maukah kamu memadamkannya?",
		"briefing": "Padamkan api dan jangan biarkan menyebar!",
		"tutorial": "Tap api sebelum menyebar!",
		"minigame_scene": "res://scenes/minigame_fire.tscn",
		"sky": Color("f0c060"),
		"far": Color("d8a44a"),
		"ground": Color("8a6b3f"),
		"ground_top": Color("c4b25c"),
		"accent": Color("e6c35c"),
		"objects": [
			{
				"name": "Pohon Akasia",
				"text": "Aku berdiri di tanah yang dilanda kemarau panjang dan kering. Siang hari terik membakar, tapi teduhku jadi tempat berlindung bagi siapa pun yang lelah.",
			},
			{
				"name": "Komodo",
				"text": "Aku penguasa padang di Nusa Tenggara Timur dan Nusa Tenggara Barat. Langkahku lambat, tapi aku tahu padang ini adalah satu-satunya rumahku.",
			},
			{
				"name": "Rumput Gajah",
				"text": "Aku makanan bagi para mamalia dan herbivora besar. Selama aku tumbuh, padang ini tetap menjadi habitat bagi mereka.",
			},
		],
		"quiz": [
			{
				"q": "Apa pohon utama yang tumbuh di Hutan Sabana?",
				"options": ["Akasia", "Meranti", "Bakau merah"],
				"answer": 0,
			},
			{
				"q": "Hewan penguasa padang sabana di Nusa Tenggara adalah...",
				"options": ["Komodo", "Harimau Sumatera", "Bekantan"],
				"answer": 0,
			},
			{
				"q": "Tumbuhan yang menjadi makanan herbivora besar di sabana adalah...",
				"options": ["Rumput Gajah", "Rafflesia arnoldi", "Pohon api-api"],
				"answer": 0,
			},
			{
				"q": "Bagaimana cuaca di hutan sabana?",
				"options": [
					"Kemarau sangat panjang dan kering",
					"Basah dan lembap sepanjang tahun",
					"Angin laut kencang tiap hari",
				],
				"answer": 0,
			},
			{
				"q": "Sabana di Indonesia banyak dijumpai di...",
				"options": ["NTT dan NTB", "Sumatera dan Kalimantan", "Papua dan Jawa"],
				"answer": 0,
			},
		],
	},
	"mangrove": {
		"name": "Hutan Mangrove",
		"short_name": "Hutan Mangrove",
		"hint": "Geser ke kanan untuk menjelajah. Dekati objek untuk mengenalnya.",
		"gate_text": "Bantu bersihkan hutan mangrove?",
		"briefing": "Tarik sampah sampai bersih!",
		"tutorial": "Tarik sampah ke luar dari akar bakau!",
		"minigame_scene": "res://scenes/minigame_trash.tscn",
		"sky": Color("8fc7c2"),
		"far": Color("5f9e9a"),
		"ground": Color("5b4632"),
		"ground_top": Color("6d8a4f"),
		"accent": Color("7ec8a9"),
		"objects": [
			{
				"name": "Bakau Merah",
				"text": "Aku tumbuh di antara panas, lembap, dan angin laut yang kencang. Air pasang datang dan pergi tiap hari, tapi akarku tetap kokoh menahan semuanya.",
			},
			{
				"name": "Bekantan",
				"text": "Aku tinggal di hutan bakau Papua, Sumatera, dan Jawa. Dahan-dahan ini rumahku, tempat bermain, sekaligus tempat aku mencari makan.",
			},
			{
				"name": "Pohon Api-api",
				"text": "Bersama saudara-saudaraku, kami menjadi benteng pantai. Kami meredam ombak dan menahan abrasi agar daratan tidak ikut hanyut.",
			},
		],
		"quiz": [
			{
				"q": "Apa pohon utama di Hutan Mangrove?",
				"options": ["Bakau merah", "Akasia", "Meranti"],
				"answer": 0,
			},
			{
				"q": "Hewan berhidung panjang yang hidup di hutan bakau adalah...",
				"options": ["Bekantan", "Komodo", "Orang utan"],
				"answer": 0,
			},
			{
				"q": "Tumbuhan dengan akar napas yang mencuat dari lumpur adalah...",
				"options": ["Pohon api-api", "Rumput gajah", "Paku-pakuan"],
				"answer": 0,
			},
			{
				"q": "Apa manfaat utama hutan mangrove bagi pantai?",
				"options": ["Benteng abrasi pantai", "Paru-paru dunia", "Sumber minyak bumi"],
				"answer": 0,
			},
			{
				"q": "Hutan mangrove di Indonesia banyak dijumpai di...",
				"options": ["Papua, Sumatera, dan Jawa", "NTT dan NTB", "Kalimantan saja"],
				"answer": 0,
			},
		],
	},
}


static func get_biome(biome_id: String) -> Dictionary:
	return BIOMES.get(biome_id, BIOMES["hujan"])


static func biome_ids() -> Array:
	return BIOMES.keys()
