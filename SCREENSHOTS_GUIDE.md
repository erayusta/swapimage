# 📸 App Store Screenshots Rehberi

## Gerekli Ekran Boyutları

### iPhone Screenshots (Zorunlu)

| Cihaz | Boyut (px) | Açıklama |
|-------|------------|----------|
| **6.7" Display** | 1290 x 2796 | iPhone 15 Pro Max, 14 Pro Max |
| **6.5" Display** | 1242 x 2688 | iPhone 11 Pro Max, XS Max |
| **5.5" Display** | 1242 x 2208 | iPhone 8 Plus, 7 Plus, 6s Plus |

### iPad Screenshots (Opsiyonel ama Önerilen)

| Cihaz | Boyut (px) |
|-------|------------|
| **12.9" Display** | 2048 x 2732 |
| **11" Display** | 1668 x 2388 |

---

## 📱 Önerilen Screenshot Sırası

### Screenshot 1: Hero Shot - Ana Ekran
**Amaç**: Uygulamanın ne yaptığını tek bakışta anlat

```
┌─────────────────────────────┐
│                             │
│     [Fotoğraf Kartı]        │
│                             │
│   ← SİL    ATLA ↑   TUT →   │
│                             │
│  "Galerini Temizle"         │
│  "Kaydır ve Kararını Ver"   │
│                             │
└─────────────────────────────┘
```

**Metin Önerisi (TR)**: 
- Başlık: "Galerini Hızla Temizle"
- Alt: "Sağa kaydır tut, sola kaydır sil"

**Metin Önerisi (EN)**:
- Title: "Clean Your Gallery Fast"
- Subtitle: "Swipe right to keep, left to delete"

---

### Screenshot 2: Sola Kaydırma - Silme
**Amaç**: Silme aksiyonunu göster

```
┌─────────────────────────────┐
│                             │
│   [Kart sola eğik]          │
│   🗑️ SİL göstergesi         │
│                             │
│                             │
│  "Gereksiz Fotoğrafları     │
│   Tek Kaydırmayla Sil"      │
│                             │
└─────────────────────────────┘
```

**Metin Önerisi (TR)**:
- "Sola Kaydır = Sil"
- "Gereksiz fotoğraflardan kurtul"

---

### Screenshot 3: Sağa Kaydırma - Tutma
**Amaç**: Tutma aksiyonunu göster

```
┌─────────────────────────────┐
│                             │
│   [Kart sağa eğik]          │
│   ❤️ TUT göstergesi         │
│                             │
│                             │
│  "Sevdiklerini Koru"        │
│                             │
└─────────────────────────────┘
```

**Metin Önerisi (TR)**:
- "Sağa Kaydır = Tut"
- "Önemli anılarını koru"

---

### Screenshot 4: Filtre Paneli
**Amaç**: Filtreleme özelliklerini göster

```
┌─────────────────────────────┐
│  ┌─────────────────────┐    │
│  │ Filtreler           │    │
│  │ ─────────────────── │    │
│  │ 📁 Albüm Seç        │    │
│  │ 📅 Tarih Filtresi   │    │
│  │ 🎬 Medya Tipi       │    │
│  └─────────────────────┘    │
│                             │
│  "Albüm ve Tarihe Göre      │
│   Filtrele"                 │
│                             │
└─────────────────────────────┘
```

---

### Screenshot 5: Başarı Ekranı
**Amaç**: Temizlik tamamlandı hissini ver

```
┌─────────────────────────────┐
│                             │
│         ✨                  │
│   "Galerin Tertemiz!"       │
│                             │
│   [Yeniden Tara Butonu]     │
│                             │
│  "X fotoğraf silindi"       │
│  "Y fotoğraf tutuldu"       │
│                             │
└─────────────────────────────┘
```

---

## 🎨 Tasarım Kuralları

### Renkler
- **Arka Plan**: Aurora gradient (mor-mavi-pembe)
- **Silme**: Kırmızı (#FA6478)
- **Tutma**: Yeşil (#52DE9F)
- **Atlama**: Turuncu (#FFC86A)

### Font
- **Başlıklar**: SF Pro Display Bold
- **Alt Metinler**: SF Pro Text Medium
- **Boyutlar**: Minimum 40pt başlık, 24pt alt metin

### Çerçeve
- Cihaz çerçevesi kullan (mockup)
- Gölge ekle
- Gradient arka plan

---

## 🛠️ Screenshot Alma Yöntemleri

### Yöntem 1: Xcode Simulator
```bash
# Simulator'da screenshot al
xcrun simctl io booted screenshot screenshot.png

# Belirli cihaz için
xcrun simctl io "iPhone 15 Pro Max" screenshot screenshot_6.7.png
```

### Yöntem 2: Fastlane Snapshot
```ruby
# Fastfile
lane :screenshots do
  snapshot(
    devices: [
      "iPhone 15 Pro Max",
      "iPhone 14 Pro Max", 
      "iPhone 8 Plus"
    ],
    languages: ["tr-TR", "en-US"]
  )
end
```

### Yöntem 3: Manuel
1. Simulator'ı aç
2. Uygulamayı çalıştır
3. İstenen ekrana git
4. `Cmd + S` ile screenshot al

---

## 📝 App Store Metadata Checklist

### Uygulama Bilgileri
- [ ] App Name (30 karakter max): `Swipe Right - Photo Cleaner`
- [ ] Subtitle (30 karakter max): `Galerini kaydırarak temizle`
- [ ] Keywords (100 karakter max)
- [ ] Description (4000 karakter max)
- [ ] Promotional Text (170 karakter max)

### Görseller
- [ ] App Icon (1024x1024)
- [ ] Screenshots (minimum 3, maximum 10)
- [ ] App Preview Video (opsiyonel, 15-30 saniye)

### Yasal
- [ ] Privacy Policy URL
- [ ] Support URL
- [ ] Marketing URL (opsiyonel)

---

## 🎬 App Preview Video (Opsiyonel)

### Önerilen İçerik (15-30 saniye)
1. **0-5s**: Uygulama açılışı, logo
2. **5-15s**: Swipe aksiyonları (sil, tut, atla)
3. **15-25s**: Filtre kullanımı
4. **25-30s**: Başarı ekranı, call-to-action

### Teknik Gereksinimler
- Format: H.264, AAC
- Çözünürlük: Cihaz boyutuna uygun
- FPS: 30
- Ses: Opsiyonel (müzik veya sessiz)

---

## 🌍 Lokalizasyon

### Türkçe (tr-TR)
```
Başlık: Swipe Right - Fotoğraf Temizleyici
Alt Başlık: Galerini kaydırarak temizle
Anahtar Kelimeler: fotoğraf temizleme, galeri düzenleme, gereksiz fotoğraf sil, albüm temizleme, hızlı silme, depolama boşalt
```

### İngilizce (en-US)
```
Title: Swipe Right - Photo Cleaner
Subtitle: Clean your gallery by swiping
Keywords: photo cleaner, gallery cleaner, delete photos, swipe delete, storage cleanup, organize photos
```

---

## ✅ Final Checklist

### Screenshots
- [ ] 6.7" iPhone screenshots (en az 3)
- [ ] 6.5" iPhone screenshots (en az 3)
- [ ] 5.5" iPhone screenshots (en az 3)
- [ ] Tüm diller için ayrı screenshots
- [ ] Metin overlay'leri eklendi
- [ ] Cihaz mockup'ları kullanıldı

### Metadata
- [ ] Türkçe açıklamalar yazıldı
- [ ] İngilizce açıklamalar yazıldı
- [ ] Keywords optimize edildi
- [ ] Privacy Policy URL eklendi
- [ ] Support URL eklendi

### Teknik
- [ ] App Icon tüm boyutlarda mevcut
- [ ] Launch Screen düzgün çalışıyor
- [ ] Tüm cihazlarda test edildi

---

## 🔧 Hızlı Komutlar

### Tüm Simulator'ları Listele
```bash
xcrun simctl list devices
```

### Belirli Cihazı Başlat
```bash
xcrun simctl boot "iPhone 15 Pro Max"
open -a Simulator
```

### Screenshot Al
```bash
xcrun simctl io booted screenshot ~/Desktop/screenshot.png
```

### Video Kaydet
```bash
xcrun simctl io booted recordVideo ~/Desktop/apppreview.mov
```

---

*Son güncelleme: Aralık 2024*
