local meta = FindMetaTable("Player")

JobRanks = {}
JobRankTables = {}

local LastID = nil

function CreateRanksTable( JobRankTableID, MaxRank , PrefixSeperator, OtherPromoPerms )

    JobRanks[JobRankTableID] = {}
    JobRanks[JobRankTableID].MaxRank = MaxRank
    JobRanks[JobRankTableID].PrefixSeperator = PrefixSeperator
    JobRanks[JobRankTableID].OtherPromoPerms = OtherPromoPerms

    -- some bullshit for the next function



    JobRanks[JobRankTableID].RankName = {}
    JobRanks[JobRankTableID].Prefix = {}
    JobRanks[JobRankTableID].Loadout = {}
    JobRanks[JobRankTableID].CanPromote = {}
    JobRanks[JobRankTableID].MaxPromoRank = {}
    JobRanks[JobRankTableID].Models = {}



    lastID = JobRankTableID

end

function CreateRank( RankID, RankName, Prefix, Loadout, CanPromote, MaxPromoRank, Models )

    if JobRanks[lastID] then 

        JobRanks[lastID].RankName[RankID] = RankName
        JobRanks[lastID].Prefix[RankID] = Prefix
        JobRanks[lastID].Loadout[RankID] = Loadout or {}-- SHOULD BE A TABLE
        JobRanks[lastID].CanPromote[RankID] = CanPromote or false
        JobRanks[lastID].MaxPromoRank[RankID] = MaxPromoRank or  JobRanks[lastID].MaxRank -- if CanPromote false then this is useless, if this is nil, it will be the highest rank
        JobRanks[lastID].Models[RankID] = Models or false -- SHOULD BE A TABLE
    
    end
end

hook.Add("loadCustomDarkRPItems", "drpranks_initshared_postdarkrp", function()

    meta.SteamName = meta.SteamName or meta.Name
    function meta:Name()
        if not IsValid(self) then DarkRP.error("Attempt to call Name/Nick/GetName on a non-existing player!", SERVER and 1 or 2) end

        local Rank = self:GetRank()
        JobRankTbl = self:GetJobRanksTable()
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
        JobRankTables[JobID] = JobRankTableID
    end
end

function meta:GetRank()
    return self:GetNWInt("JobRank")
end

function meta:GetJobRanksTable()
    local loc = JobRankTables[self:Team()]
    return JobRanks[loc]

end

function meta:GetRankName()
    return self:GetJobRanksTable().RankName[self:GetRank()]
end

function meta:GetRankNamePrefix()
    return self:GetJobRanksTable().Prefix[self:GetRank()]
end

function meta:GetRankVar(var)
    return self:GetJobRanksTable()[var[self:GetRank()]]
end