{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages.apl-combined = pkgs.callPackage ./apl-combined.nix {
        src = inputs.plugin-loader-src;
        v030-src = inputs.plugin-loader-v030-src;
      };
    };
}
