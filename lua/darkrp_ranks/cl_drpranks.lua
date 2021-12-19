net.Receive("LegacyNotifySv", function()
    local text = net.ReadString()
    local type = net.ReadInt(4)
    local lentime = net.ReadInt(8)
    print(text)
    notification.AddLegacy( text, type, lentime )
    surface.PlaySound( "buttons/button15.wav" )

end)

JRS.ClientTempRankDB = JRS.ClientTempRankDB or {}

function JRS.RequestPlyRanks(ply)

    net.Start("JRS_RqPlRnk")
    net.WriteUInt(ply:AccountID(), 28)
    net.SendToServer()

end

net.Receive("JRS_RetPlRnk", function()

    local iLen = net.ReadUInt(8)
    local pl = player.GetByAccountID( net.ReadUInt(28) )
    JRS.ClientTempRankDB[ pl:SteamID64() ]  = JRS.ClientTempRankDB[ pl:SteamID64() ] or {}

    for i = 1, iLen do
        JRS.ClientTempRankDB[ pl:SteamID64() ][net.ReadUInt(8)] = net.ReadUInt(8)
    end
end)

--------------------------------------------------

surface.CreateFont( "JRS_MenuData",{

    font = "Tahoma",
	extended = false,
	size = 16,
	weight = 400,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	outline = false,


} )



---------------------------------------------------

local function TeamPromoDemo(sply, rank, steam)
    net.Start("PromoDemoTeam")
        net.WriteString( sply:SteamID64() ) 
        if rank == "promo" then 
            rank = -1 
        elseif rank == "demo" then 
            rank = -2 
        end -- this sucks, a LOT.
        net.WriteInt(rank, 8)
        net.WriteUInt(steam, 8) -- less than 255 teams & 255 ranks each seems reasonable.
    net.SendToServer()
    
end
----------------------------------------------------

net.Receive("OpenJRSMenu", function() JRS:OpenMenu() end)

function JRS:OpenMenu()

    local w =  ScrW()/4
    local h =  ScrH()/2

    local FrameColor = Color(50, 50, 50, 245)

    local Frame = vgui.Create( "DFrame" )
    Frame:SetPos(ScrW()/2 -w/2,ScrH()/2 -h/2)
    Frame:SetSize( w , h ) 
    Frame:SetTitle( "DarkRP Ranks System Menu" ) 
    Frame:SetVisible( true ) 
    Frame:SetDraggable( true ) 

    Frame.btnClose:SetVisible( true )
	Frame.btnMaxim:SetVisible( false )
	Frame.btnMinim:SetVisible( false )
    
    Frame:MakePopup()

    function Frame:Paint(wi,hi)
        draw.RoundedBox(8, 0, 0, wi, hi, FrameColor)
    end


    local PlyList = vgui.Create("DListView", Frame)

    PlyList:Dock(NODOCK)
    PlyList:SetPos( w*0.04, h*0.1 )
    PlyList:SetSize( w * 0.9, h * 0.5 )
    PlyList:SetMultiSelect( false )

    PlyList:AddColumn("Name")
    PlyList:AddColumn("SteamID")
    PlyList:AddColumn("SteamID64")
        
    for _,v in pairs( player.GetHumans() ) do
        PlyList:AddLine( v:Nick(), v:SteamID(), v:SteamID64() )
    end

    function PlyList:OnRowSelected(rowIndex, row)
        local ply = player.GetBySteamID64( row:GetColumnText(3) )
        JRS.RequestPlyRanks(ply)

        local plytext = vgui.Create( "DLabel", Frame )
        plytext:SetPos( w*0.04, h*0.65 )

        local str = "Player : " .. ply:Nick() .. "\nCurrent Job : " .. team.GetName(ply:Team()) .. "\nCurrent Rank : " .. ply:GetRankName() .. " ( ID : ".. ply:GetRank() .. " )" 

        plytext:SetFont("JRS_MenuData")
        plytext:SetText( str )

        plytext:SizeToContents()


        local promotext = vgui.Create( "DLabel", Frame )
        promotext:SetPos( w*0.60, h*0.65 )
        promotext:SetText( "Change rank on other Jobs" )
        promotext:SizeToContents()

        local joblist = vgui.Create("DComboBox", Frame)
        joblist:SetPos( w*0.60, h*0.7 )
        joblist:SetSize(w*0.34, h*0.04 )
        

        local selectedTeam

        for k,_ in pairs(JRS.JobRankTables) do
            local default = false
            if k == ply:Team() then
                default = true
                selectedTeam = k
            end
            joblist:AddChoice(team.GetName(k), k,default)    
        end

        local selectedJobInfo = vgui.Create( "DLabel", Frame )
        selectedJobInfo:SetPos( w*0.60, h*0.70 )
        selectedJobInfo:SetText( "Change rank on other Jobs" )
        selectedJobInfo:SizeToContents()

        local selectedJobRank = vgui.Create("DComboBox", Frame)
        selectedJobRank:SetPos( w*0.60, h*0.75 )
        selectedJobRank:SetSize(w*0.34, h*0.04 )
        
        local teamJobsRanksTable = ply:GetJobRanksTable(selectedTeam)
         
        for k,v in pairs( teamJobsRanksTable.RankName ) do
            local default = false
            if k == JRS.ClientTempRankDB[ply:SteamID64()][selectedTeam] then 
                default = true
            end

            selectedJobRank:AddChoice(v,k,default)
        end

        function joblist:OnSelect(index, value, data)
            selectedTeam = data
            teamJobsRanksTable = ply:GetJobRanksTable(selectedTeam)
            selectedJobRank:Clear()
            for k,v in pairs( teamJobsRanksTable.RankName ) do
                local default = false
                if k == JRS.ClientTempRankDB[ply:SteamID64()][data] then 
                    default = true
                end
    
                selectedJobRank:AddChoice(v,k,default)
    
            end
        end

        local hbuttons = h*0.85

        local PromoButton = vgui.Create("DButton", Frame)
        PromoButton:SetText("Promote Job")
        PromoButton:SetPos( w*0.60, hbuttons )	
        PromoButton:SetSize(w*0.17, h*0.04 )

        function PromoButton.DoClick()
	        TeamPromoDemo(ply,"promo",selectedTeam)
        end

        local DemoButton = vgui.Create("DButton", Frame)
        DemoButton:SetText("Demote Job")
        DemoButton:SetPos( w*0.774, hbuttons )	
        DemoButton:SetSize(w*0.17, h*0.04 )

        function DemoButton.DoClick()
	        TeamPromoDemo(ply,"demo",selectedTeam)
        end

    end
    
    function PlyList:OnRowRightClick(lineID, line)
        local rMenu = DermaMenu()

        rMenu:AddOption("Copy SteamID", function()
            SetClipboardText(line:GetColumnText(2))
        end)
    
        rMenu:AddOption("Copy SteamID64", function()
            SetClipboardText(line:GetColumnText(3))
        end)

        rMenu:AddOption("Fast Promote", function()
            LocalPlayer():ConCommand( 'say '.. JRS.CFG.PromoCommand .. " " .. line:GetColumnText(3) )
        end)
        rMenu:AddOption("Fast Demote", function()
            LocalPlayer():ConCommand( 'say '.. JRS.CFG.DemoCommand .. " " .. line:GetColumnText(3) )
            print('say '.. JRS.CFG.DemoCommand .. " " .. line:GetColumnText(3))
        end)
        rMenu:Open()
    end
    
    local PlayerSearch = vgui.Create("DTextEntry", Frame)
    local PlySearchText = ""

    PlayerSearch:SetSize( w * 0.9, h * 0.035 )
    PlayerSearch:SetPos( w*0.04, h*0.05 )
    PlayerSearch:SetText( "Search for a Player (Nick/SteamID/SteamID64)" )
    function PlayerSearch:OnGetFocus()
        PlayerSearch:SetText( "" )
    end
    function PlayerSearch:OnEnter()
        PlySearchText = self:GetValue()
        PlyList:Clear()

        for _,v in pairs( player.GetHumans() ) do
            if ( string.find( string.lower( v:Nick() ), string.lower( PlySearchText ) ) or string.find(v:SteamID64(), PlySearchText) or string.find(v:SteamID(), PlySearchText) ) then
                PlyList:AddLine( v:Nick(), v:SteamID(), v:SteamID64() )
            end
        end
    end
    
end