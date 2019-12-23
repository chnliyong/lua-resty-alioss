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
local ngx_http_time = ngx.http_time
local ngx_hmac_sha1 = ngx.hmac_sha1


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
-- opts: table contains `access_key`, `secret_key`, `security_token`(optional), `endpoint`
-- res: resource table contains `bucket_name`, `object_name`
local function get_header_signature(req, opts, res)
    if not (opts and opts.access_key and opts.secret_key) then
        return nil, "argument opts should contain access_key and secret_key"
    end

    local ossheaders = {}
    local subresources = {}
    local c1 = 1, c2 = 1
    for k, v in pairs(headers) do
        local from, to ,err = ngx_re.find(k, "^x-oss-", "jo", "i")
        if from then
            ossheaders[c1] = str_lower(k) .. ":" .. v
            c1 = c1 + 1
        elseif need_sign[k] then
            subresources[c2] = k .. "=" .. v
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
        if opts.security_token then
            ossheaders[count] = "x-oss-security-token:" .. opts.security_token
        end
        tab_sort(ossheaders)
        c_ossheaders = tab_concat(ossheaders, "\n")
    else
        if opts.security_token then
            c_ossheaders = "x-oss-security-token:" .. opts.security_token
        end
    end

    local c_resoure
    if res.bucket_name then
        if res.object_name then
            c_resoure = str_format("/%s/%s/", res.bucket_name, res.object_name)
        else
            c_resoure = str_format("/%s/", res.bucket_name)
        end
    else
        c_resoure = "/"
    end
    
    if #subresources > 1 then
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
    end
    tosign[6] = c_resoure

    local strtosign = tab_concat(tosign, "\n")

    local digest = ngx_hmac_sha1(opts.secret_key, strtosign)
    return ngx_encode_base64(digest)
end
