# HMS Core Kurulum Rehberi (Huawei Cihazlar İçin)

## Huawei Cihazlar İçin Özel Destek

Uygulama artık Huawei cihazlar için HMS Core desteği içeriyor. Google Play Services yerine HMS Core kullanılır.

## Kurulum Adımları

### 1. HMS Core AppGallery Connect'te Proje Oluşturun

1. [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) sitesine gidin
2. Yeni bir proje oluşturun
3. Uygulamanızı ekleyin

### 2. ML Kit API Key Alın

1. AppGallery Connect'te projenizi açın
2. **Geliştirme** > **ML Kit** bölümüne gidin
3. **Image Classification** servisini etkinleştirin
4. API Key'inizi kopyalayın

### 3. API Key'i Uygulamaya Ekleyin

**AndroidManifest.xml'de:**
```xml
<meta-data
    android:name="com.huawei.hms.client.appid"
    android:value="appid=YOUR_HMS_APP_ID"/>
```

**ml_service_hms.dart dosyasında:**
```dart
await MLApplication().setApiKey("YOUR_HMS_API_KEY_HERE");
```

### 4. HMS Core SDK'yı İndirin

HMS Core SDK'sı otomatik olarak pub.dev'den indirilecektir. Manuel kurulum gerekmez.

## Özellikler

- ✅ **Otomatik Algılama**: Uygulama Huawei cihazı otomatik algılar
- ✅ **HMS ML Kit**: Google ML Kit yerine HMS ML Kit kullanır
- ✅ **Geriye Dönük Uyumluluk**: Google cihazlarda normal çalışmaya devam eder
- ✅ **Aynı API**: Kod değişikliği gerekmez, otomatik geçiş yapar

## Test Etme

1. Huawei cihazınızda uygulamayı çalıştırın
2. Kamera ile fotoğraf çekin
3. ML analizi HMS Core ile çalışacaktır

## Sorun Giderme

### HMS Core Yüklü Değil
- AppGallery'den HMS Core'u yükleyin
- Cihazınızı güncelleyin

### API Key Hatası
- AppGallery Connect'te API Key'in doğru olduğundan emin olun
- ML Kit servisinin etkin olduğunu kontrol edin

### ML Analizi Çalışmıyor
- İnternet bağlantınızı kontrol edin
- HMS Core'un güncel olduğundan emin olun

## Notlar

- HMS Core sadece Huawei cihazlarda çalışır
- Google cihazlarda Google ML Kit kullanılmaya devam eder
- Her iki platformda da aynı sonuçlar alınır

