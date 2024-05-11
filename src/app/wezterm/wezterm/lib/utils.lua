local utils = {}

function utils.string_is_empty(s)
    return s == nil or s == ''
end

function utils.file_exists(filepath)
    local f = io.open(filepath, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function utils.get_cache_dir()
    local cache = os.getenv("XDG_CACHE_HOME")
    if utils.string_is_empty(cache) then
        cache = os.getenv("HOME") .. "/.cache"
    end

    return cache
end

return utils
