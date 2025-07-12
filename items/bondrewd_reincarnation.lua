-- Bondrewd External Reincarnation Handler
print("[BONDREWD REINC] File loaded")

return function()
    local old_sell_card = Card.sell_card
    function Card:sell_card(...)
        local name = self.ability and self.ability.name or "no name"
        print("[BONDREWD REINC] sell_card called for:", name)

        if name == 'j_goolatro_bondrewd' then
            print("[BONDREWD REINC] Detected Bondrewd sale")

            local jokers = G.jokers and G.jokers.cards or {}
            print("[BONDREWD REINC] Jokers in play:")
            for i, j in ipairs(jokers) do
                print(string.format(" [%d] key: %s | name: %s", i, j.key or "?", j.ability and j.ability.name or "?"))
            end

            -- Пул из всех джокеров, кроме самого
            local pool = {}
            for _, j in ipairs(jokers) do
                if j ~= self then
                    table.insert(pool, j)
                end
            end

            if #pool == 0 then
                print("[BONDREWD REINC] No jokers to replace. Reincarnation aborted.")
            else
                local target = pseudorandom_element(pool)
                if target then
                    print(string.format("[BONDREWD REINC] Reincarnating into slot of %s", target.ability and target.ability.name or "unknown"))

                    local new_xmult = math.floor((self.ability.extra.current_xmult or 1.5) * 0.5 * 100) / 100
                    local new_chips  = math.floor((self.ability.extra.chip_bonus or 0) * 0.5)

                    target.key = 'bondrewd'
                    target.name = 'Bondrewd'
                    target.ability.name = 'j_goolatro_bondrewd'
                    target.ability.set = 'Joker'
                    target.config = deepcopy(self.config)
                    target.config.extra.current_xmult = new_xmult
                    target.config.extra.chip_bonus = new_chips

                    -- Применяем функции снова
                    local def = SMODS.Jokers['bondrewd']
                    for k, v in pairs(def) do
                        if type(v) == 'function' then
                            target[k] = v
                        end
                    end

                    G.E_MANAGER:add_event(Event({
                        trigger = 'after', delay = 0.2,
                        func = function()
                            attention_text({ text = "Bondrewd: Reincarnated", colour = G.C.MONEY, scale = 1, hold = true })
                            return true
                        end
                    }))

                    print(string.format("[BONDREWD REINC] SUCCESS! Replaced joker with Bondrewd. New xMult: %.2f, Chips: +%d", new_xmult, new_chips))
                else
                    print("[BONDREWD REINC] Failed to select target joker")
                end
            end
        end

        return old_sell_card(self, ...)
    end
end
