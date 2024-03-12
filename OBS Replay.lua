obs         = obslua
source_name = ""
hotkey_id   = obs.OBS_INVALID_HOTKEY_ID
attempts    = 0
last_replay = ""
aktiv_scen  = ""
repis_scen    = ""

----------------------------------------------------------

function try_play()

	local replay_buffer = obs.obs_frontend_get_replay_buffer_output()
	if replay_buffer == nil then
		obs.remove_current_callback()
		return
	end

	-- Call the procedure of the replay buffer named "get_last_replay" to
	-- get the last replay created by the replay buffer
	local cd = obs.calldata_create()
	local ph = obs.obs_output_get_proc_handler(replay_buffer)
	obs.proc_handler_call(ph, "get_last_replay", cd)
	local path = obs.calldata_string(cd, "path")
	obs.calldata_destroy(cd)

	obs.obs_output_release(replay_buffer)

	if path == last_replay then
		path = nil
	end

	-- If the path is valid and the source exists, update it with the
	-- replay file to play back the replay.  Otherwise, stop attempting to
	-- replay after 10 retries
	if path == nil then
		attempts = attempts + 1
		if attempts >= 10 then
			obs.remove_current_callback()
		end
	else
		last_replay = path
		local source = obs.obs_get_source_by_name(source_name)
		if source ~= nil then
			local settings = obs.obs_data_create()
			source_id = obs.obs_source_get_id(source)
			aktiv_scen = getCurrentScene()
			print (aktiv_scen)
			print ("-Repris-")
			print (repis_scen)
			if source_id == "ffmpeg_source" then
			 
				local scene_source = obs.obs_get_source_by_name(repis_scen)

				if scene_source ~= nil then
					obs.obs_frontend_set_current_scene(scene_source)
					obs.obs_source_release(scene_source)
				end
				obs.obs_data_set_string(settings, "local_file", path)
				obs.obs_data_set_bool(settings, "is_local_file", true)

				-- updating will automatically cause the source to
				-- refresh if the source is currently active
				obs.obs_source_update(source, settings)
				obs.timer_add(ater,9500)
			elseif source_id == "vlc_source" then
				local scene_source = obs.obs_get_source_by_name(repis_scen)

				if scene_source ~= nil then
					obs.obs_frontend_set_current_scene(scene_source)
					obs.obs_source_release(scene_source)
				end
				-- "playlist"
				array = obs.obs_data_array_create()
				item = obs.obs_data_create()
				obs.obs_data_set_string(item, "value", path)
				obs.obs_data_array_push_back(array, item)
				obs.obs_data_set_array(settings, "playlist", array)

				-- updating will automatically cause the source to
				-- refresh if the source is currently active
				obs.obs_source_update(source, settings)
				obs.obs_data_release(item)
				obs.obs_data_array_release(array)
				--obs.timer_add(ater,10000)
			end
			

			obs.obs_data_release(settings)
			obs.obs_source_release(source)
		end

		obs.remove_current_callback()
	end
	
end

function ater()
local scene_source = obs.obs_get_source_by_name(aktiv_scen)

				if scene_source ~= nil then
				print ("byter till tillbaka till förgånde scen")
					obs.obs_frontend_set_current_scene(scene_source)
					obs.obs_source_release(scene_source)
				end
obs.remove_current_callback()

end
function sourceFinishedCallback(source)
print("här")
print(source.source_name)
    if source_name == source.source_name then
        -- Byt scen, gör något annat, etc.
        print("Källan '" .. source_name .. "' har spelat klart!")
        -- Exempel: Byt till en annan scen
        obs.obs_frontend_set_current_scene("Pågående spel m. poäng")
		obs.obs_source_release(scene_source)
    end
end

-- The "Instant Replay" hotkey callback
function instant_replay(pressed)
	if not pressed then
		return
	end

	local replay_buffer = obs.obs_frontend_get_replay_buffer_output()
	if replay_buffer ~= nil then
		-- Call the procedure of the replay buffer named "get_last_replay" to
		-- get the last replay created by the replay buffer
		local ph = obs.obs_output_get_proc_handler(replay_buffer)
		obs.proc_handler_call(ph, "save", nil)

		-- Set a 2-second timer to attempt playback every 1 second
		-- until the replay is available
		if obs.obs_output_active(replay_buffer) then
			attempts = 0
			
			obs.timer_add(try_play, 2000)
			
		else
			obs.script_log(obs.LOG_WARNING, "Tried to save an instant replay, but the replay buffer is not active!")
		end

		obs.obs_output_release(replay_buffer)
	else
		obs.script_log(obs.LOG_WARNING, "Tried to save an instant replay, but found no active replay buffer!")
	end
end

----------------------------------------------------------

-- A function named script_update will be called when settings are changed
function script_update(settings)
	source_name = obs.obs_data_get_string(settings, "source")
	repis_scen =  obs.obs_data_get_string(settings, "scene_list")
	print("skript updateras")
	print(source_name)
	print("-----")
	registerSourceFinishedCallback()
end

-- A function named script_description returns the description shown to
-- the user
function script_description()
	return "When the \"Instant Replay\" hotkey is triggered, saves a replay with the replay buffer, and then plays it in a media source as soon as the replay is ready.  Requires an active replay buffer.\n\nMade by Lain and Exeldro"
end

-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
	props = obs.obs_properties_create()

	local p = obs.obs_properties_add_list(props, "source", "Repis källa", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_id(source)
			if source_id == "ffmpeg_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			elseif source_id == "vlc_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			else
				-- obs.script_log(obs.LOG_INFO, source_id)
			end
		end
	end

	
	-----------------
    --local props_scene = obs.obs_properties_create()
    local scenes = obs.obs_frontend_get_scenes()
    
    if scenes ~= nil then
        local sceneList = obs.obs_properties_add_list(props, "scene_list", "Scener", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
        
        for _, sceneName in ipairs(scenes) do
		local name = obs.obs_source_get_name(sceneName)
            obs.obs_property_list_add_string(sceneList, name, name)
        end
    end
	
	-------------------
	
		obs.source_list_release(sources)

	return props
end



-- A function named script_load will be called on startup
function script_load(settings)
	hotkey_id = obs.obs_hotkey_register_frontend("instant_replay.trigger", "Repris", instant_replay)
	local hotkey_save_array = obs.obs_data_get_array(settings, "instant_replay.trigger")
	obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
	--registerSourceFinishedCallback()
end

-- A function named script_save will be called when the script is saved
--
-- NOTE: This function is usually used for saving extra data (such as in this
-- case, a hotkey's save data).  Settings set via the properties are saved
-- automatically.
function script_save(settings)
	local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "instant_replay.trigger", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end

 function registerSourceFinishedCallback()
 --source_name = obs.obs_data_get_string(settings, "source")
print(source_name)
     local source = obs.obs_get_source_by_name(source_name)
    if source ~= nil then
	print("Source")
	--print(source)
        -- Skapa en callback som körs när källan har spelat klart
        sourceFinishedCallbackFunc = obs.obs_source_get_signal_handler(source)
        obs.signal_handler_connect(sourceFinishedCallbackFunc, sourceFinishedCallback)
    else
        print("Kan inte hitta källan med namn: " .. source_name)
    end
end

 function getCurrentScene()
    local currentScene = obs.obs_frontend_get_current_scene()
    if currentScene ~= nil then
        local sceneName = obs.obs_source_get_name(currentScene)
        obs.obs_source_release(currentScene)
        return sceneName
    else
        return "Ingen scen är aktiv"
    end
end
