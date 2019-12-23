package = "lua-resty-alioss"
version = "master-0"
source = {
   url = "https://github.com/chnliyong/lua-resty-alioss"
}
description = {
   summary = "OpenResty Lua sdk for Alibaba Cloud OSS",
   detailed = [[
      This is an example for the LuaRocks tutorial.
      Here we would put a detailed, typically
      paragraph-long description.
   ]],
   homepage = "http://...", -- We don't have one yet
   license = "MIT/X11" -- or whatever you like
}
dependencies = {
   "lua-resty-http = 0.15-0",
}
build = {
    type = "make",
}
