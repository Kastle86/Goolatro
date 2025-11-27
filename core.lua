--- STEAMODDED HEADER
--- MOD_NAME: Goolatro
--- MOD_ID: Goolatro
--- MOD_AUTHOR: Kastle
--- MOD_DESCRIPTION: Changed jokers!
--- PREFIX: goolatro
----------------------------------------------------------

if not Goolatro then Goolatro = {} end
local mod_path = SMODS.current_mod.path
Goolatro.path = mod_path

-- Безопасная инициализация G.localization.misc.other
G.localization = G.localization or {}
G.localization.misc = G.localization.misc or {}
G.localization.misc.other = G.localization.misc.other or {}

G.localization.misc.other.goolatro_art_credit = "Art: {1}"


G.localization.misc.other.goolatro_art_credit = "Art: {1}"
Goolatro = Goolatro or {}
Goolatro.first_hand_played = false


-- Регистрируем атласы джокеров с размерами 71x96
SMODS.Atlas{
    key = 'prototype',
    path = 'goolatro_prototype.png',
    px = 71,
    py = 96
}

SMODS.Atlas{
    key = 'puro',
    path = 'goolatro_puro.png',
    px = 71,
    py = 96
}

SMODS.Atlas{
    key = 'colin',
    path = 'goolatro_colin.png',
    px = 71,
    py = 96
}

SMODS.Atlas{
    key = 'drk',
    path = 'goolatro_drk.png',
    px = 71,
    py = 96
}


SMODS.Atlas{
    key = 'Hologram',
    path = 'goolatro_Hologram.png',
    px = 71,
    py = 95
}
SMODS.Atlas{
    key = 'Latex',
    path = 'goolatro_latex.png',
    px = 71,
    py = 95
}

SMODS.Atlas{
    key = "goolatroblinds",
    path = "goolatro_blinds_2x.png",
    px = 32,
    py = 32,
    frames = 1,               -- ← ВАЖНО!
    atlas_table = 'ANIMATION_ATLAS'
}



-- Загружаем скрипты из items/
-- Сначала грузим jokers.lua
local f, err = SMODS.load_file("items/jokers.lua")
if err then error(err) end
f()

-- Потом грузим другие файлы
local files = NFS.getDirectoryItems(mod_path .. "items")
for _, file in ipairs(files) do
    if file ~= "jokers.lua" and string.sub(file, -4) == ".lua" then
        local f2, err2 = SMODS.load_file("items/" .. file)
        if err2 then error("Ошибка в " .. file .. ": " .. err2) end
        f2()
    end
end
