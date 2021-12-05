DrpRanksPlayerData = DrpRanksPlayerData or {}

hook.Add("Initialize", "drpRanksDBCreate", function()
    if file.Exists("drpranksdata/", "DATA") then
        local f, _ = file.Find("drpranksdata/*.txt", "DATA")
        for k,v in pairs( f ) do
            DrpRanksPlayerData[ string.Left(v, 17) ] = util.JSONToTable( file.Read("drpranksdata/"..v,"DATA") ) or {}
            print(v)
        end
    else
        file.CreateDir("drpranksdata")
    end
            

end)

hook.Add("PlayerInitialSpawn", "gofuckyourself", function(ply)

    DrpRanksPlayerData[ply:SteamID64()] = DrpRanksPlayerData[ply:SteamID64()] or {}
    
end)

hook.Add("PlayerSpawn", "giveyouarankdickhead", function(ply)
    DrpRanksPlayerData[ply:SteamID64()][ply:Team()] = DrpRanksPlayerData[ply:SteamID64()][ply:Team()] or {}
    
    ply:JRS_ManageSpawn()

end)

function SaveEntireDB()
   for k,v in pairs(DrpRanksPlayerData) do
        file.Write( "drpranksdata/" .. k .. ".txt", util.TableToJSON( DrpRanksPlayerData[k] ) )
   end

end

function UpdatePlyDB(steamID)
    file.Write( "drpranksdata/" .. steamID .. ".txt", util.TableToJSON( DrpRanksPlayerData[steamID] ) )
end

util.AddNetworkString( "LegacyNotifySv" )

local NOTIFY_GENERIC = 0
local NOTIFY_ERROR = 1
local NOTIFY_UNDO = 2
local NOTIFY_HINT = 3
local NOTIFY_CLEANUP = 4

function LegacyNotifyPlayer(ply, text, type, length)
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

function IsPlyNick( nick )
    for _, v in pairs( player.GetAll() ) do
        
        if string.find( string.lower( v:Nick() ), string.lower( nick ) ) then return v end
        if (v:SteamID64() == nick) or (v:SteamID() == nick) then return v end
        
    end
    return false
end

local meta = FindMetaTable("Player")

function meta:SetRank(RankID)
    local jobID = self:Team() 
    if JobRankTables[jobID] then
        self:SetNWInt("JobRank", RankID)

        local JobName = team.GetName(jobID) .. " ( " .. self:GetRankName() .. " )"
        self:setDarkRPVar("job", JobName)

    end

end
-- Num is optional, defaults to 1
function meta:RankPromote(num)
    if num == self:GetRank() then return end
    
    if num and JobRankTables[self:Team()] then
        self:SetRank( num )
        self:RanksLoadout()
        
        DrpRanksPlayerData[self:SteamID64()] = DrpRanksPlayerData[self:SteamID64()] or {}
        DrpRanksPlayerData[self:SteamID64()][self:Team()] = DrpRanksPlayerData[self:SteamID64()][self:Team()] or {}
        -- this is painfull to write. i'm sorry about it.
        DrpRanksPlayerData[self:SteamID64()][self:Team()].Rank = num
        UpdatePlyDB( self:SteamID64())
    end

end

function meta:JRS_ManageSpawn()

    if DrpRanksPlayerData[self:SteamID64()][self:Team()].Rank then
        self:SetRank(DrpRanksPlayerData[self:SteamID64()][self:Team()].Rank)
    else 
      self:SetRank(0)
      DrpRanksPlayerData[self:SteamID64()][self:Team()].Rank = 0
    end

    self:RanksLoadout()
    self:RanksPlayerModels()

end

function meta:PlayerCanPromote(sPly, rank)
    local PlyRankTbl = self:GetJobRanksTable()
    local sPlyRankTbl = sPly:GetJobRanksTable()
    
    if !sPly:GetJobRanksTable() then return false end
    
    if ( rank >= sPly:GetJobRanksTable().MaxRank and rank >= sPly:GetJobRanksTable().MaxPromoRank[self:GetRank()]  ) then 
        LegacyNotifyPlayer(self, "The maximum rank on this job has been reached. (or you're trying to promote over the max)", NOTIFY_ERROR , 4)
        return false
    end 

    if ( rank < 0 ) then 
        LegacyNotifyPlayer(self, "The minimum rank on this job has been reached.(why are you using a negative number??)", NOTIFY_ERROR , 4)
        return false
    end

    if CAMI.PlayerHasAccess(self, "Promote_Any") then 
        return true
    end

    if self:GetRank() > sPly:GetRank() and rank < self:GetRank() and rank < sPly:GetJobRanksTable().MaxPromoRank[self:GetRank()]  then
        for _, v in pairs( PlyRankTbl.OtherPromoPerms ) do
            if JobRankTables[sPly:Team()] == v then return true end
        end
    end

    LegacyNotifyPlayer(self, "You do not have the permissions to promote/demote " .. sPly:Nick() .. " to " .. sPly:GetRankName(), NOTIFY_ERROR , 4)

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

hook.Add("PlayerSay", "JRS_ChatCommands", function(ply, text)

    local StartsWithPromo = string.StartWith(string.lower(text), JRS_PromoCommand.." ")
    local StartsWithDemo = string.StartWith(string.lower(text), JRS_DemoCommand.." ")

    if StartsWithPromo or StartsWithDemo then

        local txt = string.Explode( " ", text) 

        if tonumber(txt[#txt]) and #txt < 2 then
            LegacyNotifyPlayer(ply, "Command Usage : " .. txt[1] .. " " .. "<text PlayerName / SteamID / SteamID64> <number RankID>(optional)", NOTIFY_ERROR , 4)
            return ""
        end

        local plrank, promotee, PromoOrDemoStr, TextNoNum
        local TextNoCmd = string.sub(text, #txt[1] +2) 
        if tonumber(txt[#txt]) then
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
            
            if tonumber(txt[#txt]) then
                if ply:PromoDemoPlayer(promotee, plrank, true) then
                    LegacyNotifyPlayer("BROADCAST", ply:Nick() .. " " .. PromoOrDemoStr .. promotee:Nick() .. " to " .. ply:GetRankName(), NOTIFY_GENERIC , 3)
                    return ""
                end
            elseif ply:PromoDemoPlayer(promotee, plrank, false) then
                LegacyNotifyPlayer("BROADCAST", ply:Nick() .. " " .. PromoOrDemoStr .. promotee:Nick() .. " to " .. ply:GetRankName(), NOTIFY_GENERIC , 3)
                return ""
            else
                LegacyNotifyPlayer(ply, "Command Usage : " .. txt[1] .. " " .. "<text PlayerName / SteamID / SteamID64> <number RankID>(optional)>", NOTIFY_ERROR , 4)
                return ""
            end
        else
            LegacyNotifyPlayer(ply, "No player found with that name/SteamID/SteamID64", NOTIFY_ERROR , 3)
            LegacyNotifyPlayer(ply, "Command Usage : " .. txt[1] .. " " .. "< PlayerName / SteamID / SteamID64> <number RankID>(optional)>", NOTIFY_ERROR , 3)
            return ""
        end
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