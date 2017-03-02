-- Vector class
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

--[[
The "Vector" class is for handling arbitrary dimensional vectors 
and defining a variety of methods on them.
--]]

local Vector = class()

--[[
A vector is a size and an array of numbers.
--]]

function Vector:init(...)
    local v
    local arg = {...}
    local n = select("#",...)
    if n == 1 then
        if type(arg[1]) == "table" then
            if arg[1].is_a and arg[1]:is_a(Complex) then
                v = {arg[1]}
            else
                v = arg[1]
            end
        elseif type(arg[1]) == "userdata" then
            local mt = getmetatable(arg[1])
            if mt == getmetatable(vec2()) then
                v = {arg[1].x,arg[1].y}
            elseif mt == getmetatable(vec3()) then
                v = {arg[1].x,arg[1].y,arg[1].z}
            elseif mt == getmetatable(vec4()) then
                v = {arg[1].x,arg[1].y,arg[1].z,arg[1].w}
            end
        else
            v = {tonumber(arg[1])}
        end
    else
        v = arg
    end
    --local u = {}
    local n = 0
    for k,l in ipairs(v) do
        table.insert(self,l)
        --table.insert(u,l)
        n = n + 1
    end
    --self.vec = u
    self.size = n
    -- Shortcuts for low dimension
    self.x = self[1]
    self.y = self[2]
    self.z = self[3]
    self.w = self[4]
end

--[[
Test for zero vector.
--]]

function Vector:is_zero()
    for k,v in ipairs(self) do
        if v ~= 0 then
            return false
        end
    end
    return true
end

--[[
Test for equality.
--]]

function Vector:is_eq(u)
    if self.size ~= u.size then
        return false
    end
    for k,v in ipairs(self) do
        if v ~= u[k] then
            return false
        end
    end
    return true
end        

--[[
Inner product.
--]]

function Vector:dot(u)
    if self.size ~= u.size then
        return false
    end
    local d = 0
    for k,v in ipairs(self) do
        d = d +  v * u[k]
    end
    return d
end

--[[
Apply a given matrix (which is specified as a list of row vectors).
--]]

function Vector:applyMatrixLeft(m)
    if m.cols ~= self.size then
        return false
    end
    local u = {}
    for k,v in ipairs(m) do
        table.insert(u,self:dot(v))
    end
    return Vector(u)
end

function Vector:applyMatrixRight(m)
    if m.rows ~= self.size then
        return false
    end
    local u = {}
    local a = Vector.zero(m.cols)
    for k,v in ipairs(m) do
        a = a + self[k]*v
    end
    return a
end

--[[
Length of the vector
--]]

function Vector:len()
    local d = 0
    for k,v in ipairs(self) do
        d = d +  math.pow(v,2)
    end
    return math.sqrt(d)
end

--[[
Squared length of the vector.
--]]

function Vector:lenSqr()
    local d = 0
    for k,v in ipairs(self) do
        d = d +  math.pow(v,2)
    end
    return d
end

--[[
Norm infinity
--]]

function Vector:linfty()
    local m = 0
    for k,v in ipairs(self) do
        m = math.max(m,math.abs(v))
    end
    return m
end

--[[
Norm one
--]]

function Vector:lone()
    local m = 0
    for k,v in ipairs(self) do
        m = m + math.abs(v)
    end
    return m
end

--[[
Normalise the vector (if possible) to length 1.
--]]

function Vector:normalise()
    local l
    if self:is_zero() then
        print("Unable to normalise a zero-length vector")
        return false
    end
    l = 1/self:len()
    return self:scale(l)
end

--[[
Scale the vector.
--]]

function Vector:scale(l)
    local u = {}
    for k,v in ipairs(self) do
        table.insert(u,l*v)
    end
    return Vector(u)
end

--[[
Add vectors.
--]]

function Vector:add(u)
    if self.size ~= u.size then
        return false
    end
    local w = {}
    for k,v in ipairs(self) do
        table.insert(w, v + u[k])
    end
    return Vector(w)
end

--[[
Subtract vectors.
--]]

function Vector:subtract(u)
    if self.size ~= u.size then
        return false
    end
    local w = {}
    for k,v in ipairs(self) do
        table.insert(w, v - u[k])
    end
    return Vector(w)
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

function Vector:__add(v)
    return self:add(v)
end

function Vector:__sub(v)
    return self:subtract(v)
end

function Vector:__unm()
    return self:scale(-1)
end

function Vector:__mul(v)
    if type(self) == "number" then
        return v:scale(self)
    elseif type(v) == "number" then
        return self:scale(v)
    else
        if self.is_a and self:is_a(Matrix) then
            return v:applyMatrixLeft(self)
        elseif v.is_a and v:is_a(Matrix) then
            return self:applyMatrixRight(v)
        end
    end
    return false
end

function Vector:__div(l)
    if type(l) == "number" then
        return self:scale(1/l)
    else
        return false
    end
end

function Vector:__eq(v)
    return self:is_eq(v)
end

function Vector:__concat(v)
    if type(v) == "table" 
        and v:is_a(Vector) then
            return self .. v:tostring()
        else
            return self:tostring() .. v
        end
end

function Vector:tostring()
    local t = {}
    for k,v in ipairs(self) do
        if type(v) == "table" and v.tostring then
            table.insert(t,v:tostring())
        else
            table.insert(t,v)
        end
    end
    return "(" .. table.concat(t,",") .. ")"
end

function Vector:__tostring()
    return self:tostring()
end

function Vector:tovec()
    if self.size == 2 then
        return vec2(self[1],self[2])
    elseif self.size == 3 then
        return vec3(self[1],self[2],self[3])
    else
        return vec4(self[1],self[2],self[3],self[4])
    end
end
        

function Vector.zero(n)
    if type(n) == "table" then
        n = n.size
    end
    u = {}
    for i = 1,n do
        table.insert(u,0)
    end
    return Vector(u)
end

function Vector:bitwiseReorder(b)
    local v
    if b then
        v = self
    else
        v = Vector({})
    end
    local h = BinLength(self.size)
    local m = math.pow(2,h)
    local l
    local w = {}
    for k = 1,m do
        if not w[k] then
            l = BinReverse(k-1,h)+1
            v[k],v[l] = self[l] or 0,self[k] or 0
            w[k],w[l] = 1,1
        end
    end
    v.size = m
    return v
end

function Vector:FFT(t)
    t = t or {}
    local v
    v = self:bitwiseReorder(t.inplace)
    local pi = math.pi
    if not t.inverse then
        pi = - pi
    end
    local r = v.size
    local n = BinLength(r) -1
    local i,j,d,s,m,fi,p,pr
    for k = 0,n do
        i = math.pow(2,k)
        j = math.pow(2,k+1)
        d = pi/i
        s = math.sin(d/2)
        m = Complex(-2 * s * s, math.sin(d))
        fi = Complex(1,0)
        for l = 1,i do
            for ll = l,r-1,j do
                p = ll + i
                pr = fi * v[p]
                v[p] = v[ll] - pr
                v[ll] = v[ll] + pr
            end
            fi = m*fi + fi
        end
    end
    return v
end
        

if cmodule.loaded "TestSuite" then
    
    testsuite.addTest({
        name = "Vector",
        setup = function()
            local w = Vector({1,2,3,4,5,6,7,8})
            local z = Vector({Complex(1,1), Complex(2,3), Complex(4,5)})
            for k,v in ipairs({
                {"Vector", w},
                {"Complex Vector", z},
                {"Bitwise Reverse", w:bitwiseReorder()},
                {"Bitwise Reverse", z:bitwiseReorder()},
                {"FFT", w:FFT()},
                {"FFT", z:FFT()}
            }) do
                print(v[1] .. ": " .. v[2])
            end
        end,
        draw = function()
        end
    })
end

if _M then
    return Vector
else
    _G["Vector"] = Vector
end

