SMODS.Seal {
    name = "goolatro_hologram",
    key = "goolatro_hologram",
    badge_colour = HEX("00BFFF"),
    atlas = "Hologram",
    pos = {x=0, y=0},
    unlocked = true,
    discovered = true,

    loc_txt = {
        label = 'Hologram',
        name = 'Hologram',
        text = {
            "{C:inactive}Temporal projection.",
            "{C:attention}30%{} chance to disappear.",
            "Not counted on retrigger."
        }
    },

    loc_vars = function(self, info_queue)
        return {vars = {}}
    end,

    calculate = function(self, card, context)
        if context.cardarea == G.play and context.main_scoring then
            if not context.repetition then
                if pseudorandom('hologram_fade') < 0.3 then
                   
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        func = function()
                            card:start_dissolve()
                            return true
                        end
                    }))
                else
                    
                end
            else
                
            end
        end
    end
}


SMODS.Atlas{
    key = 'Latex',
    path = 'goolatro_latex.png',
    px = 71,
    py = 95
}

SMODS.Sound{
    key = "goolatro_latex_infect",
    path = "latex_infection.ogg"
}

SMODS.Seal{
    name = "goolatro_latex",
    key = 'goolatro_latex',
    badge_colour = HEX('6a6a6a'),
    atlas = 'Latex',
    pos = {x = 0, y = 0},
    unlocked = true,
    discovered = true,
    
    loc_txt = {
        label = 'Latex Seal',
        name = 'Latex Seal',
        text = {
            "{C:inactive}AVAILABLE NEXT UPDATE!.",
            "{C:attention}Wild Card{}, gives {C:chips}1 Chip{}",
            "{C:green}1 in 6{} chance to spread"
        }
    },
    
    loc_vars = function(self, info_queue)
        return {vars = {}}
    end,
}


local original_get_chip_bonus = Card.get_chip_bonus
function Card:get_chip_bonus()
    -- Если карта имеет Latex печать - возвращаем 0
    if self.seal == 'goolatro_latex' then
        return 1
    end
    
   
    return original_get_chip_bonus(self)
end


local latex_spread_hook_installed = false

if not latex_spread_hook_installed then
    latex_spread_hook_installed = true
    
    local original_evaluate = G.FUNCS.evaluate_play
    G.FUNCS.evaluate_play = function()
        if original_evaluate then
            original_evaluate()
        end
        
       
        if G.hand and G.hand.cards then
            for i, card in ipairs(G.hand.cards) do
                if card.seal == 'goolatro_latex' then
                    -- Шанс 1 к 6
                    if pseudorandom('latex_spread') < 1/6 then
                        local neighbors = {}
                        
                        if i > 1 and G.hand.cards[i-1].seal ~= 'goolatro_latex' then
                            table.insert(neighbors, G.hand.cards[i-1])
                        end
                        
                        if i < #G.hand.cards and G.hand.cards[i+1].seal ~= 'goolatro_latex' then
                            table.insert(neighbors, G.hand.cards[i+1])
                        end
                        
                        if #neighbors > 0 then
                            local target = pseudorandom_element(neighbors, pseudoseed('latex_target'))
                            
                            G.E_MANAGER:add_event(Event({
                                trigger = 'after',
                                delay = 0.5,
                                func = function()
                                    target:set_seal('goolatro_latex', true)
                                    target:juice_up(0.8, 0.8)
                                    play_sound('goolatro_latex_infect')
                                    
                                    card_eval_status_text(target, 'extra', nil, nil, nil, {
                                        message = "Infected!",
                                        colour = G.C.DARK_EDITION,
                                        delay = 0.3
                                    })
                                    
                                    return true
                                end
                            }))
                        end
                    end
                end
            end
        end
    end
end