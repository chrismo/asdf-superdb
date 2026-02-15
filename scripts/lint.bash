#!/usr/bin/env bash

shellcheck --shell=bash --external-sources \
	--source-path=lib/ \
	bin/* \
	lib/* \
	scripts/*.bash

shfmt --language-dialect bash --diff \
	bin/* \
	lib/* \
	scripts/*.bash
