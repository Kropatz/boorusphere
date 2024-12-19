{
  description = "Boorusphere";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
        buildToolsVersion = "30.0.3";
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ buildToolsVersion ];
          platformVersions = [ "31" "30" "34" "33" "32" "29" ];
          abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
        };
        androidSdk = androidComposition.androidsdk;
      in {
        devShell = with pkgs;
          mkShell rec {
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
            JAVA_HOME = "${jdk17}";
            buildInputs = [ flutter androidSdk jdk17 dart ];
            shellHook = ''
              export ANDROID_SDK_ROOT JAVA_HOME;
              flutter config --no-analytics;
              flutter config --jdk-dir=$JAVA_HOME;
              '';
          };
      });
}
