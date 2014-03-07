local Point = require 'Point'
local pos = Point(400, 300)
local trail = { size = 400, i = 1 }
local screenCenterX = 400
local angle = 0

function love.load(args)
    math.randomseed(os.time())
    -- hide the mouse
    love.mouse.setVisible(false)
    -- set some graphics settings
    love.graphics.setLineStyle('rough')
end

function love.draw()
    love.graphics.setColor(255, 200, 0)
    for _, point in ipairs(trail) do
        love.graphics.circle('fill', point.x, point.y, 5, 30)
    end
    love.graphics.setColor(0, 255, 255)
    love.graphics.circle('fill', love.mouse.getX(), 550, 5, 30)
end

local function updateTrail()
    trail[trail.i] = Point(pos.x, pos.y)
    trail.i = trail.i + 1
    if trail.i > trail.size then
        trail.i = 1
    end
end

function love.update(dt)
    local mouseX = love.mouse.getX()
    -- Allow small dead zone
    local angularVelocity
    if mouseX < screenCenterX + 10 and mouseX > screenCenterX - 10 then
        angularVelocity = 0
    else
        angularVelocity = 0.0001*(screenCenterX - love.mouse.getX())
    end
    angle = angle + angularVelocity
    pos.x = pos.x + math.cos(angle) 
    pos.y = pos.y + math.sin(angle)
    updateTrail()
end

function love.keypressed(key)

end

function love.keyreleased(key)

end

