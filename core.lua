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

-- Инспектор таблиц для дебага
function inspect_table(tbl, indent)
    indent = indent or ""
    if type(tbl) ~= "table" then print(indent .. tostring(tbl)); return end
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(indent .. tostring(k) .. ":")
            inspect_table(v, indent .. "  ")
        else
            print(indent .. tostring(k) .. ": " .. tostring(v))
        end
    end
end

-- Атласы джокеров
local atlas_list = {
  {key = 'prototype', path = 'goolatro_prototype.png'},
  {key = 'puro', path = 'goolatro_puro.png'},
  {key = 'colin', path = 'goolatro_colin.png'},
  {key = 'drk', path = 'goolatro_drk.png'},
  {key = 'Hologram', path = 'goolatro_Hologram.png', py = 95}
}

for _, atlas in ipairs(atlas_list) do
    SMODS.Atlas{
        key = atlas.key,
        path = atlas.path,
        px = 71,
        py = atlas.py or 96
    }
end

local old_remove_from_deck = Card.remove_from_deck
Card.remove_from_deck = function(self, ...)
    if self.ability and self.ability.set == 'Joker' then
        -- Проверка: карта больше не в колоде и это не загрузка сейва
        if G.state and G.GAME and G.GAME.round_resets ~= nil then
            print("[DEBUG] Joker remove_from_deck:", self.ability.name or self.ability.key)

            -- Вызов обработчика, если он есть
            if self.on_destroyed then
                self:on_destroyed(self)
            end
        end
    end
    return old_remove_from_deck(self, ...)
end

local files = NFS.getDirectoryItems(mod_path .. "items")
for _, file in ipairs(files) do
    if string.sub(file, -4) == ".lua" then
        local f, err = SMODS.load_file("items/" .. file)
        if err then error("Ошибка в " .. file .. ": " .. err) end
        f()
    end
end
