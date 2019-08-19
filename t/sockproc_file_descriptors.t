use strict;
use warnings;
use Test::Nginx::Socket::Lua;
use Cwd qw(abs_path);
use File::Basename;
my $root_dir = dirname(dirname(abs_path(__FILE__)));
require "$root_dir/t/inc/setup.pl";
AutoSsl::setup();

my ($nobody_user, $nobody_passwd, $nobody_uid, $nobody_gid) = getpwnam "nobody";
$ENV{TEST_NGINX_NOBODY_USER} = $nobody_user;
$ENV{TEST_NGINX_NOBODY_GROUP} = getgrgid($nobody_gid);

repeat_each(1);

plan tests => repeat_each() * (blocks() * 7);

check_accum_error_log();
no_long_string();
no_shuffle();
master_on();
workers(2);

run_tests();

__DATA__

=== TEST 1: issues a new SSL certificate and stores it as a file
--- main_config
user $TEST_NGINX_NOBODY_USER $TEST_NGINX_NOBODY_GROUP;
--- http_config
  resolver $TEST_NGINX_RESOLVER;
  lua_shared_dict auto_ssl 1m;
  lua_shared_dict auto_ssl_settings 64k;

  init_by_lua_block {
    auto_ssl = (require "resty.auto-ssl").new({
      dir = "$TEST_NGINX_RESTY_AUTO_SSL_DIR",
      ca = "https://acme-staging.api.letsencrypt.org/directory",
      storage_adapter = "resty.auto-ssl.storage_adapters.file",
      allow_domain = function(domain)
        return true
      end,
    })
    auto_ssl:init()
  }

  init_worker_by_lua_block {
    auto_ssl:init_worker()
  }

  server {
    listen 9443 ssl;
    ssl_certificate $TEST_NGINX_ROOT_DIR/t/certs/example_fallback.crt;
    ssl_certificate_key $TEST_NGINX_ROOT_DIR/t/certs/example_fallback.key;
    ssl_certificate_by_lua_block {
      auto_ssl:ssl_certificate()
    }

    location /foo {
      server_tokens off;
      more_clear_headers Date;
      echo "foo";
    }
  }

  server {
    listen 9080;
    location /.well-known/acme-challenge/ {
      content_by_lua_block {
        auto_ssl:challenge_server()
      }
    }
  }

  server {
    listen 127.0.0.1:8999;
    client_body_buffer_size 128k;
    client_max_body_size 128k;
    location / {
      content_by_lua_block {
        auto_ssl:hook_server()
      }
    }
  }
--- config
  lua_ssl_trusted_certificate $TEST_NGINX_ROOT_DIR/t/certs/letsencrypt_staging_chain.pem;
  lua_ssl_verify_depth 5;
  location /t {
    content_by_lua_block {
      local shell_blocking = require "shell-games"

      local function cleanup_sockproc()
        shell_blocking.capture_combined({ "pkill", "sockproc" })
        local _, err = shell_blocking.capture_combined({ "rm", "-f", "/tmp/shell.sock", "/tmp/auto-ssl-sockproc.pid" })
        if err then
          ngx.say("failed to remove sockproc files: ", err)
          return nil, err
        end
      end

      local function print_file_descriptors(as_user, expect_no_results)
        -- Run in bash login subshell, since when running as the "nobody" user,
        -- there may not be a default PATH set, in which case, lsof installed
        -- in /usr/sbin may not be picked up (but this behavior varies
        -- depending on distro).
        local result, err = shell_blocking.capture_combined({ "bash", "-l", "-c", "lsof -n -P -l -R -c sockproc -a -d 0-255 -F pnf" })
        if expect_no_results == true then
          if err and result["output"] == "" then
            ngx.say("")
            return
          else
            ngx.say("expected lsof to return nothing, but returned: ", result["output"], err)
            return nil, err
          end
        elseif err then
          ngx.say("failed to run lsof: ", err)
          return nil, err
        end

        local lines = {}
        for line in string.gmatch(result["output"], "[^\n]+") do
          table.insert(lines, line)
        end

        for index, line in ipairs(lines) do
          if index > 1 then
            local line, _, err = ngx.re.sub(line, "\\s*type=STREAM", "")
            local line, _, err = ngx.re.sub(line, "^n/.*logs/error.log$", "n/dev/null")
            ngx.say(line)
          end
        end

        ngx.say("")
      end

      ngx.say("already running:")
      print_file_descriptors("root")

      cleanup_sockproc()
      ngx.say("none running:")
      print_file_descriptors("root", true)

      ngx.say("current dir as current user:")
      cleanup_sockproc()
      shell_blocking.capture_combined({ auto_ssl.lua_root .. "/bin/resty-auto-ssl/start_sockproc" }, { umask = "0022" })
      print_file_descriptors("root")

      ngx.say("/tmp dir as current user:")
      cleanup_sockproc()
      shell_blocking.capture_combined({ auto_ssl.lua_root .. "/bin/resty-auto-ssl/start_sockproc" }, { umask = "0022", chdir = "/tmp" })
      print_file_descriptors("root")

      ngx.say("the end")
    }
  }
--- timeout: 30s
--- request
GET /t
--- response_body
already running:
f0
n/dev/null
f1
n/dev/null
f2
n/dev/null
f3
n/tmp/shell.sock

none running:

current dir as current user:
f0
n/dev/null
f1
n/dev/null
f2
n/dev/null
f3
n/tmp/shell.sock

/tmp dir as current user:
f0
n/dev/null
f1
n/dev/null
f2
n/dev/null
f3
n/tmp/shell.sock

the end
--- error_log
auto-ssl: starting sockproc
--- no_error_log
[warn]
[error]
[alert]
[emerg]
