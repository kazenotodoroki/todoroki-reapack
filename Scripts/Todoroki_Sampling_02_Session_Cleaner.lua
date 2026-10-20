-- @description Session Cleaner
-- @author Todoroki
-- @version 1.0
-- @changelog
--   Première version
-- @about
--   Supprime les régions et marqueurs commençant par "/".

-- Split items function
local function splitItemsAtPosition(position, track)
    for j = 0, reaper.CountTrackMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, j)
        local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        
        if position > itemStart and position < itemEnd then
            reaper.SplitMediaItem(item, position)
        end
    end
end

-- 1. Delete markers and regions starting with "/"
local i = 0
while i < reaper.CountProjectMarkers(0) do
    local _, isrgn, _, _, name, _ = reaper.EnumProjectMarkers(i)
    if name:sub(1,1) == "/" then
        reaper.DeleteProjectMarkerByIndex(0, i)
    else
        i = i + 1
    end
end

-- 2. Split all items at the beginning and end of each region
for i = 0, reaper.CountProjectMarkers(0)-1 do
    local _, isrgn, startPos, endPos = reaper.EnumProjectMarkers(i)
    if isrgn then
        for j = 0, reaper.CountSelectedTracks(0)-1 do
            local track = reaper.GetSelectedTrack(0, j)
            splitItemsAtPosition(startPos, track)
            splitItemsAtPosition(endPos, track)
        end
    end
end

-- 3. Delete items outside of any region
for j = 0, reaper.CountSelectedTracks(0)-1 do
    local track = reaper.GetSelectedTrack(0, j)
    local itemsToDelete = {}
    for k = 0, reaper.CountTrackMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, k)
        local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local isInRegion = false
        
        for i = 0, reaper.CountProjectMarkers(0)-1 do
            local _, isrgn, startPos, endPos = reaper.EnumProjectMarkers(i)
            if isrgn and not (itemEnd <= startPos or itemStart >= endPos) then
                isInRegion = true
                break
            end
        end
        
        if not isInRegion then
            table.insert(itemsToDelete, item)
        end
    end
    
    for _, item in ipairs(itemsToDelete) do
        reaper.DeleteTrackMediaItem(track, item)
    end
end

-- Update the graphical interface
reaper.UpdateArrange()
