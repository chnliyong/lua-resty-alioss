LUAJIT = "/usr/local/opt/openresty/luajit"

deps:
	luarocks install --lua-dir=$(LUAJIT)  --tree=deps --only-deps --local rockspecs/lua-resty-alioss-master-0.rockspec

.PHONY: deps
