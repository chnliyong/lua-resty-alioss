OPENRESTY_PREFIX := $(shell openresty -V 2>&1 | grep -oE 'prefix=[^ ]+/nginx' | cut -d'=' -f2)
LUAJIT_DIR := $(shell openresty -V 2>&1 | grep -oE 'prefix=[^ ]+/nginx' | grep -oE '/.*/')/luajit

deps:
	luarocks install --lua-dir=$(LUAJIT_DIR)  --tree=deps --only-deps --local rockspecs/lua-resty-alioss-master-0.rockspec

.PHONY: deps
