require  "Memcached"
json     = require "json"
md5	 = require "md5"
f	 = io.open("/var/log/nginx/lua.log", "a")
memcache = Memcached.Connect("127.0.0.1", 11212)
