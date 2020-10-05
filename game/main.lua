flux = require "lib/flux"
lume = require "lib/lume"
lovebpm = require "lib/lovebpm"
require 'dots'
require 'dialogue'

t = 0

player = {
    x = 0,
    y = 0,
    w = 20,
    h = 60,
    move_x = 0,
    vel_x = 0,
    row_frame = 1,
    man_frame = 1,
    shadow_x = 0,
    shadow_x_normalized = 0,
    light_r = 0,
    light_t = 0,
    light_fix_xo = 60,
    light_fix_yo = -42,
    star_mode_t = 0,
    light_on = false,
    star_mode = false,
    switch_mode = 0,
    switch_timer = 0,
    no_move_hack = true,
}

images = {
    love.graphics.newImage('res/layer0.png'),
    love.graphics.newImage('res/layer1.png'),
    love.graphics.newImage('res/layer2.png'),
    love.graphics.newImage('res/layer3.png'),
    love.graphics.newImage('res/smoke.png'),
}

row_anim = {
    love.graphics.newImage('res/row1.png'),
    love.graphics.newImage('res/row2.png'),
    love.graphics.newImage('res/row3.png'),
    love.graphics.newImage('res/row4.png'),
    love.graphics.newImage('res/row5.png'),
}

man_anim = {
    love.graphics.newImage('res/man1.png'),
    love.graphics.newImage('res/man3.png'),
    love.graphics.newImage('res/man5.png'),
}

switch = {
    love.graphics.newImage('res/switch_bg.png'),
    love.graphics.newImage('res/switch.png'),
}

bg = love.graphics.newImage('res/bg.jpg')
bg_night = love.graphics.newImage('res/night.png')
boat = love.graphics.newImage('res/boat.png')
star = love.graphics.newImage('res/star.png')

function love.load()
    w, h = love.graphics.getDimensions()
    love.mouse.setVisible(false)
    font = love.graphics.newFont('res/Sen-Regular.ttf', 14, 'normal')
    love.graphics.setFont(font)
    love.math.setRandomSeed(love.timer.getTime())

    images[1]:setWrap('repeat', 'clamp')
    images[2]:setWrap('repeat', 'clamp')
    images[3]:setWrap('repeat', 'clamp')
    images[4]:setWrap('repeat', 'clamp')
    
    jungle_canvas = love.graphics.newCanvas(w, h, {
        msaa = 4,
    })
    main_canvas = love.graphics.newCanvas(w, h, {
        msaa = 4,
    })
    star_canvas = love.graphics.newCanvas(w, h, {
        msaa = 4,
    })
    
    player.x = w / 2 + 40
    player.y = h / 2 - 40
    love.graphics.setBackgroundColor(1, 1, 1)
    
    water_shader = love.graphics.newShader('water.shd')
    invert_shader = love.graphics.newShader([[
        uniform float t;
        vec4 effect(vec4 color, Image texture, vec2 uv, vec2 sc) {
            vec4 tex = Texel(texture, uv);
            return vec4(mix(tex.rgb, 1.0 - tex.rgb, t), tex.a) * vec4(1, 1, 1, 1.0 - t * 0.8);
        }
    ]])
            
    love.audio.setEffect('world_reverb', {
        type = 'reverb',
        gain = 0.5,
        decaytime = 5,
    })

    click = love.audio.newSource('res/click.wav', 'static')
    waves = love.audio.newSource('res/waves.wav', 'stream')
    click:setVolume(0.2)
    click:setEffect('world_reverb')
    waves:setVolume(0.0)
    waves:setEffect('world_reverb')
    waves:setLooping(true)
    waves:play()

    music = lovebpm.newTrack()
        :load('res/track.wav')
        :setBPM(70)
        :setPitch(1)
        :setLooping(true)
        :setOffset(0)
        :setVolume(1.0)
        :on('beat', function(n) 
            if player.star_mode then return end

            if n % 4 == 0 then
                if not step_dialogue() then
                    spawn_dot()
                end

                if not player.no_move_hack then 
                    flux.to(player, 3, { move_x = player.move_x + 150 })
                    :ease('cubicinout')
                end
        
                flux.to(player, 1.5, { vel_x = 2 })
                    :ease('cubicinout')
                    :after(player, 1, { vel_x = 0 })
                    :ease('cubicinout')
            end
        end)

    music.source:setEffect('world_reverb')
    music:play()
end

function love.focus(f)
    if f then
        music:play()
    else
        music:pause()
    end
end

function toggle_flashlight(state)
    if state then
        flux.to(player, 0.4, { light_t = 1 })
            :onstart(function()
                player.light_on = true
            end)
            :ease('cubicout')
    else
        flux.to(player, 0.2, { light_t = 0 })
            :oncomplete(function()
                player.light_on = false
            end)
            :ease('cubicin')
    end
end

function love.mousepressed(x, y, btn) 
    if player.no_move_hack then return end

    if btn == 2 then
        if player.switch_timer > 0 then 
            return 
        end
        if player.switch_mode == 0 then
            toggle_flashlight(true)
            player.star_mode_t = 0
        elseif player.switch_mode == 1 then
            toggle_flashlight(false)
            calc_bounding_box()
            flux.to(player, 1, { 
                star_mode_t = 1 
            })
            :ease('cubicinout')
            :oncomplete(function()
                music:pause()
            end)
            player.star_mode = true
        else
            music:play()
            flux.to(player, 1, { 
                star_mode_t = 0,
            }):ease('cubicinout')
            player.star_mode = false
        end
        click:setPitch(0.92 + player.switch_mode * 0.08)
        click:play()
        player.switch_mode = (player.switch_mode + 1) % 3
        player.switch_timer = 1
    elseif btn == 1 then
        press_dot(x, y)
    end
end

function love.update(dt)
    local mx, my = love.mouse.getPosition()
    local r = 380
    local x_clamped = lume.clamp(mx, player.x - r, player.x + r)
    player.shadow_x = lume.smooth(player.shadow_x, x_clamped, 40 * dt)
    player.shadow_x_normalized = player.shadow_x / player.x - 1.0
    player.man_frame = lume.round((1 + player.shadow_x_normalized) * 2)
    player.light_r = lume.lerp(0, 250, player.light_t)
    player.switch_timer = player.switch_timer - dt
    
    local beat, subbeat = music:getBeat(4)
    player.row_frame = math.floor(lume.pingpong(subbeat * 2) * 4 + 1)
    music:setVolume(1.0 - player.star_mode_t)
    waves:setVolume(player.star_mode_t * 0.5)

    update_dots()

    flux.update(dt)
    t = t + dt

    water_shader:send('time', t);
    invert_shader:send('t', player.star_mode_t)
    music:update()
end

function draw_shadow_mask() 
    if not player.light_on then return end

    local shadow_abs = 1.0 - math.abs(player.shadow_x_normalized)
    local light_r = player.light_r + 20 * shadow_abs
    local x = player.x + player.light_fix_xo * player.shadow_x_normalized
    local y = player.y + player.light_fix_yo
    
    local angle = lume.angle(x, 
        y, player.shadow_x, 
        y + light_r * shadow_abs * 1.2 * lume.sign(-player.shadow_x_normalized))
    local xo = math.sin(angle) * light_r * shadow_abs
    local yo = math.cos(angle) * light_r

    local vertices = { 
        player.shadow_x + xo, y + yo, 
        player.shadow_x + xo, y - yo, 
        x, y
    }
    love.graphics.ellipse('fill', player.shadow_x, y, light_r * shadow_abs, light_r, light_r)
    love.graphics.polygon('fill', vertices)
end

function draw_whiteworld()
    love.graphics.clear()

    love.graphics.setColor(1, 1, 1, player.star_mode_t)
    love.graphics.draw(star_canvas, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)

    local rot = lume.lerp(-player.vel_x * 0.05, math.sin(t * 2) * 0.015, player.star_mode_t) + 0.05

    love.graphics.draw(man_anim[lume.clamp(player.man_frame, 1, 3)], w/2, h/2, rot, 1, 1, 10, 150)
    love.graphics.draw(boat, w/2, h/2, rot, 1, 1, 125, 115)   
    love.graphics.draw(row_anim[lume.round(lume.smooth(player.row_frame, 5, player.star_mode_t * 8))], w/2, h/2, rot, 1, 1, 200, 117)
end

function draw_jungle_background()
    love.graphics.clear()
    love.graphics.setColor(lume.color('#0B161D'))
    love.graphics.rectangle('fill', 0, 0, w, player.y)

    love.graphics.setColor(1, 1, 1)    
    local offset = 120
    local quad0 = love.graphics.newQuad(player.move_x * 0.50, offset, w, h/2, 2048, 500)
    local quad1 = love.graphics.newQuad(player.move_x * 0.75, offset, w, h/2, 2048, 500)
    local quad2 = love.graphics.newQuad(player.move_x * 1.00 + 500, offset, w, h/2, 2048, 500)
    local quad3 = love.graphics.newQuad(player.move_x * 0.25, offset, w, h/2, 2048, 500)
    
    local quad_smoke = love.graphics.newQuad(0, 0, w, h/2, 2048, 500)
    
    love.graphics.draw(images[4], quad3)
    love.graphics.draw(images[1], quad0)

    -- smoke
    local beat, subbeat = music:getBeat(4)
    love.graphics.setColor(1, 1, 1, math.sin(subbeat * math.pi) * 0.4)
    love.graphics.draw(images[5], quad_smoke)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(images[2], quad1)
    draw_dots()
    love.graphics.draw(images[3], quad2)

end

function love.draw()
    local mirror_edge = h + h / 8 - 2
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(bg, 0, 0)

    main_canvas:renderTo(draw_whiteworld)

    if player.star_mode then
        star_canvas:renderTo(function()
            love.graphics.clear()
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(bg_night, 0, 0)
            draw_star_sky()
        end)
    end
    
    if player.star_mode_t ~= 1 then
        jungle_canvas:renderTo(draw_jungle_background)
        love.graphics.stencil(draw_shadow_mask, 'replace')
        love.graphics.setStencilTest('greater', 0)
        love.graphics.setColor(1, 1, 1)
            love.graphics.setShader(water_shader)
            love.graphics.draw(jungle_canvas, 0, mirror_edge, 0, 1, -1.25)
            love.graphics.setShader()
            love.graphics.draw(jungle_canvas, 0, 0)
            draw_path()
        love.graphics.setStencilTest('equal', 0)
            draw_dialogue()
        love.graphics.setStencilTest()
    end

    -- draw mirror canvas
    love.graphics.setShader(water_shader)
    love.graphics.setScissor(0, h/2, w, h/2)
    love.graphics.draw(main_canvas, 0, mirror_edge, 0, 1, -1.25)

    -- boat ripple
    local beat, subbeat = music:getBeat(4)
    local fade = lume.lerp(math.sin(subbeat * 2), 0, player.star_mode_t)
    love.graphics.setColor(1, 1, 1, lume.lerp(math.cos(subbeat * 2) - 0.2, 0, player.star_mode_t))
    love.graphics.ellipse('line', w/2, h/2, 100 * fade, 8 * fade, 40)
    -- rowing ripples
    local offsets = { 0, 40, 70, 110 }
    love.graphics.ellipse('line', w/2 - offsets[player.row_frame], h/2, 20, 2, 20)
    -- boat ellipse
    love.graphics.setColor(1, 1, 1, 0.1)
    love.graphics.ellipse('line', w/2 + 10, h/2, 80, 4, 40)

    love.graphics.setShader()
    love.graphics.setScissor()
    love.graphics.setColor(1, 1, 1, 1)
        
    -- draw main canvas
    love.graphics.setScissor(0, 0, w, h/2)
    love.graphics.draw(main_canvas, 0, 0)
    love.graphics.setScissor()
    
    -- draw switch icon
    love.graphics.setShader(invert_shader)
    -- draw mouse dot
    local mx, my = love.mouse.getPosition()
    love.graphics.circle('fill', mx, my, 3, 16)
    love.graphics.draw(switch[1], w/2, h - 150, 0, 1, 1, 63, 0)
    love.graphics.draw(switch[2], w/2 - 33 + player.switch_mode * 32, h - 122, 0, 1, 1, 21, 0)
    love.graphics.setShader()

    love.graphics.print(love.timer.getFPS(), 5, 10)
end