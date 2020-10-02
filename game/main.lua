flux = require "lib/flux"
lume = require "lib/lume"
lovebpm = require "lib/lovebpm"
t = 0

function love.load()
    
end

function love.keypressed(key) 
end

function love.update(dt)
    flux.update(dt)
    t = t + dt
end

function love.draw() 

    -- show fps
    love.graphics.print(love.timer.getFPS() .. " fps", 5, 5)
end