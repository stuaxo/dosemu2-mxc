# Thin front end for the scripts in bin/. See README.md.

.PHONY: help fetch check dosemu config deb stage

help:
	@echo "make fetch    download the pinned MXC executor into .mxc/"
	@echo "make check    smoke test: sandbox runs, dosemu starts inside it"
	@echo "make dosemu   run dosemu in the sandbox (ARGS='-dumb -E ver')"
	@echo "make deb SRC=dir      build the .debs of a source tree in the sandbox (bin/mxc-deb)"
	@echo "make stage DEBS='..'  unpack .debs into .mxc/stage; run with mxc-run --stage"
	@echo "make config   print the generated MXC request"

fetch:
	./bin/mxc-fetch.sh

check:
	./bin/mxc-run -- sh -c 'echo "sandbox: $$MXC_SANDBOX"; dosemu --version | head -1; ls -d $$HOME'

dosemu:
	./bin/mxc-run -- dosemu $(ARGS)

config:
	./bin/mxc-run --print-config -- true

deb:
	./bin/mxc-deb $(SRC)

stage:
	./bin/mxc-stage --clean $(DEBS)
