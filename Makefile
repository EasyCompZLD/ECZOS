.PHONY: test package image github-upload

test:
	./scripts/verify-source.sh

package:
	./scripts/prepare-image-packages-vm.sh

image:
	./scripts/build-image-vm.sh

github-upload:
	./scripts/prepare-github-upload.sh
