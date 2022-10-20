minetest.register_on_player_receive_fields(function(player, formname, fields)
    if player and fields.quit then
        XBowsQuiver:close_quiver(player, formname)
    end
end)
