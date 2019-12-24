local str_upper     = string.upper
local str_lower     = string.lower
local str_format    = string.format
local tab_sort      = table.sort
local tab_concat    = table.concat
local log           = ngx.log
local ERR           = ngx.ERR
local WARN          = ngx.WARN
local DEBUG         = ngx.DEBUG
local ngx_time      = ngx.time
local ngx_re_find   = ngx.re.find
local ngx_http_time = ngx.http_time
local ngx_hmac_sha1 = ngx.hmac_sha1
local ngx_encode_base64 = ngx.encode_base64
local ngx_escape_uri = ngx.escape_uri


local need_sign = {
    ["acl"]            = true,
    ["uploads"]        = true,
    ["uploadId"]       = true,
    ["partNumber"]     = true,
    ["cors"]           = true,
    ["location"]       = true,
    ["logging"]        = true,
    ["website"]        = true,
    ["referer"]        = true,
    ["lifecycle"]      = true,
    ["delete"]         = true,
    ["append"]         = true,
    ["tagging"]        = true,
    ["objectMeta"]     = true,
    ["security-token"] = true,
    ["position"]       = true,
    ["img"]            = true,
    ["style"]          = true,
    ["styleName"]      = true,
    ["vod"]            = true,
    ["live"]           = true,
    ["replication"]    = true,
    ["cname"]          = true,
    ["bucketInfo"]     = true,
    ["comp"]           = true,
    ["qos"]            = true,
    ["status"]         = true,
    ["startTime"]      = true,
    ["endTime"]        = true,
    ["symlink"]        = true,
    ["x-oss-process"]  = true,
    ["response-expires"]             = true,
    ["replicationProgress"]          = true,
    ["replicationLocation"]          = true,
    ["response-content-type"]        = true,
    ["response-cache-control"]       = true,
    ["response-content-encoding"]    = true,
    ["response-content-language"]    = true,
    ["response-content-disposition"] = true,
}


-- req: request for `lua-resty-http`
-- res: resource table contains `bucket_name`, `object_name`
-- secret_key: access key secret
-- security_token: optional when use STS
local function get_header_signature(req, res, secret_key, security_token)
    if not secret_key then
        return nil, "secret_key required"
    end

    local resource = res or {}

    local ossheaders = {}
    local subresources = {}
    local c1, c2 = 1, 1
    local headers = req.headers or {}
    for k, v in pairs(headers) do
        local from, to ,err = ngx_re_find(k, "^x-oss-", "jo", "i")
        if from then
            ossheaders[c1] = str_lower(k) .. ":" .. v
            c1 = c1 + 1
        elseif need_sign[k] then
            subresources[c2] = k .. "=" .. ngx_escape_uri(v)
            c2 = c2 + 1
        end
    end

    local query_args = req.query_args or {}
    for k, v in pairs(query_args) do
        if need_sign[k] then
            if not v then
                subresources[c2] = k
            else
                subresources[c2] = k .. "=" .. v
            end
            c2 = c2 + 1
        end
    end

    local c_ossheaders = ""
    if #ossheaders > 1 then
        if security_token then
            ossheaders[count] = "x-oss-security-token:" .. security_token
        end
        tab_sort(ossheaders)
        c_ossheaders = tab_concat(ossheaders, "\n")
    else
        if security_token then
            c_ossheaders = "x-oss-security-token:" .. security_token
        end
    end

    local c_resoure
    if resource.bucket_name then
        if resource.object_name then
            c_resoure = str_format("/%s/%s/", resource.bucket_name, resource.object_name)
        else
            c_resoure = str_format("/%s/", resource.bucket_name)
        end
    else
        c_resoure = "/"
    end
    
    if c2 > 1 then
        tab_sort(subresources)
        local query = tab_concat(subresources, "&")
        c_resoure = c_resoure .. "?" .. query
    end

    local tosign = {
        str_upper(req.method),
        headers["Content-MD5"] or "",
        headers["Content-Type"] or "",
        headers["Date"],
    }
    if c_ossheaders ~= "" then
        tosign[5] = c_ossheaders
        tosign[6] = c_resoure
    else
        tosign[5] = c_resoure
    end

    local strtosign = tab_concat(tosign, "\n")

    log(DEBUG, "string to sign: ", strtosign)

    local digest, err = ngx_hmac_sha1(secret_key, strtosign)
    if not digest then
        return nil, err
    end

    return ngx_encode_base64(digest)
end

local _M = {
    get_header_signature = get_header_signature,
}

return _M
