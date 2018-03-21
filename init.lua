local gcc = premake.tools.gcc
local api = premake.api

api.register {
    name = "mpi",
    scope = "config",
    kind = "string",
    allowed = {
        "On",
        "Off"
    }
}

api.register {
    name = "mpicompilerdir",
    scope = "config",
    kind = "string"
}

api.register {
    name = "mpicc",
    scope = "config",
    kind = "string"
}

api.register {
    name = "mpicxx",
    scope = "config",
    kind = "string"
}

api.register {
    name = "mpimt",
    scope = "config",
    kind = "boolean"
}

if os.istarget("windows") then
    local function getMpiRoot(cfg)
        local mpi = iif(cfg.mpi ~= nil, cfg.mpi, "Off")
        local mpiRoot = nil

        if mpi == "On" then
            mpiRoot = os.getenv("I_MPI_ROOT")

            if mpiRoot == nil then
                mpiRoot = os.findlib("impi")

                if mpiRoot ~= nil then
                    mpiRoot = mpiRoot .. "../.."
                end
            end
        end

        return mpiRoot
    end

    premake.override(premake.action, 'call', function (base, name)
        local a = premake.action.get(name)

        if a.onProject == nil then
            return base(name)
        end

        premake.override(a, 'onProject', function(baseOnProject, prj)
            for cfg in premake.project.eachconfig(prj) do
                local mpiRoot = getMpiRoot(cfg)
                local libmtsuffix = iif(cfg.mpimt, "_mt", "")
                local linksmtsuffix = iif(cfg.mpimt, "mt", "")
    
                if mpiRoot ~= nil then
                    if premake.config.isDebugBuild(cfg) then
                        table.insert(cfg.libdirs, mpiRoot .. "/intel64/lib/debug" .. libmtsuffix)
                        table.insert(cfg.links, "impid" .. linksmtsuffix)
                    else
                        table.insert(cfg.libdirs, mpiRoot .. "/intel64/lib/release" .. libmtsuffix)
                        table.insert(cfg.links, "impi" .. linksmtsuffix)
                    end
                    table.insert(cfg.includedirs,  mpiRoot .. "/intel64/include")
                end
            end

            return baseOnProject(prj)
        end)

        return base(name)
    end)
else
    premake.override(gcc, "gettoolname", function(base, cfg, tool)
        local toolname = base(cfg, tool)

        if cfg.mpi == "On" then
            local mpicompilerdir = ""
            if cfg.mpicompilerdir ~= nil then
                mpicompilerdir = cfg.mpicompilerdir

                if not (mpicompilerdir:endwith("/") or mpicompilerdir:endwith("\\")) then
                    mpicompilerdir = mpicompilerdir .. "/"
                end
            end

            if tool == "cc" then
                if toolname ~= nil then
                    buildoptions {
                        "-cc=" .. toolname
                    }
                end
                toolname = iif(cfg.mpicc ~= nil, cfg.mpicc, mpicompilerdir .. "mpicc")
            elseif tool == "cxx" then
                if toolname ~= nil then
                    buildoptions {
                        "-cxx=" .. toolname
                    }
                end
                toolname = iif(cfg.mpicxx ~= nil, cfg.mpicxx, mpicompilerdir .. "mpicxx")
            end
        end

        return toolname
    end)
end
