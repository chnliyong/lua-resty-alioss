local log           = ngx.log
local ERR           = ngx.ERR
local WARN          = ngx.WARN
local DEBUG         = ngx.DEBUG
local ngx_time      = ngx.time
local ngx_re_match  = ngx.re.match
local ngx_http_time = ngx.http_time

local str_fmt = string.format

local http       = require("resty.http")
local xml2lua    = require("xml2lua")
local xmlhandler = require("xmlhandler.tree")

local oss_utils = require("resty.alioss.utils")

local _M = {}


function _M.new(cli, bucket_name)
    return setmetatable({
        bucket_name = bucket_name,
        cli = cli,
    }, {
        __index = _M,
    })
end


function _M.list_objects(self, opts)
    opts = opts or {}
    local query_args = {}
    for _, key in ipairs({"delimiter", "marker", "max-keys",
        "prefix", "encoding-type"}) do
        query_args[key] = opts[key]
    end

    local cli = self.cli
    local host = self.bucket_name .. "." .. cli.endpoint
    local req = {
        method = "GET",
        path = "/",
        headers = {
            ["Host"] = host,
            ["Date"] = ngx_http_time(ngx_time()),
        },
        query = query_args,
    }

    local s, err = oss_utils.get_header_signature(req,
        {bucket_name=self.bucket_name},
        cli.secret_key, cli.security_token)
    if not s then
        return nil, err
    end
    
    local authz = str_fmt("OSS %s:%s", cli.access_key, s)

    log(DEBUG, "Authorization: ", authz)

    req.headers["Authorization"] = authz

    local httpcli = cli.httpcli
    if cli.ssl then
        local ok, err = httpcli:ssl_handshake(nil, host, 443)
        if not ok then
            httpcli:close()
            return nil, err
        end
    else
        local ok, err = httpcli:connect(host, 80)
        if not ok then
            httpcli:close()
            return nil, err
        end
    end

    local resp, err = httpcli:request(req)
    if not resp then
        httpcli:close()
        return nil, err
    end

    local body, err = resp:read_body()
    if not body then
        httpcli:close()
        return nil, err
    end

    log(DEBUG, "Response: ", body)

    local parser = xml2lua.parser(xmlhandler)
    parser:parse(body)

    return xmlhandler.root.ListBucketResult
end


return _M
