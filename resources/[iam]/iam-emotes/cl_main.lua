-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

RegisterNetEvent('emotes:cancel')

AddEventHandler('emotes:cancel', function() 
	endAnimations() 
end)

AddEventHandler('emotes:c', function() 
	endAnimations() 
end)

AddEventHandler("emotes:playanimation", function(anim)
    startAnimation(anim)
end)

-------------------------------------------------------------------------------
-- State / Constants
-------------------------------------------------------------------------------

playingEmote = false
local AnimSet = "default" -- Movement animation for the ped
local lastAnimPlayed = "none"
isDead = 0

AnimationOptionsBitmask = {
	REPEAT = 1,
	STOP_LAST_FRAME = 2,
	UNKOWN_1 = 4,
	UNKOWN_2 = 8,
	UPPERBODY = 16,
	ENABLE_PLAYER_CONTROL = 32,
	UNKOWN_3 = 64,
	CANCELABLE = 128,
	UNKOWN_4 = 256,
	UNKOWN_5 = 512,
	UNKOWN_6 = 1024,
	UNKOWN_7 = 2048,
}

AnimationEffectArea = {
	UPPERBODY = 1,
	FULLBODY = 2,
}

AnimationPlayback = {
	REPEAT = 1,				-- Loop
	STOP_LAST_FRAME = 2,	-- Freeze at the last frame
	PLAY_ONCE = 3,			-- Play once then end the animation
	REPEAT_LAST_FRAME = 4,	-- Loop at the last frame
}

-- Cooldowns
local emotesWithCooldowns = {
    ["weights"] = true
}
local emoteCooldowns = {}

-------------------------------------------------------------------------------
-- Register slash commands
-------------------------------------------------------------------------------

RegisterCommand('e', function(source, args, raw) 
    TriggerEvent('emotes:playanimation', args[1]) 
end)
RegisterCommand('emote', function(source, args, raw) 
    TriggerEvent('emotes:playanimation', args[1]) 
end)
RegisterCommand('emotes', function()
    TriggerEvent('emotes:OpenMenu')
end)

-------------------------------------------------------------------------------
-- Player Death
-------------------------------------------------------------------------------

-- TODO: Instead of a event that toggles the current state, pass the state in the event
RegisterNetEvent('player:death')
AddEventHandler('player:death', function()
    if isDead == 0 then
        isDead = 1
    else
        isDead = 0
    end
end)

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

function startAnimation(anim)

    if isDead == 0 then
    
        local ped = PlayerPedId()

        if ped then

            if playingEmote then
                endAnimations()
                if lastAnimPlayed == anim then return end
            end

            lastAnimPlayed = anim
            playingEmote = true
            local animName = string.lower(anim)
            local anim = anims[animName]
            local model = GetEntityModel(PlayerPedId())

            if not anim then
                playingEmote = false
                return
            end

			-- Check for cooldown
            if emotesWithCooldowns[animName] then
                local time = GetGameTimer()
                if emoteCooldowns[animName] and time - emoteCooldowns[animName] < 5000 then
                    return
                end
                emoteCooldowns[animName] = time
            end
			
            if type(anim) == "function" then
            	-- If the anim is a function, call it
                anim(ped)
            elseif type(anim) == "table" and anim.t == 1 then
           	 	-- If the animation is table data, play it
            	--playAnimationFromDict(ped, anim.d, anim.a)
            	playAnimation(ped, animDict, animName, nil)
            else
				-- The animation is a scenario name
				-- Don't play while in a vehicle
				if not (IsPedInAnyVehicle(PlayerPedId(), false)) then

					-- Play the scene
					TaskStartScenarioInPlace(ped, anim, 0, false)
					playingEmote = false
				end
			end
        end
    end
end

function endAnimations()

    ped = PlayerPedId()

    if ped then

        ClearPedTasks(ped)
        playingEmote = false
        TriggerEvent("iam-props:destroyPropRight")
        TriggerEvent("iam-props:destroyPropLeft")
        TriggerEvent("iam-props:destroyPermanentProp")
    end

end

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(0)
    end
end

local function playAnimation(ped, animDict, animName, rightPropName, leftPropName, animationEffectArea, animationPlayback)
	
	local flags = 0
	
	if animationPlayback == AnimationPlayback.STOP_LAST_FRAME then
		flags = flags + AnimationOptionsBitmask.STOP_LAST_FRAME
	elseif animationPlayback == AnimationPlayback.REPEAT or animationPlayback == nil then
		flags = flags + AnimationOptionsBitmask.REPEAT
	elseif animationPlayback == AnimationPlayback.REPEAT_LAST_FRAME then
		flags = flags + AnimationOptionsBitmask.REPEAT
		flags = flags + AnimationOptionsBitmask.STOP_LAST_FRAME
	end
	
    if animationEffectArea == AnimationEffectArea.UPPERBODY then
    	flags = flags + AnimationOptionsBitmask.UPPERBODY
    end
    
    flags = flags + AnimationOptionsBitmask.ENABLE_PLAYER_CONTROL
    
	TriggerEvent("iam-props:dropAllWeapons")

	RequestAnimDict(animDict)
	while not HasAnimDictLoaded(animDict) and not handCuffed do
	  Citizen.Wait(0)
	end

	if IsEntityPlayingAnim(ped, animDict, animName, 3) then
	  ClearPedSecondaryTask(ped)
	else
	  local animLength = GetAnimDuration(animDict, animName)
	  TaskPlayAnim(ped, animDict, animName, 1.0, 1.0, animLength, flags, 0, 0, 0, 0)
	end
	
	if rightPropName then
		TriggerEvent("iam-props:destroyPropRight")
		TriggerEvent("iam-props:attachPropRightObj", rightPropName)
	end
	
	if leftPropName then
		TriggerEvent("iam-props:destroyPropLeft")
		TriggerEvent("iam-props:attachPropLeftObj", leftPropName)
	end
end

-------------------------------------------------------------------------------
-- Movement and Gait
-- TODO: This belongs in it's own resource
-------------------------------------------------------------------------------

local tempenabled = false
local tempset = "move_m@injured"
RegisterNetEvent('AnimSet:Set:temp');
AddEventHandler('AnimSet:Set:temp', function(enabled, enabledSet)
    tempenabled = enabled
    tempset = enabledSet
    TriggerEvent("AnimSet:Set")
end)

RegisterNetEvent('AnimSet:Set');
AddEventHandler('AnimSet:Set', function()
    if tempenabled then
        RequestAnimSet(tempset)
        while not HasAnimSetLoaded(tempset) do Citizen.Wait(0) end
        SetPedMovementClipset(PlayerPedId(), tempset)
        SetPedWeaponMovementClipset(PlayerPedId(), tempset)
        ResetPedStrafeClipset(PlayerPedId())
    else
        if AnimSet == "default" then
            ResetPedMovementClipset(PlayerPedId())
            ResetPedWeaponMovementClipset(PlayerPedId())
            ResetPedStrafeClipset(PlayerPedId())
        else
            RequestAnimSet(AnimSet)
            while not HasAnimSetLoaded(AnimSet) do Citizen.Wait(0) end
            SetPedMovementClipset(PlayerPedId(), AnimSet)
            ResetPedWeaponMovementClipset(PlayerPedId())
            ResetPedStrafeClipset(PlayerPedId())
        end
    end
end)

RegisterNetEvent("emote:setAnimsFromObj");
AddEventHandler("emote:setAnimsFromObj", function(anim)
    if anim == "none" or anim == nil then return end
    if anim == "default" then
        ResetPedMovementClipset(PlayerPedId(), 0)
    else
        RequestAnimSet(anim)
        while not HasAnimSetLoaded(anim) do Citizen.Wait(0) end
        SetPedMovementClipset(PlayerPedId(), anim, true)
    end

    AnimSet = anim;
end)

AddEventHandler("playerSpawned", function()
--    TODO: Implement
end)


RegisterNetEvent('AnimSet:default');
AddEventHandler('AnimSet:default', function()
    ResetPedMovementClipset(PlayerPedId(), 0)
    AnimSet = "default";
    TriggerServerEvent("police:setAnimData", AnimSet)
end)

RegisterNetEvent("Animation:Set:Gait")
AddEventHandler("Animation:Set:Gait", function(pArgs)
    local setGait = pArgs[1]
    RequestAnimSet(setGait)
    while not HasAnimSetLoaded(setGait) do Citizen.Wait(1) end
    SetPedMovementClipset(PlayerPedId(), setGait, 0.2)
    AnimSet = setGait
    TriggerServerEvent("police:setAnimData", AnimSet)
    if setGait == "move_m@swagger" then
      if exports["np-inventory"]:hasEnoughOfItem("pimpcane", 1) then
        TriggerEvent("iam-props:attach", "prop_cs_walking_stick")
      end
    end
end)

RegisterNetEvent("Animation:Set:Reset")
AddEventHandler("Animation:Set:Reset", function()
    TriggerEvent("Animation:Set:Gait",{AnimSet})
end)

-------------------------------------------------------------------------------
-- Emote Dict
-------------------------------------------------------------------------------

anims = {
    ["kneel"] = "CODE_HUMAN_MEDIC_KNEEL",
    ["medic"] = "CODE_HUMAN_MEDIC_TEND_TO_DEAD",
    ["traffic"] = "WORLD_HUMAN_CAR_PARK_ATTENDANT",
    ["binoculars"] = "WORLD_HUMAN_BINOCULARS",
    ["bum"] = "WORLD_HUMAN_BUM_FREEWAY",
    ["slump"] = "WORLD_HUMAN_BUM_SLUMPED",
    ["bumstand"] = "WORLD_HUMAN_BUM_STANDING",
    ["wash"] = "WORLD_HUMAN_BUM_WASH",
    ["cheer"] = "WORLD_HUMAN_CHEERING",
    ["drill"] = "WORLD_HUMAN_CONST_DRILL",
    ["dealer"] = "WORLD_HUMAN_DRUG_DEALER",
    ["filmshocking"] = "WORLD_HUMAN_MOBILE_FILM_SHOCKING",
    ["leafblower"] = "WORLD_HUMAN_GARDENER_LEAF_BLOWER",
    ["gardening"] = "WORLD_HUMAN_GARDENER_PLANT",
    ["guardpatrol"] = "WORLD_HUMAN_GUARD_PATROL",
    ["hammering"] = "WORLD_HUMAN_HAMMERING",
    ["hangout"] = "WORLD_HUMAN_HANG_OUT_STREET",
    ["statue"] = "WORLD_HUMAN_HUMAN_STATUE",
    ["janitor"] = "WORLD_HUMAN_JANITOR",
    ["jog"] = "WORLD_HUMAN_JOG_STANDING",
    ["maid"] = "WORLD_HUMAN_MAID_C",
    ["flex"] = "WORLD_HUMAN_MUSCLE_FLEX",
    ["weights"] = "WORLD_HUMAN_MUSCLE_FREE_WEIGHTS",
    ["musician"] = "WORLD_HUMAN_MUSICIAN",
    ["party"] = "WORLD_HUMAN_PARTYING",
    ["pushups"] = "WORLD_HUMAN_PUSH_UPS",
    ["shinetorch"] = "WORLD_HUMAN_SECURITY_SHINE_TORCH",
    ["weed"] = "WORLD_HUMAN_SMOKING_POT",
    ["impatient"] = "WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT",
    ["map"] = "WORLD_HUMAN_TOURIST_MAP",
    ["mechanic"] = "WORLD_HUMAN_VEHICLE_MECHANIC",
    ["welding"] = "WORLD_HUMAN_WELDING",
    ["browse"] = "WORLD_HUMAN_WINDOW_SHOP_BROWSE",
    ["yoga"] = "WORLD_HUMAN_YOGA",
    ["cheer1"] = {
        t = 1,
        a = "backslap_right",
        d = "anim@mp_player_intcelebrationpaired@f_f_backslap"
    },
    ["cheer2"] = {
        t = 1,
        a = "bro_hug_left",
        d = "anim@mp_player_intcelebrationpaired@f_m_bro_hug"
    },
    ["high5"] = {
    	t = 1, 
    	a = "highfive_guy_a", 
    	d = "mp_ped_interaction"},
    ["arsepick"] = {
        t = 1,
        a = "mp_player_int_arse_pick",
        d = "mp_player_int_upperarse_pick",
        e = "mp_player_int_arse_pick_exit"
    },
    ["ballgrab"] = {
        t = 1,
        a = "mp_player_int_grab_crotch",
        d = "mp_player_int_uppergrab_crotch",
        e = "mp_player_int_grab_crotch_exit"
    },
    ["gangsign3"] = {
        t = 1,
        a = "mp_player_int_bro_love",
        d = "mp_player_int_upperbro_love",
        e = "mp_player_int_bro_love_exit"
    },
    ["fuckyou"] = {
        t = 1,
        a = "mp_player_int_v_sign",
        d = "mp_player_int_upperv_sign",
        e = "mp_player_int_v_sign_exit"
    },

    ["c"] = function(ped)
		endAnimations()
    end,
    ["cancel"] = function(ped)
		endAnimations()
    end,
    ["holster"] = function(ped)
		playAnimation(ped, "reaction@intimidation@cop@unarmed", "intro", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.STOP_LAST_FRAME)
    end,
	["notepad"] = function(ped)
		playAnimation(ped, "amb@medic@standing@timeofdeath@base", "base", "notepad01", "pencil01", AnimationEffectArea.UPPERBODY)
	end,
    ["clipboard"] = function(ped)
    	playAnimation(ped, "move_m@clipboard", "idle", "clipboard01", nil, AnimationEffectArea.UPPERBODY)
    end,
    ["coffee"] = function(ped)
    	playAnimation(ped, "amb@world_human_drinking@coffee@male@idle_a", "idle_c", "coffee", nil, AnimationEffectArea.UPPERBODY)
    end,
    ["phone"] = function(ped)
    	playAnimation(ped, "cellphone@","cellphone_text_read_base", "phone01", nil, AnimationEffectArea.UPPERBODY)
    end,
    ["tennis"] = function(ped)
    	playAnimation(ped, "amb@world_human_tennis_player@male@base","base", "tennis", nil, AnimationEffectArea.UPPERBODY)
    end,
    ["stupor"] = function(ped)
    	playAnimation(ped, "amb@world_human_stupor@male_looking_right@base", "base", nil, nil)
    end,
    ["piss"] = function(ped)
    	playAnimation(ped, "missbigscore1switch_trevor_piss", "piss_loop", nil, nil)
    end,
    ["shit"] = function(ped)
    	playAnimation(ped, "missfbi3ig_0", "shit_loop_trev", nil, nil)
    end,
    ["shower"] = function(ped)
    	playAnimation(ped, "mp_safehouseshower@male@", "male_shower_idle_a", nil, nil)
    end,
    ["lean"] = function(ped)
    	playAnimation(ped, "amb@world_human_leaning@male@wall@back@legs_crossed@base", "base", nil, nil)
    end,
    ["chinups"] = function(ped)
    	playAnimation(ped, "amb@prop_human_muscle_chin_ups@male@base", "base", nil, nil)
    end,
    ["situps"] = function(ped)
		playAnimation(ped, "amb@world_human_sit_ups@male@idle_a", "idle_a", nil, nil)
    end,
    ["shrug3"] = function(ped)
    	playAnimation(ped, "oddjobs@bailbond_hobohang_out_street_b", "idle_b", nil, nil)
    end,
    ["search"] = function(ped)
		playAnimation(ped, "missexile3", "ex03_dingy_search_case_a_michael", nil, nil)
    end,
    ["kneel3"] = function(ped)
		playAnimation(ped, "oddjobs@hunter", "idle_a", nil, nil)
    end,
    ["uncuff"] = function(ped)
    	playAnimation(ped, "mp_arresting", "a_uncuff", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["trunk"] = function(ped)
		playAnimation(ped, "fin_ext_p1-7", "cs_devin_dual-7", nil, nil)
    end,
    ["lighter"] = function(ped)
		playAnimation(ped, "cover@first_person@weapon@grenade", "hi_l_cook", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["kickindoor"] = function(ped)
		playAnimation(ped, "missprologuemcs_1", "kick_down_player_zero", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["stretch5"] = function(ped)
		playAnimation(ped, "switch@franklin@bed", "stretch_short", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["pill"] = function(ped)
    	playAnimation(ped, "mp_suicide", "pill", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["stretch2"] = function(ped)
		playAnimation(ped, "switch@franklin@bed", "stretch_long", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["getup"] = function(ped)
		playAnimation(ped, "switch@franklin@bed", "sleep_getup_rubeyes", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["layspike"] = function(ped)
		playAnimation(ped, "weapons@first_person@aim_rng@generic@projectile@thermal_charge@", "plant_floor", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["layspike2"] = function(ped)
		playAnimation(ped, "weapons@first_person@aim_rng@generic@projectile@thermal_charge@", "plant_floor", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["hairtie"] = function(ped)
		playAnimation(ped, "amb@code_human_wander_idles@female@idle_a", "idle_a_hairtouch", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["veston"] = function(ped)
		playAnimation(ped, "clothingtie", "try_tie_positive_a", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["dab"] = function(ped)
		playAnimation(ped, "amb@world_human_statue@base", "base", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["cokecut"] = function(ped)
		playAnimation(ped, "anim@amb@business@coc@coc_unpack_cut@", "fullcut_cycle_v6_cokecutter", nil, nil)
    end,
    ["beg"] = function(ped)
		playAnimation(ped, "oddjobs@bailbond_mountain", "excited_idle_b", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["searchground"] = function(ped)
		playAnimation(ped, "clothingshoes", "try_shoes_positive_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["taxi"] = function(ped)
		playAnimation(ped, "taxi_hail", "hail_taxi", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["forgetit"] = function(ped)
		playAnimation(ped, "taxi_hail", "forget_it", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["cop"] = function(ped)
    	playAnimation(ped, "amb@world_human_cop_idles@male@idle_a", "idle_b", nil, nil)
    end,
    ["cross"] = function(ped)
    	playAnimation(ped,  "amb@world_human_hang_out_street@female_arms_crossed@base", "base", nil, nil)
    end,
    ["cowerlow"] = function(ped)
    	playAnimation(ped, "amb@code_human_cower@male@base", "base", nil, nil)
    end,
    ["cower"] = function(ped)
    	playAnimation(ped, "amb@code_human_cower_stand@male@base", "base", nil, nil)
    end,
    ["cowerkneel"] = function(ped)
    	playAnimation(ped, "random@homelandsecurity", "knees_loop_girl", nil, nil)
    end,
    ["aware"] = function(ped)
    	playAnimation(ped, "amb@code_human_cross_road@male@base", "base", nil, nil)
    end,
    ["ballscratch"] = function(ped)
    	playAnimation(ped, "amb@code_human_in_car_mp_actions@grab_crotch@std@ds@base", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["cleanfront"] = "WORLD_HUMAN_MAID_CLEAN",
    ["lapdance1"] = function(ped)
    	playAnimation(ped, "mini@strip_club@lap_dance@ld_girl_a_song_a_p1", "ld_girl_a_song_a_p1_f", nil, nil)
    end,
    ["dancef"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@dancers@solomun_entourage@", "mi_dance_facedj_17_v1_female^1", nil, nil)
    end,
    ["dancef2"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@", "high_center", nil, nil)
    end,
    ["dancef3"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@", "high_center_up", nil, nil)
    end,
    ["dancef4"] = function(ped)
    	playAnimation(ped,  "anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^1", nil, nil)
    end,
    ["dancef5"] = function(ped)
    	playAnimation(ped,  "anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^3", nil, nil)
    end,
    ["dancef6"] = function(ped)
    	playAnimation(ped,  "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@", "high_center_up", nil, nil)
    end,
    ["danceslow2"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@", "low_center", nil, nil)
    end,
    ["danceslow3"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@", "low_center_down", nil, nil)
    end,
    ["danceslow4"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@female@var_b@", "low_center", nil, nil)
    end,
    ["dance"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@dancers@podium_dancers@", "hi_dance_facedj_17_v2_male^5", nil, nil)
    end,
    ["dance2"] = function(ped)
		playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@", "high_center_down", nil, nil)
    end,
    ["dance3"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@male@var_a@", "high_center", nil, nil)
    end,
    ["dance4"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@", "high_center_up", nil, nil)
    end,
    ["danceupper"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@female@var_b@", "high_center", nil, nil)
    end,
    ["danceupper2"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@female@var_b@", "high_center_up", nil, nil)
    end,
    ["danceshy"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@male@var_a@", "low_center", nil, nil)
    end,
    ["danceshy2"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@female@var_b@", "low_center_down", nil, nil)
    end,
    ["danceslow"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@", "low_center", nil, nil)
    end,
    ["dancesilly9"] = function(ped)
    	playAnimation(ped, "rcmnigel1bnmt_1b", "dance_loop_tyler", nil, nil)
    end,
    ["dance6"] = function(ped)
    	playAnimation(ped, "misschinese2_crystalmazemcs1_cs", "dance_loop_tao", nil, nil)
    end,
    ["dance7"] = function(ped)
    	playAnimation(ped, "misschinese2_crystalmazemcs1_ig", "dance_loop_tao", nil, nil)
    end,
    ["dance8"] = function(ped)
    	playAnimation(ped, "missfbi3_sniping", "dance_m_default", nil, nil)
    end,
    ["dancesilly"] = function(ped)
    	playAnimation(ped, "special_ped@mountain_dancer@monologue_3@monologue_3a", "mnt_dnc_buttwag", nil, nil)
    end,
    ["dancesilly2"] = function(ped)
    	playAnimation(ped, "move_clown@p_m_zero_idles@", "fidget_short_dance", nil, nil)
    end,
    ["dancesilly3"] = function(ped)
    	playAnimation(ped, "move_clown@p_m_two_idles@", "fidget_short_dance", nil, nil)
    end,
    ["dancesilly4"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@lazlow@hi_podium@", "danceidle_hi_11_buttwiggle_b_laz", nil, nil)
    end,
    ["dancesilly5"] = function(ped)
    	playAnimation(ped, "timetable@tracy@ig_5@idle_a", "idle_a", nil, nil)
    end,
    ["dancesilly6"] = function(ped)
    	playAnimation(ped, "timetable@tracy@ig_8@idle_b", "idle_d", nil, nil)
    end,
    ["dance9"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@", "med_center_up", nil, nil)
    end,
    ["dancesilly8"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@the_woogie", "the_woogie", nil, nil)
    end,
    ["danceglowstick"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@lazlow@hi_railing@", "ambclub_13_mi_hi_sexualgriding_laz", "glowstickRight", "glowstickLeft")
    end,
    ["danceglowstick2"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@lazlow@hi_railing@", "ambclub_12_mi_hi_bootyshake_laz", "glowstickRight", "glowstickLeft")
    end,
    ["danceglowstick3"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@lazlow@hi_railing@", "ambclub_09_mi_hi_bellydancer_laz", "glowstickRight", "glowstickLeft")
    end,
    ["dancehorse"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@lazlow@hi_dancefloor@", "dancecrowd_li_15_handup_laz", "toyHorse", nil)
    end,
    ["dancehorse2"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@lazlow@hi_dancefloor@", "crowddance_hi_11_handup_laz", "toyHorse", nil)
    end,
    ["dancehorse3"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@lazlow@hi_dancefloor@", "dancecrowd_li_11_hu_shimmy_laz", "toyHorse", nil)
    end,
    ["conv1"] = function(ped)
    	playAnimation(ped, "special_ped@jessie@monologue_5@monologue_5c", "jessie_ig_1_p5_heressomthinginteresting_2", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["conv2"] = function(ped)
    	playAnimation(ped, "special_ped@jessie@monologue_11@monologue_11c", "jessie_ig_1_p11_canyouimagine_2", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["conv3"] = function(ped)
    	playAnimation(ped, "rcmjosh4", "beckon_a_cop_b", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["cross2"] = function(ped)
    	playAnimation(ped, "rcmme_amanda1", "stand_loop_cop", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["investigate"] = function(ped)
    	playAnimation(ped, "amb@code_human_police_investigate@base", "base", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["curse"] = function(ped)
    	playAnimation(ped, "misscommon@response", "curse", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["taunt"] = function(ped)
    	playAnimation(ped, "misscommon@response", "threaten", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["what"] = function(ped)
    	playAnimation(ped, "misscommon@response", "numbnuts", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["break"] = function(ped)
    	playAnimation(ped, "misscommon@response", "give_me_a_break", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["cmon"] = function(ped)
    	playAnimation(ped, "misscommon@response", "bring_it_on", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["chair"] = function(ped)
        TriggerEvent("emotes:chair")
    end,
    ["carry"] = function(ped) 
    	TriggerEvent("emotes:Carry") 
    end,
    ["shoosh"] = function(ped)
		playAnimation(ped, "anim@mp_player_intuppershush", "idle_a_fp", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["picknose"] = function(ped)
		playAnimation(ped, "anim@mp_player_intuppernose_pick", "exit", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["wanker"] = function(ped)
		playAnimation(ped, "anim@mp_player_intselfiewank", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["id"] = function(ped)
    	playAnimation(ped, "friends@laf@ig_5", "nephew", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["why"] = function(ped)
    	playAnimation(ped, "gestures@m@standing@fat", "gesture_why", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["hi"] = function(ped)
    	playAnimation(ped, "gestures@m@standing@fat", "gesture_hello", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["bye"] = function(ped)
    	playAnimation(ped, "gestures@m@standing@fat", "gesture_bye_soft", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["come"] = function(ped)
    	playAnimation(ped, "gestures@m@standing@fat", "gesture_come_here_hard", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["down"] = function(ped)
    	playAnimation(ped, "gestures@m@standing@fat", "gesture_hand_down", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["yes"] = function(ped)
        playAnimation(ped, "random@getawaydriver", "gesture_nod_yes_hard", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["swatcome"] = function(ped)
    	playAnimation(ped, "swat", "come", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["swatfreeze"] = function(ped)
    	playAnimation(ped, "swat", "freeze", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["swatrally"] = function(ped)
    	playAnimation(ped, "swat", "rally_point", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["swatyes"] = function(ped)
    	playAnimation(ped, "swat", "understood", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["swatback"] = function(ped)
    	playAnimation(ped, "swat", "you_back", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["swatfwd"] = function(ped)
    	playAnimation(ped, "swat", "you_fwd", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["swatleft"] = function(ped)
    	playAnimation(ped, "swat", "you_left", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["swatright"] = function(ped)
    	playAnimation(ped, "swat", "you_right", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["shocked"] = function(ped)
    	playAnimation(ped, "reaction@male_stand@big_variations@idle_a", "react_big_variations_c", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["shocked2"] = function(ped)
    	playAnimation(ped, "reaction@male_stand@big_variations@idle_b", "react_big_variations_f", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["shocked3"] = function(ped)
    	playAnimation(ped, "reaction@male_stand@big_variations@idle_c", "react_big_variations_q", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["shocked4"] = function(ped)
    	playAnimation(ped, "reaction@male_stand@big_variations@idle_c", "react_big_variations_s", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["shocked5"] = function(ped)
    	playAnimation(ped, "reaction@male_stand@small_variations@idle_a", "react_small_variations_d", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["shocked6"] = function(ped)
    	playAnimation(ped, "reaction@male_stand@small_variations@idle_b", "react_small_variations_e", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["shocked7"] = function(ped)
    	playAnimation(ped, "reaction@male_stand@small_variations@idle_c", "react_small_variations_o", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["ziptied"] = function(ped)
    	playAnimation(ped, "re@stag_do@idle_a", "idle_a_ped", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["breakzipties"] = function(ped)
    	playAnimation(ped, "re@stag_do@idle_a", "idle_c_ped", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wavedown"] = function(ped)
    	playAnimation(ped, "random@mugging5", "001445_01_gangintimidation_1_female_idle_b", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["hitch"] = function(ped)
    	playAnimation(ped, "random@hitch_lift", "idle_f", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["handsup2"] = function(ped)
		playAnimation(ped, "missfbi5ig_22", "hands_up_anxious_scientist", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["handsup3"] = function(ped)
		playAnimation(ped, "missfbi5ig_22", "hands_up_loop_scientist", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["handshead"] = function(ped)
    	playAnimation(ped, "random@arrests@busted", "idle_a", nil, nil, nil, animationPlayback.STOP_LAST_FRAME)
    end,
    ["handshead2"] = function(ped)
    	playAnimation(ped, "random@arrests@busted", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["twerk"] = function(ped)
    	playAnimation(ped, "switch@trevor@mocks_lapdance", "001443_01_trvs_28_idle_stripper", nil, nil)
    end,
    ["karate"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@karate_chops", "karate_chops", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["karate2"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationmale@karate_chops", "karate_chops", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["cprstanding"] = function(ped)
    	playAnimation(ped, "mini@cpr@char_a@cpr_str", "cpr_pumpchest", nil, nil)
    end,
    ["suicidepill"] = function(ped)
    	playAnimation(ped, "mp_suicide", "pill", nil, nil)
    end,
    ["drink"] = function(ped)
    	playAnimation(ped, "mp_player_inteat@pnq", "loop", nil, nil, AnimationEffectArea.UPPERBODY, animationPlayback.STOP_LAST_FRAME)
    end,
    ["beast"] = function(ped)
    	playAnimation(ped, "anim@mp_fm_event@intro", "beast_transform", nil, nil, nil, animationPlayback.PLAY_ONCE)
    end,
    ["chill"] = function(ped)
    	playAnimation(ped, "switch@trevor@scares_tramp", "trev_scares_tramp_idle_tramp", nil, nil)
    end,
    ["cloudgaze"] = function(ped)
    	playAnimation(ped, "switch@trevor@annoys_sunbathers", "trev_annoys_sunbathers_loop_girl", nil, nil)
    end,
    ["cloudgaze2"] = function(ped)
    	playAnimation(ped, "switch@trevor@annoys_sunbathers", "trev_annoys_sunbathers_loop_guy", nil, nil)
    end,
    ["prone"] = function(ped)
		playAnimation(ped, "missfbi3_sniping", "prone_dave", nil, nil, nil, animationPlayback.PLAY_ONCE)
     end,
    ["pullover"] = function(ped)
    	playAnimation(ped, "misscarsteal3pullover", "pull_over_right", nil, nil, nil, animationPlayback.PLAY_ONCE)
    end,
    ["idle"] = function(ped)
    	playAnimation(ped, "anim@heists@heist_corona@team_idles@male_a", "idle", nil, nil)
    end,
    ["idle8"] = function(ped)
    	playAnimation(ped, "amb@world_human_hang_out_street@male_b@idle_a", "idle_b", nil, nil)
    end,
    ["idle9"] = function(ped)
    	playAnimation(ped, "friends@fra@ig_1", "base_idle", nil, nil)
    end,
    ["idle10"] = function(ped)
    	playAnimation(ped, "mp_move@prostitute@m@french", "idle", nil, nil)
    end,
    ["idle11"] = function(ped)
    	playAnimation(ped, "random@countrysiderobbery", "idle_a", nil, nil)
    end,
    ["idle2"] = function(ped)
    	playAnimation(ped, "anim@heists@heist_corona@team_idles@female_a", "idle", nil, nil)
    end,
    ["idle3"] = function(ped)
    	playAnimation(ped, "anim@heists@humane_labs@finale@strip_club", "ped_b_celebrate_loop", nil, nil)
    end,
    ["idle4"] = function(ped)
    	playAnimation(ped, "anim@mp_celebration@idles@female", "celebration_idle_f_a", nil, nil)
    end,
    ["idle5"] = function(ped)
    	playAnimation(ped, "anim@mp_corona_idles@female_b@idle_a", "idle_a", nil, nil)
    end,
    ["idle6"] = function(ped)
    	playAnimation(ped, "anim@mp_corona_idles@male_c@idle_a", "idle_a", nil, nil)
    end,
    ["idle7"] = function(ped)
    	playAnimation(ped, "anim@mp_corona_idles@male_d@idle_a", "idle_a", nil, nil)
    end,
    ["wait3"] = function(ped)
    	playAnimation(ped, "amb@world_human_hang_out_street@female_hold_arm@idle_a", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["idledrunk"] = function(ped)
    	playAnimation(ped, "random@drunk_driver_1", "drunk_driver_stand_loop_dd1", nil, nil)
    end,
    ["idledrunk2"] = function(ped)
    	playAnimation(ped, "random@drunk_driver_1", "drunk_driver_stand_loop_dd2", nil, nil)
    end,
    ["idledrunk3"] = function(ped)
    	playAnimation(ped, "missarmenian2", "standing_idle_loop_drunk", nil, nil)
    end,
    ["airguitar"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@air_guitar", "air_guitar", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["airsynth"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@air_synth", "air_synth", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["argue"] = function(ped)
    	playAnimation(ped, "misscarsteal4@actor", "actor_berating_loop", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["argue2"] = function(ped)
    	playAnimation(ped, "oddjobs@assassinate@vice@hooker", "argue_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["bartender"] = function(ped)
    	playAnimation(ped, "anim@amb@clubhouse@bar@drink@idle_a", "idle_a_bartender", nil, nil)
    end,
    ["blowkiss"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@blow_kiss", "blow_kiss", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["blowkiss2"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intselfieblow_kiss", "exit", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["curtsy"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationpaired@f_f_sarcastic", "sarcastic_left", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["comeatmebro"] = function(ped)
    	playAnimation(ped, "mini@triathlon", "want_some_of_this", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["cop2"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@peds@", "rcmme_amanda1_stand_loop_cop", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["cop3"] = function(ped)
    	playAnimation(ped, "amb@code_human_police_investigate@idle_a", "idle_b", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["crossarms"] = function(ped)
    	playAnimation(ped, "amb@world_human_hang_out_street@female_arms_crossed@idle_a", "idle_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["crossarms2"] = function(ped)
    	playAnimation(ped, "amb@world_human_hang_out_street@male_c@idle_a", "idle_b", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["crossarms3"] = function(ped)
    	playAnimation(ped, "anim@heists@heist_corona@single_team", "single_team_loop_boss", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["crossarms4"] = function(ped)
    	playAnimation(ped, "random@street_race", "_car_b_lookout", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["crossarms5"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@peds@", "rcmme_amanda1_stand_loop_cop", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["crossarms6"] = function(ped)
    	playAnimation(ped, "random@shop_gunstore", "_idle", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["crossarmsside"] = function(ped)
    	playAnimation(ped, "rcmnigel1a_band_groupies", "base_m2", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["damn"] = function(ped)
    	playAnimation(ped, "anim@am_hold_up@male", "shoplift_mid", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["pointdown"] = function(ped)
    	playAnimation(ped, "gestures@f@standing@casual", "gesture_hand_down", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["facepalm2"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@face_palm", "face_palm", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["facepalm"] = function(ped)
    	playAnimation(ped, "random@car_thief@agitated@idle_a", "agitated_idle_a", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["facepalm3"] = function(ped)
    	playAnimation(ped, "missminuteman_1ig_2", "tasered_2", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["facepalm4"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intupperface_palm", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["fallover"] = function(ped)
    	playAnimation(ped, "random@drunk_driver_1", "drunk_fall_over", nil, nil, nil, AnimationPlayback.STOP_LAST_FRAME)
    end,
    ["fallover2"] = function(ped)
    	playAnimation(ped, "mp_suicide", "pistol", nil, nil, nil, AnimationPlayback.STOP_LAST_FRAME)
    end,
    ["fallover3"] = function(ped)
    	playAnimation(ped, "friends@frf@ig_2", "knockout_plyr", nil, nil, nil, AnimationPlayback.STOP_LAST_FRAME)
    end,
    ["fallover4"] = function(ped)
    	playAnimation(ped, "anim@gangops@hostage@", "victim_fail", nil, nil, nil, AnimationPlayback.STOP_LAST_FRAME)
    end,
    ["fallasleep"] = function(ped)
    	playAnimation(ped, "mp_sleep", "sleep_loop", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.REPEAT_LAST_FRAME)
    end,
    ["fightme"] = function(ped)
    	playAnimation(ped, "anim@deathmatch_intros@unarmed", "intro_male_unarmed_c", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["fightme2"] = function(ped)
    	playAnimation(ped, "anim@gangops@hostage@", "victim_fail", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["finger"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intselfiethe_bird", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["finger2"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intupperfinger", "idle_a_fp", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["smoke"] = "WORLD_HUMAN_SMOKING",
    ["smokemale"] = function(ped)
    	playAnimation(ped, "amb@world_human_smoking@male@male_a@base", "base", "cigarette", nil, AnimationEffectArea.UPPERBODY)
    end,
    ["smokefemale"] = function(ped)
    	playAnimation(ped, "amb@world_human_smoking@female@idle_a", "idle_b", "cigarette", nil, AnimationEffectArea.UPPERBODY)
    end,
    ["cigarette"] = function(ped)
    	playAnimation(ped, "amb@world_human_smoking@male@male_a@enter", "enter", "cigmouth", nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["cigar"] = function(ped)
    	playAnimation(ped, "amb@world_human_smoking@male@male_a@enter", "enter", "cigar1", nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["cigar2"] = function(ped)
    	playAnimation(ped, "amb@world_human_smoking@male@male_a@enter", "enter", "cigar2", nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["cigar3"] = function(ped)
    	playAnimation(ped, "amb@world_human_smoking@male@male_a@enter", "enter", "cigar3", nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["handshake"] = function(ped)
    	playAnimation(ped, "mp_ped_interaction", "handshake_guy_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["handshake2"] = function(ped)
    	playAnimation(ped, "mp_ped_interaction", "handshake_guy_b", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["wait4"] = function(ped)
    	playAnimation(ped, "amb@world_human_hang_out_street@Female_arm_side@idle_a", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wait5"] = function(ped)
    	playAnimation(ped, "missclothing", "idle_storeclerk", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wait6"] = function(ped)
    	playAnimation(ped, "timetable@amanda@ig_2", "ig_2_base_amanda", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wait7"] = function(ped)
    	playAnimation(ped, "rcmnigel1cnmt_1c", "base", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wait8"] = function(ped)
    	playAnimation(ped, "rcmjosh1", "idle", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wait9"] = function(ped)
    	playAnimation(ped, "rcmjosh2", "josh_2_intp1_base", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wait10"] = function(ped)
    	playAnimation(ped, "timetable@amanda@ig_3", "ig_3_base_tracy", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wait11"] = function(ped)
    	playAnimation(ped, "misshair_shop@hair_dressers", "keeper_base", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["hiking"] = function(ped)
    	playAnimation(ped, "move_m@hiking", "idle", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["hug"] = function(ped)
    	playAnimation(ped, "mp_ped_interaction", "kisses_guy_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["hug2"] = function(ped)
    	playAnimation(ped, "mp_ped_interaction", "kisses_guy_b", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["hug3"] = function(ped)
    	playAnimation(ped, "mp_ped_interaction", "hugs_guy_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["inspect"] = function(ped)
    	playAnimation(ped, "random@train_tracks", "idle_e", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["jazzhands"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@jazz_hands", "jazz_hands", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["jog2"] = function(ped)
    	playAnimation(ped, "amb@world_human_jog_standing@male@idle_a", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["jog3"] = function(ped)
    	playAnimation(ped, "amb@world_human_jog_standing@female@idle_a", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["jog4"] = function(ped)
    	playAnimation(ped, "amb@world_human_power_walker@female@idle_a", "idle_a", nil, nil, nil, AnimationPlayback.REPEAT_LAST_FRAME)
    end,
    ["jog5"] = function(ped)
    	playAnimation(ped, "move_m@joy@a", "walk", nil, nil, nil, AnimationPlayback.REPEAT_LAST_FRAME)
    end,
    ["jumpingjacks"] = function(ped)
    	playAnimation(ped, "timetable@reunited@ig_2", "jimmy_getknocked", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["kneel2"] = function(ped)
    	playAnimation(ped, "rcmextreme3", "idle", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["kneel3"] = function(ped)
    	playAnimation(ped, "amb@world_human_bum_wash@male@low@idle_a", "idle_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["knock"] = function(ped)
    	playAnimation(ped, "timetable@jimmy@doorknock@", "knockdoor_idle", nil, nil)
    end,
    ["knock2"] = function(ped)
    	playAnimation(ped, "missheistfbi3b_ig7", "lift_fibagent_loop", nil, nil)
    end,
    ["knucklecrunch"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@knuckle_crunch", "knuckle_crunch", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["lapdance"] = function(ped)
    	playAnimation(ped, "mp_safehouse", "lap_dance_girl", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["lean2"] = function(ped)
    	playAnimation(ped, "amb@world_human_leaning@female@wall@back@hand_up@idle_a", "idle_a", nil, nil)
    end,
    ["lean3"] = function(ped)
    	playAnimation(ped, "amb@world_human_leaning@female@wall@back@holding_elbow@idle_a", "idle_a", nil, nil)
    end,
    ["lean4"] = function(ped)
    	playAnimation(ped, "amb@world_human_leaning@male@wall@back@foot_up@idle_a", "idle_a", nil, nil)
    end,
    ["lean5"] = function(ped)
    	playAnimation(ped, "amb@world_human_leaning@male@wall@back@hands_together@idle_b", "idle_b", nil, nil)
    end,
    ["leanflirt"] = function(ped)
    	playAnimation(ped, "random@street_race", "_car_a_flirt_girl", nil, nil)
    end,
    ["leanbar2"] = function(ped)
    	playAnimation(ped, "amb@prop_human_bum_shopping_cart@male@idle_a", "idle_c", nil, nil)
    end,
    ["leanbar3"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@lazlow@ig1_vip@", "clubvip_base_laz", nil, nil)
    end,
    ["leanbar4"] = function(ped)
    	playAnimation(ped, "anim@heists@prison_heist", "ped_b_loop_a", nil, nil)
    end,
    ["leanhigh"] = function(ped)
    	playAnimation(ped, "anim@mp_ferris_wheel", "idle_a_player_one", nil, nil)
    end,
    ["leanhigh2"] = function(ped)
    	playAnimation(ped, "anim@mp_ferris_wheel", "idle_a_player_two", nil, nil)
    end,
    ["leanside"] = function(ped)
    	playAnimation(ped, "timetable@mime@01_gc", "idle_a", nil, nil)
    end,
    ["leanside2"] = function(ped)
    	playAnimation(ped, "misscarstealfinale", "packer_idle_1_trevor", nil, nil)
    end,
    ["leanside3"] = function(ped)
    	playAnimation(ped, "misscarstealfinalecar_5_ig_1", "waitloop_lamar", nil, nil)
    end,
    ["leanside4"] = function(ped)
    	playAnimation(ped, "misscarstealfinalecar_5_ig_1", "waitloop_lamar", nil, nil)
    end,
    ["leanside5"] = function(ped)
    	playAnimation(ped, "rcmjosh2", "josh_2_intp1_base", nil, nil)
    end,
    ["me"] = function(ped)
    	playAnimation(ped, "gestures@f@standing@casual", "gesture_me_hard", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["mechanic"] = function(ped)
    	playAnimation(ped, "mini@repair", "fixing_a_ped", nil, nil)
    end,
    ["mechanic2"] = function(ped)
    	playAnimation(ped, "amb@world_human_vehicle_mechanic@male@base", "idle_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["mechanic3"] = function(ped)
    	playAnimation(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["mechanic4"] = function(ped)
    	playAnimation(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["medic2"] = function(ped)
    	playAnimation(ped, "amb@medic@standing@tendtodead@base", "base", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["meditate"] = function(ped)
    	playAnimation(ped, "rcmcollect_paperleadinout@", "meditiate_idle", nil, nil)
    end,
    ["meditate2"] = function(ped)
    	playAnimation(ped, "rcmepsilonism3", "ep_3_rcm_marnie_meditating", nil, nil)
    end,
    ["meditate3"] = function(ped)
    	playAnimation(ped, "rcmepsilonism3", "base_loop", nil, nil)
    end,
    ["metal"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intincarrockstd@ps@", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["no"] = function(ped)
    	playAnimation(ped, "anim@heists@ornate_bank@chat_manager", "fail", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["no2"] = function(ped)
    	playAnimation(ped, "mp_player_int_upper_nod", "mp_player_int_nod_no", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["nosepick"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@nose_pick", "nose_pick", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["noway"] = function(ped)
    	playAnimation(ped, "gestures@m@standing@casual", "gesture_no_way", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["ok"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intselfiedock", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["outofbreath"] = function(ped)
    	playAnimation(ped, "re@construction", "out_of_breath", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["pickup"] = function(ped)
    	playAnimation(ped, "random@domestic", "pickup_low", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["push"] = function(ped)
    	playAnimation(ped, "missfinale_c2ig_11", "pushcar_offcliff_f", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["push2"] = function(ped)
    	playAnimation(ped, "missfinale_c2ig_11", "pushcar_offcliff_m", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["point"] = function(ped)
    	playAnimation(ped, "gestures@f@standing@casual", "gesture_point", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["countdown"] = function(ped)
    	playAnimation(ped, "random@street_race", "grid_girl_race_start", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["pointright"] = function(ped)
    	playAnimation(ped, "mp_gun_shop_tut", "indicate_right", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["salute"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intincarsalutestd@ds@", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["salute2"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intincarsalutestd@ps@", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["salute3"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intuppersalute", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["scared"] = function(ped)
    	playAnimation(ped, "random@domestic", "f_distressed_loop", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["scared2"] = function(ped)
    	playAnimation(ped, "random@homelandsecurity", "knees_loop_girl", nil, nil)
    end,
    ["screwyou"] = function(ped)
    	playAnimation(ped, "misscommon@response", "screw_you", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["shakeoff"] = function(ped)
    	playAnimation(ped, "move_m@_idles@shake_off", "shakeoff_1", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["shot"] = function(ped)
    	playAnimation(ped, "random@crash_rescue@wounded@base", "base", nil, nil)
    end,
    ["injured"] = function(ped) anims["shot"](ped) end,
    ["sleep"] = function(ped)
    	playAnimation(ped, "timetable@tracy@sleep@", "idle_c", nil, nil)
    end,
    ["shrug"] = function(ped)
    	playAnimation(ped, "gestures@f@standing@casual", "gesture_shrug_hard", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["shrug2"] = function(ped)
    	playAnimation(ped, "gestures@m@standing@casual", "gesture_shrug_hard", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["sit"] = function(ped)
    	playAnimation(ped, "anim@amb@business@bgen@bgen_no_work@", "sit_phone_phoneputdown_idle_nowork", nil, nil)
    end,
    ["sit2"] = function(ped)
    	playAnimation(ped, "rcm_barry3", "barry_3_sit_loop", nil, nil)
    end,
    ["sit3"] = function(ped)
    	playAnimation(ped, "amb@world_human_picnic@male@idle_a", "idle_a", nil, nil)
    end,
    ["sit4"] = function(ped)
    	playAnimation(ped, "amb@world_human_picnic@female@idle_a", "idle_a", nil, nil)
    end,
    ["sit5"] = function(ped)
    	playAnimation(ped, "anim@heists@fleeca_bank@ig_7_jetski_owner", "owner_idle", nil, nil)
    end,
    ["sit6"] = function(ped)
    	playAnimation(ped, "timetable@jimmy@mics3_ig_15@", "idle_a_jimmy", nil, nil)
    end,
    ["sit7"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@lazlow@lo_alone@", "lowalone_base_laz", nil, nil)
    end,
    ["sit8"] = function(ped)
    	playAnimation(ped, "timetable@jimmy@mics3_ig_15@", "mics3_15_base_jimmy", nil, nil)
    end,
    ["sit9"] = function(ped)
    	playAnimation(ped, "amb@world_human_stupor@male@idle_a", "idle_a", nil, nil)
    end,
    ["sitlean"] = function(ped)
    	playAnimation(ped, "timetable@tracy@ig_14@", "ig_14_base_tracy", nil, nil)
    end,
    ["sitsad"] = function(ped)
    	playAnimation(ped, "anim@amb@business@bgen@bgen_no_work@", "sit_phone_phoneputdown_sleeping-noworkfemale", nil, nil)
    end,
    ["sitscared"] = function(ped)
    	playAnimation(ped, "anim@heists@ornate_bank@hostages@hit", "hit_loop_ped_b", nil, nil)
    end,
    ["sitscared2"] = function(ped)
    	playAnimation(ped, "anim@heists@ornate_bank@hostages@ped_c@", "flinch_loop", nil, nil)
    end,
    ["sitscared3"] = function(ped)
    	playAnimation(ped, "anim@heists@ornate_bank@hostages@ped_e@", "flinch_loop", nil, nil)
    end,
    ["sitdrunk"] = function(ped)
    	playAnimation(ped, "timetable@amanda@drunk@base", "base", nil, nil)
    end,
    ["sitchair2"] = function(ped)
    	playAnimation(ped, "timetable@ron@ig_5_p3", "ig_5_p3_base", nil, nil)
    end,
    ["sitchair3"] = function(ped)
    	playAnimation(ped, "timetable@reunited@ig_10", "base_amanda", nil, nil)
    end,
    ["sitchair4"] = function(ped)
    	playAnimation(ped, "timetable@ron@ig_3_couch", "base", nil, nil)
    end,
    ["sitchair5"] = function(ped)
    	playAnimation(ped, "timetable@jimmy@mics3_ig_15@", "mics3_15_base_tracy", nil, nil)
    end,
    ["sitchair6"] = function(ped)
    	playAnimation(ped, "timetable@maid@couch@", "base", nil, nil)
    end,
    ["sitchairside"] = function(ped)
    	playAnimation(ped, "timetable@ron@ron_ig_2_alt1", "ig_2_alt1_base", nil, nil)
    end,
    ["clapangry"] = function(ped)
    	playAnimation(ped, "anim@arena@celeb@flat@solo@no_props@", "angry_clap_a_player_a", nil, nil)
    end,
    ["slowclap3"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intupperslow_clap", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["clap"] = function(ped)
    	playAnimation(ped, "amb@world_human_cheering@male_a", "base", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["slowclap"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@slow_clap", "slow_clap", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["slowclap2"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationmale@slow_clap", "slow_clap", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["smell"] = function(ped)
    	playAnimation(ped, "move_p_m_two_idles@generic", "fidget_sniff_fingers", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["stickup"] = function(ped)
    	playAnimation(ped, "random@countryside_gang_fight", "biker_02_stickup_loop", nil, nil)
    end,
    ["stickup2"] = function(ped)
    	playAnimation(ped, "random@countryside_gang_fight", "biker_02_stickup_loop", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["stumble"] = function(ped)
    	playAnimation(ped, "misscarsteal4@actor", "stumble", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["stunned"] = function(ped)
    	playAnimation(ped, "stungun@standing", "damage", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["sunbathe"] = function(ped)
    	playAnimation(ped, "amb@world_human_sunbathe@male@back@base", "base", nil, nil)
    end,
    ["sunbathe2"] = function(ped)
    	playAnimation(ped, "amb@world_human_sunbathe@female@back@base", "base", nil, nil)
    end,
    ["t"] = function(ped)
    	playAnimation(ped, "missfam5_yoga", "a2_pose", nil, nil)
    end,
    ["t2"] = function(ped)
    	playAnimation(ped, "missfam5_yoga", "a2_pose", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["think5"] = function(ped)
    	playAnimation(ped, "mp_cp_welcome_tutthink", "b_think", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["think"] = function(ped)
    	playAnimation(ped, "misscarsteal4@aliens", "rehearsal_base_idle_director", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["think3"] = function(ped)
    	playAnimation(ped, "timetable@tracy@ig_8@base", "base", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["think2"] = function(ped)
    	playAnimation(ped, "missheist_jewelleadinout", "jh_int_outro_loop_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["thumbsup3"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intincarthumbs_uplow@ds@", "enter", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["thumbsup2"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intselfiethumbs_up", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["thumbsup"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intupperthumbs_up", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["type"] = function(ped)
    	playAnimation(ped, "anim@heists@prison_heiststation@cop_reactions", "cop_b_idle", nil, nil)
    end,
    ["type2"] = function(ped)
    	playAnimation(ped, "anim@heists@prison_heistig1_p1_guard_checks_bus", "loop", nil, nil)
    end,
    ["type3"] = function(ped)
    	playAnimation(ped, "mp_prison_break", "hack_loop", nil, nil)
    end,
    ["type4"] = function(ped)
    	playAnimation(ped, "mp_fbi_heist", "loop", nil, nil)
    end,
    ["warmth"] = function(ped)
    	playAnimation(ped, "amb@world_human_stand_fire@male@idle_a", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wave4"] = function(ped)
    	playAnimation(ped, "random@mugging5", "001445_01_gangintimidation_1_female_idle_b", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wave2"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@wave", "wave", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wave3"] = function(ped)
    	playAnimation(ped, "friends@fra@ig_1", "over_here_idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wave"] = function(ped)
    	playAnimation(ped, "friends@frj@ig_1", "wave_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wave5"] = function(ped)
    	playAnimation(ped, "friends@frj@ig_1", "wave_b", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wave6"] = function(ped)
    	playAnimation(ped, "friends@frj@ig_1", "wave_c", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wave7"] = function(ped)
    	playAnimation(ped, "friends@frj@ig_1", "wave_d", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wave8"] = function(ped)
    	playAnimation(ped, "friends@frj@ig_1", "wave_e", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wave9"] = function(ped)
    	playAnimation(ped, "gestures@m@standing@casual", "gesture_hello", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["whistle"] = function(ped)
    	playAnimation(ped, "taxi_hail", "hail_taxi", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["whistle2"] = function(ped)
    	playAnimation(ped, "rcmnigel1c", "hailing_whistle_waive_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["yeah"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intupperair_shagging", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["lift"] = function(ped)
    	playAnimation(ped, "random@hitch_lift", "idle_f", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["lol"] = function(ped)
    	playAnimation(ped, "anim@arena@celeb@flat@paired@no_props@", "laugh_a_player_b", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["lol2"] = function(ped)
    	playAnimation(ped, "anim@arena@celeb@flat@solo@no_props@", "giggle_a_player_b", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["statue2"] = function(ped)
    	playAnimation(ped, "fra_0_int-1", "cs_lamardavis_dual-1", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["statue3"] = function(ped)
    	playAnimation(ped, "club_intro2-0", "csb_englishdave_dual-0", nil, nil)
    end,
    ["gangsign"] = function(ped)
    	playAnimation(ped, "mp_player_int_uppergang_sign_a", "mp_player_int_gang_sign_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["gangsign2"] = function(ped)
    	playAnimation(ped, "mp_player_int_uppergang_sign_b", "mp_player_int_gang_sign_b", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["passout"] = function(ped)
    	playAnimation(ped, "missarmenian2", "drunk_loop", nil, nil)
    end,
    ["passout2"] = function(ped)
    	playAnimation(ped, "missarmenian2", "corpse_search_exit_ped", nil, nil)
    end,
    ["passout3"] = function(ped)
    	playAnimation(ped, "anim@gangops@morgue@table@", "body_search", nil, nil)
    end,
    ["passout4"] = function(ped)
    	playAnimation(ped, "mini@cpr@char_b@cpr_def", "cpr_pumpchest_idle", nil, nil)
    end,
    ["passout5"] = function(ped)
    	playAnimation(ped, "random@mugging4", "flee_backward_loop_shopkeeper", nil, nil)
    end,
    ["petting"] = function(ped)
    	playAnimation(ped, "creatures@rottweiler@tricks@", "petting_franklin", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["crawl"] = function(ped)
    	playAnimation(ped, "move_injured_ground", "front_loop", nil, nil, nil, animationPlayback.REPEAT)
    end,
    ["flip2"] = function(ped)
    	playAnimation(ped, "anim@arena@celeb@flat@solo@no_props@", "cap_a_player_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["flip"] = function(ped)
    	playAnimation(ped, "anim@arena@celeb@flat@solo@no_props@", "flip_a_player_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["slide"] = function(ped)
    	playAnimation(ped, "anim@arena@celeb@flat@solo@no_props@", "slide_a_player_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["slide2"] = function(ped)
    	playAnimation(ped, "anim@arena@celeb@flat@solo@no_props@", "slide_b_player_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["slide3"] = function(ped)
    	playAnimation(ped, "anim@arena@celeb@flat@solo@no_props@", "slide_c_player_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["slugger"] = function(ped)
    	playAnimation(ped, "anim@arena@celeb@flat@solo@no_props@", "slugger_a_player_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["flipoff"] = function(ped)
    	playAnimation(ped, "anim@arena@celeb@podium@no_prop@", "flip_off_a_1st", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["flipoff2"] = function(ped)
    	playAnimation(ped, "anim@arena@celeb@podium@no_prop@", "flip_off_c_1st", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["bow"] = function(ped)
    	playAnimation(ped, "anim@arena@celeb@podium@no_prop@", "regal_c_1st", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["bow2"] = function(ped)
    	playAnimation(ped, "anim@arena@celeb@podium@no_prop@", "regal_a_1st", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["keyfob"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intmenu@key_fob@", "fob_click", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["golfswing"] = function(ped)
    	playAnimation(ped, "rcmnigel1d", "swing_a_mark", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["eat"] = function(ped)
    	playAnimation(ped, "mp_player_inteat@burger", "mp_player_int_eat_burger", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["reaching"] = function(ped)
    	playAnimation(ped, "move_m@intimidation@cop@unarmed", "idle", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wait"] = function(ped)
    	playAnimation(ped, "random@shop_tattoo", "_idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wait2"] = function(ped)
    	playAnimation(ped, "missbigscore2aig_3", "wait_for_van_c", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wait12"] = function(ped)
    	playAnimation(ped, "rcmjosh1", "idle", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["wait13"] = function(ped)
    	playAnimation(ped, "rcmnigel1a", "base", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["lapdance2"] = function(ped)
    	playAnimation(ped, "mini@strip_club@private_dance@idle", "priv_dance_idle", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["lapdance3"] = function(ped)
    	playAnimation(ped, "mini@strip_club@private_dance@part2", "priv_dance_p2", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["slap"] = function(ped)
    	playAnimation(ped, "melee@unarmed@streamed_variations", "plyr_takedown_front_slap", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["headbutt"] = function(ped)
    	playAnimation(ped, "melee@unarmed@streamed_variations", "plyr_takedown_front_headbutt", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["fishdance"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intupperfind_the_fish", "idle_a", nil, nil)
    end,
    ["peace"] = function(ped)
    	playAnimation(ped, "mp_player_int_upperpeace_sign", "mp_player_int_peace_sign", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["peace2"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intupperpeace", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["cpr"] = function(ped)
    	playAnimation(ped, "mini@cpr@char_a@cpr_str", "cpr_pumpchest", nil, nil)
    end,
    ["ledge"] = function(ped)
    	playAnimation(ped, "missfbi1", "ledge_loop", nil, nil)
    end,
    ["airplane"] = function(ped)
    	playAnimation(ped, "missfbi1", "ledge_loop", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["peek"] = function(ped)
    	playAnimation(ped, "random@paparazzi@peek", "left_peek_a", nil, nil)
    end,
    ["cough"] = function(ped)
    	playAnimation(ped, "timetable@gardener@smoking_joint", "idle_cough", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["stretch"] = function(ped)
    	playAnimation(ped, "mini@triathlon", "idle_e", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["stretch2"] = function(ped)
    	playAnimation(ped, "mini@triathlon", "idle_f", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["stretch3"] = function(ped)
    	playAnimation(ped, "mini@triathlon", "idle_d", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["stretch4"] = function(ped)
    	playAnimation(ped, "rcmfanatic1maryann_stretchidle_b", "idle_e", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["celebrate"] = function(ped)
    	playAnimation(ped, "rcmfanatic1celebrate", "celebrate", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["punching"] = function(ped)
    	playAnimation(ped, "rcmextreme2", "loop_punching", nil, nil, AnimationEffectArea.UPPERBODY, animationPlayback.STOP_LAST_FRAME)
    end,
    ["superhero"] = function(ped)
    	playAnimation(ped, "rcmbarry", "base", nil, nil)
    end,
    ["superhero2"] = function(ped)
    	playAnimation(ped, "rcmbarry", "base", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["mindcontrol"] = function(ped)
    	playAnimation(ped, "rcmbarry", "mind_control_b_loop", nil, nil)
    end,
    ["mindcontrol2"] = function(ped)
    	playAnimation(ped, "rcmbarry", "bar_1_attack_idle_aln", nil, nil)
    end,
    ["mindcontrol3"] = function(ped)
    	playAnimation(ped, "rcmbarry", "bar_1_attack_idle_aln", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["clown"] = function(ped)
    	playAnimation(ped, "rcm_barry2", "clown_idle_0", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["clown2"] = function(ped)
    	playAnimation(ped, "rcm_barry2", "clown_idle_1", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["clown3"] = function(ped)
    	playAnimation(ped, "rcm_barry2", "clown_idle_2", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["clown4"] = function(ped)
    	playAnimation(ped, "rcm_barry2", "clown_idle_3", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["clown5"] = function(ped)
    	playAnimation(ped, "rcm_barry2", "clown_idle_6", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["tryclothes"] = function(ped)
    	playAnimation(ped, "mp_clothing@female@trousers", "try_trousers_neutral_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["tryclothes2"] = function(ped)
    	playAnimation(ped, "mp_clothing@female@shirt", "try_shirt_positive_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["tryclothes3"] = function(ped)
    	playAnimation(ped, "mp_clothing@female@shoes", "try_shoes_positive_a", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["nervous2"] = function(ped)
    	playAnimation(ped, "mp_missheist_countrybank@nervous", "nervous_idle", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["nervous"] = function(ped)
    	playAnimation(ped, "amb@world_human_bum_standing@twitchy@idle_a", "idle_c", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["nervous3"] = function(ped)
    	playAnimation(ped, "rcmme_tracey1", "nervous_loop", nil, nil, AnimationEffectArea.UPPERBODY)
    end,

    ["namaste"] = function(ped)
    	playAnimation(ped, "timetable@amanda@ig_4", "ig_4_base", nil, nil, AnimationEffectArea.UPPERBODY, animationPlayback.STOP_LAST_FRAME)
    end,
    ["dj"] = function(ped)
    	playAnimation(ped, "anim@amb@nightclub@djs@dixon@", "dixn_dance_cntr_open_dix", nil, nil)
    end,
    ["threaten"] = function(ped)
    	playAnimation(ped, "random@atmrobberygen", "b_atm_mugging", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["radio"] = function(ped)
    	playAnimation(ped, "random@arrests", "generic_radio_chatter", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["pull"] = function(ped)
    	playAnimation(ped, "random@mugging4", "struggle_loop_b_thief", nil, nil)
    end,
    ["bird"] = function(ped)
    	playAnimation(ped, "random@peyote@bird", "wakeup", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["chicken"] = function(ped)
    	playAnimation(ped, "random@peyote@chicken", "wakeup", nil, nil, AnimationEffectArea.UPPERBODY) -- repeat?
    end,
    ["bark"] = function(ped)
    	playAnimation(ped, "random@peyote@dog", "wakeup", nil, nil, nil, AnimationPlayback.PLAY_ONCE) -- repeat?
    end,
    ["rabbit"] = function(ped)
    	playAnimation(ped, "random@peyote@rabbit", "wakeup", nil, nil, nil, AnimationPlayback.PLAY_ONCE) -- repeat?
    end,
    ["spiderman"] = function(ped)
    	playAnimation(ped, "missexile3", "ex03_train_roof_idle", nil, nil)
    end,
    ["boi"] = function(ped)
    	playAnimation(ped, "special_ped@jane@monologue_5@monologue_5c", "brotheradrianhasshown_2", nil, nil, nil, AnimationPlayback.PLAY_ONCE)
    end,
    ["adjust"] = function(ped)
    	playAnimation(ped, "missmic4", "michael_tux_fidget", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["handsup"] = function(ped)
    	playAnimation(ped, "missminuteman_1ig_2", "handsup_base", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["pee"] = function(ped)
    	playAnimation(ped, "misscarsteal2peeing", "peeing_loop", nil, nil)
    end,
    ["mindblown"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationmale@mind_blown", "mind_blown", nil, nil, AnimationEffectArea.UPPERBODY, animationPlayback.PLAY_ONCE)
    end,
    ["mindblown2"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@mind_blown", "mind_blown", nil, nil, AnimationEffectArea.UPPERBODY, animationPlayback.PLAY_ONCE)
    end,
    ["boxing"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationmale@shadow_boxing", "shadow_boxing", nil, nil)
    end,
    ["boxing2"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@shadow_boxing", "shadow_boxing", nil, nil)
    end,
    ["stink"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intcelebrationfemale@stinker", "stinker", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["think4"] = function(ped)
    	playAnimation(ped, "anim@amb@casino@hangout@ped_male@stand@02b@idles", "idle_a", nil, nil, AnimationEffectArea.UPPERBODY)
    end,
    ["adjusttie"] = function(ped)
    	playAnimation(ped, "clothingtie", "try_tie_positive_a", nil, nil, AnimationEffectArea.UPPERBODY, AnimationPlayback.PLAY_ONCE)
    end,
    ["sweep"] = function(ped)
    	playAnimation(ped, "amb@world_human_janitor@male@idle_a", "idle_a", "broom", nil, AnimationEffectArea.UPPERBODY)
    end,
    ["makeitrain"] = function(ped)
    	playAnimation(ped, "anim@mp_player_intupperraining_cash", "idle_a", "wadofbills", nil, AnimationEffectArea.UPPERBODY)
    end,
}
