
dots = {}
path = {}
saved_paths = {}
best_index = nil
clicked_dot = nil
min_x = 0
max_x = 0

function spawn_dot()
    local scl = lume.randomchoice({ 0.75, 0.85, 0.95, 1.05 })
    local dot = {
        x = player.move_x * scl + w,
        y = lume.random(100, h/2-50),
        scl = scl,
        t = 0,
    }
    lume.push(dots, dot)
end

function calc_bounding_box()
    if lume.count(saved_paths) == 0 then return end

    local min_x1 = lume.reduce(saved_paths, function(a, b) 
        return a[1].x > b[1].x and b or a
    end)[1].x

    local min_x2 = lume.reduce(saved_paths, function(a, b) 
        return a[2].x > b[2].x and b or a
    end)[2].x

    local max_x1 = lume.reduce(saved_paths, function(a, b) 
        return a[1].x > b[1].x and a or b
    end)[1].x

    local max_x2 = lume.reduce(saved_paths, function(a, b) 
        return a[2].x > b[2].x and a or b
    end)[2].x

    min_x = math.min(min_x1, min_x2)
    max_x = math.max(max_x1, max_x2)
end

function press_dot(x, y)
    if not player.light_on then return end

    if clicked_dot ~= nil and best_index ~= nil then
        lume.push(path, clicked_dot)
        lume.push(path, dots[best_index])
        if clicked_dot ~= dots[best_index] then
            flux.to(clicked_dot, 1, { t = 1 })
            flux.to(dots[best_index], 1, { t = 1 })
            lume.push(saved_paths, path)
        end
        path = {}
        clicked_dot = nil
        return
    end
    
    if best_index ~= nil then
        clicked_dot = dots[best_index]
    end
end

function update_dots()
    dots = lume.filter(dots, function(dot)
        return (dot.x - player.move_x * dot.scl) > 0
    end)

    if lume.count(dots) > 0 then
        local mx, my = love.mouse.getPosition()

        local dists = lume.map(dots, function(dot)
            local x = dot.x - player.move_x * dot.scl
            local y = dot.y
            return lume.distance(mx, my, x, y, true)
        end)

        local best_dist = lume.reduce(dists, function(a, b)
            return a > b and b or a
        end)

        best_index = best_dist < 1000 and lume.find(dists, best_dist) or nil
    end
end

function draw_path()
    love.graphics.setColor(1, 1, 0.5)

    draw_path_internal(path)

    local payload = lume.filter(saved_paths, function(path)
        return 
            (path[1].x - player.move_x * path[1].scl) > -w and 
            (path[2].x - player.move_x * path[2].scl) > -w
    end)

    lume.count(payload, draw_path_internal)

    if clicked_dot ~= nil and player.light_on then
        local xo = clicked_dot.x - player.move_x * clicked_dot.scl
        local yo = clicked_dot.y
        local mx, my = love.mouse.getPosition()
        love.graphics.line(xo, yo, mx, my)
    end

    love.graphics.setColor(1, 1, 1)
end

function draw_path_internal(my_path)
    if lume.count(my_path) == 0 then return end

    lume.reduce(my_path, function(a, b)
        local xo = a.x - player.move_x * a.scl
        local yo = a.y
        love.graphics.line(
            xo, yo, 
            b.x - player.move_x * b.scl, 
            b.y)

        love.graphics.circle('fill', xo, yo, 2 * a.t * a.scl, 10)
        love.graphics.circle('fill', b.x - player.move_x * b.scl, b.y, 2 * b.t * b.scl, 10)
        return b
    end)
end

function draw_star_sky()
    love.graphics.push()
    local pad = math.max(25, 300 / lume.count(saved_paths))
    local scl = (max_x - min_x) / (w - pad * 2)
    love.graphics.scale(1 / scl, 1)
    love.graphics.translate(-min_x + pad * scl, -10)
    
    local r = 3
    lume.count(saved_paths, function(path)
        love.graphics.setColor(1, 1, 1, math.abs(math.sin(t + path[1].x)) * 0.2)
        love.graphics.line(path[1].x, path[1].y, path[2].x, path[2].y)
        love.graphics.setColor(1, 1, 1, math.abs(math.cos(t + path[1].y)) + 0.2)
        love.graphics.ellipse('fill', path[1].x, path[1].y, r * scl * path[1].scl, r * path[1].scl, 5)
        love.graphics.ellipse('fill', path[2].x, path[2].y, r * scl * path[2].scl, r * path[2].scl, 5)
    end)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

function draw_dots()
    local beat = music:getBeat(1)
    lume.each(dots, function(dot)
        love.graphics.push()
        love.graphics.translate(-player.move_x * dot.scl, 0)
        love.graphics.setColor(1, 1, 1)
        love.graphics.line(dot.x, lume.lerp(dot.y - 5 * dot.scl, 0, dot.t), dot.x, 0)
        local rot = -(beat % 15)
        love.graphics.draw(star, dot.x, dot.y, rot, 0.8 * dot.scl, 0.8 * dot.scl, 16, 16)
        
        love.graphics.pop()
    end)
end