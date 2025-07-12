
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



SMODS.Joker{
    key = 'puro',
    loc_txt = {
        name = "Puro",
        text = {
            "{X:mult,C:white}+3{} Mult per {C:hearts}Heart{} in scoring hand",
            '{C:inactive}"Он просто желает помочь"'
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


SMODS.Joker{
    key = 'colin',
    loc_txt = {
        name = "Colin",
        text = {
            "{X:mult,C:white}X#1#{} Mult increases by {C:green}+1{}",
            "each time you beat a blind",
            '{C:inactive}"Вспомни кто ты есть"'
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
            '{C:inactive}"Результаты важнее всего"'
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
        name = "Сява",
        text = {
            "После каждой разыгранной руки:",
            "{C:green}70%{} шанс: +10 {C:mult}Mult{} и +50 {C:chips}фишек{}",
            "{C:red}30%{} шанс: множитель *0.01",
            "{C:inactive}О да, {C:attention}джекпот!"
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

-- БОНДРЮД — РЕИНКАРНИРУЮЩИЙ ДЖОКЕР
SMODS.Atlas{
    key = 'bondrewd',
    path = 'goolatro_bondrewd.png',
    px = 71,
    py = 96
}
SMODS.Joker{
    key = 'bondrewd',
    loc_txt = {
        name = "Bondrewd",
        text = {
            "Gain {X:mult,C:white}+0.25{} Mult per destruction",
            "Gain {C:chips}+5{} Chips per discard",
            "{C:attention}If sold{}, reincarnates into another Joker",
            '"Glory to progress, children."',
            "",
            "{C:inactive}xMult: {X:mult,C:white}x#1#{}, Chips: {C:chips}+#2#{}"
        }
    },
    rarity = 3,
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    pools = { Default = true },
    atlas = 'bondrewd',
    pos = {x = 0, y = 0},
    config = {
        extra = {
            current_xmult = 1.5,
            chip_bonus = 0
        }
    },

    loc_vars = function(self, info_queue, card)
        local x = card.ability.extra.current_xmult or 1.5
        local c = card.ability.extra.chip_bonus or 0
        return { vars = { string.format("%.2f", x), c } }
    end,

    calculate = function(self, card, context)
        local extra = card.ability.extra
        extra.current_xmult = extra.current_xmult or 1.5
        extra.chip_bonus = extra.chip_bonus or 0

        -- 📈 Уничтожение карт
        if context.remove_playing_cards and context.removed then
            for _, c in ipairs(context.removed) do
                extra.current_xmult = extra.current_xmult + 0.25
                return {
                    message = "Sacrificed!",
                    colour = G.C.MULT
                }
            end
        end

        -- 💰 Сброс карты
        if context.full_hand and context.discard then
            for _, c in ipairs(context.full_hand) do
                extra.chip_bonus = extra.chip_bonus + 5
                return {
                    message = "Scrapped!",
                    colour = G.C.CHIPS
                }
            end
        end

        -- 💀 Реинкарнация при продаже
        if context.selling_self then
            print("[BONDREWD] Reincarnation triggered")

            local candidates = {}
            for _, j in ipairs(G.jokers.cards) do
                if j ~= card and not j.deleting and not j.getting_sliced then
                    table.insert(candidates, j)
                end
            end

            if #candidates > 0 then
                local victim = pseudorandom_element(candidates)
                local index = nil
                for i, j in ipairs(G.jokers.cards) do
                    if j == victim then index = i break end
                end

                if index then
                    -- Сообщение и растворение жертвы
                    
                    victim.getting_sliced = true
                    victim:start_dissolve()

                    -- Через 0.3 секунды — удалить и вставить нового Бондрюда
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.3,
                        func = function()
                            G.jokers:remove_card(victim)

                            local card = create_card('j_bondrewd', G.jokers, nil, nil, nil, nil, 'j_bondrewd', 'goolatro')
                            card:add_to_deck()
                            G.jokers:emplace(card)


                            if clone then
                                clone.ability.extra = {
                                    current_xmult = math.floor(extra.current_xmult * 0.5 * 100) / 100,
                                    chip_bonus = math.floor(extra.chip_bonus * 0.5)
                                }
                                table.insert(G.jokers.cards, index, clone)
                                play_sound('tarot1', 1.1)
                                clone:juice_up()
                                

                            else
                                print("[BONDREWD] Failed to create clone")
                            end
                            return true
                        end
                    }))
                end
            end
        end

        -- 🎁 Подсчет бонусов
        if context.after and context.joker_main then
            return {
                Xmult_mod = extra.current_xmult,
                chip_mod = extra.chip_bonus,
                message = "x" .. string.format("%.2f", extra.current_xmult) ..
                          ", +" .. tostring(extra.chip_bonus) .. " chips",
                colour = G.C.MULT
            }
        end
    end
}
