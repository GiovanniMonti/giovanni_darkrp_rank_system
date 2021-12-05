net.Receive("LegacyNotifySv", function()
    local text = net.ReadString()
    local type = net.ReadInt(4)
    local lentime = net.ReadInt(8)
    print (text)
    notification.AddLegacy( text, type, lentime )
    surface.PlaySound( "buttons/button15.wav" )

end)