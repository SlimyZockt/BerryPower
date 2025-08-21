{
  description = "Raylib development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
      wgpu-native-static = pkgs.wgpu-native.overrideAttrs (old: {
        postInstall = ''
          install -Dm644 ./ffi/wgpu.h -t $dev/include/webgpu
          install -Dm644 ./ffi/webgpu-headers/webgpu.h -t $dev/include/webgpu
        '';
      });

      odin-with-wgpu = pkgs.odin.overrideAttrs {
        buildInputs = [ wgpu-native-static ];

        postInstall = ''
          mkdir $out/share/vendor/wgpu/lib/wgpu-linux-x86_64-release/
          ln -s ${wgpu-native-static}/lib/ $out/share/vendor/wgpu/lib/wgpu-linux-x86_64-release/
        '';
      };

      packages =
        with pkgs;
        [
          raylib
          wgpu-utils
          fish
        ]
        ++ [
          odin-with-wgpu
        ];
    in
    {
      devShells."${system}".default = pkgs.mkShell {
        nativeBuildInputs = packages;

        shellHook = ''
          export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath packages}:$LD_LIBRARY_PATH
          export LIBGL_ALWAYS_SOFTWARE=1
          export DISPLAY=:0
          export XDG_SESSION_TYPE=x11
          export GDK_BACKEND=wayland
          export SDL_VIDEODRIVER=wayland

          echo "Odin environment running"
          fish
        '';
      };

    };
}
