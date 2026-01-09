# 📱 Instalacja OrthoSense na iPhone (Zosia)

## Wymagania
- Mac z sklonowanym projektem OrthoSense
- Kabel do iPhone'a
- ~5 minut

---

## Krok 1: Podłącz iPhone
1. Podłącz kabel do Maca
2. Na iPhone kliknij **"Zaufaj"** i wpisz PIN

## Krok 2: Terminal - zbuduj i zainstaluj

```bash
cd ~/OrthoSense

# Zbuduj aplikację
flutter build ios --release --dart-define=API_URL=https://xpcua8sib3.eu-central-1.awsapprunner.com

# Znajdź ID telefonu
xcrun devicectl list devices

# Zainstaluj (zamień TWOJE_ID na ID z listy powyżej)
xcrun devicectl device install app --device "TWOJE_ID" build/ios/iphoneos/Runner.app
```

## Krok 3: Zaufaj deweloperowi
1. **Ustawienia** → **Ogólne** → **Zarządzanie urządzeniem**
2. Znajdź profil Apple Development
3. Kliknij **"Zaufaj"**

## Krok 4: Gotowe! 🎉
Otwórz aplikację z ekranu głównego.

---

## ⚠️ Ważne
- Aplikacja działa **7 dni**, potem powtórz instalację
- Potrzebujesz **internetu** do połączenia z serwerem

## 🐛 Znalazłaś bug?
Zapisz: co robiłaś → co się stało → co powinno się stać + screenshot
