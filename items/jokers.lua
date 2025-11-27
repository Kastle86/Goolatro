-- Этот файл регистрирует всех джокеров из Goolatro с рабочей логикой
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Puro
SMODS.Joker{
    key = 'puro',
    loc_txt = {
        name = "Puro",
        text = {
            "{X:mult,C:white}+3{} Mult per {C:hearts}Heart{} in scoring hand",
            '{C:inactive}"He just wants to help"'
        }
    },
    atlas = 'puro',
    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    pools = { ["Default"] = true },
    pos = { x = 0, y = 0 },
    config = {},
    calculate = function(self, card, context)
        if context.joker_main then
            local count = 0
            for _, c in ipairs(context.scoring_hand or {}) do
                if c:is_suit('Hearts') then count = count + 1 end
            end
            local total = count * 3
            if total > 0 then
                return {
                    message = "+" .. total .. " (Hearts)",
                    Xmult_mod = total
                }
            end
        end
    end
}

-- Colin
SMODS.Joker{
    key = 'colin',
    loc_txt = {
        name = "Colin",
        text = {
            "{X:mult,C:white}X#1#{} Mult increases by {C:green}+1{}",
            "each time you beat a blind",
            '{C:inactive}"Remember who you are"'
        }
    },
    atlas = 'colin',
    rarity = 4,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    pools = { ["Default"] = true },
    pos = { x = 0, y = 0 },
    config = { extra = { Xmult = 1 } },
    loc_vars = function(self, info_queue, center)
        return { vars = { center.ability.extra.Xmult } }
    end,
    calculate = function(self, card, context)
        card.ability.extra = card.ability.extra or {}
        card.ability.extra.Xmult = card.ability.extra.Xmult or 1

        if context.setting_blind and not context.lost_round then
            card.ability.extra.Xmult = card.ability.extra.Xmult + 1
            return { message = "+1 to memory" }
        end
        if context.lose_round then
            card.ability.extra.Xmult = 1
            return { message = "He forgot..." }
        end
        if context.joker_main then
            return {
                message = "X" .. card.ability.extra.Xmult,
                Xmult_mod = card.ability.extra.Xmult
            }
        end
    end
}

-- Dr. K
SMODS.Joker{
    key = 'drk',
    loc_txt = {
        name = "Dr. K",
        text = {
            "{X:mult,C:white}X#1#{} and {C:blue}+#2# Chips{} if",
            "scoring hand has only even cards",
            "{C:red}-50 Chips{} if not",
            '{C:inactive}"Results first"'
        }
    },
    atlas = 'drk',
    rarity = 3,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    pools = { ["Default"] = true },
    pos = { x = 0, y = 0 },
    config = { extra = { Xmult = 2.0, Chips = 250 } },
    loc_vars = function(self, info_queue, center)
        return { vars = { center.ability.extra.Xmult, center.ability.extra.Chips } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local even_only = true
            for _, c in ipairs(context.scoring_hand or {}) do
                if c:get_id() % 2 ~= 0 then
                    even_only = false
                    break
                end
            end
            if even_only then
                return {
                    message = "Precise calculation.",
                    Xmult_mod = card.ability.extra.Xmult,
                    chip_mod = card.ability.extra.Chips
                }
            else
                return {
                    message = "Failure penalty.",
                    chip_mod = -50
                }
            end
        end
    end
}



-- Регистрируем атлас
SMODS.Atlas{
    key = 'prototype',
    path = 'goolatro_prototype.png',
    px = 71,
    py = 96
}
-- Регистрируем звук
SMODS.Sound{
    key = "goolatro_prototype_clone",
    path = "prototype_clone.ogg"
}

SMODS.Joker {
    key = "prototype",
    loc_txt = {
        name = "Prototype",
        text = {
            "At the start of round",
            "Clones first card in {C:attention}scoring hand{}",
            "into a {C:keyword}Hologram{} ",
            "Retriggers {C:keyword}Hologram{} cards"
        }
    },
    rarity = 3,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    atlas = "prototype",
    pos = {x = 0, y = 0},
    pools = {Default = true},

    calculate = function(self, card, context)
        -- Подсветка карты на первой руке
        if context.first_hand_drawn and not context.blueprint then
            local eval = function()
                return G.GAME.current_round.hands_played == 0 and not G.RESET_JIGGLES
            end
            juice_card_until(card, eval, true)
        end

        -- Клонирование карты
        if context.before and context.main_eval and G.GAME.current_round.hands_played == 0 and context.scoring_hand and #context.scoring_hand > 0 then
            local base = context.scoring_hand[1]
            if base:get_seal() == 'goolatro_hologram' then return end -- пропуск голограмм

            local clone = copy_card(base, nil, nil, G.playing_card or 1)
            clone.ability.hologram_uses = 0
            clone:set_seal('goolatro_hologram')
            clone:add_to_deck()
            G.hand:emplace(clone)
            clone.states.visible = nil

            G.E_MANAGER:add_event(Event({
                func = function()
                    clone:start_materialize()
                    return true
                end
            }))

            G.E_MANAGER:add_event(Event({
                func = function()
                    SMODS.calculate_context({
                        playing_card_added = true,
                        cards = { clone }
                    })
                    play_sound('goolatro_prototype_clone')
                    return {
                        message = 'Projected!',
                        colour = G.C.MULT
                    }
                end
            }))
        end

        -- Ретриггер карт с голограммой
        if context.cardarea == G.play and context.repetition and context.other_card:get_seal() == 'goolatro_hologram' then
            return {
                repetitions = 1,
                card = card,
                message = 'Echoed!',
                colour = G.C.MONEY
            }
        end
    end
}



SMODS.Atlas{
    key = 'syava',
    path = 'goolatro_syava.png',
    px = 71,
    py = 96
}

SMODS.Sound{ key = "goolatro_syava_jackpot", path = "syava_jackpot.ogg" }
SMODS.Sound{ key = "goolatro_syava_fail", path = "syava_fail.ogg" }

SMODS.Joker{
    key = 'syava',
    loc_txt = {
        name = "Syava",
        text = {
            "After playing hand:",
            "{C:green}70%{} chance: +10 {C:mult}Mult{} и +50 {C:chips}chips{}",
            "{C:red}30%{} Chance for x0.01Mult",
            "{C:inactive}JACKPOT, {C:attention}JACKPOT!"
        }
    },
    rarity = 2,
    cost = 4,
    pools = { Default = true },
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    atlas = 'syava',
    pos = {x = 0, y = 0},

    calculate = function(self, card, context)
        if context.scoring_hand and context.joker_main then
            local roll = pseudorandom('syava:roll')
            print("[Сява] Результат броска: " .. tostring(roll))

            if roll < 0.7 then
                print("[Сява] Джекпот! +10 mult и +50 фишек")
                return {
                    mult_mod = 10,
                    chips = 50,
                    message = "ДЖЕКПОТ ДЖЕКПОТ",
                    sound = "goolatro_syava_jackpot",
                    status = "extra"
                }
            else
                print("[Сява] ПРОВАЛ! Mult *0.01")
                return {
                    Xmult = 0.01,
                    message = "ХУЙ ТЕ В РОТ",
                    sound = "goolatro_syava_fail",
                    status = "bad"
                }
            end
        end
    end
}



-- Luck the wolf
SMODS.Atlas{
    key = 'luck',
    path = 'goolatro_luck.png',
    px = 71,
    py = 96
}

SMODS.Joker{
    key = 'luck',
    loc_txt = {
        name = "Luck the Wolf",
        text = {
            "If hand contains {C:attention}3 or more{}",
            "cards with {C:green}Lucky{} modifier:",
            "{X:mult,C:white}X3{} Mult",
            '{C:inactive}"Luck is on my side"'
        }
    },
    atlas = 'luck',
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    pools = { ["Default"] = true },
    pos = { x = 0, y = 0 },
    config = {},
    
    calculate = function(self, card, context)
        if context.joker_main then
            local lucky_count = 0
            
            for _, c in ipairs(context.scoring_hand or {}) do
                if c.ability.effect and c.ability.effect == 'Lucky Card' then
                    lucky_count = lucky_count + 1
                end
            end
            
            if lucky_count >= 3 then
                return {
                    message = "Lucky Strike!",
                    Xmult_mod = 3,
                    colour = G.C.GREEN
                }
            end
        end
    end
}

-- Shizi 
SMODS.Atlas{
    key = 'shizi',
    path = 'goolatro_shizi.png',
    px = 71,
    py = 96
}


function shiziExists()
    if not G.jokers or not G.jokers.cards then return false end
    for i = 1, #G.jokers.cards do
        if G.jokers.cards[i].ability.name == 'j_goolatro_shizi' then
            return G.jokers.cards[i]
        end
    end
    return false
end


function stopAllMusic()
    if G.SOUND_MANAGER and G.SOUND_MANAGER.channel then
        G.SOUND_MANAGER.channel:stop()
    end
end


SMODS.Sound({
    key = "music_goolatro_main1", 
    path = "music_goolatro_changed_main1.ogg",
    pitch = 1,
    volume = 0.6,
    select_music_track = function()
        if shiziExists() and G.GAME and not (G.GAME.blind and G.GAME.blind.boss) and G.STATE ~= G.STATES.SHOP then
            if not G.goolatro_music_selected then
                G.goolatro_music_selected = math.random(1, 5)
            end
            return G.goolatro_music_selected == 1
        end
        return false
    end,
})

SMODS.Sound({
    key = "music_goolatro_main2", 
    path = "music_goolatro_changed_main2.ogg",
    pitch = 1,
    volume = 0.6,
    select_music_track = function()
        if shiziExists() and G.GAME and not (G.GAME.blind and G.GAME.blind.boss) and G.STATE ~= G.STATES.SHOP then
            if not G.goolatro_music_selected then
                G.goolatro_music_selected = math.random(1, 5)
            end
            return G.goolatro_music_selected == 2
        end
        return false
    end,
})

SMODS.Sound({
    key = "music_goolatro_main3", 
    path = "music_goolatro_changed_main3.ogg",
    pitch = 1,
    volume = 0.6,
    select_music_track = function()
        if shiziExists() and G.GAME and not (G.GAME.blind and G.GAME.blind.boss) and G.STATE ~= G.STATES.SHOP then
            if not G.goolatro_music_selected then
                G.goolatro_music_selected = math.random(1, 5)
            end
            return G.goolatro_music_selected == 3
        end
        return false
    end,
})

SMODS.Sound({
    key = "music_goolatro_main4", 
    path = "music_goolatro_changed_main4.ogg",
    pitch = 1,
    volume = 0.6,
    select_music_track = function()
        if shiziExists() and G.GAME and not (G.GAME.blind and G.GAME.blind.boss) and G.STATE ~= G.STATES.SHOP then
            if not G.goolatro_music_selected then
                G.goolatro_music_selected = math.random(1, 5)
            end
            return G.goolatro_music_selected == 4
        end
        return false
    end,
})

SMODS.Sound({
    key = "music_goolatro_main5", 
    path = "music_goolatro_changed_main5.ogg",
    pitch = 1,
    volume = 0.6,
    select_music_track = function()
        if shiziExists() and G.GAME and not (G.GAME.blind and G.GAME.blind.boss) and G.STATE ~= G.STATES.SHOP then
            if not G.goolatro_music_selected then
                G.goolatro_music_selected = math.random(1, 5)
            end
            return G.goolatro_music_selected == 5
        end
        return false
    end,
})

-- Boss tracks
SMODS.Sound({
    key = "music_goolatro_boss1", 
    path = "music_goolatro_changed_boss1.ogg",
    pitch = 1,
    volume = 0.6,
    select_music_track = function()
        if shiziExists() and G.GAME and G.GAME.blind and G.GAME.blind.boss then
            if not G.goolatro_boss_selected then
                G.goolatro_boss_selected = math.random(1, 3)
            end
            return G.goolatro_boss_selected == 1
        end
        return false
    end,
})

SMODS.Sound({
    key = "music_goolatro_boss2", 
    path = "music_goolatro_changed_boss2.ogg",
    pitch = 1,
    volume = 0.6,
    select_music_track = function()
        if shiziExists() and G.GAME and G.GAME.blind and G.GAME.blind.boss then
            if not G.goolatro_boss_selected then
                G.goolatro_boss_selected = math.random(1, 3)
            end
            return G.goolatro_boss_selected == 2
        end
        return false
    end,
})

SMODS.Sound({
    key = "music_goolatro_boss3", 
    path = "music_goolatro_changed_boss3.ogg",
    pitch = 1,
    volume = 0.6,
    select_music_track = function()
        if shiziExists() and G.GAME and G.GAME.blind and G.GAME.blind.boss then
            if not G.goolatro_boss_selected then
                G.goolatro_boss_selected = math.random(1, 3)
            end
            return G.goolatro_boss_selected == 3
        end
        return false
    end,
})

-- Shop track
SMODS.Sound({
    key = "music_goolatro_shop", 
    path = "music_goolatro_changed_shop.ogg",
    pitch = 1,
    volume = 0.6,
    select_music_track = function()
        return shiziExists() and G.STATE == G.STATES.SHOP
    end,
})

SMODS.Joker{
    key = 'shizi',
    loc_txt = {
        name = "Shizi",
        text = {
            "Replaces {C:attention}all game music{}",
            "with OST from {C:dark_edition}Changed{}",
            '{C:inactive}"♪ Transfurred ambience ♪"'
        }
    },
    atlas = 'shizi',
    rarity = 1,
    cost = 3,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    pools = { ["Default"] = true },
    pos = { x = 0, y = 0 },
    config = {},
    
    add_to_deck = function(self, card, from_debuff)
        card_eval_status_text(card, 'extra', nil, nil, nil, {
            message = "♪ Changed OST ♪",
            colour = G.C.PURPLE
        })
    end,
    
    calculate = function(self, card, context)
        
        if context.setting_blind and not context.blueprint then
            if G.GAME.blind and G.GAME.blind.boss then
                G.goolatro_boss_selected = math.random(1, 3)
            else
                G.goolatro_music_selected = math.random(1, 5)
            end
            G.goolatro_boss_selected = nil
        end
        
        
        if context.end_of_round and not context.blueprint then
            G.goolatro_music_selected = nil
            G.goolatro_boss_selected = nil
        end
    end,
}


-- Savepoint 
SMODS.Atlas{
    key = 'savepoint',
    path = 'goolatro_savepoint.png',
    px = 71,
    py = 96
}

SMODS.Joker{
    key = 'savepoint',
    loc_txt = {
        name = "Savepoint",
        text = {
            "If last hand doesn't reach",
            "required {C:chips}Chips{},",
            "automatically {C:attention}adds missing amount{}",
            "{C:red}Destroys{} after use",
            '{C:inactive}"Point of no return"'
        }
    },
    atlas = 'savepoint',
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    pools = { ["Default"] = true },
    pos = { x = 0, y = 0 },
    config = { extra = { does_not_occupy_slot = true } },
    
    add_to_deck = function(self, card, from_debuff)
        if G.jokers then
            G.jokers.config.card_limit = G.jokers.config.card_limit + 1
        end
    end,
    
    remove_from_deck = function(self, card, from_debuff)
        if G.jokers then
            G.jokers.config.card_limit = G.jokers.config.card_limit - 1
        end
    end,
    
    calculate = function(self, card, context)
       
        if context.joker_main and not context.blueprint then
            
            if G.GAME.current_round.hands_left == 0 then
                
                local chips_needed = G.GAME.blind.chips - hand_chips
                
                if chips_needed > 0 then
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            card:start_dissolve()
                            return true
                        end
                    }))
                    
                    return {
                        message = "SAVED!",
                        chip_mod = chips_needed,
                        colour = G.C.CHIPS
                    }
                end
            end
        end
    end
}

-- DragonSnow
SMODS.Atlas{
    key = 'dragonsnow',
    path = 'goolatro_dragonsnow.png',
    px = 71,
    py = 96
}

SMODS.Joker{
    key = 'dragonsnow',
    loc_txt = {
        name = "DragonSnow",
        text = {
            "When playing hand,",
            "{C:attention}evolves{} random card",
            "to next rank or better suit",
            "{C:inactive}(Ignores Aces and Latex)"
        }
    },
    atlas = 'dragonsnow',
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    pools = { ["Default"] = true },
    pos = { x = 0, y = 0 },
    config = {},
}


function dragonsnowExists()
    if not G.jokers or not G.jokers.cards then return false end
    for i = 1, #G.jokers.cards do
        if G.jokers.cards[i].ability.name == 'j_goolatro_dragonsnow' then
            return true
        end
    end
    return false
end

-- Хук на кнопку Play Hand
local original_play_cards = G.FUNCS.play_cards_from_highlighted
G.FUNCS.play_cards_from_highlighted = function(e)
    if dragonsnowExists() and G.hand and G.hand.highlighted and #G.hand.highlighted > 0 then
        -- Фильтруем карты: исключаем Latex
        local valid_targets = {}
        for _, c in ipairs(G.hand.highlighted) do
            if c.seal ~= 'goolatro_latex' then  -- ← ИГНОРИРУЕМ LATEX
                table.insert(valid_targets, c)
            end
        end
        
        if #valid_targets > 0 then
            local target = pseudorandom_element(valid_targets, pseudoseed('dragonsnow'))
            local old_id = target.base.id
            local old_suit = target.base.suit
            
            -- Префикс масти
            local suit_map = {Spades = 'S', Hearts = 'H', Diamonds = 'D', Clubs = 'C'}
            local old_suit_prefix = suit_map[old_suit]
            
            local new_id, new_suit_prefix
            
            if old_id == 14 then
                -- Туз - меняем масть
                new_id = 14
                local suit_counts = {S = 0, H = 0, D = 0, C = 0}
                for _, c in ipairs(G.hand.highlighted) do
                    local s = suit_map[c.base.suit]
                    suit_counts[s] = (suit_counts[s] or 0) + 1
                end
                
                local best_suit = old_suit_prefix
                local best_count = 0
                for suit, count in pairs(suit_counts) do
                    if suit ~= old_suit_prefix and count > best_count then
                        best_suit = suit
                        best_count = count
                    end
                end
                new_suit_prefix = best_count > 0 and best_suit or old_suit_prefix
            else
                -- Не туз
                if pseudorandom('dragonsnow_choice') < 0.5 then
                    new_id = old_id + 1
                    if new_id > 14 then new_id = 2 end
                    new_suit_prefix = old_suit_prefix
                else
                    new_id = old_id
                    local suit_counts = {S = 0, H = 0, D = 0, C = 0}
                    for _, c in ipairs(G.hand.highlighted) do
                        local s = suit_map[c.base.suit]
                        suit_counts[s] = (suit_counts[s] or 0) + 1
                    end
                    
                    local best_suit = old_suit_prefix
                    local best_count = 0
                    for suit, count in pairs(suit_counts) do
                        if suit ~= old_suit_prefix and count > best_count then
                            best_suit = suit
                            best_count = count
                        end
                    end
                    new_suit_prefix = best_count > 0 and best_suit or old_suit_prefix
                end
            end
            
            
            local rank_suffix = new_id < 10 and tostring(new_id) or
                               new_id == 10 and 'T' or
                               new_id == 11 and 'J' or
                               new_id == 12 and 'Q' or
                               new_id == 13 and 'K' or
                               new_id == 14 and 'A'
            
            local new_card_key = new_suit_prefix .. '_' .. rank_suffix
            
            
            G.E_MANAGER:add_event(Event({
                trigger = 'before',
                delay = 0.1,
                func = function()
                    target:flip()
                    play_sound('card1')
                    return true
                end
            }))
            
            G.E_MANAGER:add_event(Event({
                func = function()
                    target:set_base(G.P_CARDS[new_card_key])
                    play_sound('tarot2')
                    return true
                end
            }))
            
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.1,
                func = function()
                    target:flip()
                    target:juice_up(0.5, 0.5)
                    return true
                end
            }))
        end
    end
    
    return original_play_cards(e)
end

-- Nella
SMODS.Atlas{
    key = 'nella',
    path = 'goolatro_nella.png',
    px = 71,
    py = 96
}

SMODS.Joker{
    key = 'nella',
    loc_txt = {
        name = "Nella",
        text = {
            "Gains {X:mult,C:white}X0.2{} Mult whenever",
            "any card gains a {C:attention}seal{}, {C:attention}edition{},",
            "or {C:attention}enhancement{}",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)"
        }
    },
    atlas = 'nella',
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    pools = { ["Default"] = true },
    pos = { x = 0, y = 0 },
    config = { extra = { Xmult = 1.0, gain = 0.2 } },
    
    loc_vars = function(self, info_queue, center)
        return { vars = { center.ability.extra.Xmult } }
    end,
    
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                message = localize({ type = "variable", key = "a_xmult", vars = { card.ability.extra.Xmult } }),
                Xmult_mod = card.ability.extra.Xmult
            }
        end
    end
}


local function nellaGainMult()
    if not G.jokers then return end
    for i = 1, #G.jokers.cards do
        if G.jokers.cards[i].ability.name == 'j_goolatro_nella' then
            local nella = G.jokers.cards[i]
            nella.ability.extra.Xmult = nella.ability.extra.Xmult + nella.ability.extra.gain
            
            card_eval_status_text(nella, 'extra', nil, nil, nil, {
                message = "+X" .. nella.ability.extra.gain,
                colour = G.C.MULT
            })
            return true
        end
    end
    return false
end


local original_set_seal = Card.set_seal
function Card:set_seal(seal, silent, final)
    local result = original_set_seal(self, seal, silent, final)
    
    
    if self.playing_card and seal and not silent then
        nellaGainMult()
    end
    
    return result
end

-- Хук на set_ability 
local original_set_ability = Card.set_ability
function Card:set_ability(center, initial, delay_sprites)
    local had_ability = self.ability and self.ability.name
    local result = original_set_ability(self, center, initial, delay_sprites)
    
    
    if self.playing_card and not initial and center and center.name and center.name ~= 'Default Base' and had_ability ~= center.name then
        nellaGainMult()
    end
    
    return result
end

-- Хук на set_edition 
local original_set_edition = Card.set_edition
function Card:set_edition(edition, immediate, silent)
    local result = original_set_edition(self, edition, immediate, silent)
    
    
    if self.playing_card and edition and not silent then
        nellaGainMult()
    end
    
    return result
end

-- HELL NAW 
SMODS.Atlas{
    key = 'hellnaw',
    path = 'goolatro_hellnaw.png',
    px = 71,
    py = 96
}

SMODS.Sound{
    key = "goolatro_hellnaw",
    path = "HELLNAW.ogg"
}

SMODS.Joker{
    key = 'hellnaw',
    loc_txt = {
        name = "HELL NAW",
        text = {
            "{C:attention}Disables{} Boss Blind condition",
            "Becomes {C:inactive}inactive{} after use",
            "Reactivates when you {C:attention}sell{} a Joker",
            '{C:inactive}"Don\'t say she ain\'t eat a treat"'
        }
    },
    atlas = 'hellnaw',
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    pools = { ["Default"] = true },
    pos = { x = 0, y = 0 },
    config = { extra = { active = true } },
    
    calculate = function(self, card, context)
        if context.setting_blind and not context.retrigger_joker then
            if card.ability.extra.active and G.GAME.blind and G.GAME.blind.boss then
                
                play_sound('goolatro_hellnaw')
                
                
                G.GAME.blind:disable()
                
                
                if G.GAME.blind.loc_debuff_lines then
                    G.GAME.blind.loc_debuff_lines = {"HELL NAW"}
                end
                
                
                SMODS.juice_up_blind()
                
                
                card.ability.extra.active = false
                card:juice_up(0.8, 0.8)
                
                return {
                    message = "HELL NAW!",
                    colour = G.C.RED
                }
            end
        end
    end,
    
    add_to_deck = function(self, card, from_debuff)
        card.ability.extra.active = true
    end
}


local original_sell_card = Card.sell_card
function Card:sell_card()
    local is_joker = self.ability and self.ability.set == 'Joker'
    local result = original_sell_card(self)
    
    if is_joker and G.jokers then
        for i = 1, #G.jokers.cards do
            if G.jokers.cards[i].ability.name == 'j_goolatro_hellnaw' then
                local hellnaw = G.jokers.cards[i]
                if not hellnaw.ability.extra.active then
                    hellnaw.ability.extra.active = true
                    hellnaw:juice_up(0.5, 0.5)
                    play_sound('generic1')
                    
                    card_eval_status_text(hellnaw, 'extra', nil, nil, nil, {
                        message = "Reactivated!",
                        colour = G.C.GREEN
                    })
                end
            end
        end
    end
    
    return result
end