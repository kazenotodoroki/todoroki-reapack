-- @description FX Param_idx Lister
-- @author Todoroki
-- @version 1.0
-- @changelog
--   Première version
-- @about
--   Liste les paramètres d'un plugin et leurs index.

-- Function to get user input for track number and part of plugin name
function GetUserInput()
  local title = "Enter Track and Plugin Info"
  local num_inputs = 2
  local captions_csv = "Track Number,Part of Plugin Name"
  local defaults_csv = "2,ISOL8"
  
  -- Prompt the user for input
  local retval, user_input_csv = reaper.GetUserInputs(title, num_inputs, captions_csv, defaults_csv)
  
  -- Check if user clicked OK
  if retval then
    -- Split the user input CSV into individual values
    local track_num, plugin_name_part = user_input_csv:match("([^,]+),([^,]+)")
    
    -- Convert track number from string to integer
    track_num = tonumber(track_num)
    
    return track_num, plugin_name_part  -- Return the values
  else
    return nil  -- User clicked cancel, return nil
  end
end

-- Function to list plugin parameters based on user input
function ListPluginParameters()
  local track_num, plugin_name_part = GetUserInput()  -- Get user input
  
  -- Check if user input was received
  if track_num and plugin_name_part then
    local track = reaper.GetTrack(0, track_num - 1)  -- Get the track (0-based index)
    
    -- Find the plugin based on part of name
    for fx_index = 0, reaper.TrackFX_GetCount(track) - 1 do
      local retval, fx_name = reaper.TrackFX_GetFXName(track, fx_index, "")
      if fx_name:match(plugin_name_part) then
        -- Plugin found, list its parameters
        local param_count = reaper.TrackFX_GetNumParams(track, fx_index)
        for param_index = 0, param_count - 1 do
          local retval, param_name = reaper.TrackFX_GetParamName(track, fx_index, param_index, "")
          reaper.ShowConsoleMsg("Param index: " .. param_index .. ", Param name: " .. param_name .. "\n")
        end
        break  -- Exit the loop once the plugin is found
      end
    end
  else
    reaper.ShowConsoleMsg("User input cancelled or invalid.\n")
  end
end

ListPluginParameters()  -- Execute the function to list plugin parameters
