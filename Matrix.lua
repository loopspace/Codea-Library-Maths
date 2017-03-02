-- Matrix
local Vector, Sentence = Vector, Sentence
if _M then
    Vector = cimport "Vector"
    _,Sentence = unpack(cimport "Font")
end
local Matrix = class()

function Matrix:init(t)
    local r = 0
    local c = 0
    for k,v in ipairs(t) do
        table.insert(self,Vector(v))
        r = r + 1
    end
    c = self[1].size
    for k,v in ipairs(self) do
        if v.size ~= c then
            return false
        end
    end
    
    self.rows = r
    self.cols = c
end

function Matrix:add(m)
    if self.rows ~= m.rows then
        return false
    end
    if self.cols ~= m.cols then
        return false
    end
    local u = {}
    for k,v in ipairs(self) do
        table.insert(u,v + m[k])
    end
    return Matrix(u)
end

function Matrix:subtract(m)
    if self.rows ~= m.rows then
        return false
    end
    if self.cols ~= m.cols then
        return false
    end
    local u = {}
    for k,v in ipairs(self) do
        table.insert(u,v - m[k])
    end
    return Matrix(u)
end

function Matrix:scale(l)
    local u = {}
    for k,v in ipairs(self) do
        table.insert(u,l*v)
    end
    return Matrix(u)
end

function Matrix:multiplyRight(m)
    if self.cols ~= m.rows then
        return false
    end
    local u = {}
    for k,v in ipairs(self) do
        table.insert(u,v*m)
    end
    return Matrix(u)
end

function Matrix:multiplyLeft(m)
    return m:multiplyRight(self)
end

function Matrix:transpose()
    local nrows = {}
    for i = 1,self.cols do
        nrows[i] = {}
    end
    for k,v in ipairs(self) do
        for i = 1,self.cols do
            table.insert(nrows[i],v[i])
        end
    end
    return Matrix(nrows)
end

--[[
Inline operators:

u + v
u - v
-u
u * v : scaling
u / v : scaling
u == v : equality
--]]

function Matrix:__add(v)
    return self:add(v)
end

function Matrix:__sub(v)
    return self:subtract(v)
end

function Matrix:__unm()
    return self:scale(-1)
end

function Matrix:__mul(v)
    if type(self) == "number" then
        return v:scale(self)
    elseif type(v) == "number" then
        return self:scale(v)
    elseif type(self) == "userdata" then
        return Vector(self):applyMatrixRight(v):tovec()
    elseif type(v) == "userdata" then
        return Vector(v):applyMatrixLeft(self):tovec()
    else
        if self.is_a and self:is_a(Vector) then
            return self:applyMatrixRight(v)
        elseif v.is_a and v:is_a(Vector) then
            return v:applyMatrixLeft(self)
        else
            return self:multiplyRight(v)
        end
    end
    return false
end

function Matrix:__div(l)
    if type(l) == "number" then
        return self:scale(1/l)
    else
        return false
    end
end

function Matrix:__eq(v)
    return self:is_eq(v)
end

function Matrix:__concat(v)
    if type(v) == "table" 
        and v:is_a(Matrix) then
            return self .. v:tostring()
        else
            return self:tostring() .. v
        end
end

function Matrix:tostring()
    local u = {}
    for k,v in ipairs(self) do
        table.insert(u,v:tostring())
    end
    return "[" .. table.concat(u,";") .. "]"
end

function Matrix:__tostring()
    return self:tostring()
end

function Matrix:toModelMatrix()
    local m = {}
    for j=1,4 do
        for i=1,4 do
            if self[i] and self[i][j] then
                table.insert(m,self[i][j])
            elseif i == j then
                table.insert(m,1)
            else
                table.insert(m,0)
            end
        end
    end
    return matrix(unpack(m))
end

function Matrix:setParameters(t)
    t = t or {}
    for k,v in pairs({
        "font",
        "colour",
        "ui",
        "pos",
        "rowSep",
        "colSep",
        "anchor"
    }) do
        if t[v] then
            self[v] = t[v]
        end
    end
    if t.touchHandler then
        t.touchHandler:pushHandler(self)
    end
end

function Matrix:prepare()
    if not self.prepared then
    local f = self.font
    local t = {}
    local r
    local w = {}
    local s
    local col = self.colour or Colour.svg.White
    for k,v in ipairs(self) do
        r = {}
        for l,u in ipairs(v) do
            s = Sentence(f,math.floor(100*u+.5)/100)
            s:prepare()
            if not w[l] then
                w[l] = s.width
            else
                w[l] = math.max(w[l],s.width)
            end
            s:setColour(col)
            table.insert(r,s)
        end
        table.insert(t,r)
    end
    self.entries = t
    self.widths = w
    self.prepared = true
    end
end

function Matrix:draw()
    pushStyle()
    resetStyle()
    self:prepare()
    local rs = self.rowSep or 0
    local cs = self.colSep or 0
    local x,y = WIDTH/2,HEIGHT/2
    if self.pos then
        x,y = self.pos()
    end
    local a = self.anchor or "centre"
    local widths = self.widths
    local w = cs * self.cols
    for k,v in ipairs(widths) do
        w = w + v
    end
    local lh = self.font:lineheight() + rs
    local h = self.rows * lh
    x,y = RectAnchorAt(x,y,w,h,a)
    local yy = y + h + rs/2
    local xx = x + cs/2
    y = yy + rs/2 + self.font.descent
    for k,v in ipairs(self.entries) do
        x = xx
        y = y - lh
        for l,u in ipairs(v) do
            u:draw(x,y)
            x = x + widths[l] + cs
        end
    end
    xx = xx - cs/2
    yy = yy - rs/2
    smooth()
    strokeWidth(4)
    local col = self.colour or Colour.svg.White
    stroke(col)
    lineCapMode(PROJECT)
    line(xx-5,yy,xx,yy)
    line(xx-5,yy,xx-5,yy-h)
    line(xx-5,yy-h,xx,yy-h)
    line(xx+w+5,yy,xx+w,yy)
    line(xx+w+5,yy,xx+w+5,yy-h)
    line(xx+w+5,yy-h,xx+w,yy-h)
    popStyle()
end
            
function Matrix:isTouchedBy(touch)
    local rs = self.rowSep or 0
    local cs = self.colSep or 0
    local x,y = WIDTH/2,HEIGHT/2
    if self.pos then
        x,y = self.pos()
    end
    local a = self.anchor or "centre"
    local widths = self.widths
    local w = cs * self.cols
    for k,v in ipairs(widths) do
        w = w + v
    end
    local lh = self.font:lineheight() + rs
    local h = self.rows * lh
    x,y = RectAnchorAt(x,y,w,h,a)
    if touch.x < x then
        return false
    end
    if touch.x > x + w then
        return false
    end
    if touch.y < y then
        return false
    end
    if touch.y > y + h then
        return false
    end
    return true
end

function Matrix:processTouches(g)
    if g.type.ended and g.type.tap then
        local t = g.touchesArr[1]
        local rs = self.rowSep or 0
    local cs = self.colSep or 0
    local x,y = WIDTH/2,HEIGHT/2
    if self.pos then
        x,y = self.pos()
    end
    local a = self.anchor or "centre"
    local lh = self.font:lineheight() + rs
    local h = self.rows * lh
        local widths = self.widths
    local w = cs * self.cols
    for k,v in ipairs(widths) do
        w = w + v
    end
    x,y = RectAnchorAt(x,y,w,h,a)
        local r = math.floor((y + h - t.touch.y)/lh) + 1
        
        w = x
        local c
        for k,v in ipairs(widths) do
            w = w + v + cs
            if t.touch.x < w then
                c = k
                break
            end
        end
        self.ui:getNumberSpinner({
            action = function(v)
                    self[r][c] = v
                    self.prepared = false
                    return true
                end,
            value = self[r][c]
        })
    end
    if g.updated then
        g:noted()
    end
    if g.type.ended then
        g:reset()
    end
end

if _M then
    return Matrix
else
    _G["Matrix"] = Matrix
end

