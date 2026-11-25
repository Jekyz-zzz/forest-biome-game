class_name BiomeData
extends RefCounted
## Data statis semua bioma: teks dialog, kuis, warna, dan mini-game-nya.
## Semua teks diambil dari dokumen desain "KEBANGKITAN".
##
## Format soal kuis:
##   "q":           teks soal
##   "options":     4 pilihan, urutan A-D sesuai storyboard
##   "answer":      indeks pilihan yang benar (0 = A, 1 = B, 2 = C, 3 = D)
##   "explanation": penjelasan yang tampil setelah pemain menjawab

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
				"text": "Aku penjaga rimba yang hanya hidup di Sumatera. Setiap jejakku menandakan hutan ini masih sehat. Jika rumahku hilang, aku pun ikut lenyap.",
			},
			{
				"name": "Rafflesia arnoldii",
				"text": "Aku bunga terbesar di dunia, tumbuh di rimba yang menjadi paru-paru dunia. Hutan ini menyaring udara dan menyimpan napas bagi kita semua.",
			},
		],
		"quiz": [
			{
				"q": "Hewan pemangsa langka yang hidup di hutan hujan Sumatera adalah...",
				"options": ["Komodo", "Bekantan", "Singa", "Harimau sumatera"],
				"answer": 3,
				"explanation": "Harimau sumatera hanya hidup liar di Pulau Sumatera. Kalau hutannya hilang, rumahnya ikut hilang.",
			},
			{
				"q": "Pohon raksasa khas hutan hujan yang menjulang tinggi adalah pohon...",
				"options": ["Akasia", "Bakau merah", "Meranti", "Kelapa"],
				"answer": 2,
				"explanation": "Meranti tumbuh tinggi di tanah yang sangat basah, hangat, dan lembap, dan teduhnya menjadi tempat hidup banyak makhluk.",
			},
			{
				"q": "Rafflesia arnoldii dikenal sebagai...",
				"options": [
					"Pohon tertinggi di dunia",
					"Bunga terbesar di dunia",
					"Rumput tertinggi",
					"Buah termanis",
				],
				"answer": 1,
				"explanation": "Rafflesia arnoldii tumbuh di lantai hutan hujan, dan bunganya bisa selebar sekitar satu meter.",
			},
			{
				"q": "Mengapa hutan hujan tropis sering disebut \"paru-paru dunia\"?",
				"options": [
					"Pohonnya menyerap karbon dioksida dan melepas oksigen",
					"Bentuknya mirip paru-paru",
					"Tidak punya pohon",
					"Membuat udara jadi beku",
				],
				"answer": 0,
				"explanation": "Lewat fotosintesis, pohon ikut menyaring udara dan menyimpan karbon.",
			},
			{
				"q": "Bagaimana cuaca di hutan hujan tropis?",
				"options": [
					"Kering dan berdebu",
					"Sangat basah, hangat, dan lembap sepanjang tahun",
					"Dingin dan bersalju",
					"Kemarau sangat panjang",
				],
				"answer": 1,
				"explanation": "Hujan turun hampir sepanjang tahun, jadi pepohonan bisa tumbuh tinggi dan rapat.",
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
				"text": "Aku penguasa padang di Nusa Tenggara Timur. Langkahku lambat, tapi aku tahu padang ini adalah satu-satunya rumahku.",
			},
			{
				"name": "Rumput Gajah",
				"text": "Aku makanan bagi para mamalia dan herbivora besar. Selama aku tumbuh, padang ini tetap menjadi habitat bagi mereka.",
			},
		],
		"quiz": [
			{
				"q": "Bagaimana cuaca di sabana?",
				"options": [
					"Hujan turun setiap hari",
					"Dingin dan bersalju",
					"Musim kemarau sangat panjang, kering, dan terik di siang hari",
					"Lembap dan berkabut sepanjang tahun",
				],
				"answer": 2,
				"explanation": "Air yang sedikit membuat rumput lebih mudah bertahan daripada pohon besar.",
			},
			{
				"q": "Kadal terbesar di dunia yang hidup di padang sabana Nusa Tenggara Timur adalah...",
				"options": ["Bunglon", "Komodo", "Cicak", "Bekantan"],
				"answer": 1,
				"explanation": "Komodo hanya hidup liar di Indonesia, di Nusa Tenggara Timur.",
			},
			{
				"q": "Rumput tinggi yang menjadi makanan penting bagi mamalia dan herbivora besar di sabana adalah rumput...",
				"options": ["Laut", "Teki", "Gajah", "Jepang"],
				"answer": 2,
				"explanation": "Rumput gajah membuat sabana tetap menjadi habitat bagi mamalia dan herbivora besar.",
			},
			{
				"q": "Pohon berkanopi lebar yang tahan kemarau dan tumbuh di padang sabana adalah...",
				"options": ["Meranti", "Bakau merah", "Akasia", "Api-api"],
				"answer": 2,
				"explanation": "Akasia tahan kering, dan teduhnya menjadi tempat berlindung hewan dari terik matahari.",
			},
			{
				"q": "Sabana di Indonesia banyak dijumpai di...",
				"options": [
					"Puncak gunung bersalju",
					"Nusa Tenggara Timur dan Nusa Tenggara Barat",
					"Dasar laut",
					"Tengah kota",
				],
				"answer": 1,
				"explanation": "Kemarau yang panjang di Nusa Tenggara membuat padang rumput lebih mudah tumbuh daripada hutan lebat.",
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
				"text": "Aku hanya hidup di hutan bakau Kalimantan. Dahan-dahan ini rumahku, tempat bermain, sekaligus tempat aku mencari makan.",
			},
			{
				"name": "Pohon Api-api",
				"text": "Bersama saudara-saudaraku, kami menjadi benteng pantai. Kami meredam ombak dan menahan abrasi agar daratan tidak ikut hanyut.",
			},
		],
		"quiz": [
			{
				"q": "Pohon utama mangrove yang akar tunjangnya menopang batang di dalam air adalah...",
				"options": ["Meranti", "Akasia", "Bakau merah", "Rumput gajah"],
				"answer": 2,
				"explanation": "Akar tunjang membuat bakau merah kokoh, tidak mudah tumbang walau diterjang pasang surut dan angin laut.",
			},
			{
				"q": "Monyet berhidung panjang yang hidup di hutan mangrove adalah...",
				"options": ["Bekantan", "Zebra", "Pinguin", "Singa"],
				"answer": 0,
				"explanation": "Bekantan memakan daun dan buah dari pepohonan mangrove. Kalau mangrove rusak, tempat tinggal dan makanannya ikut hilang.",
			},
			{
				"q": "Pohon api-api bersama pohon mangrove lainnya menjadi benteng pantai karena...",
				"options": [
					"Menambah tinggi ombak",
					"Mengeringkan air laut",
					"Membuat pantai makin sempit",
					"Meredam ombak dan menahan abrasi",
				],
				"answer": 3,
				"explanation": "Akar mangrove menahan gelombang, jadi daratan di belakangnya terlindung dari hantaman ombak.",
			},
			{
				"q": "Apa yang terjadi di hutan mangrove setiap hari?",
				"options": [
					"Salju turun",
					"Air laut pasang dan surut",
					"Tanah selalu kering",
					"Daun berubah warna",
				],
				"answer": 1,
				"explanation": "Air laut naik-turun setiap hari, makanya akar mangrove harus kokoh mencengkeram lumpur.",
			},
			{
				"q": "Hutan mangrove di Indonesia banyak dijumpai di...",
				"options": [
					"Pesisir Papua, Sumatera, dan Jawa",
					"Puncak gunung",
					"Gurun pasir",
					"Danau di dataran tinggi",
				],
				"answer": 0,
				"explanation": "Mangrove tumbuh di pesisir, di tempat air laut dan air sungai bertemu.",
			},
		],
	},
}


static func get_biome(biome_id: String) -> Dictionary:
	return BIOMES.get(biome_id, BIOMES["hujan"])


static func biome_ids() -> Array:
	return BIOMES.keys()
