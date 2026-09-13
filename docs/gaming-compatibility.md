# ECZ Gaming compatibility

ECZ Gaming uses Vulkan as a capability gate for the normal Proton path. DXVK maps
Direct3D 8/9/10/11 to Vulkan and VKD3D-Proton maps Direct3D 12 to Vulkan, so a
software Vulkan device such as llvmpipe is not accepted as a gaming GPU.

Run `eczos-gaming doctor` before provisioning Proton. The verdicts are:

- `ready`: hardware Vulkan, a 32-bit Vulkan ICD, UMU and GameMode are present;
- `setup-required`: the GPU is suitable, but a runtime component is missing;
- `unsupported`: no hardware Vulkan device is available.

The Steam integration has been physically launched successfully on the GamePC.
That result qualifies the current ECZOS gaming prototype. Separate positive
tests with individual Vulkan, DXVK, VKD3D or UMU games are optional additions
to the compatibility matrix, not a current release blocker.

The Dell OptiPlex 780 development host has Intel Q45/Q43 graphics. It exposes
OpenGL 2.1 and only the llvmpipe CPU Vulkan device. It is therefore a useful
negative diagnostic target but cannot qualify Proton, DXVK or VKD3D. It does
not need to be used for positive game testing.

UMU launcher 1.4.0-1 is recorded by exact Debian 13 package URL and SHA-256.
The helper verifies its checksum and Debian package metadata before installing
it. UMU subsequently manages its stable UMU-Proton and Steam Linux Runtime
payload in the user's data directory; those downloads are not part of the
ECZOS Debian package.
