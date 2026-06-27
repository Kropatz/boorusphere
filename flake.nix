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
            "35"
          ];
          abiVersions = [
            "armeabi-v7a"
            "arm64-v8a"
          ];
          ndkVersions = [ "28.2.13676358" ];
          includeNDK = true;
        };
        androidSdk = androidComposition.androidsdk;
        emu = pkgs.androidenv.emulateApp {
          name = "emulator-boorusphere";
          platformVersion = "33";
          abiVersion = "x86_64";
          systemImageType = "google_apis_playstore";
          configOptions = {
            "hw.gpu.enabled" = "yes";
          };
        };
        run-emulator = pkgs.writeShellScriptBin "run-emulator" "${pkgs.steam-run}/bin/steam-run ${emu}/bin/run-test-emulator $@";
        includeAndroid = false;
        includeLinux = true;
      in
      {
        devShell =
          with pkgs;
          mkShell rec {
            buildInputs = [
              flutter
              dart
            ]
            ++ lib.optionals includeAndroid [
              androidSdk
              jdk17
              pkgsCmake22.cmake
              #run-emulator # uncomment to include the emulator in the dev shell
            ]
            ++ lib.optionals includeLinux [
              xdg-user-dirs
              libpulseaudio
            ];
            shellHook = lib.concatLines [
              ''
                export ANDROID_SDK_ROOT JAVA_HOME ANDROID_NDK_HOME;
                flutter config --no-analytics;
                flutter config --jdk-dir=$JAVA_HOME;
              ''
              (
                if includeLinux then
                  ''
                    export LD_LIBRARY_PATH=${
                      lib.makeLibraryPath [
                        libpulseaudio
                        alsa-lib
                        lz4.lib
                        libGL
                        libX11
                        libgbm
                        libdrm
                        libva
                        libvdpau
                      ]
                    }:$LD_LIBRARY_PATH
                  ''
                else
                  ""
              )
            ];
          }
          // lib.optionalAttrs includeAndroid {
            JAVA_HOME = "${jdk17}";
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
            ANDROID_NDK_HOME = "${androidSdk}/libexec/android-sdk/ndk/28.2.13676358";
          };
      }
    );
}
