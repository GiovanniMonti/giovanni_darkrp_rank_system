JRS.DrpRanksPlayerData = JRS.DrpRanksPlayerData or {}

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

util.AddNetworkString( "LegacyNotifySv" )

local NOTIFY_GENERIC = 0
local NOTIFY_ERROR = 1
local NOTIFY_UNDO = 2
local NOTIFY_HINT = 3
local NOTIFY_CLEANUP = 4

function JRS.LegacyNotifyPlayer(ply, text, type, length)
    length = length or 2
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
-- Num is optional, defaults to 1
function meta:RankPromote(num)
    if num == self:GetRank() then return end
    
    if num and JRS.JobRankTables[self:Team()] then
        self:SetRank( num )
        self:RanksLoadout()
        
        JRS.DrpRanksPlayerData[self:SteamID64()] = JRS.DrpRanksPlayerData[self:SteamID64()] or {}
        JRS.DrpRanksPlayerData[self:SteamID64()][self:Team()] = JRS.DrpRanksPlayerData[self:SteamID64()][self:Team()] or {}
        JRS.DrpRanksPlayerData[self:SteamID64()][self:Team()].Rank = num
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

    self:RanksLoadout()
    self:RanksPlayerModels()

end

function meta:PlayerCanPromote(sPly, rank)
    local PlyRankTbl = self:GetJobRanksTable()
    local sPlyRankTbl = sPly:GetJobRanksTable()
    
    if !sPly:GetJobRanksTable() then return false end
    
    if ( rank >= sPly:GetJobRanksTable().MaxRank and rank >= sPly:GetJobRanksTable().MaxPromoRank[self:GetRank()]  ) then 
        JRS.LegacyNotifyPlayer(self, "The maximum rank on this job has been reached. (or you're trying to promote over the max)", NOTIFY_ERROR , 4)
        return false
    end 

    if ( rank < 0 ) then 
        JRS.LegacyNotifyPlayer(self, "The minimum rank on this job has been reached.(why are you using a negative number??)", NOTIFY_ERROR , 4)
        return false
    end

    if CAMI.PlayerHasAccess(self, "Promote_Any") then 
        return true
    end

    if self:GetRank() > sPly:GetRank() and rank < self:GetRank() and rank < sPly:GetJobRanksTable().MaxPromoRank[self:GetRank()]  then
        for _, v in pairs( PlyRankTbl.OtherPromoPerms ) do
            if JRS.JobRankTables[sPly:Team()] == v then return true end
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

util.AddNetworkString("OpenJRSMenu")

hook.Add("PlayerSay", "JRS_ChatCommands", function(ply, text)

    if string.StartWith( string.lower(text), JRS.CFG.OpenMenuCommand) then
        if ply:GetRankVar("CanPromote") or CAMI.PlayerHasAccess(ply, "Promote_Any") then
            net.Start("OpenJRSMenu")
            net.Send(ply)
        end
        return ""
    end

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
    
    local loadout = self:GetJobRanksTable().Loadout[self:GetRank()]
    
    if loadout then
        for _, v in pairs( loadout ) do
            self:Give(v)
            
        end
    end

end

function meta:RanksPlayerModels()

    local PlyModels = self:GetJobRanksTable().Models[self:GetRank()]

    if PlyModels then
        self:SetModel( PlyModels[math.random(#PlyModels)] )
    end

end

hook.Add("PlayerSpawn", "jrs_managespawn", function(ply)
    JRS.DrpRanksPlayerData[ply:SteamID64()][ply:Team()] = JRS.DrpRanksPlayerData[ply:SteamID64()][ply:Team()] or {}
    
    ply:JRS_ManageSpawn()

end)