{
  callPackage,
  symlinkJoin,
  src,
  v030-src,
  ...
}:
let
  version = "unstable";

  apl = callPackage ./apl.nix {
    inherit version src;
  };

  bootstrap = callPackage ./bootstrap.nix {
    inherit version src;
  };

  # Native d2d1 build from v0.3.0 plus our bezier recursion guard patch.
  # Avoids the Wine 9.13 stock d2d1 delay-load failure that crashes
  # serif.interop.persona at startup, while preventing the infinite
  # recursion hang that the dev-branch C# patches would normally guard
  # against (but can't, because their byte patterns target Wine 9.13).
  d2d1 = callPackage ./d2d1.nix {
    inherit version;
    src = v030-src;
  };
in
symlinkJoin {
  pname = "apl-combined";
  inherit version;
  paths = [
    apl
    bootstrap
    d2d1
  ];

  postBuild = ''
    mv $out/lib/AffinityPluginLoader/* $out
    rm -rf $out/lib
  '';
}
