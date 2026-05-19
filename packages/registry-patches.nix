{
  pkgs,
}:
rec {
  # vkd3d was added in revision 10. DXVK overrides added in fork for Intel Iris Xe
  # users where Wine's stock d3d11/dxgi falls back to WARP (Software-Renderer).
  one-vkd3d =
    (pkgs.writeText "vkd3d-dxvk-regedit-changes.reg" ''
      Windows Registry Editor Version 5.00

      [HKEY_CURRENT_USER\Software\Wine\DllOverrides]
      "d3d12"="native"
      "d3d12core"="native"
      "d3d11"="native"
      "d3d10core"="native"
      "dxgi"="native"
    '').outPath;

  combined = pkgs.linkFarm "registry-patches-combined" [
    {
      name = "one.reg";
      path = one-vkd3d;
    }
  ];
}
