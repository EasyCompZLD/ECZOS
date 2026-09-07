# 0008 — FreeOffice uses the vendor-maintained repository

## Decision

SoftMaker FreeOffice 2024 is the intended familiar office suite for ECZOS
Desktop. LibreOffice is removed from the product profile. EasyComp Zeeland
reported receiving vendor permission on 6 September 2026. The development host
therefore installs FreeOffice from SoftMaker's signed APT repository. ECZOS does
not commit or silently mirror the proprietary package in its source repository.

## Reason

SoftMaker documents free private and business use and publishes an official
Linux installer, but that is not by itself an explicit redistribution grant to
ECZOS. Executing a changing remote shell script during an image build would
also bypass the project's pinned-input and reproducibility requirements.

## Consequence

The product and vendor update source are recorded in
`/usr/share/eczos/product/default-apps.json`. Before a public image is released,
the written permission must be archived outside the public source tree and its
scope recorded, including ISO redistribution and automatic updates. The image
pipeline must then pin or snapshot the exact vendor package used for a release.
