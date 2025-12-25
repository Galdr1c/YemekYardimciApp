# Java 17 Kurulum Rehberi

## Sorun
Java 25 çok yeni ve Gradle ile uyumlu değil. Java 17 kullanmamız gerekiyor.

## Çözüm: Java 17 İndirin ve Kurun

### Adım 1: Java 17 İndirin
1. Bu linke gidin: https://adoptium.net/temurin/releases/?version=17
2. **Windows x64** için **.msi** dosyasını indirin
3. İndirilen dosyayı çalıştırın ve kurulumu tamamlayın

### Adım 2: Flutter'a Java 17'yi Söyleyin
Kurulum tamamlandıktan sonra şu komutu çalıştırın:

```powershell
flutter config --jdk-dir="C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot"
```

(Kurulum yoluna göre güncelleyin - genellikle `C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot`)

### Adım 3: Kontrol Edin
```powershell
flutter doctor -v
```

Java versiyonunun 17 olduğunu görmelisiniz.

### Adım 4: Uygulamayı Çalıştırın
```powershell
cd D:\YemekYardimciApp
flutter clean
flutter run
```

## Alternatif: Hızlı Çözüm (Geçici)

Eğer şimdilik Java 17 kurmak istemiyorsanız, Gradle'ı daha eski bir Java versiyonu ile çalışacak şekilde ayarlayabiliriz, ama bu ideal değil.

