# @description FX Lua Creator
# @author Todoroki
# @version 1.2
# @changelog
#   Première version
# @provides
#   [nomain] .
# @about
#   Crée des actions toggle (pour la toolbar) à partir des paramètres d'un plugin.
#   Outil externe : à lancer avec Python, en dehors de REAPER.

def parse_params_from_input(input_text):
    """Parse the pasted input into a list of (index, name) tuples."""
    params = []
    for line in input_text.strip().split('\n'):
        if not line.startswith("Param index:"):
            continue
        first_comma = line.index(',')
        index_part = line[:first_comma]
        name_part = line[first_comma + 1:]
        index = int(index_part.split(':')[1].strip())
        name = name_part.split(':', 1)[1].strip()
        params.append((index, name))
    return params

def generate_lua_scripts(track_num, plugin_name, params, use_monitor):
    for param_index, param_name in params:

        if use_monitor:
            get_track_and_plugin_func = f"""
function get_track_and_plugin_idx()
    local track = reaper.GetMasterTrack(0)
    local fx_count = reaper.TrackFX_GetRecCount(track)
    for fx_idx = 0, fx_count - 1 do
        local ret, fx_name = reaper.TrackFX_GetFXName(track, 0x1000000 + fx_idx, "")
        if string.find(fx_name, plugin_name_part) then
            return track, 0x1000000 + fx_idx
        end
    end
    return nil, -1
end"""
            call_func = "local track, plugin_idx = get_track_and_plugin_idx()"
            error_msg = f"Plugin part of name '\" .. plugin_name_part .. \"' not found in Monitoring FX"
        else:
            get_track_and_plugin_func = f"""
function get_track_and_plugin_idx()
    local track = reaper.GetTrack(0, track_num - 1)
    local fx_count = reaper.TrackFX_GetCount(track)
    for fx_idx = 0, fx_count - 1 do
        local ret, fx_name = reaper.TrackFX_GetFXName(track, fx_idx, "")
        if string.find(fx_name, plugin_name_part) then
            return track, fx_idx
        end
    end
    return nil, -1
end"""
            call_func = "local track, plugin_idx = get_track_and_plugin_idx()"
            error_msg = f"Plugin part of name '\" .. plugin_name_part .. \"' not found on track \" .. track_num"

        track_num_line = f"local track_num = {track_num}\n" if not use_monitor else ""

        script_content = f"""-- Generated Lua Script to toggle parameter
{track_num_line}local plugin_name_part = "{plugin_name}"
local param_index = {param_index}

_, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
{get_track_and_plugin_func}

function getCurrentParamToggleState(track, plugin_idx, param_index)
    local param_value = reaper.TrackFX_GetParamNormalized(track, plugin_idx, param_index)
    return param_value >= 0.5 and "1" or "0"
end

function togglePluginParameter(track, plugin_idx, param_index, expectedState)
    local currentState = getCurrentParamToggleState(track, plugin_idx, param_index)
    if currentState ~= expectedState then
        local newValue = currentState == "0" and 1 or 0
        reaper.TrackFX_SetParamNormalized(track, plugin_idx, param_index, newValue)
    end
end

{call_func}
if plugin_idx ~= -1 then
    local expectedState = reaper.GetToggleCommandStateEx(sectionID, cmdID) == 1 and "0" or "1"
    togglePluginParameter(track, plugin_idx, param_index, expectedState)
    reaper.SetToggleCommandState(sectionID, cmdID, expectedState == "1" and 1 or 0)
    reaper.RefreshToolbar2(sectionID, cmdID)
else
    reaper.ShowMessageBox("{error_msg}", "Error", 0)
end
"""
        chain_label = "Monitor" if use_monitor else f"Track{track_num}"
        script_name = f"FX_Switch_{chain_label}_{plugin_name}_{param_name.replace(' ', '_')}.lua"
        with open(script_name, "w") as script_file:
            script_file.write(script_content)
        print(f"Generated Lua script: {script_name}")

def main():
    fx_chain = input("FX chain? (track/monitor) [default: track]: ").strip().lower()
    use_monitor = fx_chain == "monitor"

    track_num = None
    if not use_monitor:
        track_num = input("Enter the track number where the plugin is placed: ")

    plugin_name = input("Enter part of the plugin name: ")

    print("Paste the parameters list, then type 'end' on a new line and press Enter:")
    input_lines = []
    while True:
        line = input()
        if line == 'end':
            break
        input_lines.append(line)

    input_text = '\n'.join(input_lines)
    params = parse_params_from_input(input_text)
    generate_lua_scripts(track_num, plugin_name, params, use_monitor)

if __name__ == "__main__":
    main()
