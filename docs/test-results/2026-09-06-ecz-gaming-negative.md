# ECZ Gaming negative hardware test — 2026-09-06

## Target

- Dell OptiPlex 780
- Debian 13 amd64
- Intel Q45/Q43 integrated graphics using `i915`
- Pentium Dual-Core E5800 without AVX
- 2924 MiB physical memory

## Result

`eczos-gaming-core` 0.1.0~dev1 built and installed successfully. Its installed
package smoke test passed. The doctor found only the llvmpipe CPU Vulkan device
and correctly returned `unsupported`; it did not mistake software rendering for
a Vulkan gaming GPU and did not download or start Proton.

The machine has the 64-bit and i386 Vulkan loader and Mesa driver libraries,
but its physical Intel generation exposes no hardware Vulkan. The package's
Debian multiarch detection was corrected in 0.1.0~dev2 after this test.

This closes the negative hardware gate only. A positive UMU-Proton game test
still requires a different computer with a supported hardware Vulkan device.
