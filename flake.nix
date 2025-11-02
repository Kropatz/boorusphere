{
  description = "Boorusphere";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-cmake22.url = "github:nixos/nixpkgs/f76bef61369be38a10c7a1aa718782a60340d9ff";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-cmake22,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
        pkgsCmake22 = import nixpkgs-cmake22 {
          inherit system;
        };
        buildToolsVersion = "34.0.0";
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ buildToolsVersion ];
          platformVersions = [
            "31"
            "30"
            "34"
            "33"
            "32"
            "29"
            "27"
            "35"
          ];
          abiVersions = [
            "armeabi-v7a"
            "arm64-v8a"
          ];
          ndkVersions = [ "27.0.12077973" ];
          includeNDK = true;
        };
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell =
          with pkgs;
          mkShell rec {
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
            ANDROID_NDK_HOME = "${androidSdk}/libexec/android-sdk/ndk/27.0.12077973";
            JAVA_HOME = "${jdk17}";
            buildInputs = [
              flutter
              androidSdk
              jdk17
              dart
              pkgsCmake22.cmake
            ];
            shellHook = ''
              export ANDROID_SDK_ROOT JAVA_HOME ANDROID_NDK_HOME;
              flutter config --no-analytics;
              flutter config --jdk-dir=$JAVA_HOME;
            '';
          };
      }
    );
}
