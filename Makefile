.PHONY: test package image

test:
	./scripts/verify-source.sh

package:
	./scripts/prepare-image-packages-vm.sh

image:
	./scripts/build-image-vm.sh
