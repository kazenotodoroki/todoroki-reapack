-- @description Select Regions to export
-- @author Todoroki
-- @version 1.0
-- @changelog
--   Première version
-- @about
--   Exporte toutes les régions sauf celles commençant par "#".

local track_count = reaper.CountTracks(0)
local track_names = {}
local track_selections = {}

for i = 0, track_count - 1 do
    local track = reaper.GetTrack(0, i)
    local _, track_name = reaper.GetTrackName(track)
    table.insert(track_names, track_name)
    table.insert(track_selections, false)
end

-- Gather user input for tracks to export
local retval, track_selections_str = reaper.GetUserInputs("Select Tracks to Export", track_count, table.concat(track_names, ","), "")
if retval then
    local selections = {}
    for selection in string.gmatch(track_selections_str, "([^,]+)") do
        table.insert(selections, selection == "1")
    end

    track_selections = selections

    -- Select regions based on user input
    for i, selected in ipairs(track_selections) do
        if selected then
            local track = reaper.GetTrack(0, i-1)
            local region_count = reaper.CountProjectMarkers(0)
            for j = 0, region_count - 1 do
                local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers3(0, j)
                if isrgn then
                    local startIndex = name:find("#")
                    if startIndex ~= 1 then  -- Updated the condition to check for regions starting with "/"
                    reaper.SetRegionRenderMatrix(0, markrgnindexnumber, track, 1)
                    end
                end
            end
        end
    end
end