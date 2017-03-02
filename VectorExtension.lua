--[==[
-- Extensions to the native Codea vector and matrix typed
-- Author: Andrew Stacey
-- Website: http://loopspace.mathforge.com
-- Licence: CC0 http://wiki.creativecommons.org/CC0
 
--[[
vec4s are promoted to quaternions, vec2s to complex numbers, and other functions are adapted to make use of them
--]]
 
-- Simplistic error handling
local error = error or print
 
-- Localise the maths functions/constants that we use for faster lookup.
local abs = math.abs
local pow = math.pow
local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local acos = math.acos
local asin = math.asin
local pi = math.pi
local floor = math.floor
local min = math.min
local max = math.max
local exp = math.exp
local log = math.log
local tan = math.tan
local sinh = math.sinh
local cosh = math.cosh
local tanh = math.tanh

--[[
The function "is_a" extends the capabilities of the method "is_a" which is automatically defined by Codea for classes.
 
Parameters:
a: object to be tested
b: test
 
The tests work as follows.
 
1. If the type of b is a string, it is taken as the name of a type to test a against.
2. If the type of b is a table, it is assumed to be a class to test if a is an instance thereof.
3. If the type of b is a userdata, the test is to see if a is the same type of object.
4. If b is a function, then it is replaced by the value of that function.
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

function edge(t,a,b)
    a = a or 0
    b = b or 1
    t = (t-a)/(b-a)
    return min(1,max(0,t))
end

function smoothstep(t,a,b)
    a = a or 0
    b = b or 1
    t = (t-a)/(b-a)
    t = min(1,max(0,t))
    return t * t * (3 - 2 * t)
end

function smootherstep(t,a,b)
    a = a or 0
    b = b or 1
    t = (t-a)/(b-a)
    t = min(1,max(0,t))
    return t * t * t * (t * (t * 6 - 15) + 10)
end

local mt = getmetatable(vec2())

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




-- Import the metatable of vec4s for extending
local mtq = getmetatable(vec4())
 
-- We run into difficulties if our vec4s contain NaNs or infs.  This
-- tests for those.
mtq["is_finite"] = function(q)
    if q.x < math.huge and q.x > -math.huge 
        and q.y < math.huge and q.y > -math.huge 
        and q.z < math.huge and q.z > -math.huge 
        and q.w < math.huge and q.w > -math.huge 
    then
        return true
    end
    return false
end
 
--[[
Test if we are real.
--]]
 
mtq["is_real"] = function (q)
    if q.y ~= 0 or q.z ~= 0 or q.w ~= 0 then
        return false
    end
    return true
end
 
--[[
Test if the real part is zero.
--]]
 
mtq["is_imaginary"] = function (q)
    if q.x ~= 0 then
        return false
    end
    return true
end
 
--[[
Normalise a quaternion to have length 1, safely.  Here "safely" means
that we ensure that we do not have NaNs or infs.  If we do, the
returned quaternion is the unit.
--]]
 
mtq["normalise"] = function (q)
    q = q:normalize()
    if q:is_finite() then
        return q
    else
        return vec4(1,0,0,0)
    end
end
 
--[[
Spherical length and distance.
--]]
 
mtq["slen"] = function(q)
    q = q:normalise()
    q.x = q.x - 1
    return 2*asin(q:len()/2)
end
 
mtq["sdist"] = function(q,qq)
    q = q:normalise()
    qq = qq:normalise()
    return 2*asin(q:dist(qq)/2)
end
 
--[[
Add two quaternions inline, including promotion of a number.
 
q + p
--]]
 
local __add = mtq["__add"]
 
mtq["__add"] = function (a,b)
    if is_a(a,"number") then
        a = vec4(a,0,0,0)
    end
    if is_a(b,"number") then
        b = vec4(b,0,0,0)
    end
    return __add(a,b)
end
 
--[[
Same for inline subtraction.
 
q - p
--]]
 
local __sub = mtq["__sub"]
 
mtq["__sub"] = function (a,b)
    if is_a(a,"number") then
        a = vec4(a,0,0,0)
    end
    if is_a(b,"number") then
        b = vec4(b,0,0,0)
    end
    return __sub(a,b)
end
 
--[[
For inline multiplication, we also allow multiplication by a matrix.
In this case, we use the fact that we're viewing quaternions as
rotations and matrices as affine transformations, so the best result
of multiplication is as the matrix representing the appropriate
composition.
 
q * p
--]]
 
local __mul = mtq["__mul"]
 
mtq["__mul"] = function (a,b)
    if is_a(a,"number") then
        return __mul(a,b)
    end
    if is_a(b,"number") then
        return __mul(a,b)
    end
    if is_a(a,matrix) then
        return a:__mul(b:tomatrixleft())
    end
    if is_a(b,matrix) then
        a = a:tomatrixleft()
        return a:__mul(b)
    end
    local x,y,z,w
    x = a.x * b.x - a.y * b.y - a.z * b.z - a.w * b.w
    y = a.x * b.y + a.y * b.x + a.z * b.w - a.w * b.z
    z = a.x * b.z - a.y * b.w + a.z * b.x + a.w * b.y
    w = a.x * b.w + a.y * b.z - a.z * b.y + a.w * b.x
    return vec4(x,y,z,w)
end
 
--[[
Conjugation (corresponds to inverting a rotation).
--]]
 
mtq["conjugate"] = function (q)
    return vec4(q.x, - q.y, - q.z, - q.w)
end
 
mtq["co"] = mtq["conjugate"]
 
--[[
Inline division, including division of and by a number.
--]]
 
local __div = mtq["__div"]
 
mtq["__div"] = function (a,b)
    if is_a(b,"number") then
        return __div(a,b)
    end
    local l = b:lenSqr()
    b = vec4(b.x/l,-b.y/l,-b.z/l,-b.w/l)
    if is_a(a,"number") then
        return vec4(a*b.x,a*b.y,a*b.z,a*b.w)
    end
    local x,y,z,w
    x = a.x * b.x - a.y * b.y - a.z * b.z - a.w * b.w
    y = a.x * b.y + a.y * b.x + a.z * b.w - a.w * b.z
    z = a.x * b.z - a.y * b.w + a.z * b.x + a.w * b.y
    w = a.x * b.w + a.y * b.z - a.z * b.y + a.w * b.x
    return vec4(x,y,z,w)
end
 
--[[
Powers.  Integer powers are defined iteratively.  Non-integer powers
use the slerp function.
 
TODO: test whether the slerp is faster than the iterative method for
integer powers as well.
--]]
 
local function intpower(q,n)
    if n == 0 then
        return vec4(1,0,0,0)
    elseif n > 0 then
       return q:__mul(intpower(q,n-1))
    elseif n < 0 then
       local l = q:lenSqr()
       q = vec4(q.x/l,-q.y/l,-q.z/l,-q.w/l)
       return q:intpower(-n)
    end
end
 
local function power(q,n)
   if n == floor(n) then
      return intpower(q,n)
   end
   local l = q:len()
   q = q:normalise()
   return l^n * q:slerp(n)
end
 
--[[
Inline exponentiation.
 
q^n
 
The behaviour depends on the type of the exponent:
 
* number: compute the power.
* vec4: conjugate by the exponent.
* other: return the conjugate.
--]]
 
mtq["__pow"] = function (q,n)
    if is_a(n,"number") then
        return power(q,n)
    elseif is_a(n,vec4) then
        return n:__mul(q):__div(n)
    else
        return q:conjugate()
    end
end
 
--[[
Interpolation functions, we assume the input to be already normalised
for speed.  If you cannot guarantee this, renormalise the input first.
The constructor functions do do the renormalisation.
 
Parameters:
q initial rotation
qq final rotation
t parameter (only for the direct functions)
 
If the input does not provide enough parameters, it is assumed that
the missing one is the initial rotation and that this should be taken
to be the identity rotation (represented by vec4(1,0,0,0)).
--]]
 
 
--[[
Linear interpolation, renormalised.
--]]
 
mtq["lerp"] = function (q,qq,t)
    if not t then
        return vec4(1,0,0,0):lerp(q,qq)
    end
    local v
    if (q + qq):len() == 0 then
        -- antipodal points, need a midpoint
        v = vec4(q.y,-q.x,q.w,-q.z)
        v = (1 - 2*t)*q + (1-abs(2*t-1))*v
    else
        v = (1-t)*q + t*qq
    end
    return v:normalise()
end
 
--[[
Spherical interpolation.
 
We have to be quite careful here not to emit anything with NaNs or
infs as there are several opportunities to create them due to the
limits of finite precision mathematics.
--]]
 
mtq["slerp"] = function (q,qq,t)
    if not t then
        return vec4(1,0,0,0):slerp(q,qq)
    end
    local v
    if (q + qq):len() == 0 then
        -- antipodal points, need a midpoint
        v = vec4(q.y,-q.x,q.w,-q.z)
        t = 2*t
    elseif (q - qq):len() == 0 then
        return q
    else
        v = qq
    end
    local ca = q:dot(v)
    local sa = sqrt(1 - pow(ca,2))
    if sa == 0 or sa ~= sa then
        return q
    end
    local a = acos(ca)
    sa = sin(a*t)/sa
    v = (cos(a*t) - ca*sa)*q+ sa*v
    return v
end
 
--[[
Constructor for normalised linear interpolation.
--]]
 
mtq["make_lerp"] = function (q,qq)
    if not qq then
        return vec4(1,0,0,0):make_lerp(q)
    end
    local v,w
    w = q:normalise()
    if (q + qq):len() == 0 then
        -- antipodal points, need a midpoint
        v = vec4(w.y,-w.x,w.w,-w.z)
        return function(t)
            local u = (1 - 2*t)*w + (1-abs(2*t-1))*v
            return u:normalise()
        end
    else
        v = qq:normalise()
        return function(t)
            local u = (1-t)*w + t*v
            return u:normalise()
        end
    end
end
 
--[[
Spherical interpolation
--]]
 
mtq["make_slerp"] = function (q,qq)
    if not qq then
        q,qq = vec4(1,0,0,0),q
    end
    local v,f,u
    if (q + qq):len() == 0 then
        -- antipodal points, need a midpoint
        v = vec4(q.y,-q.x,q.w,-q.z)
        f = 2
    elseif (q - qq):len() == 0 then
        return function(t)
            return q
        end
    else
        v = qq
        f = 1
    end
    v = v:normalise()
    u = q:normalise()
    local ca = u:dot(v)
    local sa = sqrt(1 - pow(ca,2))
    if sa == 0 or sa ~= sa then
        return function(t)
            return q
        end
    end
    local a = acos(ca)
    v = (v - ca*q)/sa
    return function(t)
        return cos(a*f*t)*q + sin(a*f*t)*v
    end
end
 
--[[
Returns the real part.
--]]
 
mtq["toreal"] = function (q)
    return q.x
end
 
--[[
Returns the vector (imaginary) part as a vec3 object.
--]]
 
mtq["vector"] = function (q)
    return vec3(q.y, q.z, q.w)
end
 
mtq["tovector"] = mtq["vector"]
 
mtq["log"] = function (q)
    local l = q:slen()
    local v = q:tovector()
    v = v:normalize()
    if not v:is_finite() then
        return vec3(0,0,0)
    else
        return v * l
    end
end
                                    
--[[
Represents a quaternion as a string.
--]]
 
mtq["tostring"] = function (q)
    local s
    local im = {{q.y,"i"},{q.z,"j"},{q.w,"k"}}
    if q.x ~= 0 then
        s = string.format("%.3f",q.x)
    end
    for k,v in pairs(im) do
    if v[1] ~= 0 then
        if s then 
                if v[1] > 0 then
                    if v[1] == 1 then
                        s = s .. " + " .. v[2]
                    else
                        s = s .. " + " .. 
                        string.format("%.3f",v[1]) .. v[2]
                    end
                else
                    if v[1] == -1 then
                        s = s .. " - " .. v[2]
                    else
                        s = s .. " - " .. 
                        string.format("%.3f",-v[1]) .. v[2]
                    end
                end
        else
                if v[1] == 1 then
                    s = v[2]
                elseif v[1] == - 1 then
                    s = "-" .. v[2]
                else
                    s = string.format("%.3f",v[1]) .. v[2]
                end
        end
    end
    end
    if s then
        return s
    else
        return "0"
    end
end
 
 
mtq["__concat"] = function (q,s)
    if is_a(s,"string") then
        return q:tostring() .. s
    else
        return q .. s:tostring()
    end
end
 
--[[
Converts the quaternion to a matrix.
 
We distinguish between left and right actions.  A rotation matrix
acting on the right is the transpose of the matrix on the left.
--]]
 
mtq["tomatrixleft"] = function (q)
    q = q:normalise()
    local a,b,c,d = q.x,q.y,q.z,q.w
    local ab = 2*a*b
    local ac = 2*a*c
    local ad = 2*a*d
    local bb = 2*b*b
    local bc = 2*b*c
    local bd = 2*b*d
    local cc = 2*c*c
    local cd = 2*c*d
    local dd = 2*d*d
    return matrix(
        1 - cc - dd,
        bc - ad,
        ac + bd,
        0,
        bc + ad,
        1 - bb - dd,
        cd - ab,
        0,
        bd - ac,
        cd + ab,
        1 - bb - cc,
        0,
        0,0,0,1
    )
end
 
mtq["tomatrixright"] = function (q)
    q = q:normalise()
    local a,b,c,d = q.x,-q.y,-q.z,-q.w
    local ab = 2*a*b
    local ac = 2*a*c
    local ad = 2*a*d
    local bb = 2*b*b
    local bc = 2*b*c
    local bd = 2*b*d
    local cc = 2*c*c
    local cd = 2*c*d
    local dd = 2*d*d
    return matrix(
        1 - cc - dd,
        bc - ad,
        ac + bd,
        0,
        bc + ad,
        1 - bb - dd,
        cd - ab,
        0,
        bd - ac,
        cd + ab,
        1 - bb - cc,
        0,
        0,0,0,1
    )
end
 
mtq["tomatrix"] = mtq["tomatrixright"]
 
--[[
Converts the quaternion to an "angle-axis" representation.
--]]
 
mtq["toangleaxis"] = function (q)
    q = q:normalise()
    local a = 2*acos(q.x)
    local v = vec3(q.y,q.z,q.w)
    if v == vec3(0,0,0) then
        return 0,vec3(0,0,1)
    end
    return a,v:normalise()
end
 
--[[
The following code modifies various of Codea's functions to enable
them to take a quaternion as input.  We have to be careful as for some
passing nil is distinct to passing an empty input.
 
The other issue is as to the distinction between left and right
actions of matrices.  In OpenGL, matrices act on the right.  However,
in standard linear algebra, the convention is for matrices to act on
the left.
--]]
 
local __modelMatrix = modelMatrix
 
function modelMatrix(m)
    if m then
        if is_a(m,vec4) then
            m = m:tomatrixright()
        end
        return __modelMatrix(m)
    else
        return __modelMatrix()
    end
end
 
local __applyMatrix = applyMatrix
 
function applyMatrix(m)
    if m then
        if is_a(m,vec4) then
            m = m:tomatrixright()
        end
        return __applyMatrix(m)
    else
        return __applyMatrix()
    end
end
 
local __viewMatrix = viewMatrix
 
function viewMatrix(m)
    if m then
        if is_a(m,vec4) then
            m = m:tomatrixright()
        end
        return __viewMatrix(m)
    else
        return __viewMatrix()
    end
end
 
local __projectionMatrix = projectionMatrix
 
function projectionMatrix(m)
    if m then
        if is_a(m,vec4) then
            m = m:tomatrixright()
        end
        return __projectionMatrix(m)
    else
        return __projectionMatrix()
    end
end
 
local __rotate = rotate
 
function rotate(a,x,y,z)
    if is_a(a,vec4) then
        local v
        a,v = a:toangleaxis()
        x,y,z = v.x,v.y,v.z
        a = a*180/pi
    end
    return __rotate(a,x,y,z)
end
 
local __translate = translate
 
function translate(x,y,z)
    if not y then
        x,y,z = x.x,x.y,x.z
    end
    return __translate(x,y,z)
end
                                    
 
local __scale = scale
 
function scale(a,b,c)
    if is_a(a,vec3) then
        a,b,c = a.x,a.y,a.z
    end
    if c then
        return __scale(a,b,c)
    end
    if b then
        return __scale(a,b)
    end
    if a then
        return __scale(a)
    end
end
                                    
local __camera = camera
 
function camera(a,b,c,d,e,f,g,h,i)
    if is_a(a,vec3) then
        a,b,c,d,e,f,g,h,i = a.x,a.y,a.z,b,c,d,e,f,g                              
    end
    if is_a(d,vec3) then
        d,e,f,g,h,i = d.x,d.y,d.z,e,f,g
    end
    if is_a(g,vec3) then
        g,h,i = g.x,g.y,g.z
    end
    if g then
        return __camera(a,b,c,d,e,f,g,h,i)
    elseif d then
        return __camera(a,b,c,d,e,f)
    elseif a then
        return __camera(a,b,c)
    else
        return __camera()
    end
end
 
--[[
We also define some extensions to the vec3 type.
--]]
 
local mt = getmetatable(vec3())
 
-- Same as for vec4.
mt["is_finite"] = function(v)
    if v.x < math.huge and v.x > -math.huge 
        and v.y < math.huge and v.y > -math.huge 
        and v.z < math.huge and v.z > -math.huge 
    then
        return true
    end
    return false
end
 
--[[
Promote to a quaternion with 0 real part.
--]]
 
mt["toQuaternion"] = function (v)
    return vec4(0,v.x,v.y,v.z)
end
 
--[[
Apply a quaternion as a rotation (assumes unit quaternion for speed)
using conjugation.
--]]
 
mt["applyQuaternion"] = function (v,q)
   v = v:toQuaternion()
    v = q:__mul(v)
    v = v:__mul(q:conjugate())
    return v:vector()
end
 
-- There is no native rotate method for a vec3.
mt["rotate"] = function(v,q,x,y,z)
    if is_a(q,"number") then
        q = qRotation(q,x,y,z)
    end
    return v:applyQuaternion(q)
end
 
-- We use the exponential notation for writing the action of a
-- quaternion on a vector (this is consistent with group theory
-- notation).
mt["__pow"] = function (v,q)
    if is_a(q,vec4) then
        return v:applyQuaternion(q)
    end
    return false
end
 
mt["__concat"] = function (u,s)
    if is_a(s,"string") then
        return u:__tostring() .. s
    else
        return u .. s:__tostring()
    end
end
 
--[[
The rotateTo method produces a rotation that rotates the first vector
to the second about an axis that is perpendicular to both.  So long as
the two are not collinear, the axis is unique.  The angle is taken to
be the smallest angle.  If the vectors point in opposite directions,
an orthogonal axis is chosen in such a way as to minimise precision
error.
 
TODO: Allow for a third parameter to specify the axis in case of
ambiguity.
--]]
mt["rotateTo"] = function (u,v)
    if v:lenSqr() == 0 or u:lenSqr() == 0 then
        return vec4(1,0,0,0)
    end
    u = u:normalise()
    v = u + v:normalise()
    if v:lenSqr() == 0 then
        -- Opposite vectors, no canonical direction
        local a,b,c = abs(u.x), abs(u.y), abs(u.z)
        if a < b and a < c then
            v = vec3(0,-u.z,u.y)
        elseif b < c then
            v = vec3(u.z,0,-u.x)
        else
            v = vec3(u.y,-u.x,0)
        end
    end
    v = v:normalise()
    local d = u:dot(v)
    u = u:cross(v)
    return vec4(d,u.x,u.y,u.z)
end
 
--[[
Safe renormalisation, as for quaternions.  Except that there is no
"cannonical" unit vec3, so we return the unit vector in the z
direction.  The rationale for that is that if this is an axis, this
vector represents the axis out of the screen.
--]]
mt["normalise"] = function (v)
    v = v:normalize()
    if v:is_finite() then
        return v
    else
        return vec3(0,0,1)
    end
end
 
--[[
Inline multiplication extended to allow for multiplication by a matrix.
 
We interpret the vec3 as vertical or horizontal depending on whether
the matrix is on the right or left.  Multiplication by a matrix is
viewed as applying an affine transformation.
--]]
local __mulv = mt["__mul"]
 
mt["__mul"] = function(m,v)
    if is_a(m,vec3) and is_a(v,"number") then
        return __mulv(m,v)
    end
    if is_a(m,"number") and is_a(v,vec3) then
        return __mulv(m,v)
    end
    if is_a(m,vec3) and is_a(v,vec3) then
        return vec3(m.x*v.x,m.y*v.y,m.z*v.z)
    end
    if is_a(m,matrix) and is_a(v,vec3) then
        local l = m[13]*v.x + m[14]*v.y + m[15]*v.z + m[16]
        return vec3(
            (m[1]*v.x + m[2]*v.y + m[3]*v.z + m[4])/l,
            (m[5]*v.x + m[6]*v.y + m[7]*v.z + m[8])/l,
            (m[9]*v.x + m[10]*v.y + m[11]*v.z + m[12])/l
        )
    end
    if is_a(m,vec3) and is_a(v,matrix) then
       m,v = v,m
        local l = m[4]*v.x + m[8]*v.y + m[12]*v.z + m[16]
        return vec3(
            (m[1]*v.x + m[5]*v.y + m[9]*v.z + m[13])/l,
            (m[2]*v.x + m[6]*v.y + m[10]*v.z + m[14])/l,
            (m[3]*v.x + m[7]*v.y + m[11]*v.z + m[15])/l
        )
    end
end
 
local __addv = mt["__add"]
 
mt["__add"] = function(a,b)
    if is_a(a,"number") then
        a = vec3(a,a,a)
    end
    if is_a(b,"number") then
        b = vec3(b,b,b)
    end
    return __addv(a,b)
end
 
local __subv = mt["__sub"]
 
mt["__sub"] = function(a,b)
    if is_a(a,"number") then
        a = vec3(a,a,a)
    end
    if is_a(b,"number") then
        b = vec3(b,b,b)
    end
    return __subv(a,b)
end
                    
 
--[[
Extensions to the matrix class.
--]]
local mtm = getmetatable(matrix())
 
--[[
Inline multiplication by either quaternion or vector.
--]]
local __mulm = mtm["__mul"]
 
mtm["__mul"] = function (m,mm)
    if is_a(m,matrix) and is_a(mm,matrix) then
        return __mulm(m,mm)
    end
    if is_a(m,matrix) and is_a(mm,vec4) then
        return __mulm(m,mm:tomatrix())
    end
    if is_a(m,vec4) and is_a(mm,matrix) then
        return __mulm(m:tomatrix(),mm)
    end
    if is_a(m,matrix) and is_a(mm,vec3) then
        local l = m[13]*mm.x + m[14]*mm.y + m[15]*mm.z + m[16]
        return vec3(
            (m[1]*mm.x + m[2]*mm.y + m[3]*mm.z + m[4])/l,
            (m[5]*mm.x + m[6]*mm.y + m[7]*mm.z + m[8])/l,
            (m[9]*mm.x + m[10]*mm.y + m[11]*mm.z + m[12])/l
        )
    end
    if is_a(m,vec3) and is_a(mm,matrix) then
        local l = mm[4]*m.x + mm[8]*m.y + mm[12]*m.z + mm[16]
        return vec3(
            (mm[1]*m.x + mm[5]*m.y + mm[9]*m.z + mm[13])/l,
            (mm[2]*m.x + mm[6]*m.y + mm[10]*m.z + mm[14])/l,
            (mm[3]*m.x + mm[7]*m.y + mm[11]*m.z + mm[15])/l
        )
    end
end
 
-- Extending the rotate method to take a quaternion.
local __mrotate = mtm["rotate"]
 
mtm["rotate"] = function(m,a,x,y,z)
    if is_a(a,vec4) then
        a,x = a:toangleaxis()
        x,y,z = x.x,x.y,x.z
    end
    return __mrotate(m,a,x,y,z)
end
 
 
--[[
The following functions are intended to be more "user friendly" and
provide solutions to common problems.
 
The primary functions construct a rotation dependent on some initial
data.  The simplest are to define a rotation from some other method of
specifying rotations: angle-axis or Euler angles.  More complicated
are methods to define a rotation by giving two (orthogonal) frames and
computing the rotation to get from the first to the last.  In
particular, there are certain common frames that might be expected to
be used frequently:
 
1. The initial orientation of the iPad.
 
2. A gravitational frame wherein the Gravity vector is "straight
down".  This is not completely defined as there is currently no way to
choose a corresponding horizontal direction (access to the compass
would provide this).  Two possibilities are: to choose the x-axis so
that it is always in the plane of the iPad, and to use RotationRate to
try to keep track of the initial x-axis.
 
3. A "DeltaOrientation" in which the change in orientation from one
frame to the next is used (this uses RotationRate).
 
There are obvious limits in accuracy in using these.
--]]
 
--[[
Returns a quaternion corresponding to the current gravitational vector
so that after applying the corresponding rotation, the y-axis points
in the gravitational direction and the x-axis is in the plane of the
iPad screen.
 
When we have access to the compass, the x-axis behaviour might change.
--]]
 
local function qGravity()
    local gxy, gy, gygxy, a, b, c, d
    if Gravity.x == 0 and Gravity.y == 0 then
        return vec4(1,0,0,0)
    else
        gy = - Gravity.y
        gxy = sqrt(pow(Gravity.x,2) + pow(Gravity.y,2))
        gygxy = gy/gxy
        a = sqrt(1 + gxy - gygxy - gy)/2
        b = sqrt(1 - gxy - gygxy + gy)/2
        c = sqrt(1 - gxy + gygxy - gy)/2
        d = sqrt(1 + gxy + gygxy + gy)/2
        if Gravity.y > 0 then
                a = a
                b = b
        end
        if Gravity.z < 0 then
                b = - b
                c = - c
        end
        if Gravity.x > 0 then
                c = - c
                d = - d
        end
        return vec4(a,b,c,d)
    end
end
 
function qrGravity(q)
    local qg,qx
    if not q then
        qx = ReferenceFrame()
    else
        qx = q
    end
    local y = vec3(0,-1,0)^qx
    qg = y:rotateTo(Gravity)
    return qg*qx
end
 
mtq["gravity"] = qrGravity
 
local frame = {
        vec3(1,0,0),
        vec3(0,1,0),
        vec3(0,0,1)
    }
local qzyx = vec4(1,0,0,0)
 
--[[
Needs to be run once every frame!
--]]
 
function updateReferenceFrame(q)
    local x,y,z
    --[[
    if CurrentOrientation == PORTRAIT then
        x,y,z = -frame[1],-frame[2],-frame[3]
    elseif CurrentOrientation == PORTRAIT_UPSIDE_DOWN then
        x,y,z = frame[1],frame[2],-frame[3]
    elseif CurrentOrientation == LANDSCAPE_LEFT then
        x,y,z = frame[2],-frame[1],-frame[3]
    elseif CurrentOrientation == LANDSCAPE_RIGHT then
        x,y,z = -frame[2],frame[1],-frame[3]
    end
    --]]
    x,y,z = unpack(frame)
    local qz = qRotation(RotationRate.z*DeltaTime,z.x,z.y,z.z)
    local qy = qRotation(RotationRate.y*DeltaTime,y.x,y.y,y.z)
    local qx = qRotation(RotationRate.x*DeltaTime,x.x,x.y,x.z)
    if q then
        local qq = qz * qy * qx * q
        q.x,q.y,q.z,q.w = qq.x,qq.y,qq.z,qq.w
    else
        qzyx = qz * qy * qx * qzyx
        return qzyx
    end
end
 
function ReferenceFrame(q)
    return q or qzyx
end
 
mtq["updateReferenceFrame"] = updateReferenceFrame
mtq["ReferenceFrame"] = ReferenceFrame
 
--[[
Converts a rotation to a quaternion.  The first argument is the angle
to rotate, the rest must specify an axis, either as a Vec3 object or
as three numbers.
--]]
 
function qRotation(a,x,y,z)
    local q,c,s
    if not y then
        x,y,z = x.x,x.y,x.z
    end
    q = vec4(0,x,y,z)
    q = q:normalise()
    if q == vec4(1,0,0,0) then
        return q
    end
    c = cos(a/2)
    s = sin(a/2)
    q = q:__mul(s)
    q = q:__add(c)
    return q
end
 
--[[
The qEuler function handles conversion from Euler angles.  As there
are many ways to specify Euler angles, we have to allow for quite a
variety.  The table __euler contains the code necessary for allowing
all of this flexibility.
 
The last parameter is the specification, which is a table taken from
the alphabet "xXyYzZ".  This ought to correspond to the axes of
rotation, using lowercase to mean the absolute frame and uppercase to
mean the transformed frame.
 
TODO: Test this.
 
If only two parameters are passed, the first is taken to be a vec3 or
a table containing the Euler angles.
--]]
 
local __euler = {}
__euler.x = function(q)
    return vec3(1,0,0)^q
end
__euler.X = function(q)
    return vec3(1,0,0)
end
__euler.y = function(q)
    return vec3(0,1,0)^q
end
__euler.Y = function(q)
    return vec3(0,1,0)
end
__euler.z = function(q)
    return vec3(0,0,1)^q
end
__euler.Z = function(q)
    return vec3(0,0,1)
end
 
function qEuler(a,b,c,v)
    if c then
        a = {a,b,c}
    else
        if is_a(a,vec3) then
            a = {a.x,a.y,a.z}
        end
        v = b
    end
    v = v or {"x","y","z"}
    local q = vec4(1,0,0,0)
    local w
    for k,u in ipairs(v) do
        w = __euler[u](q)
        q = q * qRotation(a[k],w)
    end
    return q
end
 
-- v is a tangent vector at the identity
function qTangent(x,y,z,t)
    local q
    if is_a(x,"number") then
        q = vec4(0,x,y,z)
        t = t or 1
    else
        q = vec4(0,x.x,x.y,x.z)
        t = y or 1
    end
    local qn = q:normalise()
    if qn == vec4(1,0,0,0) then
        return qn
    end
    local a = t * q:len() --/2
    return cos(a)*vec4(1,0,0,0) + sin(a)*qn
end
 
mt["exp"] = qTangent
 
function qRotationRate()
    return qTangent(DeltaTime * RotationRate)
end
 
local iGravity = vec3(0,-1,0)
Frame = {
    Roll = vec4(1,0,0,0),
    Pitch = vec4(1,0,0,0),
    Yaw = vec4(1,0,0,0),
    Gravity = vec4(1,0,0,0),
    Rotation = vec4(1,0,0,0),
    AdjustedRotation = vec4(1,0,0,0),
    RotationRate = vec4(1,0,0,0)
}
 
local update_fn 
update_fn = function()
    local q = vec3(iGravity.x,iGravity.y,0):rotateTo(
            vec3(Gravity.x,Gravity.y,0))
    Frame.Roll.x = q.x
    Frame.Roll.y = q.y
    Frame.Roll.z = q.z
    Frame.Roll.w = q.w
    q = vec3(0,iGravity.y,iGravity.z):rotateTo(
            vec3(0,Gravity.y,Gravity.z))
    Frame.Pitch.x = q.x
    Frame.Pitch.y = q.y
    Frame.Pitch.z = q.z
    Frame.Pitch.w = q.w
    q = vec3(iGravity.x,0,iGravity.z):rotateTo(
            vec3(Gravity.x,0,Gravity.z))
    Frame.Yaw.x = q.x
    Frame.Yaw.y = q.y
    Frame.Yaw.z = q.z
    Frame.Yaw.w = q.w
    q = iGravity:rotateTo(Gravity)
    Frame.Gravity.x = q.x
    Frame.Gravity.y = q.y
    Frame.Gravity.z = q.z
    Frame.Gravity.w = q.w
    q = vec4(0,RotationRate.x,RotationRate.y,RotationRate.z)
    local qn = q:normalise()
    if qn ~= vec4(1,0,0,0) then
        local a = q:len()*DeltaTime/2
        qn = cos(a)*vec4(1,0,0,0) + sin(a)*qn
    end
    Frame.RotationRate.x = qn.x
    Frame.RotationRate.y = qn.y
    Frame.RotationRate.z = qn.z
    Frame.RotationRate.w = qn.w
    q = qn*Frame.Rotation
    Frame.Rotation.x = q.x
    Frame.Rotation.y = q.y
    Frame.Rotation.z = q.z
    Frame.Rotation.w = q.w
    q = qn*Frame.AdjustedRotation
    local g = iGravity^(q)
    qn = g:rotateTo(iGravity)
    q = q*qn
    Frame.AdjustedRotation.x = q.x
    Frame.AdjustedRotation.y = q.y
    Frame.AdjustedRotation.z = q.z
    Frame.AdjustedRotation.w = q.w
    tween.delay(0,update_fn)
end
    
 
tween.delay(.5,function()
     iGravity = vec3(Gravity.x,Gravity.y,Gravity.z)
     tween.delay(0,update_fn)
     end)
 
--[[
A suite of test functions.
--]]
function testRotations()
    print("Rotation tests:")
    local tolerance = 10^(-6)
    local vars = [[local q1,q2,i,j,k
    q1 = vec4(1,2,3,4)
    q2 = vec4(.5,.5,-.5,-.5)
    i = vec4(0,1,0,0)
    j = vec4(0,0,1,0)
    k = vec4(0,0,0,1)
    q3 = vec4(1/math.sqrt(2),0,0,1/math.sqrt(2))
    v1 = vec3(1,0,0)
    v2 = vec3(0,1,0)
    v3 = vec3(1,-1,2)
    m = matrix(
        10,10,5,1,
        4,6,4,1,
        1,3,3,1,
        0,1,2,1
    )
    return ]]
    local tests = {
        {"q1 * q2", vec4(3,2,4,-1)},
        {"q1 + q2", vec4(1.5,2.5,2.5,3.5)},
        {"q1 - q2", vec4(.5,1.5,3.5,4.5)},
        {"q1 / q2", vec4(-2,0,-1,5)},
        {"q1^q2", vec4(1,-4,-2,3)},
        {"q1^\"\"", vec4(1,-2,-3,-4)},
        {"i * j", vec4(0,0,0,1)},
        {"j * k", vec4(0,1,0,0)},
        {"k * i", vec4(0,0,1,0)},
        {"v1^q3", vec3(0,1,0)},
        {"q3:tomatrixleft()*v1", vec3(0,1,0)},
        {"v1:rotate(q3)", vec3(0,1,0)},
        {"v2^q3", vec3(-1,0,0)},
        {"q3:tomatrixleft()*v2", vec3(-1,0,0)},
        {"v2:rotate(q3)", vec3(-1,0,0)},
        {"qRotation(math.pi/2,0,0,1)", vec4(1/math.sqrt(2),0,0,1/math.sqrt(2))},
        {"v1:rotateTo(v2)", vec4(1/math.sqrt(2),0,0,1/math.sqrt(2))},
        {"v3 * m", vec3(8,11,9)/3},
        {"m * v3", vec3(11,7,5)/4}
    }
    local t,a,m,n,tn
    tn,n = 0,0
    for k,u in ipairs(tests) do
        tn = tn + 1
        t = loadstring(vars .. u[1])
        a = t()
        if a == u[2] then
            m = "OK"
            n = n + 1
        elseif a.dist and a:dist(u[2]) < tolerance then
            m = "OK (" .. a:dist(u[2]) .. ")"
            n = n + 1
        else
            m = "not OK (expected " .. u[2] .. ")"
        end
        print(u[1] .. " = " .. a .. " : " .. m)
    end
    print(n .. " tests passed out of " .. tn)
end
 
 
 
 



--]==]