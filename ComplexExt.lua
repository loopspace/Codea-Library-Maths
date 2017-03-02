--[==[
-- Complex numbers class as extension of vec2
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

--[[
This promotes vec2s to complex numbers.
--]]

local function is_a(a,b)
    if type(b) == "function" then
        b = b()
    end
    if type(b) == "string" then
        return type(a) == b
    end
    if type(b) == "table" then
        if type(a) == "table"
            and a.is_a
            and a:is_a(b) then
                return true
        else
            return false
        end
    end
    if type(b) == "userdata" then
        if type(a) == "userdata" then
            a = getmetatable(a)
            b = getmetatable(b)
            return a == b
        else
            return false
        end
    end
    return false
end

local error = error or print

local mt = getmetatable(vec2())
local Complex = function (a,b)
    return vec2(a,b)
end

local symbol = readLocalData("Complex Symbol","i")
local radeg = readLocalData("Complex Angle","rad")
local angle, angsym
if radeg == "rad" then
    angle = 1
    angsym = "π"
else
    angle = 180
    angsym = "°"
end
local precision = readLocalData("Complex Precision",2)
local tostring

function setComplex(t)
    angle = t.angle or angle
    angsym = t.angsym or angsym
    precision = t.precision or precision
    symbol = t.symbol or symbol
    tostring = t.tostring or tostring
end

local abs = math.abs
local pow = math.pow
local sqrt = math.sqrt
local exp = math.exp
local log = math.log
local sin = math.sin
local cos = math.cos
local tan = math.tan
local sinh = math.sinh
local cosh = math.cosh
local tanh = math.tanh
local pi = math.pi
local floor = math.floor

mt["clone"] = function (self)
    return vec2(self.x,self.y)
end

--[[
Test if we are real.
--]]

mt["is_real"] = function (self)
    if self.y ~= 0 then
        return false
    end
    return true
end

--[[
Test if the real part is zero.
--]]

mt["is_imaginary"] = function (self)
    if self.x ~= 0 then
        return false
    end
    return true
end

--[[
Normalise a complex number to have length 1, if possible.
--]]

mt["normalise"] = mt["normalize"]

--[[
Addition and subtraction automatically convert numbers to complex numbers
--]]

--[[
q + p
--]]

local __add = mt["__add"]

mt["__add"] = function (a,b)
    if is_a(a,"number") then
        a = vec2(a,0)
    end
    if is_a(b,"number") then
        b = vec2(b,0)
    end
    return __add(a,b)
end

local __sub = mt["__sub"]

mt["__sub"] = function (a,b)
    if is_a(a,"number") then
        a = vec2(a,0)
    end
    if is_a(b,"number") then
        b = vec2(b,0)
    end
    return __sub(a,b)
end

--[[
q * p
--]]

mt["__mul"] = function (a,b)
    if is_a(a,"number") then
        a = vec2(a,0)
    end
    if is_a(b,"number") then
        b = vec2(b,0)
    end
    return vec2(a.x*b.x - a.y*b.y,a.x*b.y+a.y*b.x)
end

--[[
Conjugation.
--]]

mt["conjugate"] = function (self)
    return vec2(self.x, - self.y)
end

mt["co"] = mt["conjugate"]

--[[
Real powers.
--]]

local function repower(self,n,k)
    local r = self:len()
    local t = -self:angleBetween(vec2(1,0))
    k = k or 0
    r = pow(r,n)
    t = (t + k * 2 * pi) *n
    return vec2(r*cos(t),r*sin(t))
end

--[[
Complex powers.
--]]

local function power(self,w,k)
    if is_a(w,"number") then
        return repower(self,w,k)
    end
    if self == vec2(0,0) then
        error("Taking powers of 0 is somewhat dubious")
        return false
    end
    local r = self:len()
    local t = -self:angleBetween(vec2(1,0))
    local u = w.x
    local v = w.y
    k = k or 0
    local nr = pow(r,u) * exp(-v*t)
    local nt = (t + k * 2 * pi) * u + log(r) * v
    return vec2(nr*cos(nt),nr*sin(nt))
end

--[[
q^n

This is overloaded so that a non-(complex) number exponent returns
the conjugate.  This means that one can write things like q^"" to
get the conjugate of a complex number.
--]]

mt["__pow"] = function (self,n)
    if is_a(n,"number") then
        return repower(self,n)
    elseif is_a(n,vec2) then
        return power(self,n)
    else
        return self:conjugate()
    end
end

--[[
Division: q/p
--]]

mt["__div"] = function (self,q)
    if is_a(q,"number") then
        return vec2(self.x/q,self.y/q)
    elseif is_a(self,"number") then
        return vec2(self*q.x/q:lenSqr(),-self*q.y/q:lenSqr())
    else
        return vec2((self.x*q.x + self.y*q.y)/q:lenSqr(),
                (self.y*q.x - self.x*q.y)/q:lenSqr())
    end
end

--[[
Returns the real part.
--]]

mt["real"] = function (self)
    return self.x
end

--[[
Returns the imaginary part.
--]]

mt["imaginary"] = function (self)
    return self.y
end

--[[
Represents a complex number as a string.
--]]

mt["__concat"] = function (self,v)
    if is_a(v,vec2) then
        return self .. v:tostring()
    else
        return self:tostring() .. v
    end
end

--[[
mt["__tostring"] = function (self)
    return self:tostring()
end
--]]
mt["tostring"] = function (self)
    return tostring(self)
end

local function tostring_cartesian(self)
    local s
    local x = floor(
        self.x * 10^precision +.5
        )/10^precision
    local y = floor(
        self.y * 10^precision +.5
        )/10^precision
    if x ~= 0 then
        s = x
    end
    if y ~= 0 then
        if s then 
                if y > 0 then
                    if y == 1 then
                        s = s .. " + " .. symbol
                    else
                        s = s .. " + " .. y .. symbol
                    end
                else
                    if y == -1 then
                        s = s .. " - " .. symbol
                    else
                        s = s .. " - " .. (-y) .. symbol
                    end
                end
        else
                if y == 1 then
                    s = symbol
                elseif y == - 1 then
                    s = "-" .. symbol
                else
                    s = y .. symbol
                end
        end
    end
    if s then
        return s
    else
        return "0"
    end
end

local function tostring_polar (self)
    local t = floor(angle *
        self:arg() * 10^precision/pi +.5
        )/10^precision
    local r = floor(
        self:len() * 10^precision +.5
        )/10^precision
    local s = ""
    --[[
    -- this is exponential notation
    if t == 0 then
        s = r
    else
        if r ~= 1 then
            s = r
        end
        s = s .. "e^(" .. t .."i)"
    end
    --]]
    s = "(" .. r .. "," .. t .. angsym .. ")"
    return s
end

tostring = tostring_cartesian
mt["topolarstring"] = tostring_polar
mt["tocartesianstring"] = tostring_cartesian

mt["arg"] = function (self)
    return -self:angleBetween(vec2(1,0))
end

--[[
The unit complex number.
--]]

function Complex_unit()
    return vec2(1,0)
end
function Complex_zero()
    return vec2(0,0)
end
function Complex_i()
    return vec2(0,-1)
end

--[[
Overload the maths functions
--]]



function math.abs(n)
    if is_a(n,"number") then return abs(n) end
    if is_a(n,vec2) then
        return n:len()
    end
    error("Cannot take the length of " .. n)
end

function math.pow(n,e)
    if is_a(n,"number") then
        if is_a(e,"number") then
             return pow(n,e)
        elseif is_a(e,vec2) then
            local w = vec2(n,0)
            return repower(w,e,0)
        end
    end
    if is_a(n,vec2) then
        return power(n,e,0)
    end
    error("Cannot take the power of " .. n .. " by " .. e)
end

function math.sqrt(n)
    if is_a(n,"number") then return sqrt(n) end
    if is_a(n,vec2) then
        return repower(n,.5,0)
    end
    error("Cannot take the square root of " .. n)
end

function math.exp(n)
    if is_a(n,"number") then return exp(n) end
    if is_a(n,vec2) then
        local r = exp(n.x)
        local a = n.y
        return vec2(r*cos(a),r*sin(a))
    end
    error("Cannot exponentiate " .. n)
end

--[[
cos(x+iy) = cos(x) cos(iy) - sin(x) sin(iy)
          = cos(x) cosh(y) - i sin(x) sinh(y)
--]]

function math.cos(n)
    if is_a(n,"number") then return cos(n) end
    if is_a(n,vec2) then
        local x = n.x
        local y = n.y
        return vec2(cos(x)*cosh(y),-sin(x)*sinh(y))
    end
    error("Cannot take the cosine of " .. n)
end

--[[
sin(x+iy) = sin(x) cos(iy) + cos(x) sin(iy)
          = sin(x) cosh(y) + i cos(x) sinh(y)
--]]

function math.sin(n)
    if is_a(n,"number") then return sin(n) end
    if type(n,vec2) then
        local x = n.x
        local y = n.y
        return vec2(sin(x)*cosh(y), cos(x)*sinh(y))
    end
    error("Cannot take the sine of " .. n)
end

--[[
cosh(x+iy) = cosh(x) cosh(iy) + sinh(x) sinh(iy)
           = cosh(x) cos(y) + i sinh(x) sin(y)
--]]

function math.cosh(n)
    if is_a(n,"number") then return cosh(n) end
    if type(n,vec2) then
        local x = n.x
        local y = n.y
        return vec2(cosh(x)*cos(y), sinh(x)*sin(y))
    end
    error("Cannot take the hyperbolic cosine of " .. n)
end

--[[
sinh(x+iy) = sinh(x) cosh(iy) + cosh(x) sinh(iy)
          = sinh(x) cos(y) + i cosh(x) sin(y)
--]]

function math.sinh(n)
    if is_a(n,"number") then return sinh(n) end
    if type(n,vec2) then
        local x = n.x
        local y = n.y
        return vec2(sinh(x)*cos(y), cosh(x)*sin(y))
    end
    error("Cannot take the hyperbolic sine of " .. n)
end

--[[
tan(x+iy) = (sin(x) cos(x) + i sinh(y) cosh(y))
            /(cos^2(x) cosh^2(y) + sin^2(x) sinh^2(y))
--]]

function math.tan(n)
    if is_a(n,"number") then return tan(n) end
    if is_a(n,vec2) then
            local x = n.x
            local y = n.y
            local cx = cos(x)
            local sx = sin(x)
            local chy = cosh(y)
            local shy = sinh(y)
            local d = cx^2 * chy^2 + sx^2 * shy^2
            if d == 0 then
                return false
            end
            return vec2(sx*cx/d,shy*chy/d)
    end
    error("Cannot take the tangent of " .. n)
end

--[[
tanh(x+iy) = i tan(y - ix)
           = (sin(x) cos(x) + i sinh(y) cosh(y))
            /(cos^2(x) cosh^2(y) + sin^2(x) sinh^2(y))
           = (sinh(x) cosh(x) + i sin(y) cos(y))
            /(cos^2(y) cosh^2(x) + sin^2(y) sinh^2(x))
--]]

function math.tanh(n)
    if is_a(n,"number") then return tanh(n) end
    if is_a(n,vec2) then
            local x = n.x
            local y = n.y
            local cy = cos(y)
            local sy = sin(y)
            local chx = cosh(x)
            local shx = sinh(x)
            local d = cy^2 * chx^2 + sy^2 * shx^2
            if d == 0 then
                return false
            end
            return vec2(shx*chx/d,sy*cy/d)
    end
    error("Cannot take the hyperbolic tangent of " .. n)
end

--[[
log(r e^(i a)) = log(r) + i (a + 2 k pi)
--]]

function math.log(n,k)
    if is_a(n,"number") then
        if k then
            return vec2(log(n), 2*k*pi)
        else
            return log(n)
        end
    end
    k = k or 0
    if is_a(n,vec2) then
        return vec2(log(n:len()),n:arg() + 2*k*pi)
    end
    error("Cannot take the logarithm of " .. n)
end

if cmodule.loaded "TestSuite" then
    
    testsuite.addTest({
        name = "ComplexExt",
        setup = function()
    local z = vec2(2,4)
    local w = vec2(-1,1)
    for k,v in ipairs({
        {"z", z},
        {"w", w},
        {"Muliplication" , z*w},
        {"ScalingLeft" , 2*z},
        {"ScalingRight" , z*2},
        {"Addition" , z+w},
        {"Addition" , 3+w},
        {"Addition" , w+3},
        {"Subtraction" , z-w},
        {"Subtraction" , 3-w},
        {"Subtraction" , w-3},
        {"Division" , z/w},
        {"DivisionLeft" , 2/z},
        {"DivisionRight" , z/2},
        {"Reciprocal", 1/z},
        {"Negation", -z},
        {"Powers", z^2},
        {"Roots", z^.5},
        {"Complex Powers", z^w},
        {"Conjugation", w^""},
        {"Polar Form", z:topolarstring()},
        {"Length", z:len()},
        {"Overloading",""},
        {"Absolute value", math.abs(z)},
        {"Powers", math.pow(z,w)},
        {"Square Root", math.sqrt(z)},
        {"Cosine", math.cos(z)},
        {"Sine", math.sin(z)},
        {"Tangent", math.tan(z)},
        {"Hyperbolic Cosine", math.cosh(z)},
        {"Hyperbolic Sine", math.sinh(z)},
        {"Hyperbolic Tangent", math.tanh(z)},
        {"Logarithm", math.log(z,1)},
    }) do
        print(v[1] .. ": " .. v[2])
    end
end,
draw = function()
end
})

end


--]==]
