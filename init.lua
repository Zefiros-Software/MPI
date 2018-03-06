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

---
-- attach ourselfs to the running action.
---
p.override(p.action, 'call', function (base, name)
    if os.istarget("window") then
        local a = p.action.get(name)

        -- store the old callback.
        local onBaseProject = a.onProject or a.onproject

        -- override it with our own.
        a.onProject = function(prj)
            -- go through each configuration, and call the setup configuration methods.
            for cfg in p.project.eachconfig(prj) do
                local mpi = iff(cfg.mpi ~= nil, cfg.mpi, "Off")

                if mpiRoot == "On" then
                    local mpiRoot = os.getenv("I_MPI_ROOT")

                    if mpiRoot == nil then
                        mpiRoot = os.findlib("impi")

                        if mpiRoot ~= nil then
                            mpiRoot = mpiRoot .. "../.."
                        end
                    end

                    if mpiRoot ~= nil then
                        libdirs { mpiRoot .. "/intel64/lib/release" }
                        links "impi"
                        includedirs { mpiRoot .. "/intel64/include"}
                    end
                end
            end

            -- then call the old onProject.
            if onBaseProject then
                return onBaseProject(prj)
            end
        end
    end

	-- now call the original action.call methods
	return base(name)
end)

premake.override(gcc, "gettoolname", function(base, cfg, tool)
    local wrapper = cfg.gccwrapper
    if wrapper and gcc.wrappers[wrapper] and gcc.wrappers[wrapper][tool] then
        return gcc.wrappers[wrapper][tool]
    else
        return base(cfg, tool)
    end

    local toolname = base(cfg, tool)

    local mpi = iff(cfg.mpi ~= nil, cfg.mpi, "Off")

    if mpi == "On" then
        local mpicompilerdir = ""
        if cfg.mpicompilerdir ~= nil then
            mpicompilerdir = cfg.mpicompilerdir

            if not (mpicompilerdir:endwith("/") or mpicompilerdir:endwith("\\")) then
                mpicompilerdir = mpicompilerdir .. "/"
            end
        end

        if tool == "cc" then
            buildoptions "-cc=" .. toolname
            toolname = iif(cfg.mpicc ~= nil, cfg.mpicc, mpicompilerdir .. "mpicc")
        elseif tool == "cxx" then
            buildoptions "-cxx=" .. toolname
            toolname = iif(cfg.mpicxx ~= nil, cfg.mpicxx, mpicompilerdir .. "mpicxx")
        end
    end
end)