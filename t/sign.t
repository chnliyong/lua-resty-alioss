use Test::Nginx::Socket;
use Cwd qw(cwd);

plan tests => repeat_each() * (blocks() * 4) + 1;

my $pwd = cwd();

$ENV{TEST_NGINX_RESOLVER} = '223.5.5.5';
$ENV{TEST_COVERAGE} ||= 0;

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
=== TEST 1: Simple default get.
--- http_config eval: $::HttpConfig
--- config
    location = /a {
        content_by_lua '
            local alioss = require "resty.alioss"
            local oss_cli = alioss.new({
                access_key = "123",
                secret_key = "456",
                endpoint = "oss-cn-hangzhou.aliyuncs.com",
            })
            httpc:connect("127.0.0.1", ngx.var.server_port)
            local res, err = httpc:request{
                path = "/b"
            }
            ngx.status = res.status
            ngx.print(res:read_body())
            httpc:close()
        ';
    }
    location = /b {
        echo "OK";
    }
--- request
GET /a
--- response_body
OK
--- no_error_log
[error]
[warn]

__DATA__

=== TEST 1: 