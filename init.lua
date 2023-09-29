-- forces the map into singlenode mode, don't do this if this is just a "realm".
luamap.set_singlenode()
-- creates a terrain noise
luamap.register_noise("terrain",{
    type = "3d",
    np_vals = {
        offset = 0,
        scale = 1,
        spread = {x=1000, y=1000, z=1000},
        seed = 5900033,
        octaves = 10,
        persist = 0.8,
        lacunarity = 1.6,
        flags = ""
    },

})
luamap.register_noise("mountains",{
    type = "2d",
    np_vals = {
        offset = 0,
        scale = 1,
        spread = {x=150, y=130, z=130},
        seed = 3452345,
        octaves = 5,
        persist = 0.6,
        lacunarity = 2,
        flags = "absvalue"
    },

})

luamap.register_noise("dunes",{
    type = "2d",
    np_vals = {
        offset = 0,
        scale = 1,
        spread = {x=40, y=20, z=300},
        seed = 22345234,
        octaves = 2,
        persist = 0.6,
        lacunarity = 2,
        flags = "absvalue"
    },

})

luamap.register_noise("hills",{
    type = "2d",
    np_vals = {
        offset = 0,
        scale = 1,
        spread = {x=100, y=50, z=100},
        seed = 1345123,
        octaves = 3,
        persist = 0.5,
        lacunarity = 1.8,
        flags = "absvalue"
    },

})

luamap.register_noise("canyons",{
    type = "3d",
    np_vals = {
        offset = 0,
        scale = 1,
        spread = {x=30, y=100, z=30},
        seed = 48545,
        octaves = 4,
        persist = 0.5,
        lacunarity = 1.8,
        flags = "absvalue"
    },

})

luamap.register_noise("canyon_top",{
    type = "2d",
    np_vals = {
        offset = 0,
        scale = 1,
        spread = {x=100, y=100, z=100},
        seed = 134512,
        octaves = 3,
        persist = 0.5,
        lacunarity = 1.8,
        flags = "absvalue"
    },
})


local function cid(nodename)
    return minetest.get_content_id(nodename)
end

local stone = cid("default:stone")
local water = cid("default:water_source")
local desert_sand = cid("default:desert_sand")
local air = cid("air")
local dirt = cid("default:dirt")
local sand = cid("default:sand")
local dirt_with_grass = cid("default:dirt_with_grass")
local desert_sandstone = cid("default:desert_sandstone")
local dry_dirt_with_dry_grass = cid("default:dry_dirt_with_dry_grass")
local dry_dirt = cid("default:dry_dirt")
local desert_sandstone = cid("default:desert_sandstone")
local dirt_with_snow = cid("default:dirt_with_snow")
local dirt_with_coniferous_litter = cid("default:dirt_with_coniferous_litter")


local old_logic = luamap.logic

function luamap.logic(noise_vals,x,y,z,seed,original_content)

    -- get any terrain defined in another mod
    local content = old_logic(noise_vals,x,y,z,seed,original_content)
    local o_y = y -- original y before modification

    local r = 500
    local biomeoffset = 250
    local e = 2.71828
    local lake_water_level = 37
    local mountains = noise_vals.mountains
    local desertdunes = noise_vals.dunes
    local hills = noise_vals.hills
    local canyons = noise_vals.canyons
    local canyon_top = noise_vals.canyon_top
    local biome_depth = math.abs(noise_vals.terrain*6) + 1
    local mtnareaspread = 100
    local dsrtareaspread = 140
    local lkareaspread = 110
    local hillareaspread = 140
    local islandspread = 30
    local canyspread = 120
    local canyon_top_level = 12
    

    -- gausian bumps in a quadrant
    local mountain_mix = (e^(-((((x-biomeoffset)^2)+((z-biomeoffset)^2))/(2*mtnareaspread^2))))
    local desert_mix = (e^(-(((((-x)-biomeoffset)^2)+((z-biomeoffset)^2))/(2*dsrtareaspread^2))))

    local not_desert = -(desert_mix-1)

    --gausian bump in the center
    local lakes_mix = (e^(-((((x)^2)+((z)^2))/(2*lkareaspread^2))))
    local isle_mix = (e^(-((((x)^2)+((z)^2))/(2*islandspread^2))))

    local hills_mix = (e^(-(((((-x)-biomeoffset)^2)+(((-z)-biomeoffset)^2))/(2*hillareaspread^2))))
    local canyon_mix = (e^(-(((((x)-biomeoffset)^2)+(((-z)-biomeoffset)^2))/(2*canyspread^2))))

    -- add to y to lower the level, subtract to raise the level

    -- fill the lake first before modifying the land coords

    -- mix in the mountians
    y=y-mountain_mix*mountains*100

    -- make the lake by subtracting height in the center
    y = y + lakes_mix * 25
    -- add the island in the center
    y = y - isle_mix * 12
    -- mix in the dunes
    y=y-desert_mix*desertdunes*10

    -- mix in the hills
    y=y-hills_mix*hills*20
    -- mix in the small detail terrain but not in the desert
    y=y-noise_vals.terrain*not_desert*5


    local biome = "grass"
    if canyon_mix + biome_depth * canyon_mix > .15 then
        biome = "canyon"
    elseif mountain_mix + biome_depth * mountain_mix > .15 then
        if o_y - biome_depth > 80 then
            biome = "pine_and_snow"
        else
            biome = "pine"
        end
    elseif hills_mix + biome_depth * hills_mix > .15 then
        biome = "deciduous"
    -- elseif desert_mix + biome_depth * desert_mix > .15 then
    --     biome = "desert"
    end
    if desert_mix > .2*desertdunes and desert_mix>.08 and y > desertdunes*5 then
        biome = "desert"
    end


    -- add water using original y for flat water surface
    if o_y>0 and (10*o_y)^2 < (r^2-x^2-z^2) then

        -- fill the lake
        if lakes_mix > .1 and o_y < lake_water_level then
            content = water
            biome = "lake"
        end


    end

    -- canyons
    c_y = o_y - (canyon_top*10 + canyon_top_level)

    if c_y>0 and (10*c_y)^2 < (r^2-x^2-z^2) or
    c_y<=0 and (c_y>((x^2)/(2*r))+((z^2)/(2*r))-(r/2)) then

        if canyon_mix > .6* canyon_top and -- keep it from overflowing
        canyons > 0 and canyons < .3 then
            content = desert_sandstone
        end
    end

    -- stone and biomes

    if y>0 and (10*y)^2 < (r^2-x^2-z^2) or
        y<=0 and (y>((x^2)/(2*r))+((z^2)/(2*r))-(r/2)) then

        content = stone
        
        if y > 0 then
            -- lake
            if biome == "lake" and (10*(y+biome_depth))^2 > (r^2-x^2-z^2) then
                content = sand
            end

            -- desert
            if desert_mix > .2*desertdunes and desert_mix>.08 and y > desertdunes*5 then
                content = desert_sand
            -- other biomes
            elseif (10*(y+biome_depth))^2 > (r^2-x^2-z^2) then
                -- top nodes
                if (10*(y+1))^2 > (r^2-x^2-z^2) then
                    if biome == "grass" then
                        content = dirt_with_grass
                    end
                    if biome == "canyon" then
                        content = dry_dirt_with_dry_grass
                    end
                    if biome == "pine_and_snow" then
                        content = dirt_with_snow
                    end
                    if biome == "pine" then
                        content = dirt_with_coniferous_litter
                    end
                    if biome == "deciduous" then
                        content = dirt_with_grass
                    end
                    if biome == "desert" then
                        content = desert_sand
                    end

                else

                    -- under nodes
                    content = dirt

                    if biome == "canyon" then
                        content = dry_dirt
                    end
                    if biome == "desert" then
                        content = desert_sand
                    end

                end

            end
        end
        

    end
    return content
end

minetest.register_on_joinplayer(function(player)
    minetest.chat_send_player(player:get_player_name(),"MisterE's Adventure Map Creator mod is overriding mapgen. Use /emerge_map to load the entire map (it will take a while)")
end)

minetest.register_chatcommand("emerge_map", {
    description = "Emerge the entire adventure map island",
    privs = {server=true},
    func = function(name, param)
        local minp = vector.new(-500,-30,-500)
        local maxp = vector.new(500, 50, 500)
        minetest.emerge_area(minp, maxp)
        minetest.chat_send_player(name, "MisterE's Adventure map is emerging! Have fun creating! Try using worldedit additions with bonemeal mods to create forests, and the terraform mod to edit the landscape.")
    end
})
