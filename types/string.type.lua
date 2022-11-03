---@diagnostic disable: codestyle-check, duplicate-doc-alias
---https://github.com/sumneko/lua-language-server/wiki

---@alias string string|StringAbstract

---String helpers
---@class StringAbstract
---@field split fun(self: string, str: string, separator?: string, include_empty?: boolean, max_splits?: number, sep_is_pattern?: boolean): table `separator`: string, default: `","`, `include_empty`: boolean, default: `false`, `max_splits`: number, if it's negative, splits aren't limited, default: `-1`, `sep_is_pattern`: boolean, it specifies whether separator is a plain string or a pattern (regex), default: `false`. e.g. `"a,b":split","` returns `{"a","b"}`
