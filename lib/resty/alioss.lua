local log           = ngx.log
local ERR           = ngx.ERR
local WARN          = ngx.WARN
local DEBUG         = ngx.DEBUG
local ngx_time      = ngx.time
local ngx_re_match  = ngx.re.match
local ngx_http_time = ngx.http_time

local str_sub    = string.sub
local str_fmt    = string.format
local tab_concat = table.concat

local http       = require("resty.http")
local xml2lua    = require("xml2lua")
local xmlhandler = require("xmlhandler.tree")

local bucket    = require("resty.alioss.bucket")
local oss_utils = require("resty.alioss.utils")


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

    local req = {
        method = "GET",
        path = "/",
        headers = {
            ["Host"] = self.endpoint,
            ["Date"] = ngx_http_time(ngx_time()),
        },
        query = query_args,
    }
    local s, err = oss_utils.get_header_signature(req, {}, self.secret_key, self.security_token)
    if not s then
        return nil, err
    end

    local authz = str_fmt("OSS %s:%s", self.access_key, s)
    req.headers["Authorization"] = authz


    local httpcli = self.httpcli
    if self.ssl then
        local ok, err = httpcli:ssl_handshake(nil, self.endpoint, 443)
        if not ok then
            httpcli:close()
            return nil, err
        end
    else
        local ok, err = httpcli:connect(self.endpoint, 80)
        if not ok then
            httpcli:close()
            return nil, err
        end
    end

    local resp, err = httpcli:request(req)
    if not resp then
        return nil, err
    end

    local body, err = resp:read_body()
    if not body then
        httpcli:close()
    end

    local parser = xml2lua.parser(xmlhandler)
    parser:parse(body)

    return xmlhandler.root.ListAllMyBucketsResult
end


function _M.get_bucket(self, bucket_name)
    return bucket.new(self, bucket_name)
end

return _M
