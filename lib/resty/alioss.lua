local log = ngx.log
local ERR = ngx.ERR
local WARN = ngx.WARN
local DEBUG = ngx.DEBUG
local ngx_re_match = ngx.re.match
local str_sub = string.sub

local http = require("resty.http")

local bucket = require("resty.alioss.bucket")
local object = require("resty.alioss.object")


local _M = {
    _VERSION = "0.0.1"
}


local mt = { __index = _M }


function _M.new(opts)
    local access_key = (opts or {}).access_key
    local secret_key = (opts or {}).secret_key
    local security_token = (opts or {}).security_token
    local endpoint = (opts or {}).endpoint
    local ssl = false
    local httpcli = http.new()
    
    if not access_key or not secret_key or not endpoint then
        return nil, "valid access_key, secret_key, endpoint required"
    end
    local caps, err = ngx_re_match(endpoint, "^((http|https)://)?([a-z0-9\\.-]+\\.aliyuncs.com)$", "jo")
    if not caps then
        return nil, "valid endpoint required"
    end
    if caps[1] == "https" then
        ssl = true
    end
    endpoint = caps[3]

    return setmetatable({
        access_key     = access_key,
        secret_key     = secret_key,
        security_token = security_token,
        endpoint       = endpoint,
        ssl            = scheme,
        httpcli        = httpcli,
    }, mt)
end


function _M.list_buckets(self, prefix, marker, maxn)
    local query_args = {}
    if prefix then
        query_args["prefix"] = prefix
    end
    if marker then
        query_args["marker"] = marker
    end
    if maxn then
        query_args["max-keys"] = tostring(maxn)
    end

    if self.ssl then
        httpcli:ssl_handshake(self.endpoint, port)
    end
    return
end


function _M.get_bucket(self, bucket_name)
    return bucket.new(self, bucket_name)
end
