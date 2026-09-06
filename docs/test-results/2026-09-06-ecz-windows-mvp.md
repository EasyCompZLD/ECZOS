# ECZ Windows MVP physical-host test — 2026-09-06

Host: Dell OptiPlex 780, Debian 13 amd64, KDE Plasma 6.

Test application: EasyVoice TV WebView2 Setup 0.1.1
SHA-256: `734f8b26530aed62d94461bdb28af023d7373bc9a6fb62382c7d0bb645fe4832`

Verified:

- `.exe` association opens the ECZ Windows confirmation workflow;
- Debian i386 and amd64 Wine runtimes coexist;
- a fresh per-application prefix is created;
- the unsafe Wine `Z:` root mapping is removed;
- a 32-bit self-extracting installer runs from internal `C:\ECZOS-Install`;
- the installer can start child processes from its internal temporary directory;
- the Windows Start Menu shortcut resolves to the verified executable inside
  the same prefix;
- an ECZOS desktop launcher is generated as `EasyVoice TV`;
- the generated launcher starts `EasyVoiceTV.exe` and its 64-bit Edge WebView2
  processes successfully;
- concurrent installation attempts are locked;
- installed application state is available in the ECZ Windows application
  manager.

Still outside this MVP test: MSI lifecycle, real executable icon extraction,
drive-letter grants, Proton, DXVK/VKD3D, game detection and GPU diagnostics.
