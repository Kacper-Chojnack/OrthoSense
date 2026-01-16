# Fix: iOS Codesigning Error "resource fork, Finder information, or similar detritus not allowed"

## Problem
Build iOS kończy się błędem:
```
Failed to codesign Flutter.framework with identity ...
resource fork, Finder information, or similar detritus not allowed
```

## Przyczyna
macOS dodaje **extended attributes** (metadane) do plików, które blokują proces codesigning.

## Rozwiązanie

### 1. Wyczyść build directory
```bash
cd ~/Desktop/repo\ kacpra/OrthoSense

# Wyczyść wszystkie extended attributes z projektu
xattr -cr .

# Wyczyść build Flutter
flutter clean
```

### 2. Wyczyść cache Cocoapods
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
cd ..
```

### 3. Reinstaluj zależności
```bash
flutter pub get
cd ios
pod install
cd ..
```

### 4. Zbuduj ponownie
```bash
flutter run --release
```

---

## Rozwiązanie automatyczne (już naprawione w projekcie)

✅ **Projekt został zaktualizowany** - skrypt `Clean Extended Attributes` w Xcode teraz automatycznie usuwa extended attributes podczas każdego builda.

Jeśli nadal występują błędy, uruchom ręcznie:
```bash
# Z poziomu głównego katalogu projektu
find build -type f -exec xattr -c {} \; 2>/dev/null
```

---

## Profilaktyka

### Przed każdym buildem (opcjonalnie)
```bash
# Wyczyść tylko build directory
xattr -cr build/
```

### Jeśli problem się powtarza
```bash
# Sprawdź które pliki mają extended attributes
find . -type f -exec xattr -l {} \; | grep -v "^$"

# Usuń wszystkie extended attributes rekursywnie
xattr -cr .
```

---

## Inne częste błędy iOS

### "No valid code signing certificates were found"
- Sprawdź czy Team ID w `ios/Flutter/Developer.xcconfig` jest poprawny
- Uruchom ponownie: `./scripts/ios-setup.sh`

### "Pod install" zawiesza się
```bash
cd ios
rm -rf Pods Podfile.lock ~/Library/Caches/CocoaPods
pod install --repo-update
```

### Brak miejsca na dysku podczas buildu
- Wyczyść Xcode DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Wyczyść Flutter cache: `flutter clean`
