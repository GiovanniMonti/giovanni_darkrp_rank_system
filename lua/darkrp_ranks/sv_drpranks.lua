JRS.DrpRanksPlayerData = JRS.DrpRanksPlayerData or {}
-- data saving - json file
hook.Add("Initialize", "jrs_DBCreate", function()
    if file.Exists("drpranksdata/", "DATA") then
        local f, _ = file.Find("drpranksdata/*.txt", "DATA")
        for k,v in pairs( f ) do
            JRS.DrpRanksPlayerData[ string.Left(v, 17) ] = util.JSONToTable( file.Read("drpranksdata/"..v,"DATA") ) or {}
        end
    else
        file.CreateDir("drpranksdata")
    end
            

end)

hook.Add("PlayerInitialSpawn", "jrs_InitPlyDb", function(ply)

    JRS.DrpRanksPlayerData[ply:SteamID64()] = JRS.DrpRanksPlayerData[ply:SteamID64()] or {}
    
end)

function JRS:SaveEntireDB()
   for k,v in pairs(self.DrpRanksPlayerData) do
        file.Write( "drpranksdata/" .. k .. ".txt", util.TableToJSON( self.DrpRanksPlayerData[k] ) )
   end

end

function JRS:UpdatePlyDB(steamID)
    file.Write( "drpranksdata/" .. steamID .. ".txt", util.TableToJSON( self.DrpRanksPlayerData[steamID] ) )
end

------
util.AddNetworkString("JRS_RqPlRnk") -- request from cl
util.AddNetworkString("JRS_RetPlRnk") -- response from sv
local RankTblCooldown
function JRS:TransmitPlyRankTbl(ply,reciever)
    RankTblCooldown = RankTblCooldown or CurTime()

    if CurTime() - RankTblCooldown < 1 then return end

    local tbl = self.DrpRanksPlayerData[ply:SteamID64()]

    net.Start("JRS_RetPlRnk")
    local iLen = #tbl 
    net.WriteUInt(iLen, 8)
    net.WriteUInt( ply:AccountID() , 28)

    for job, _ in pairs(tbl) do
        net.WriteUInt(job, 8)
        net.WriteUInt(tbl[job]["Rank"], 8)
    end

    net.Send(reciever)

end

net.Receive("JRS_RqPlRnk", function(len, pl) 

    local ply = player.GetByAccountID( net.ReadUInt(28) )

    JRS:TransmitPlyRankTbl(ply,pl)
end)

--------

util.AddNetworkString( "LegacyNotifySv" )

-- same as the client-only vanilla gmod ones.

local NOTIFY_GENERIC = 0
local NOTIFY_ERROR = 1
local NOTIFY_UNDO = 2
local NOTIFY_HINT = 3
local NOTIFY_CLEANUP = 4

function JRS.LegacyNotifyPlayer(ply, text, type, length)
    length = length or 2
    type = type or 0
    net.Start("LegacyNotifySv")
        net.WriteString(text)
        net.WriteInt(type, 4)
        net.WriteInt(length,8) 
    if ply == "BROADCAST" then     
        net.Broadcast()
    else   
        net.Send(ply)
    end
end

CAMI.RegisterPrivilege({
    Name = "Promote_Any",
    MinAccess = "user"
})

util.AddNetworkString( "JRSClientMenu" )

local meta = FindMetaTable("Player")

function meta:SetRank(RankID)
    local jobID = self:Team() 
    if JRS.JobRankTables[jobID] then
        self:SetNWInt("JobRank", RankID)

        if JRS.CFG.AddRankToJobName then
            local JobName = team.GetName(jobID) .. " ( " .. self:GetRankName() .. " )"
            self:setDarkRPVar("job", JobName)
        end
    end

end
-- cteam optional
function meta:RankPromote(num, cteam)
 
    cteam = cteam or self:Team()
    
    if num == self:GetRank() then return end
    
    if num and JRS.JobRankTables[cteam] then
        self:SetRank( num )
        self:RanksLoadout()
        self:RanksPlayerModels()
        self:RanksBonusSalary(true)
        
        JRS.DrpRanksPlayerData[self:SteamID64()] = JRS.DrpRanksPlayerData[self:SteamID64()] or {}
        JRS.DrpRanksPlayerData[self:SteamID64()][cteam] = JRS.DrpRanksPlayerData[self:SteamID64()][cteam] or {}
        JRS.DrpRanksPlayerData[self:SteamID64()][cteam].Rank = num
        JRS:UpdatePlyDB( self:SteamID64())
    end

end

function meta:JRS_ManageSpawn()

    if JRS.DrpRanksPlayerData[self:SteamID64()][self:Team()].Rank then
        self:SetRank(JRS.DrpRanksPlayerData[self:SteamID64()][self:Team()].Rank)
    else 
      self:SetRank(0)
      JRS.DrpRanksPlayerData[self:SteamID64()][self:Team()].Rank = 0
    end
    -- SetRank uses a NWvar which may take some time?
    timer.Simple(0, function()
        self:RanksLoadout()
        self:RanksPlayerModels()
        self:RanksBonusSalary(false)
    end)
end

function meta:PlayerCanPromote(sPly, rank, cteam)

    local PlyRankTbl = self:GetJobRanksTable()
    local sPlyRankTbl, sPlyTeam, sPlyRank
    
    if cteam then
        sPlyRankTbl = sPly:GetJobRanksTable(cteam)
        sPlyTeam = cteam
        sPlyRank = JRS.DrpRanksPlayerData[sPly:SteamID64()][sPly:Team()].Rank
    else
        sPlyRankTbl = sPly:GetJobRanksTable(cteam)
        sPlyTeam = sPly:Team()
        sPlyRank = sPly:GetRank()
    end

    if !sPly:GetJobRanksTable() then return false end
    
    if ( rank >= sPlyRankTbl.MaxRank and rank >= self:GetJobRanksTable().MaxPromoRank[self:GetRank()]  ) then 
        JRS.LegacyNotifyPlayer(self, "The maximum rank on this job has been reached. (or you're trying to promote over the max)", NOTIFY_ERROR , 4)
        return false
    end 

    if ( rank < 0 ) then 
        JRS.LegacyNotifyPlayer(self, "The minimum rank on this job has been reached.", NOTIFY_ERROR , 4)
        return false
    end

    if CAMI.PlayerHasAccess(self, "Promote_Any") then 
        return true
    end

    if self:GetRank() > sPlyRank and rank < self:GetRank() and rank < sPlyRankTbl.MaxPromoRank[self:GetRank()]  then
        for _, v in pairs( PlyRankTbl.OtherPromoPerms ) do
            if JRS.JobRankTables[sPlyTeam] == v then return true end
        end
    end

    JRS.LegacyNotifyPlayer(self, "You do not have the permissions to promote/demote " .. sPly:Nick() .. " to " .. sPly:GetRankName(), NOTIFY_ERROR , 4)

    return false
    
end

-- use negative numbers to demote
function meta:PromoDemoPlayer(sPly, rank, setrank)
    local CurRank = sPly:GetRank()
    local newrank = 0

    if setrank == false then

        if ( rank == "promo" or rank == 1 ) then 
            newrank = CurRank + 1
        elseif ( rank == "demo" or rank == -1 ) then
            newrank = CurRank -1
        else 
            newrank = CurRank + rank
        end
        
    elseif setrank == true then
        newrank = rank  
    end
 

    local PlyCanPromote = self:PlayerCanPromote(sPly, newrank)
    
    if PlyCanPromote then sPly:RankPromote(newrank) end

    return PlyCanPromote
    
end

----------- for the clientside menu.

function meta:PromoDemoTeam(sPly, rank, setrank, team)
    local CurRank = JRS.DrpRanksPlayerData[sPly:SteamID64()][team].Rank
    local newrank = 0
    local PromoOrDemoStr

    if rank == CurRank then return end

    if setrank == false then

        if ( rank == "promo" or rank == 1 ) then 
            newrank = CurRank + 1
            PromoOrDemoStr = "promoted"
        elseif ( rank == "demo" or rank == -1 ) then
            newrank = CurRank -1
            PromoOrDemoStr = "demoted"
        else 
            newrank = CurRank + rank
        end
        
    elseif setrank == true then
        newrank = rank  
        if newrank > CurRank then
            PromoOrDemoStr = "promoted"
        else
            PromoOrDemoStr = "demoted"
        end
    end
 

    local PlyCanPromote = self:PlayerCanPromote(sPly, newrank,team)
    
    if PlyCanPromote then sPly:RankPromote(newrank,team) end
    JRS.LegacyNotifyPlayer("BROADCAST", self:Nick() .. " " .. PromoOrDemoStr .. " ".. sPly:Nick() .. " to " .. JRS.JobRanks[team].RankName[newrank] , NOTIFY_GENERIC , 3)

    return PlyCanPromote
    
end

util.AddNetworkString("PromoDemoTeam")

net.Receive("PromoDemoTeam", function(len, pl)
    local sid64,rank,rteam
    sid64 = net.ReadString()
    rank = net.ReadInt(8)
    rteam = net.ReadUInt(8)

    local setrank = true
    if rank <0 then
        setrank = false
        if rank == -1 then 
            rank = "promo"
        elseif rank == -2 then 
            rank = "demo"
        end
    end

    pl:PromoDemoTeam( player.GetBySteamID64(sid64) , rank, setrank, rteam)
    

end )

-----------


util.AddNetworkString("OpenJRSMenu")

hook.Add("PlayerSay", "JRS_ChatCommands", function(ply, text)

  --[[  if string.StartWith( string.lower(text), JRS.CFG.OpenMenuCommand) then
        if ply:GetRankVar("CanPromote") or CAMI.PlayerHasAccess(ply, "Promote_Any") then
            net.Start("OpenJRSMenu")
            net.Send(ply)
        end
        return ""
    end
    ]]
    local StartsWithPromo = string.StartWith(string.lower(text), JRS.CFG.PromoCommand .. " ")
    local StartsWithDemo = string.StartWith(string.lower(text), JRS.CFG.DemoCommand .. " ")

    if StartsWithPromo or StartsWithDemo then

        local txt = string.Explode( " ", text) 

        if tonumber(txt[#txt]) and #txt < 2 then
            JRS.LegacyNotifyPlayer(ply, "Command Usage : " .. txt[1] .. " " .. "<text PlayerName / SteamID / SteamID64> <number RankID>(optional)", NOTIFY_ERROR , 4)
            return ""
        end

        local plrank, promotee, PromoOrDemoStr, TextNoNum
        local TextNoCmd = string.sub(text, #txt[1] +2) 
        if tonumber(txt[#txt]) && #txt > 2 then
            TextNoNum = string.sub(TextNoCmd, 1, #TextNoCmd - #txt[#txt] - 1 )
            plrank = tonumber(txt[#txt])

            if StartsWithPromo then
                PromoOrDemoStr = "Promoted " 
            else
                PromoOrDemoStr = "Demoted "  
            end
        else 
            TextNoNum = TextNoCmd
            if StartsWithPromo then
                PromoOrDemoStr = "Promoted "
                plrank = 1
            else
                PromoOrDemoStr = "Demoted "
                plrank = -1
            end
        end

        if IsPlyNick(TextNoNum) then

            promotee = IsPlyNick( TextNoNum ) 
            
            if tonumber(txt[#txt]) && #txt > 2 then
                if ply:PromoDemoPlayer(promotee, plrank, true) then
                    JRS.LegacyNotifyPlayer("BROADCAST", ply:Nick() .. " " .. PromoOrDemoStr .. promotee:Nick() .. " to " .. ply:GetRankName(), NOTIFY_GENERIC , 3)
                    return ""
                end
            elseif ply:PromoDemoPlayer(promotee, plrank, false) then
                JRS.LegacyNotifyPlayer("BROADCAST", ply:Nick() .. " " .. PromoOrDemoStr .. promotee:Nick() .. " to " .. ply:GetRankName(), NOTIFY_GENERIC , 3)
                return ""
            else
                JRS.LegacyNotifyPlayer(ply, "Command Usage : " .. txt[1] .. " " .. "<text PlayerName / SteamID / SteamID64> <number RankID>(optional)>", NOTIFY_ERROR , 4)
                return ""
            end
        else
            JRS.LegacyNotifyPlayer(ply, "No player found with that name/SteamID/SteamID64", NOTIFY_ERROR , 3)
            JRS.LegacyNotifyPlayer(ply, "Command Usage : " .. txt[1] .. " " .. "< PlayerName / SteamID / SteamID64> <number RankID>(optional)>", NOTIFY_ERROR , 3)
            return ""
        end
        return ""
    end
end )


function meta:RanksLoadout()
    local tbl = self:GetJobRanksTable()
    
    if tbl and tbl.Loadout[self:GetRank()] then
        for _, v in pairs( tbl.Loadout[self:GetRank()] ) do
            self:Give(v)
        end
    end

end

function meta:RanksPlayerModels()

    local tbl = self:GetJobRanksTable()
    
    if tbl and tbl.Models[self:GetRank()] then
        self:SetModel( tbl.Models[self:GetRank()][ math.random( #tbl.Models[ self:GetRank() ] ) ] )
    end

end

function meta:RanksBonusSalary(RankChanged)

    local tbl,bonus = self:GetJobRanksTable()
    
    if tbl then bonus = tbl.BonusSalary[self:GetRank()] end

    if tbl and bonus then
        local salary = self:getJobTable().salary
        bonus = salary/100 * bonus -- as a % of salary
        self:setDarkRPVar("salary", salary + bonus)
        if RankChanged then
            JRS.LegacyNotifyPlayer(self, "Your salary has chaged to a total of " .. tostring(salary + bonus) .. "€ (" ..  tostring(bonus) .. "€ rank bonus).", NOTIFY_GENERIC, 3  )
        end
    end
end

hook.Add("PlayerSpawn", "jrs_managespawn", function(ply)
    JRS.DrpRanksPlayerData[ply:SteamID64()][ply:Team()] = JRS.DrpRanksPlayerData[ply:SteamID64()][ply:Team()] or {}
    
    ply:JRS_ManageSpawn()

end)
