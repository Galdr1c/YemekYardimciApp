# Cihaz Bağlama Sorun Giderme Rehberi

## Cihaz Görünmüyor - Adım Adım Çözüm

### 1. USB Hata Ayıklama Kontrolü

**Android Cihazınızda:**
1. **Ayarlar** > **Telefon Hakkında** (veya **Cihaz Bilgisi**)
2. **Yapı Numarası**'na 7 kez dokunun (Geliştirici seçenekleri açılır)
3. **Ayarlar** > **Geliştirici Seçenekleri**
4. **USB Hata Ayıklama**'yı açın
5. **USB ile Yükleme**'yi açın (varsa)

### 2. USB Bağlantı Modu

Cihazınızda USB bağlantı modunu kontrol edin:
- **Dosya Aktarımı** (MTP) veya **PTP** modunu seçin
- Sadece şarj modu yeterli değil

### 3. USB Kablosu

- Orijinal USB kablosunu kullanın
- Veri aktarımı yapabilen bir kablo olmalı (sadece şarj kablosu değil)
- Farklı bir USB portu deneyin

### 4. Windows Sürücüleri

**Huawei Cihazlar İçin:**
1. [Huawei USB Driver](https://consumer.huawei.com/en/support/drivers/) indirin
2. Kurun ve bilgisayarı yeniden başlatın

**Diğer Cihazlar:**
- Cihaz üreticisinin USB sürücülerini indirin
- Google USB Driver (Android Studio ile gelir)

### 5. ADB Kontrolü

PowerShell'de şu komutları çalıştırın:

```powershell
# ADB yolunu kontrol et
where adb

# Cihazları listele
adb devices

# Eğer "unauthorized" görürseniz, cihazınızda izin verin
```

### 6. Flutter Cihaz Kontrolü

```powershell
cd D:\YemekYardimciApp
flutter devices
```

### 7. ADB Sunucusunu Yeniden Başlat

```powershell
adb kill-server
adb start-server
adb devices
```

### 8. Cihazda İzin Onayı

İlk bağlantıda cihazınızda bir uyarı çıkacak:
- **"Bu bilgisayara USB hata ayıklama izni verilsin mi?"**
- **"Bu bilgisayara her zaman izin ver"** kutusunu işaretleyin
- **İzin Ver**'e dokunun

### 9. Windows Defender / Güvenlik Duvarı

Bazen güvenlik yazılımları USB bağlantısını engelleyebilir:
- Geçici olarak devre dışı bırakın
- Veya ADB'ye izin verin

### 10. Farklı USB Portu

- USB 2.0 portu deneyin (USB 3.0 yerine)
- Bilgisayarın arka portlarını deneyin
- USB hub kullanıyorsanız, doğrudan bilgisayara bağlayın

## Hızlı Kontrol Listesi

- [ ] USB hata ayıklama açık mı?
- [ ] USB bağlantı modu "Dosya Aktarımı" mı?
- [ ] Orijinal USB kablosu kullanılıyor mu?
- [ ] USB sürücüleri yüklü mü?
- [ ] Cihazda izin verildi mi?
- [ ] ADB cihazı görüyor mu?
- [ ] Farklı USB portu denendi mi?

## Komutlar

```powershell
# Tüm kontroller
adb devices
flutter devices
adb kill-server
adb start-server
adb devices
```

## Hala Görünmüyorsa

1. Cihazı çıkarıp tekrar takın
2. Bilgisayarı yeniden başlatın
3. Cihazı yeniden başlatın
4. Farklı bir USB kablosu deneyin

