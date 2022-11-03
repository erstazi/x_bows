---@diagnostic disable: codestyle-check
---Sfinv API
---@class Sfinv
---@field register_page fun(name: string, def: SfinvDef): nil Register a page
---@field make_formspec fun(player: ObjectRef, contex: SfinvContext, content: string, show_inv?: boolean, size?: string): nil Adds a theme to a formspec show_inv, defaults to false. Whether to show the player's main inventory size, defaults to `size[8,8.6]` if not specified
---@field get_or_create_context fun(player: ObjectRef): SfinvContext Gets the player's context
---@field set_context fun(player: ObjectRef, context: SfinvContext): nil
---@field get_formspec fun(player: ObjectRef, context: SfinvContext): string Builds current page's formspec
---@field set_player_inventory_formspec fun(player: ObjectRef): string (re)builds page formspec and calls set_inventory_formspec().


---Sfinv Definition
---@class SfinvDef
---@field title string Human readable page name (required)
---@field get fun(self: Sfinv, player: ObjectRef, context: SfinvContext): string Returns a formspec string. See formspec variables. (required)
---@field is_in_nav fun(self: Sfinv, player: ObjectRef, context: SfinvContext): boolean Return true to show in the navigation (the tab header, by default)
---@field on_player_receive_fields fun(self: Sfinv, player: ObjectRef, context: SfinvContext, fields: table): nil On formspec submit.
---@field on_enter fun(self: Sfinv, player: ObjectRef, context: SfinvContext): nil Called when the player changes pages, usually using the tabs.
---@field on_leave fun(self: Sfinv, player: ObjectRef, context: SfinvContext): nil When leaving this page to go to another, called before other's on_enter

---Sfinv Context, including: any thing you want to store, sfinv will clear the stored data on log out / log in
---@class SfinvContext
---@field page string Current page name
---@field nav string[] A list of page names
---@field nav_titles string[] A list of page titles
---@field nav_idx number Current nav index (in nav and nav_titles)
