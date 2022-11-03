---@diagnostic disable: codestyle-check, duplicate-doc-alias
---https://github.com/sumneko/lua-language-server/wiki

---@alias mathlib mathlib|MathAbstract

---Math helpers
---@class MathAbstract
---@field round fun(x: number): number Returns `x` rounded to the nearest integer. At a multiple of 0.5, rounds away from zero.
