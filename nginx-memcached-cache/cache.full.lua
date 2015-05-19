--[[
-- @brief A little lua module for nginx to store page in memcache
-- @author Leandro Mendes<leandro.mendes@dafiti.com.br>
--]]

-- Getting some vars we will need
local uri    = ngx.var.request_uri 
local host   = ngx.var.host

-- Path of our backend location
origin = "/backend"

-- hash
hash = md5.sumhexa(uri)

f:write("LOG: GET ".. hash .. "\n")
-- Checking up memcache to see if the URL is cached
data = memcache:get("uri:"..hash)

-- if cached, then data will be displayed
if data ~= nil then
    hstring    = memcache:get("header:" .. hash)
    if hstring ~= nil then
        f:write("LOG: HEADER ".. hstring .. "\n")
   	hdata = json.decode(hstring)
    	for k, v in pairs(hdata) do
            ngx.header[k] = v
   	end
    	ngx.header["X-Cache-Agent"] = "Dafiti Acelerator";
    end
    -- displaying data
    ngx.say(data)
else
-- not cached... need to check our origin backend for missed data

    -- getting data
    f:write("LOG: GET location "..uri .. "\n")
    res   = ngx.location.capture(origin.. uri)

    -- getting headers
    for k, v in pairs(res.header) do
        ngx.header[k] = v
    end

    -- checking for returning status code
    if res.status == 200 then
        cache = true
    elseif res.status == 304 then
        cache = true
    end

    -- if we should cache it, then we cache!
    if cache == true then
        memcache:set("uri:" .. hash, res.body)
        memcache:set("index:" .. hash, uri)
        memcache:set("header:" .. hash, json.encode(res.header))
    end

    -- displaying header data
    ngx.header["X-Cache-Agent"] = "Dafiti Acelerator";
    ngx.status = res.status

    -- displaying data
    ngx.say(res.body)
end
