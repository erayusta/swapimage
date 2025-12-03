# TestFlight & App Store Review Rehberi

## 📱 TestFlight'a Yükleme Adımları

### 1. Xcode Hazırlıkları

#### A. Signing & Capabilities Ayarları
1. Xcode'da projeyi aç: `SwapImageCleaner.xcodeproj`
2. **TARGETS** → **SwapImageCleaner** seç
3. **Signing & Capabilities** sekmesine git
4. **Team**: Apple Developer hesabını seç
5. **Bundle Identifier**: Benzersiz bir ID gir (örn: `com.seninfirman.swapimagecleaner`)
6. **Automatically manage signing**: İşaretli olsun

#### B. Build Settings Kontrolü
1. **Build Settings** sekmesine git
2. **iOS Deployment Target**: En az `16.0` olmalı
3. **Swift Language Version**: `5.0` veya üstü

#### C. Info.plist Kontrolleri
Aşağıdaki izinlerin tanımlı olduğundan emin ol:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Fotoğraflarınızı görüntülemek ve temizlemek için galeri erişimi gereklidir.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Fotoğraflarınızı yönetmek için galeri erişimi gereklidir.</string>
```

### 2. Archive Oluşturma

1. **Product** → **Destination** → **Any iOS Device (arm64)** seç
2. **Product** → **Archive** tıkla
3. Build tamamlandığında **Organizer** penceresi açılacak

### 3. App Store Connect'e Yükleme

1. **Organizer**'da archive'ı seç
2. **Distribute App** tıkla
3. **App Store Connect** seç → **Next**
4. **Upload** seç → **Next**
5. Tüm seçenekleri varsayılan bırak → **Next**
6. **Upload** tıkla

### 4. App Store Connect Ayarları

#### A. Yeni Uygulama Oluşturma (İlk kez ise)
1. [App Store Connect](https://appstoreconnect.apple.com) aç
2. **My Apps** → **+** → **New App**
3. Bilgileri doldur:
   - **Platforms**: iOS
   - **Name**: Swap Image Cleaner
   - **Primary Language**: Turkish
   - **Bundle ID**: Xcode'daki ile aynı
   - **SKU**: Benzersiz bir kod (örn: `SWAPIMAGECLEANER001`)

#### B. App Information
- **Subtitle**: Gereksiz fotoğrafları kaydırarak temizle
- **Category**: Utilities veya Photo & Video
- **Content Rights**: "This app does not contain..."

#### C. Pricing and Availability
- **Price**: Free (veya istediğin fiyat)
- **Availability**: Tüm ülkeler veya seçili ülkeler

### 5. TestFlight Kurulumu

#### A. Internal Testing (Dahili Test)
1. **TestFlight** sekmesine git
2. **Internal Testing** → **App Store Connect Users**
3. Takım üyelerini ekle (max 100 kişi)
4. Build yüklendikten sonra otomatik dağıtılır

#### B. External Testing (Harici Test)
1. **External Testing** → **+** ile yeni grup oluştur
2. Grup adı gir (örn: "Beta Testers")
3. **Test Information** doldur:
   - **Beta App Description**: Uygulamanın ne yaptığını açıkla
   - **Feedback Email**: Geri bildirim için email
   - **What to Test**: Test edilmesi gereken özellikler
4. Build'i gruba ekle
5. **Submit for Review** tıkla (İlk external test için Apple review gerekli)

---

## 🍎 App Store Review'a Gönderme

### 1. Version Information

#### A. Screenshots (Zorunlu)
Her cihaz boyutu için ekran görüntüleri hazırla:
- **6.7" Display** (iPhone 15 Pro Max): 1290 x 2796 px
- **6.5" Display** (iPhone 11 Pro Max): 1242 x 2688 px
- **5.5" Display** (iPhone 8 Plus): 1242 x 2208 px

**Önerilen Screenshot İçerikleri:**
1. Ana swipe ekranı (fotoğraf kartı görünür)
2. Silme aksiyonu (sola kaydırma)
3. Tutma aksiyonu (sağa kaydırma)
4. Filtre paneli
5. Onboarding ekranı

#### B. App Preview (Opsiyonel ama Önerilen)
- 15-30 saniyelik video
- Uygulamanın nasıl çalıştığını göster

#### C. Description
Türkçe ve İngilizce açıklamalar `AppStoreMetadata.md` dosyasında mevcut.

#### D. Keywords
- TR: `fotoğraf temizleme, galeri düzenleme, gereksiz fotoğraf sil, albüm temizleme, hızlı silme`
- EN: `photo cleaner, gallery cleaner, delete duplicates, swipe delete, album clean`

### 2. App Review Information

#### A. Contact Information
- **First Name**: Adın
- **Last Name**: Soyadın
- **Phone Number**: Telefon numarası
- **Email**: Email adresi

#### B. Demo Account (Gerekli Değil)
Bu uygulama için demo hesap gerekmiyor çünkü kullanıcının kendi fotoğraflarını kullanıyor.

#### C. Notes for Review
```
Bu uygulama kullanıcının fotoğraf galerisine erişim izni ister. Test için:
1. Uygulamayı açın
2. Onboarding ekranlarını geçin
3. Fotoğraf erişim izni verin
4. Fotoğrafları sağa/sola kaydırarak test edin
5. Silme onayı geldiğinde "İzin Ver" veya "İzin Verme" seçeneklerini test edin

Uygulama hiçbir veriyi sunucuya göndermez, tüm işlemler cihazda gerçekleşir.
```

### 3. Age Rating
Questionnaire'i doldur:
- **Violence**: None
- **Sexual Content**: None
- **Profanity**: None
- **Drugs**: None
- **Gambling**: None
- **Horror**: None
- **Mature Themes**: None

**Sonuç**: 4+ yaş sınıfı

### 4. App Privacy

#### A. Privacy Policy URL
Bir privacy policy sayfası oluştur ve URL'ini gir.

#### B. Data Collection
**Data Types Collected**: None (veya minimal)

Bu uygulama için:
- ✅ **Photos or Videos**: Collected but not linked to identity
- ❌ Diğer tüm kategoriler: Not collected

### 5. Submit for Review

1. Tüm alanları doldur
2. **Add for Review** tıkla
3. **Submit to App Review** tıkla

---

## ⚠️ Sık Karşılaşılan Rejection Nedenleri ve Çözümleri

### 1. Guideline 5.1.1 - Data Collection and Storage
**Sorun**: Privacy policy eksik
**Çözüm**: Privacy policy URL'i ekle

### 2. Guideline 2.1 - App Completeness
**Sorun**: Crash veya bug
**Çözüm**: Tüm cihazlarda test et, crash loglarını kontrol et

### 3. Guideline 4.0 - Design
**Sorun**: Minimum fonksiyonellik
**Çözüm**: Uygulamanın değer kattığını göster (bu uygulama için sorun yok)

### 4. Guideline 5.1.2 - Data Use and Sharing
**Sorun**: Fotoğraf erişimi açıklaması yetersiz
**Çözüm**: Info.plist'teki açıklamayı detaylandır

---

## 📋 Pre-Submission Checklist

- [ ] Bundle ID benzersiz ve doğru
- [ ] Version number doğru (1.0.0)
- [ ] Build number artırıldı
- [ ] App icon tüm boyutlarda mevcut
- [ ] Launch screen düzgün çalışıyor
- [ ] Info.plist izin açıklamaları Türkçe/İngilizce
- [ ] Screenshots hazır (tüm cihaz boyutları)
- [ ] App description yazıldı
- [ ] Keywords belirlendi
- [ ] Privacy policy URL'i hazır
- [ ] Support URL'i hazır
- [ ] Marketing URL'i hazır (opsiyonel)
- [ ] Age rating questionnaire dolduruldu
- [ ] App privacy bilgileri girildi
- [ ] Review notes yazıldı
- [ ] Contact information güncel

---

## 🚀 Hızlı Komutlar

### Archive Oluşturma (Terminal)
```bash
cd /Users/erayusta/mobile/SwapImageCleaner
xcodebuild -project SwapImageCleaner.xcodeproj \
  -scheme SwapImageCleaner \
  -configuration Release \
  -archivePath build/SwapImageCleaner.xcarchive \
  archive
```

### IPA Export (Terminal)
```bash
xcodebuild -exportArchive \
  -archivePath build/SwapImageCleaner.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

---

## 📞 Destek

- **Apple Developer Support**: https://developer.apple.com/support/
- **App Store Connect Help**: https://help.apple.com/app-store-connect/
- **TestFlight Documentation**: https://developer.apple.com/testflight/

---

*Son güncelleme: Aralık 2024*
