JRS = JRS or {}

if SERVER then 
    AddCSLuaFile("darkrp_ranks/sh_cami.lua") 
    AddCSLuaFile("darkrp_ranks/sh_drpranks.lua")
    AddCSLuaFile("darkrp_ranks/sh_drpranks_cfg.lua")
    AddCSLuaFile("darkrp_ranks/cl_drpranks.lua")

end

include("darkrp_ranks/sh_cami.lua")
include("darkrp_ranks/sh_drpranks.lua")

if SERVER then

    print("--------------------------------")
    print("---- Giovanni's Rank System ----")
    print("------ Loaded version 1.0 ------")
    print("--------------------------------")
    
    include("darkrp_ranks/sv_drpranks.lua")
end

include("darkrp_ranks/sh_drpranks_cfg.lua")

if CLIENT then
    include("darkrp_ranks/cl_drpranks.lua")
end