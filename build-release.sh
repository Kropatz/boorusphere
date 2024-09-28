#/usr/bin/env bash
# Get version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d "+" -f1)
BUILD_NUMBER=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d "+" -f2)

if [[ -z "$VERSION" ]]; then
  echo "Version not found in pubspec.yaml. Exiting..."
  exit 1
fi
if [[ -z "$BUILD_NUMBER" ]]; then
  echo "Build number not found in pubspec.yaml. Exiting..."
  exit 1
fi

# Function to rename files
rename_apk() {
  ARCH=$1
  if [ -f app-$ARCH-release.apk ]; then
    mv app-$ARCH-release.apk boorusphere-$VERSION-$ARCH.apk
    mv app-$ARCH-release.apk.sha1 boorusphere-$VERSION-$ARCH.apk.sha1
    echo "Renamed app-$ARCH-release.apk to boorusphere-$VERSION-$ARCH.apk"
  else
    echo "File app-$ARCH-release.apk not found. Skipping..."
  fi
}

# Build release APKs
echo "Building universal APK..."
flutter build apk --build-number=$BUILD_NUMBER --build-name=$VERSION --release
echo "Building ABI-specific APKs..."
flutter build apk --split-per-abi --build-number=$BUILD_NUMBER --build-name=$VERSION --release

# Rename APK files based on architecture
cd build/app/outputs/flutter-apk
rename_apk "arm64-v8a"
rename_apk "armeabi-v7a"
rename_apk "x86_64"

# Handle the universal APK (if any)
if [ -f app-release.apk ]; then
  mv app-release.apk boorusphere-$VERSION-universal.apk
  mv app-release.apk.sha1 boorusphere-$VERSION-universal.apk.sha1
  echo "Renamed app-release.apk to boorusphere-$VERSION-universal.apk"
else
  echo "File app-release.apk not found. Skipping..."
fi
