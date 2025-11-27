SMODS.Atlas{
    key = "goolatroblinds",
    path = "goolatro_blinds_2x.png",
    px = 32,
    py = 32,
    frames = 1,               -- ← ВАЖНО!
    atlas_table = 'ANIMATION_ATLAS'
}


SMODS.Blind {
    name = "boss_palevirus",
    key = "boss_palevirus",
    atlas = "goolatro_goolatroblinds",
    pos = { x = 0, y = 0 },

    dollars = 10,
    mult = 2,
    boss = { min = 0 },
    boss_colour = HEX('ffffff'),

    loc_txt = {
        name = "PALE VIRUS",
        text = {
            "ALL SUIT-BASED HANDS",
            "ARE DEBUFFED"
        }
    },

    debuff_hand = function(self)
        if G.GAME.blind.disabled then return end

        local hand = G.GAME.current_round.current_hand
        if not hand or not hand.handname then return end

        local name = hand.handname

        if name == "Flush"
        or name == "Straight"
        or name == "Straight Flush"
        or name == "Royal Flush"
        then
            -- HUD эффект вместо card_eval_status_text(nil,...)
            if G.HUD_blind_debuff then
                G.HUD_blind_debuff:set_text("PALED!")
                G.HUD_blind_debuff:juice_up()
            end

            SMODS.juice_up_blind()
            return true    -- блокируем скоринг
        end
    end,

    defeat = function(self)
        local card = create_card(
            "Joker",
            G.jokers,
            nil, nil, nil, nil,
            "j_goolatro_colin"
        )
        card.ignore_pools = true
        G.jokers:emplace(card)

        card_eval_status_text(
            card,
            'extra',
            nil, nil, nil,
            {
                message = "JOINED!",
                colour = G.C.CHIPS
            }
        )
    end



}
