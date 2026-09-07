# Product-gate result — 2026-09-07

## Target

Dell OptiPlex 780, Debian 13 amd64, KDE Plasma 6, legacy BIOS.

## Result

The ECZOS product batch and subsequent Windows-gate batch passed on the
physical host.

- SoftMaker FreeOffice 2024 package version 3702 installed from the signed
  SoftMaker APT repository.
- Every ECZOS package smoke test passed.
- A locally built harmless MSI installed into an isolated Wine prefix.
- The installed PE application received an extracted icon through the
  Bubblewrap-isolated parser path.
- Windows application repair and recoverable removal passed.
- The visible-branding audit completed. ECZOS now owns the console issue,
  issue.net, motd and GRUB background presentation through reversible package
  diversions.

## Remaining scope

This qualifies the development host product gates, not a public image. The
positive Vulkan/Proton test, broader real-app compatibility matrix, image
upgrade/rollback test, ISO boot/install test and FreeOffice release-artifact
pinning remain release gates.
