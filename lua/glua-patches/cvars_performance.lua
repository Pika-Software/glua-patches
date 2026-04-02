if CLIENT then

    local changeConvarList = {
        ['cl_threaded_bone_setup'] = '1',
        ['cl_threaded_client_leaf_system'] = '1',

        ['r_queued_ropes'] = '1',
        ['studio_queue_mode'] = '1',

        ['cl_forcepreload'] = '1',
        ['r_fastzreject'] = '1',
    }

    local function EnsureDir()
        if not file.Exists("glua_patches", "DATA") then
            file.CreateDir("glua_patches")
        end
    end

    local function SaveCvars()
        EnsureDir()

        local save_cvars = {}

        for cvar_name in pairs(changeConvarList) do
            if ConVarExists(cvar_name) then
                save_cvars[cvar_name] = GetConVar(cvar_name):GetString()
            end
        end

        file.Write("glua_patches/cvars.json", util.TableToJSON(save_cvars, true))
    end

    local function ApplyCvars()
        for cvar_name, cvar_value in pairs(changeConvarList) do
            if ConVarExists(cvar_name) then
                RunConsoleCommand(cvar_name, cvar_value)
            end
        end
    end

    local function RestoreCvars()
        if not file.Exists("glua_patches/cvars.json", "DATA") then return end

        local raw = file.Read("glua_patches/cvars.json", "DATA")
        if not raw then return end

        local savedCvars = util.JSONToTable(raw)
        if not savedCvars then return end

        for cvar_name, cvar_value in pairs(savedCvars) do
            RunConsoleCommand(cvar_name, cvar_value)
        end

        file.Delete("glua_patches/cvars.json")
    end

    local function CvarsOptimization()
        SaveCvars()
        ApplyCvars()
    end

    local function CvarsOptimizationRollback()
        RestoreCvars()
    end

    hook.Add("Initialize", "GLuaPatches_CVars", function()
        if cv_enable:GetBool() then
            CvarsOptimization()
        else
            CvarsOptimizationRollback()
        end
    end)

    cvars.AddChangeCallback("glua_patches_cvars_optimization", function(_, _, newValue)
        if tobool(newValue) then
            CvarsOptimization()
        else
            CvarsOptimizationRollback()
        end
    end, "GLuaPatches_CVars")

end
