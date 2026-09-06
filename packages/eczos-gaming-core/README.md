# eczos-gaming-core

This optional package is the hardware and runtime gate for **ECZ Gaming**. It
does not claim that Proton support exists merely because a command is installed.
`eczos-gaming doctor` separately verifies hardware Vulkan, a 32-bit Vulkan ICD,
UMU and GameMode. Software Vulkan such as llvmpipe or lavapipe is rejected for
DXVK/VKD3D gaming.

The included UMU adapter uses a separate prefix supplied by a future per-game
profile. It intentionally does not reuse an ECZ Windows application prefix.
UMU's stable `UMU-Proton` channel supplies Proton and the Steam Linux Runtime;
this network-managed payload still needs a positive test on supported graphics
hardware before ECZ Gaming can be considered release-qualified.
