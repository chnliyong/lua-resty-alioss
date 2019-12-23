
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
    return
end


