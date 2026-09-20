.PHONY: test package image github-upload github-source

test:
	./scripts/verify-source.sh

package:
	./scripts/prepare-image-packages-vm.sh

image:
	./scripts/build-image-vm.sh

github-upload:
	./scripts/prepare-github-upload.sh

github-source:
	./scripts/prepare-github-source.sh
