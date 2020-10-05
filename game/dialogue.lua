
dialogue = {
    step = 0,
    a_t = 0,
    b_t = 0,
    a_text = -1,
    b_text = 0,
}

texts = {
    "Star seeking is really not what it used to be...",
    "Why is that?",
    "In my day, we didn't have those fancy starfinders at all.",
    "Really? How did you do it then?",
    "We just had to guess where the stars had fallen!",
    "That must have been difficult.",
    "It sure was.",
    "How do I use it now again?",
    "Right mouse button.",
    "Ah.",
}

function step_dialogue()
    if dialogue.step == 12 then return false end
    if dialogue.step == 9 then player.no_move_hack = false end

    if dialogue.step % 2 == 0 then
        flux.to(dialogue, 0.2, {
            a_t = 0,
        })
        :oncomplete(function()
            dialogue.a_text = dialogue.a_text + 2
        end)
        :after(dialogue, 0.5, {
            a_t = 1
        })
    else 
        flux.to(dialogue, 0.2, {
            b_t = 0,
        })
        :oncomplete(function()
            dialogue.b_text = dialogue.b_text + 2
        end)
        :after(dialogue, 0.5, {
            b_t = 1
        })
    end
    dialogue.step = dialogue.step + 1
    return player.no_move_hack
end

function draw_dialogue()
    love.graphics.setColor(0, 0, 0, dialogue.a_t)
    love.graphics.printf(texts[dialogue.a_text] or '', w/2 - 275, h/2 - 140, 200, 'right')
    love.graphics.setColor(0, 0, 0, dialogue.b_t)
    love.graphics.printf(texts[dialogue.b_text] or '', w/2 + 80, h/2 - 170, 200, 'left')
    love.graphics.setColor(1, 1, 1)
end