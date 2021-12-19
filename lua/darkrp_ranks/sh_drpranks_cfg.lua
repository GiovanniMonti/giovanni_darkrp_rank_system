JRS.CFG = JRS.CFG or {}

JRS.CFG.Prefix = "!"
-- the prefix for the command, be smart about it.
JRS.CFG.PromoCommand = JRS.CFG.Prefix .. "gpromote"
-- chat command used to promote
JRS.CFG.DemoCommand = JRS.CFG.Prefix .. "gdemote" 
-- chat command used to demote

JRS.CFG.OpenMenuCommand = JRS.CFG.Prefix .. "gmenu"

JRS.CFG.AddRankToJobName = true
-- does this : jobname (rankname)


--[[
    Config Usage & formatting.

    NOTICE : Up to 255 ranks & 255 jobs with ranks.

    Create a ranks table    
        CreateRanksTable( RankTableID, MaxRank, PrefixSeparator, PromoTableID )

        RankTableID : the number ID of the table. (integer)
        MaxRank : the highest rank you want to create in the table (integer)
        Prefix Separator : The string of text between the rank prefix and the player's name (string)
        PromoTable ID : a table with the number IDs of all other jobtables who's players THIS table's players can promote. ( table of integers) nil to disable.

        Example : 
        CreateRanksTable(1, 4 , ".", {2} )

    Create a rank for the rankstable last ranktable created.
        CreateRank( RankID, RankName, Prefix, Loadout, CanPromote, MaxPromoRank )

        RankID : the number ID of the rank you are creating, start from 0 and go up. (Integer)
        RankName : The name of the rank you are creating. (String)
        Prefix : A prefix for your rank, will be displayed before player's name. (String)
        Loadout : Table of the names of weapons to give players at spawn (Table of Strings)
        CanPromote : If a rank can promote ranks lower than itself or not. (boolean - true or false )
        MaxPromoRank : The highest rank this rank can promote. only if CanPromote = true. (integer)
]]

local function JRS_InitRanks() 
timer.Simple(3, function()

    -- rank tables in here.
    print(1)

    CreateRanksTable(1, 4 , ".", {2} )
    CreateRank( 0, "Rank 1", "JOB-RNK-1", {"weapon_pistol"}, false, nil )
    CreateRank( 1, "Rank 2", "JOB-RNK-2", {"weapon_pistol","weapon_smg1"}, false, nil, nil )
    CreateRank( 2, "Rank 3", "JOB-RNK-3", {"weapon_pistol","weapon_smg1"}, true, 2, nil )
    CreateRank( 3, "Rank 4", "JOB-RNK-4", {"weapon_pistol","weapon_smg1"}, true, nil, nil )
    GiveJobRankTable(1 , TEAM_CITIZEN )

    CreateRanksTable(2, 2 , ".", nil )
    CreateRank( 0, "Rank 1", "JOB-RNK-1", {"weapon_pistol","weapon_smg1"}, false, nil, nil )
    CreateRank( 1, "Rank 2", "JOB-RNK-2", {"weapon_pistol","weapon_smg1"}, false, nil, nil )

    GiveJobRankTable(2, TEAM_POLICE )


    -- Editing anything below here will result in errors.
end)
end

hook.Add("loadCustomDarkRPItems", "JRS_InitConfigRanks", JRS_InitRanks() )