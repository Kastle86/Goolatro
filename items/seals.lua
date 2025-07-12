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
