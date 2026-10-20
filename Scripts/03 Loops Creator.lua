-- @description Loops Creator
-- @author Todoroki
-- @version 1.0
-- @changelog
--   Première version
-- @about
--   Crée une boucle sans coupure sur chaque sample.

-- Get the length of the time selection
start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
time_selection_length = end_time - start_time

-- Get the end position of the first region
retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers3(0, 0)
if retval == 1 and isrgn then
    first_region_end = rgnend
else
    first_region_end = 0
end

-- Calculate the value of endofloop_to_endofregion
endofloop_to_endofregion = first_region_end - end_time

function Msg(msg)
    reaper.ShowConsoleMsg(tostring(msg) .. "\n")
end

function Move_regions()
    local i = 0
    local region_idx = 0
    local regions = {}
    while true do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers3(0, i)
        if retval == 0 then
            break
        end
        if isrgn then
            table.insert(regions, {index = markrgnindexnumber, pos = pos, rgnend = rgnend, name = name})
            region_idx = region_idx + 1
        end
        i = i + 1
    end
    for i, region in ipairs(regions) do
        local new_pos = region.pos + (i-1) * time_selection_length
        local new_end = region.rgnend + i * time_selection_length - (endofloop_to_endofregion + 0.5 * time_selection_length)
        reaper.SetProjectMarker3(0, region.index, true, new_pos, new_end, region.name, 0)
    end
end

function Move_items()
    local count_sel_tracks = reaper.CountSelectedTracks(0)

    for t = 0, count_sel_tracks - 1 do
        local track = reaper.GetSelectedTrack(0, t)
        local count_track_items = reaper.CountTrackMediaItems(track)

        for i = count_track_items - 1, 0, -1 do
            local item = reaper.GetTrackMediaItem(track, i)
            local item_position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

            local increment = (i * time_selection_length)
            local new_position = item_position + increment
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_position)
        end
    end
end

function Select_Media_On_Selected_Tracks()
    local num_tracks = reaper.CountTracks(0)

    for t = 0, num_tracks - 1 do
        local track = reaper.GetTrack(0, t)
        local track_selected = reaper.IsTrackSelected(track)
        local num_items = reaper.CountTrackMediaItems(track)

        for i = 0, num_items - 1 do
            local item = reaper.GetTrackMediaItem(track, i)

            if track_selected then
                -- Select items for selected track
                reaper.SetMediaItemSelected(item, true)
            else
                -- Unselect items for unselected tracks
                reaper.SetMediaItemSelected(item, false)
            end
        end
    end
end

function Loop_Creator()
    first_item = reaper.GetSelectedMediaItem(0,0)
    if first_item ~= nil then
    
        -- Get the current value of the "Create automatic fade-in/fade-out for new items and when splitting" option
        local auto_fade_state = reaper.GetToggleCommandStateEx(0, 41194)
        
        -- Disable the "Create automatic fade-in/fade-out for new items and when splitting" option
        if auto_fade_state == 1 then
            reaper.Main_OnCommand(41194, 0)
        end
        
        start_looptime, end_looptime = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false )
        start_first_item = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")
        length_first_item = reaper.GetMediaItemInfo_Value(first_item, "D_LENGTH")
        cut_first = (start_looptime - start_first_item)
        cut_last = (end_looptime - start_first_item)
        length_middle = cut_last - cut_first  
        count_sel_item =  reaper.CountSelectedMediaItems(0)
        selected_items = {}
        for i = 0, count_sel_item - 1 do
            item = reaper.GetSelectedMediaItem(0, i)
            table.insert(selected_items, item)
        end
    
        for i, item in ipairs(selected_items) do
            Msg("i = " ..i)
            start_item = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            reaper.SplitMediaItem(item, start_item + cut_last)
            reaper.SplitMediaItem(item, start_item + cut_first + 0.5 * length_middle)
            reaper.SplitMediaItem(item, start_item + cut_first)
        end
    
        cut_items = {}
        for i = 0, reaper.CountMediaItems(0) - 1 do
            item = reaper.GetMediaItem(0, i)
            table.insert(cut_items, item)
        end
    
        for i = 1, #cut_items, 4 do
            if cut_items[i] and cut_items[i+1] and cut_items[i+2] and cut_items[i+3] then
                length_item1 = reaper.GetMediaItemInfo_Value(cut_items[i], "D_LENGTH")
                length_item2 = reaper.GetMediaItemInfo_Value(cut_items[i+1], "D_LENGTH")
                length_item3 = reaper.GetMediaItemInfo_Value(cut_items[i+2], "D_LENGTH")
                length_item4 = reaper.GetMediaItemInfo_Value(cut_items[i+3], "D_LENGTH")
                start_item = reaper.GetMediaItemInfo_Value(cut_items[i], "D_POSITION")
                reaper.SetMediaItemInfo_Value(cut_items[i+3], "D_POSITION", start_item + length_item1 + length_item2 + length_item3 + length_item2 + length_item3)
                
                start_part4 = start_item + length_item1 + length_item2 + length_item3 - 0.25 * length_middle
                end_part4 = start_item + length_item1 + length_item2 + length_item3 + length_item2 + length_item3 + length_item4
                reaper.BR_SetItemEdges(cut_items[i+3], start_part4, end_part4)
                start_item3 = reaper.GetMediaItemInfo_Value(cut_items[i+2], "D_POSITION")
                reaper.AddProjectMarker2(0, true, start_item3, start_item3 + length_middle, "#LOOP", -1, 0)
            else
                Msg("Skipping group of 4 items starting at index " .. i .. " because not all items exist.")
            end
        end
        
        -- Restore the original state of the "Create automatic fade-in/fade-out for new items and when splitting" option
        if auto_fade_state == 1 then
            reaper.Main_OnCommand(41194, 0)
        end
    else 
        Msg("No Item selected")
    end
end
-- Start the undo block
reaper.Undo_BeginBlock()

-- Run the functions
reaper.ShowConsoleMsg("")
Select_Media_On_Selected_Tracks()
Move_items()
Move_regions()
Loop_Creator()

-- Update the graphical interface
reaper.UpdateArrange()

-- End the undo block and allow to undo the whole script with one undo action
reaper.Undo_EndBlock("Run script with multiple actions", -1)