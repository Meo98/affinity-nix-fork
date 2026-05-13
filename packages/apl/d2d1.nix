{ stdenv, ... }:
# dev branch removed WineFix/lib/d2d1 — D2D1 fixes are now pure .NET
# (WidenStubPatch + BezierSplitBudgetPatch + BezierSplitGuardPatch via NativeHook)
stdenv.mkDerivation {
  pname = "d2d1";
  version = "unstable";
  dontUnpack = true;
  installPhase = "mkdir -p $out";
}
