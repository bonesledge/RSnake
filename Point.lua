-- TODO: Change global funcs to Point. funcs.
-- Represents a 2d point.
local Point = require('class')
{
    name = 'Point',
    function(self, x, y, table)
        if table ~= nil then
            self.x = table.x
            self.y = table.y
        else
            self.x = x
            self.y = y
        end
    end
}

function Point.__add(p0, p1)
    return Point(p0.x + p1.x, p0.y + p1.y)
end

function Point.__sub(p0, p1)
    return Point(p0.x - p1.x, p0.y - p1.y)
end

function Point.__mult(p0, p1)
    return Point(p0.x * p1.x, p0.y * p1.y)
end

function Point.__tostring(p)
    return string.format('(%.1f, %.1f)', p.x, p.y)
end

function Point:magSquared()
    return self.x * self.x + self.y * self.y
end

function Point:magnitude()
    return math.sqrt(self:magSquared())
end

function Point:normalize()
    local m = self:magnitude()
    if m == 0 then
        return
    end
    self.x = self.x / m
    self.y = self.y / m
end

function Point:reflectAcrossPoint(point)
    local x = self.x - point
    local y = self.y - point
    self.x = point - x
    self.y = point - y
end

function Point:getReflectAcrossPoint(point)
    local x = self.x - point.x
    local y = self.y - point.y
    return Point(point.x - x, point.y - y)
end

function Point:compress()
    gapX = (conf.screenWidth - 2*gridXOffset) / gridSize
    gapY = (conf.screenHeight - 2*gridYOffset) / gridSize
    self.x = (self.x - gridXOffset) / gapX
    self.y = (self.y - gridYOffset) / gapY
end

function Point:offset(x, y)
    self.x = self.x + x
    self.y = self.y + y
end

function Point:scale(value)
    self.x = self.x * value
    self.y = self.y * value
end

function Point:equals(point)
    return self.x == point.x and self.y == point.y
end

function Point:distance(point)
    return math.sqrt(self:distanceSquared(point))
end

function Point:distanceSquared(point)
    return (point.x - self.x)*(point.x - self.x)
    + (point.y - self.y)*(point.y - self.y)
end

function mirrorPoint(point, shouldX, shouldY)
    local shouldX = shouldX or false
    local shouldY = shouldY or false
    local mirPoint = Point(point.x, point.y)
    if shouldX then
        mirPoint.x = -1.0 * point.x
    end
    if shouldY then
        mirPoint.y = -1.0 * point.y
    end
    return mirPoint
end

function mirrorXPoint(point)
    return mirrorPoint(point, true)
end

function mirrorYPoint(point)
    return mirrorPoint(point, false, true)
end

function mirrorXYPoint(point)
    return mirrorPoint(point, true, true)
end

dot = function(p0, p1)
    return p0.x * p1.x + p0.y * p1.y
end

function ccw(p1, p2, p3)
    -- From http://en.wikipedia.org/wiki/Graham_scan
    -- 2d cross product (z-component of 3d cross product).
    -- Three points are a counter-clockwise turn if ccw > 0, clockwise if
    -- ccw < 0, and collinear if ccw = 0 because ccw is a determinant that
    -- gives the signed area of the triangle formed by p1, p2 and p3.
    return (p2.x - p1.x)*(p3.y - p1.y) - (p2.y - p1.y)*(p3.x - p1.x)
end

equals = function(p0, p1)
    return p0.x == p1.x and p0.y == p1.y
end

function Point.mirrorXListOfPoints(points)
    local mirroredPoints = {}
    for i = 1, #points do
        mirroredPoints[i] = mirrorXPoint(points[i])
    end
    return mirroredPoints
end

function computeCentroid(points)
    --From http://en.wikipedia.org/wiki/Centroid#Locating_the_centroid
    local cx = 0
    local cy = 0
    local a = 0
    for i = 1, #points do
        local p0 = points[i]
        local p1
        if i == #points then
            p1 = points[1]
        else
            p1 = points[i + 1]
        end
        cx = cx + (p0.x + p1.x)*(p0.x*p1.y - p1.x*p0.y)
        cy = cy + (p0.y + p1.y)*(p0.x*p1.y - p1.x*p0.y)
        a = a + (p0.x*p1.y - p1.x*p0.y)
    end
    a = a/2
    if a ~= 0 then
        cx = cx/(6*a)
        cy = cy/(6*a)
    end
    return Point(cx, cy)
end


function computeArea(points)
    -- From http://en.wikipedia.org/wiki/Centroid#Locating_the_centroid
    local a = 0
    for i = 1, #points do
        local p0 = points[i]
        local p1
        if i == #points then
            p1 = points[1]
        else
            p1 = points[i + 1]
        end
        a = a + (p0.x*p1.y - p1.x*p0.y)
    end
    a = a/2
    return a
end

function convexHull(unsortedPoints)
    -- Finds the smallest convex polygon that encapsulates all the points.
    -- using Graham's scan. See http://en.wikipedia.org/wiki/Graham_scan
    -- and http://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain
    local points = objectDeepcopy(unsortedPoints)
    -- Sort the points by Y value.
    table.sort(points, compareXthenY)
    if #points <= 2 then
        -- Can't make a polygon without a big enough input.
        return nil
    end
    -- Build lower hull
    local lower = {}
    for i = 1, #points do
        local p = points[i]
        while #lower >= 2 and ccw(lower[#lower - 1], lower[#lower], p)
        <= 0 do
            table.remove(lower)
        end
        table.insert(lower, p)
    end
    -- Build upper hull
    local upper = {}
    for i = #points, 1, -1 do
        local p = points[i]
        while #upper >= 2 and ccw(upper[#upper - 1], upper[#upper], p)
        <= 0 do
            table.remove(upper)
        end
        table.insert(upper, p)
    end
    -- Concatenate the hulls, but skip the last value of each
    table.remove(lower)
    for i = 1, #upper - 1 do
        table.insert(lower, upper[i])
    end

    if #lower < 3 then
        return unsortedPoints
    end
    return lower
end

function compareYthenX(p0, p1)
    if not p0 or not p1 then
        return false
    end
    if p0.y == p1.y then
        return p0.x <= p1.x
    end
    return p0.y <= p1.y
end

function compareXthenY(p0, p1)
    if not p0 or not p1 then
        return false
    end
    if p0.x == p1.x then
        return p0.y <= p1.y
    end
    return p0.x <= p1.x
end

function nearestPoint(points, point)
    local nearestIndex = 1
    local nearestDist = conf.worldXEnd
    for i = 1, #points do
        local dist = points[i]:distanceSquared(point)
        if dist < nearestDist then
            nearestDist = dist
            nearestIndex = i
        end
    end
    return points[nearestIndex], nearestIndex
end

function midPoint(p0, p1)
    local x = (p0.x + p1.x)/2
    local y = (p0.y + p1.y)/2
    return Point(x, y)
end

function removeRedundantPoints(points)
    for i = #points, 1, -1 do
        for j = #points, 1, -1 do
            if i ~= j and points[i]:equals(points[j]) then
                table.remove(points, j)
            end
        end
    end
end

function testPoint(p, points)
    -- Return true if the point p is in the polygon points, else false.
    -- From http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
    local c = false
    local j = #points
    for i = 1, #points do
        if ((points[i].y > p.y) ~= (points[j].y > p.y)) and
        (p.x < (points[j].x - points[i].x)*(p.y - points[i].y)
        /(points[j].y - points[i].y) + points[i].x) then
            c = not c
        end
        j = i
    end
    return c
end

function Point.pointsToCoordsTable(points)
    local coords = {}
    for i = 1, #points do
        table.insert(coords, points[i].x)
        table.insert(coords, points[i].y)
    end
    return coords
end

function Point.pointsToCoords(points)
    return unpack(Point.pointsToCoordsTable(points))
end

function Point.coordsToPoints(coords)
    local points = {}
    for i = 1, #coords, 2 do
        table.insert(points, Point(coords[i], coords[i + 1]))
    end
    return points
end

local function getOtherPointFromLines(lines, point)
    for i = 1, #lines do
        local otherPoint = objectDeepcopy(lines[i]:getOtherPoint(point))
        if otherPoint then
            table.remove(lines, i)
            return otherPoint
        end
    end
    return false
end

function Point.connectLinesIntoPolygon(lines)
    if #lines < 3 then return nil end
    local segs = objectDeepcopy(lines)
    local points = {segs[1].p0, segs[1].p1}
    local lastPoint = points[2]
    table.remove(segs, 1)
    while #segs > 0 do
        lastPoint = getOtherPointFromLines(segs, lastPoint)
        if lastPoint then
            table.insert(points, lastPoint)
        else
            return nil
        end
    end
    if equals(lastPoint, points[1]) then
        table.remove(points, #points)
        return points
    end
    return nil
end

return Point
