flux = require "flux"
local t = 0

function love.load()
   print("DONE!")
end

function love.filedropped(file)
	file:open("r")
	local data = file:read()
	print("Content of " .. file:getFilename() .. ' is')
	print(data)
	print("End of file")
end

function love.keypressed(key) 

end

function love.update(dt)
    flux.update(dt)
    t = t + dt
end

function love.draw() 
end