-- @noindex
-- RS Trig Rescan Library: refreshes Data/RSampler/_library.txt (the list shown in the sampler).
-- Assign it to a shortcut or a toolbar button.
local dir = debug.getinfo(1, "S").source:match("^@?(.*[/\\])") or ""
RS_KB_MODE = "rescan"
dofile(dir .. "Todoroki_RS Trig Kit Builder.lua")
