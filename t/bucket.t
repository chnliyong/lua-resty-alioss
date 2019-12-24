use Test::Nginx::Socket;
use Cwd qw(cwd);

plan tests => repeat_each() * (blocks() * 4) + 1;

my $pwd = cwd();

$ENV{TEST_COVERAGE} ||= 0;
$ENV{TEST_NGINX_RESOLVER}            ||= '223.5.5.5';
$ENV{TEST_NGINX_ALICLOUD_ACCESS_KEY} ||= '123';
$ENV{TEST_NGINX_ALICLOUD_SECRET_KEY} ||= '123';
$ENV{TEST_NGINX_ALICLOUD_ENDPOINT}   ||= 'oss-cn-shenzhen.aliyuncs.com';
$ENV{TEST_NGINX_ALICLOUD_BUCKET}     ||= 'aliyun-test';

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;$pwd/deps/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?.lua;;";
    error_log logs/error.log debug;

    init_by_lua_block {
        if $ENV{TEST_COVERAGE} == 1 then
            jit.off()
            require("luacov.runner").init()
        end
    }
};

no_long_string();
#no_diff();

run_tests();

__DATA__
=== TEST 1: List objects.
--- http_config eval: $::HttpConfig
--- config
    location = /a {
        resolver $TEST_NGINX_RESOLVER;
        content_by_lua '
            local alioss = require "resty.alioss"
	    local cjson = require "cjson"
            local oss_cli = alioss.new({
                access_key = "$TEST_NGINX_ALICLOUD_ACCESS_KEY",
                secret_key = "$TEST_NGINX_ALICLOUD_SECRET_KEY",
                endpoint   = "$TEST_NGINX_ALICLOUD_ENDPOINT",
            })
	    local bucket = oss_cli:get_bucket("$TEST_NGINX_ALICLOUD_BUCKET")
	    local objs, err = bucket:list_objects({
	        ["delimiter"] = "/",
		["prefix"] = "m.example.com.cn/",
	    })
	    if not objs then
	        ngx.say("failed to list_objects: ", err)
	    end

	    ngx.say(cjson.encode(objs))
        ';
    }
--- request
GET /a
--- response_body_like
^\{".*\}$
--- no_error_log
[error]
[warn]

__DATA__
