local meta = FindMetaTable("Player")

JRS.JobRanks = JRS.JobRanks or {}
JRS.JobRankTables = JRS.JobRankTables or {}

local CurID = nil

function CreateRanksTable( JobRankTableID, MaxRank , PrefixSeperator, OtherPromoPerms )    

    JRS.JobRanks[JobRankTableID] = {}
    JRS.JobRanks[JobRankTableID].MaxRank = MaxRank
    JRS.JobRanks[JobRankTableID].PrefixSeperator = PrefixSeperator
    JRS.JobRanks[JobRankTableID].OtherPromoPerms = OtherPromoPerms

    JRS.JobRanks[JobRankTableID].RankName = {}
    JRS.JobRanks[JobRankTableID].Prefix = {}
    JRS.JobRanks[JobRankTableID].Loadout = {}
    JRS.JobRanks[JobRankTableID].CanPromote = {}
    JRS.JobRanks[JobRankTableID].MaxPromoRank = {}
    JRS.JobRanks[JobRankTableID].Models = {}
    JRS.JobRanks[JobRankTableID].BonusSalary = {}

    CurID = JobRankTableID
end

function CreateRank( RankID, RankName, Prefix, Loadout, CanPromote, MaxPromoRank, Models, BonusSalary )

    if JRS.JobRanks[CurID] then 

        JRS.JobRanks[CurID].RankName[RankID] = RankName
        JRS.JobRanks[CurID].Prefix[RankID] = Prefix
        JRS.JobRanks[CurID].Loadout[RankID] = Loadout or {}
        JRS.JobRanks[CurID].Models[RankID] = Models or false 
        JRS.JobRanks[CurID].CanPromote[RankID] = CanPromote or false
        JRS.JobRanks[CurID].MaxPromoRank[RankID] = MaxPromoRank or  JRS.JobRanks[CurID].MaxRank -- if CanPromote false then this is useless, if this is nil, it will be the highest rank
        JRS.JobRanks[CurID].BonusSalary[RankID] = BonusSalary
        
        if Models then
            for _,v in pairs( Models ) do
                util.PrecacheModel(v)  
            end
        end

    end
end

function GiveJobRankTable(JobRankTableID, JobID)
    if JobRankTableID and JobID then
        JRS.JobRankTables[JobID] = JobRankTableID
    end
end

function DisablePrefix(job)
    local tblID = JRS.JobRankTables[job]

    for i= 0,#JRS.JobRanks[tblID].Prefix do
        JRS.JobRanks[tblID].Prefix[i] = ""
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

function meta:GetRank()
    return self:GetNWInt("JobRank",0)
end

function meta:GetJobRanksTable(cteam)
    cteam = cteam or self:Team()

    local loc = JRS.JobRankTables[cteam]
    if !loc then return false end

    return JRS.JobRanks[loc]
    
end

function meta:GetRankName()
    if !self:GetJobRanksTable() then return false end
    return self:GetJobRanksTable().RankName[self:GetRank()]
end

function meta:GetRankNamePrefix()
    if !self:GetJobRanksTable() then return false end
    return self:GetJobRanksTable().Prefix[self:GetRank()]
end

function meta:GetRankVar(var)
    if !self:GetJobRanksTable() then return false end
    return self:GetJobRanksTable()[var][self:GetRank()]
end

function IsPlyNick( nick )
    for _, v in pairs( player.GetAll() ) do
        
        if string.find( string.lower( v:Nick() ), string.lower( nick ), 1, true ) then return v end
        if (v:SteamID64() == nick) or (v:SteamID() == nick) then return v end
        
    end
    return false
end
