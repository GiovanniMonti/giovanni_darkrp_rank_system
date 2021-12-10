net.Receive("LegacyNotifySv", function()
    local text = net.ReadString()
    local type = net.ReadInt(4)
    local lentime = net.ReadInt(8)
    print(text)
    notification.AddLegacy( text, type, lentime )
    surface.PlaySound( "buttons/button15.wav" )

end)
--------------------------------------------------

net.Receive("OpenJRSMenu", function() JRS:OpenMenu() end)

function JRS:OpenMenu()

    local w =  ScrW()/4
    local h =  ScrH()/2

    local FrameColor = Color(50, 50, 50, 245)

    local Frame = vgui.Create( "DFrame" )
    Frame:SetPos(ScrW()/2 -w/2,ScrH()/2 -h/2)
    Frame:SetSize( w , h ) 
    Frame:SetTitle( "DarkRP Ranks System" ) 
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


    function PlyList:OnRowRightClick(lineID, line)

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