{
  callPackage,
  fetchzip,
  runCommand,
  lndir,
  zstd,
  lib,

  inputs,
  v3 ? true,
  wine-packages,
  apl-combined,
  ...
}:
let
  layer_3 = callPackage ./basePrefix.nix {
    inherit inputs wine-packages;
  };

  installers = callPackage ./sources.nix { };
  registry-patches = callPackage ./registry-patches.nix { };

  vkd3d = fetchzip {
    url = "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v3.0b/vkd3d-proton-3.0b.tar.zst";
    nativeBuildInputs = [ zstd ];
    hash = "sha256-/W5gmh+RrvCytjIL0CkqOepygrz2wHn2pJf0VAGj1Hs=";
  };

  # DXVK: D3D9/10/11 -> Vulkan translator. Needed on iGPUs (Intel Iris Xe) where
  # Wine's stock d3d11 fails to create a hardware device and Affinity falls back
  # to WARP (Software-Renderer), which in turn isn't implemented in Wine -> reine
  # GDI-Software-Rendering -> CPU am Anschlag. DXVK lets Affinity render via Vulkan.
  dxvk = fetchzip {
    url = "https://github.com/doitsujin/dxvk/releases/download/v2.4.1/dxvk-2.4.1.tar.gz";
    hash = "sha256-SD9ObbkwCdrlQN9WrH5iUXWhtlbuwVGgVBo6ZNVKsmA=";
  };

  inherit (wine-packages) wine wineserver;
in
runCommand "base-prefix-4" { } ''
  set -x -e

  mkdir -p $out
  cp -a ${layer_3}/. $out
  chmod -R +w $out
  export WINEPREFIX="$out"

  cp ${vkd3d}/x64/d3d12.dll "$WINEPREFIX/drive_c/windows/system32"
  cp ${vkd3d}/x64/d3d12core.dll "$WINEPREFIX/drive_c/windows/system32"

  # DXVK: D3D11 + D3D10core + DXGI -> Vulkan. The DXGI from DXVK supersedes Wine's
  # AND is compatible with vkd3d-proton (Proton uses this exact combo).
  cp ${dxvk}/x64/d3d11.dll "$WINEPREFIX/drive_c/windows/system32"
  cp ${dxvk}/x64/d3d10core.dll "$WINEPREFIX/drive_c/windows/system32"
  cp ${dxvk}/x64/dxgi.dll "$WINEPREFIX/drive_c/windows/system32"

  ${lib.getExe wine} regedit /S "${registry-patches.one-vkd3d}"

  ${lib.optionalString v3 ''
    ${lib.getExe lndir} ${installers.v3} "$WINEPREFIX/drive_c/Program Files/"

    pushd "$WINEPREFIX/drive_c/Program Files/Affinity/Affinity"
    cp -r "${apl-combined}/." .
    popd
  ''}

  ${lib.optionalString (!v3) ''
    ${lib.getExe lndir} ${installers.photo} "$WINEPREFIX/drive_c/Program Files/"
    ${lib.getExe lndir} ${installers.designer} "$WINEPREFIX/drive_c/Program Files/"
    ${lib.getExe lndir} ${installers.publisher} "$WINEPREFIX/drive_c/Program Files/"
  ''}

  ${lib.getExe wineserver} -w

  rm -rf $WINEPREFIX/drive_c/users/nixbld
''
