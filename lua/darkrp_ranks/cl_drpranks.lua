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

    local w =  ScrW()/5
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

    function Frame:Paint(w,h)
        draw.RoundedBox(8, 0, 0, w, h, FrameColor)
    end

    local PlayerSearch = vgui.Create("DTextEntry", Frame)

    PlayerSearch:SetSize( w * 0.85, h * 0.035 )
    PlayerSearch:SetPos( w*0.04, h*0.05 )
    PlayerSearch:SetText( "Search for a Player (Nick/SteamID/SteamID64)" )
    function PlayerSearch:OnEnter()
        local Text = self:GetValue()
        Text = IsPlyNick(Text)
        if Text then
            --- make search & list
        else
            -- error messege
        end
    end
end