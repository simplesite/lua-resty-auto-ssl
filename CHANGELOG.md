# lua-resty-auto-ssl Change Log

## 0.12.0 - 2018-02-04

### Upgrade Notes

This version upgrades the bundled version of the dehydrated library to deal with recent redirect changes in the Let's Encrypt service. The issue could lead to certificate registration failures in dehydrated and quota exhaustion, so upgrading is recommended. See [4aed490](https://github.com/GUI/lua-resty-auto-ssl/commit/4aed490c1d76b8bf09a8151aad2373c3e0cac6ce) or https://community.letsencrypt.org/t/dehydrated-caused-rate-limits-to-be-reached/52477/2 for more details.

### Added
- Allow for the Redis `db` number to be configured. Thanks to [@RainFlying](https://github.com/RainFlying). ([#103](https://github.com/GUI/lua-resty-auto-ssl/pull/103))
- Expose the storage adapter instance in the `allow_domain` callback so the Redis connection can be reused. ([#38](https://github.com/GUI/lua-resty-auto-ssl/issues/38))
- Add `generate_certs` option to allow for disabling SSL certification generation within specific server blocks. Thanks to [@mklauber](https://github.com/mklauber). ([#91](https://github.com/GUI/lua-resty-auto-ssl/issues/91), [#92](https://github.com/GUI/lua-resty-auto-ssl/pull/92))
- Add `json_adapter` option for choosing a different JSON encoder/decoder library. Thanks to [@meyskens](https://github.com/meyskens). ([#85](https://github.com/GUI/lua-resty-auto-ssl/pull/85), [#84](https://github.com/GUI/lua-resty-auto-ssl/issues/84))

### Changed
- Upgrade dehydrated to latest version from master to fix recent redirect changes in Let's Encrypt. The issue could lead to certificate registration failures in dehydrated and quota exhaustion. ([4aed490](https://github.com/GUI/lua-resty-auto-ssl/commit/4aed490c1d76b8bf09a8151aad2373c3e0cac6ce))
- Make the renewal process more efficient so the dehydrated shell script is only executed when certificates are up for renewal (rather than every night). This can reduce CPU usage in environments with lots of certificates. Thanks to [@brianlund](https://github.com/brianlund). ([#111](https://github.com/GUI/lua-resty-auto-ssl/pull/111), [#110](https://github.com/GUI/lua-resty-auto-ssl/issues/110))
- Only call the `allow_domain` callback if a certificate is not present in shared memory. This may improve efficiency in cases where the `allow_domain` callback is more costly or takes longer. Thanks to [@gohai](https://github.com/gohai). ([#107](https://github.com/GUI/lua-resty-auto-ssl/pull/107))
- The internal APIs for `storage:get_cert()` and `ssl_provider.issue_cert()` has changed to return a single table of data instead of multiple values (so it's easier to pass along other metadata).

### Deprecated
- If accessing the storage object off of the auto-ssl instance, use `auto_ssl.storage` instead of `auto_ssl:get("storage")`.

### Fixed
- Fix renewals when using the file adapter and too many certificate files were present for shell globbing ([#109](https://github.com/GUI/lua-resty-auto-ssl/issues/109))

## 0.11.1 - 2017-11-17

### Fixed
- Update dehydrated to v0.4.0 to account for new [Let's Encrypt Subscriber Agreement](https://letsencrypt.org/documents/2017.11.15-LE-SA-v1.2.pdf) as of November 15, 2017. This would lead to certificate registration errors for new users (but should not have affected existing lua-resty-auto-ssl users). ([#13](https://github.com/GUI/lua-resty-auto-ssl/issues/13), [#104](https://github.com/GUI/lua-resty-auto-ssl/issues/104))

## 0.11.0 - 2017-06-18

### Upgrade Notes

This update mostly fixes bugs related to edge-case situations, so upgrading is recommended. However, it requires a couple of small adjustments to your nginx configuration, so if you're upgrading, be sure to make the following changes:

1. Add this line to nginx's `http` block:

   ```
   lua_shared_dict auto_ssl_settings 64k;
   ```

   (This is in addition to the existing `lua_shared_dict auto_ssl` you should already have.)
2. Add these 2 lines to the `server` block that is listening on port 8999:

   ```
   client_body_buffer_size 128k;
   client_max_body_size 128k;
   ```

See the [README](https://github.com/GUI/lua-resty-auto-ssl#installation) for a full example of the updated config.

### Fixed
- Fix potential for failed requests if nginx is reloaded at the same time new certificates are being issued. Many thanks to [@luto](https://github.com/luto). ([#66](https://github.com/GUI/lua-resty-auto-ssl/issues/66), [#68](https://github.com/GUI/lua-resty-auto-ssl/pull/68))
- Fix possibility of sockproc inheriting nginx's sockets, which could lead to nginx hanging after reloading or restarting. ([#75](https://github.com/GUI/lua-resty-auto-ssl/pull/75))
- Fix race condition on nginx reload if the `lua_shared_dict` ran out of memory that could lead to sockproc trying to be started twice. ([#76](https://github.com/GUI/lua-resty-auto-ssl/pull/76))
- Increase the suggested body buffer size configuration, to prevent SSL registration from failing if nginx's default was too small. ([#65](https://github.com/GUI/lua-resty-auto-ssl/issues/65]), [#77](https://github.com/GUI/lua-resty-auto-ssl/pull/77))

### Security
- Fix possibility of certificate private keys being logged to nginx's error log when unexpected errors occur (this has actually been fixed since v0.10.5, but somewhat by accident—further steps have been taken to reduce debug output in this release). ([#64](https://github.com/GUI/lua-resty-auto-ssl/issues/64))

### Added
- Add documentation and link about test suite used. Thanks to [@luto](https://github.com/luto). ([#69](https://github.com/GUI/lua-resty-auto-ssl/pull/69))

## 0.10.6 - 2017-04-16

### Fixed
- Fix installation under LuaRocks 2.4+ (executable files were not installed as executable).
- Fix inability to register new certificates if the configured `lua_shared_dict` ran out of memory.

### Changed
- Additional error logging to warn admins when the configured `lua_shared_dict` has run out of memory.
- Updated test suite dependencies, and added Docker test setup.

## 0.10.5 - 2017-03-16

### Fixed
- Fix potential issue with deploy-cert hanging in some environments. Thanks to [@Adel-Magebinary](https://github.com/Adel-Magebinary)

## 0.10.4 - 2017-02-25

### Fixed
- Fix errors not being returned if conversion to DER format failed.
- Wrap SSL certificate function in more error handling.

## 0.10.3 - 2016-12-11

### Fixed
- Fix a LuaRocks install-time warning and potential load path issues.

## 0.10.2 - 2016-12-07

### Fixed
- Extend timeout for calling dehydrated shell script from 15 seconds to 60 seconds to improve handling when Let's Encrypt may take longer to respond than normal (the intended fix for this same issue in v0.8.4 didn't actually fix the issue).

## 0.10.1 - 2016-11-13

### Fixed
- Fix certificate renewal if using the Redis storage adapter with key prefixes. Thanks to [@brettg](https://github.com/brettg).
- Fix potential issues caused by locks not being released if unexpected errors occurred during certificate issuance or renewal.
- Clarify nginx "resolver" usage for potential IPv6 compatibility issues.

## 0.10.0 - 2016-10-22

### Added
- Add support for Redis key prefix when using the Redis storage adapter. Thanks to [@brettg](https://github.com/brettg).

### Fixed
- Fix concurrent initial requests for different domains blocking SSL cert creation.

### Changed
- Upgrade letsencrypt.sh dependency, which has also been renamed "dehydrated".
- Upgrade lua-resty-shell and sockproc dependencies.

## 0.9.0 - 2016-09-11

### Added
- Add support for Redis authentication when using the Redis storage adapter. Thanks to [@Eihrister](https://github.com/Eihrister).
- Add dependency checks during install and startup to provide better error messages in case system commands are not available.

### Fixed
- Fix compatibility on BusyBox-based systems where the `find` command did not support the `-printf` option.
- Fix compatibility for systems where bash is installed in a location other than `/bin/bash`.

## 0.8.6 - 2016-08-11

### Fixed
- Fix compatibility with OpenResty pre-built packages or when compiled with Lua 5.2 compatibility enabled (`LUAJIT_ENABLE_LUA52COMPAT`). Thanks to [@ikennaokpala](https://github.com/ikennaokpala).

## 0.8.5 - 2016-08-03

### Fixed
- Update letsencrypt.sh to account for new Let's Encrypt license as of August 1, 2016. This would lead to certificate registration errors for new users (but should not have affected existing lua-resty-auto-ssl users).

### Changed
- Improve error messages for OCSP stapling failures to aid in debugging.

## 0.8.4 - 2016-07-23

### Fixed
- Extend timeout for calling letsencrypt.sh from 15 seconds to 60 seconds to improve handling when Let's Encrypt may take longer to respond than normal.

## 0.8.3 - 2016-07-20

### Fixed
- Fix the default Redis port (6379) not being applied for the Redis storage adapter.
- Fix recovering certs from Let's Encrypt's local files if the cert was deleted from the adapter's storage (or if the cert failed to successfully be added the first time).
- Fix potential issues with calling letsencrypt.sh for very long domain names, or if the base directory was set to a long path.

## 0.8.2 - 2016-06-26

### Fixed
- Fix letsencrypt.sh directory permissions on startup.

## 0.8.1 - 2016-05-31

### Fixed
- Fix compatibility with Let's Encrypt API changes by upgrading vendored letsencrypt.sh to v0.2.0.
- Fix certificate renewals not being picked up until nginx restarts.

## 0.8.0 - 2016-04-10

### Changed
- Initial version published as LuaRock.
