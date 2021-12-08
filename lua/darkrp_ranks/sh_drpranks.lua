local meta = FindMetaTable("Player")

JRS.JobRanks = {}
JRS.JobRankTables = {}

local LastID = nil

function CreateRanksTable( JobRankTableID, MaxRank , PrefixSeperator, OtherPromoPerms )

    JRS.JobRanks[JobRankTableID] = {}
    JRS.JobRanks[JobRankTableID].MaxRank = MaxRank
    JRS.JobRanks[JobRankTableID].PrefixSeperator = PrefixSeperator
    JRS.JobRanks[JobRankTableID].OtherPromoPerms = OtherPromoPerms

    -- pre- initializing things for the ranks below here.

    JRS.JobRanks[JobRankTableID].RankName = {}
    JRS.JobRanks[JobRankTableID].Prefix = {}
    JRS.JobRanks[JobRankTableID].Loadout = {}
    JRS.JobRanks[JobRankTableID].CanPromote = {}
    JRS.JobRanks[JobRankTableID].MaxPromoRank = {}
    JRS.JobRanks[JobRankTableID].Models = {}



    lastID = JobRankTableID

end

function CreateRank( RankID, RankName, Prefix, Loadout, CanPromote, MaxPromoRank, Models )

    if JRS.JobRanks[lastID] then 

        JRS.JobRanks[lastID].RankName[RankID] = RankName
        JRS.JobRanks[lastID].Prefix[RankID] = Prefix
        JRS.JobRanks[lastID].Loadout[RankID] = Loadout or {}
        JRS.JobRanks[lastID].CanPromote[RankID] = CanPromote or false
        JRS.JobRanks[lastID].MaxPromoRank[RankID] = MaxPromoRank or  JRS.JobRanks[lastID].MaxRank -- if CanPromote false then this is useless, if this is nil, it will be the highest rank
        JRS.JobRanks[lastID].Models[RankID] = Models or false 
    
    end
end

hook.Add("loadCustomDarkRPItems", "drpranks_initshared_postdarkrp", function()

    meta.SteamName = meta.SteamName or meta.Name
    function meta:Name()
        if not IsValid(self) then DarkRP.error("Attempt to call Name/Nick/GetName on a non-existing player!", SERVER and 1 or 2) end

        local Rank = self:GetRank()
        JobRankTbl = self:JobRanksTable()
        local Nick = GAMEMODE.Config.allowrpnames and self:getDarkRPVar("rpname") or self:SteamName()
        if JobRankTbl and JobRankTbl.Prefix and JobRankTbl.Prefix[Rank] then
            local PrefixSep = "."
            if JobRankTbl.PrefixSeperator then
                PrefixSep = JobRankTbl.PrefixSeperator
            end
            Nick = self:GetRankNamePrefix() .. PrefixSep .. Nick
        end

        return Nick
    end
    meta.GetName = meta.Name
    meta.Nick = meta.Name
end)

function GiveJobRankTable(JobRankTableID, JobID)
    if JobRankTableID and JobID then
        JRS.JobRankTables[JobID] = JobRankTableID
    end
end

function meta:GetRank()
    return self:GetNWInt("JobRank")
end

function meta:JobRanksTable()
    local loc = JRS.JobRankTables[self:Team()]
    return JRS.JobRanks[loc]

end

function meta:GetRankName()
    return self:JobRanksTable().RankName[self:GetRank()]
end

function meta:GetRankNamePrefix()
    return self:JobRanksTable().Prefix[self:GetRank()]
end

function meta:GetRankVar(var)
    return self:JobRanksTable()[var[self:GetRank()]]
end