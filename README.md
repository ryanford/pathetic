# Pathetic

Helper library build to parse http URI paths as described in https://tools.ietf.org/html/rfc3986

Originally designed to be used with [lua-http](https://github.com/daurnimator/lua-http)

`luarocks install pathetic`

Only dependency is LPeg. This should already be installed if using with lua-http.

## [View Demo](https://ryanford-frontend.github.io/pathetic)

Demo made with [Fengari](https://fengari.io), [LuLPeg](https://github.com/pygy/LuLPeg) and [inspect.lua](https://github.com/kikito/inspect.lua)

---

## Documentation

---
### `pathetic:parse(path_str)`

Returns the path parsed into a table, unescaped. Query is parsed into a subtable, unescaped and any keys appearing more than once with different values are gathered into a subtable.

```lua
pathetic:parse("/hello/world?lang=lua%21&lang=english&lib=pathetic#docs%2Finfo")
```
```lua
{
  fragment = "docs/info",
  path = "/hello/world",
  query = {
    lang = { "lua!", "english" },
    lib = "pathetic"
  },
  raw_fragment = "docs%2Finfo",
  raw_path = "/hello/world",
  raw_query = "lang=lua%21&lang=english&lib=pathetic"
}

```
---
### `pathetic:get_path(path_str)`

Returns a path's base path part, unescaped.
```lua
pathetic:get_path("/hello%2Fworld?lang=lua")
```
```lua
"/hello/world/"
```
---
### `pathetic:get_raw_path(path_str)`

Returns a path's base path part, without unescaping.
```lua
pathetic:get_path("/hello%2Fworld?lang=lua")
```
```lua
"/hello%2Fworld/"
```
---
### `pathetic:get_query(path_str)`

Returns a path's query string parsed into a table with key and values unescaped. Any keys appearing more than once with different values are gathered into a subtable.

```lua
pathetic:get_query("/hello/world?lang=lua%20lang&lib=english&lib=pathetic")
```
```lua
{
  lang = { "lua lang", "english" },
  lib = "pathetic"
}
```
---
### `pathetic:get_raw_query(path_str)`

Returns a path's raw query string, without unescaping.
```lua
pathetic:get_raw_query("/hello/world?lang=lua%20lang&lib=pathetic")
```
```lua
"lang=lua%20lang&lib=pathetic"
```
---
### `pathetic:get_fragment(path_str)`

Returns a path's fragment part, unescaped.
```lua
pathetic:get_path("/hello%2Fworld?lang=lua#docs%2Finfo")
```
```lua
"docs/info"
```
---
### `pathetic:get_raw_fragment(path_str)`

Returns a path's fragment part, without unescaping.
```lua
pathetic:get_path("/hello%2Fworld?lang=lua#docs%2Finfo")
```
```lua
"docs%2Finfo"
```
---
### `pathetic:parse_query(query_str)`

Returns a query string parsed into a table, unescaped. Any keys appearing more than once with different values are gathered into a table.
```lua
pathetic:parse("lang=lua%20lang&lang=english&lib=pathetic")
```
```lua
{
  lang = { "lua lang", "english" },
  lib = "pathetic"
}
```
---
### `pathetic:unescape(pct_encoded_str)`

Returns string unescaping any percent encoding.
```lua
pathetic:unescape("hello%20world%21")
```
```lua
"hello world!"
```
---
### `pathetic:unescape(str)`

Returns a string with an [RFC3986](https://tools.ietf.org/html/rfc3986#section-2.2) reserved chars percent encoded.
```lua
pathetic:escape("hello world!")
```
```lua
"hello%20world%21"
```
