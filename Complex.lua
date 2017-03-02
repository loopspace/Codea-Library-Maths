--[==[
-- Complex numbers class
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

--[[
This is a class for handling complex numbers.
--]]

local Complex = class()

Complex.symbol = readLocalData("Complex Symbol","i")
local radeg = readLocalData("Complex Angle","rad")
if radeg == "rad" then
    Complex.angle = 1
    Complex.angsym = "π"
else
    Complex.angle = 180
    Complex.angsym = "°"
end
Complex.precision = readLocalData("Complex Precision",2)


--[[
A complex number can either be specified by giving the two
coordinates as real numbers or by giving a vector.
--]]


function Complex:init(...)
    -- you can accept and set parameters here
    if arg.n == 2 then
        -- two numbers
        self.z = vec2(arg[1],arg[2])
    elseif arg.n == 1 then
        -- vector
        self.z = arg[1]
    else
        print("Incorrect number of arguments to Complex")
    end
end

function Complex:clone(z)
    return Complex(z:real(),z:imaginary())
end

--[[
Test if we are zero.
--]]

function Complex:is_zero()
    -- are we the zero vector
    if self.z ~= vec2(0,0) then
        return false
    end
    return true
end

--[[
Test if we are real.
--]]

function Complex:is_real()
    -- are we the zero vector
    if self.z.y ~= 0 then
        return false
    end
    return true
end

--[[
Test if the real part is zero.
--]]

function Complex:is_imaginary()
    -- are we the zero vector
    if self.z.x ~= 0 then
        return false
    end
    return true
end

--[[
Test for equality.
--]]

function Complex:is_eq(q)
    if self.z ~= q.z then
        return false
    end
    return true
end

--[[
Defines the "==" shortcut.
--]]

function Complex:__eq(q)
    return self:is_eq(q)
end

--[[
The inner product of two complex numbers.
Why did I program this?
--]]

function Complex:dot(q)
    return self.z:dot(q.z)
end

--[[
Length of a complex number.
--]]

function Complex:len()
    return self.z:len()
end

--[[
Often enough to know the length squared, which is quicker.
--]]

function Complex:lensq()
    return self.z:lenSqr()
end

--[[
Distance between two complex numbers.
--]]

function Complex:dist(w)
    return self.z:dist(w.z)
end

--[[
Often enough to know the distance squared, which is quicker.
--]]

function Complex:distSqr(w)
    return self.z:distSqr(w.z)
end

--[[
Normalise a complex number to have length 1, if possible.
--]]

function Complex:normalise()
    local l
    if self:is_zero() then
        print("Unable to normalise a zero-length complex number")
        return false
    end
    l = 1/self:len()
    return self:scale(l)
end

--[[
Scale the complex number.
--]]

function Complex:scale(l)
    return Complex(l * self.z)
end

--[[
Add two complex numbers.  Or add a real number to a complex one.
--]]

function Complex:add(q)
    if type(q) == "number" then
        return Complex(self.z + vec2(q,0))
    else
        return Complex(self.z + q.z)
    end
end

--[[
q + p
--]]

function Complex:__add(q)
    if type(self) == "number" then
        return q:add(self)
    else
        return self:add(q)
    end
end

--[[
Subtraction
--]]

function Complex:subtract(q)
    if type(q) == "number" then
        return Complex(self.z - vec2(q,0))
    else
        return Complex(self.z - q.z)
    end
end

--[[
q - p
--]]

function Complex:__sub(q)
    if type(self) == "number" then
        return q:subtract(self):scale(-1)
    else
        return self:subtract(q)
    end
end

--[[
Negation (-q)
--]]

function Complex:__unm()
    return self:scale(-1)
end

--[[
Length (#q)
--]]

function Complex:__len()
    return self:len()
end

--[[
Multiplication.
--]]

function Complex:multiply(q)
    local a,b,c,d
    a = self.z.x
    b = self.z.y
    c = q.z.x
    d = q.z.y
    return Complex(a*c - b*d,a*d + b*c)
end

--[[
q * p
--]]

function Complex:__mul(q)
    if type(q) == "number" then
        return self:scale(q)
    elseif type(self) == "number" then
        return q:scale(self)
    elseif type(q) == "table" then
        if q:is_a(Complex) then
                return self:multiply(q)
        end
    end
end

--[[
Conjugation.
--]]

function Complex:conjugate()
    return Complex(self.z.x, - self.z.y)
end

function Complex:co()
    return self:conjugate()
end

--[[
Reciprocal: 1/q
--]]

function Complex:reciprocal()
    if self:is_zero() then
        print("Cannot reciprocate a zero complex number")
        return false
    end
    local q = self:conjugate()
    local l = self:lensq()
    q = q:scale(1/l)
    return q
end

--[[
Real powers.
--]]

function Complex:repower(n,k)
    local r = self.z:len()
    local t = -self.z:angleBetween(vec2(1,0))
    k = k or 0
    r = math.pow(r,n)
    t = (t + k * 2 * math.pi) *n
    return Complex:polar(r,t)
end

--[[
Complex powers.
--]]

function Complex:power(w,k)
    if type(w) == "number" then
        return self:repower(w,k)
    end
    if self:is_zero() then
        print("Taking powers of 0 is somewhat dubious")
        return false
    end
    local r = self.z:len()
    local t = -self.z:angleBetween(vec2(1,0))
    local u = w.z.x
    local v = w.z.y
    k = k or 0
    local nr = math.pow(r,u) * math.exp(-v*t)
    local nt = (t + k * 2 * math.pi) * u + math.log(r) * v
    return Complex:polar(nr,nt)
end

--[[
q^n

This is overloaded so that a non-(complex) number exponent returns
the conjugate.  This means that one can write things like q^"" to
get the conjugate of a complex number.
--]]

function Complex:__pow(n)
    if type(n) == "number" then
        return self:repower(n)
    elseif type(n) == "table" and n:is_a(Complex) then
        return self:power(n)
    else
        return self:conjugate()
    end
end

--[[
Division: q/p
--]]

function Complex:__div(q)
    if type(q) == "number" then
        return self:scale(1/q)
    elseif type(self) == "number" then
        return q:scale(1/self):reciprocal()
    elseif type(q) == "table" then
        if q:is_a(Complex) then
                return self:multiply(q:reciprocal())
        end
    end
end

--[[
Returns the real part.
--]]

function Complex:real()
    return self.z.x
end

--[[
Returns the imaginary part.
--]]

function Complex:imaginary()
    return self.z.y
end

--[[
Represents a complex number as a string.
--]]

Complex.precision = 2

function Complex:__concat(v)
    if type(v) == "table" 
        and v:is_a(Complex) then
            return self .. v:tostring()
        else
            return self:tostring() .. v
        end
end

function Complex:__tostring()
    return self:tostring()
end

function Complex:tostring()
    local s
    local x = math.floor(
        self.z.x * 10^Complex.precision +.5
        )/10^Complex.precision
    local y = math.floor(
        self.z.y * 10^Complex.precision +.5
        )/10^Complex.precision
    if x ~= 0 then
        s = x
    end
    if y ~= 0 then
        if s then 
                if y > 0 then
                    if y == 1 then
                        s = s .. " + " .. Complex.symbol
                    else
                        s = s .. " + " .. y .. Complex.symbol
                    end
                else
                    if y == -1 then
                        s = s .. " - " .. Complex.symbol
                    else
                        s = s .. " - " .. (-y) .. Complex.symbol
                    end
                end
        else
                if y == 1 then
                    s = Complex.symbol
                elseif y == - 1 then
                    s = "-" .. Complex.symbol
                else
                    s = y .. Complex.symbol
                end
        end
    end
    if s then
        return s
    else
        return "0"
    end
end

function Complex:topolarstring()
    local t = math.floor(Complex.angle *
        self:arg() * 10^Complex.precision/math.pi +.5
        )/10^Complex.precision
    local r = math.floor(
        self:len() * 10^Complex.precision +.5
        )/10^Complex.precision
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
    s = "(" .. r .. "," .. t .. Complex.angsym .. ")"
    return s
end

function Complex:arg()
    return -self.z:angleBetween(vec2(1,0))
end

function Complex:polar(r,t)
    return Complex(r * math.cos(t), r * math.sin(t))
end

--[[
The unit complex number.
--]]

function Complex.unit()
    return Complex(1,0)
end
function Complex.zero()
    return Complex(0,0)
end
function Complex.i()
    return Complex(0,-1)
end

--[[
Overload the maths functions
--]]

local __math = {}
for _,v in ipairs({
    "abs",
    "pow",
    "sqrt",
    "exp",
    "log",
    "sin",
    "cos",
    "sinh",
    "cosh",
    "tan",
    "tanh"
    }) do
    __math[v] = math[v]
end

function math.abs(n)
    if type(n) == "number" then return __math.abs(n) end
    if type(n) == "table"
        and n.is_a
        and n:is_a(Complex)
        then
            return n:len()
    end
    print("Cannot take the length of " .. n)
end

function math.pow(n,e)
    if type(n) == "number" then
        if type(e) == "number" then
             return __math.pow(n,e)
        elseif type(e) == "table"
        and e.is_a
        and e:is_a(Complex)
        then
            local w = Complex(n,0)
            return w:repower(e,0)
        end
    end
    if type(n) == "table"
        and n.is_a
        and n:is_a(Complex)
        then
            return n:power(e,0)
    end
    print("Cannot take the power of " .. n .. " by " .. e)
end

function math.sqrt(n)
    if type(n) == "number" then return __math.sqrt(n) end
    if type(n) == "table"
        and n.is_a
        and n:is_a(Complex)
        then
            return n:repower(.5,0)
    end
    print("Cannot take the square root of " .. n)
end

function math.exp(n)
    if type(n) == "number" then return __math.exp(n) end
    if type(n) == "table"
        and n.is_a
        and n:is_a(Complex)
        then
            return Complex:polar(math.exp(n:real()),n:imaginary())
    end
    print("Cannot exponentiate " .. n)
end

--[[
cos(x+iy) = cos(x) cos(iy) - sin(x) sin(iy)
          = cos(x) cosh(y) - i sin(x) sinh(y)
--]]

function math.cos(n)
    if type(n) == "number" then return __math.cos(n) end
    if type(n) == "table"
        and n.is_a
        and n:is_a(Complex)
        then
            local x = n:real()
            local y = n:imaginary()
            return Complex(__math.cos(x)*__math.cosh(y),-__math.sin(x)*__math.sinh(y))
    end
    print("Cannot take the cosine of " .. n)
end

--[[
sin(x+iy) = sin(x) cos(iy) + cos(x) sin(iy)
          = sin(x) cosh(y) + i cos(x) sinh(y)
--]]

function math.sin(n)
    if type(n) == "number" then return __math.sin(n) end
    if type(n) == "table"
        and n.is_a
        and n:is_a(Complex)
        then
            local x = n:real()
            local y = n:imaginary()
            return Complex(__math.sin(x)*__math.cosh(y), __math.cos(x)*__math.sinh(y))
    end
    print("Cannot take the sine of " .. n)
end

--[[
cosh(x+iy) = cosh(x) cosh(iy) + sinh(x) sinh(iy)
           = cosh(x) cos(y) + i sinh(x) sin(y)
--]]

function math.cosh(n)
    if type(n) == "number" then return __math.cosh(n) end
    if type(n) == "table"
        and n.is_a
        and n:is_a(Complex)
        then
            local x = n:real()
            local y = n:imaginary()
            return Complex(__math.cosh(x)*__math.cos(y), __math.sinh(x)*__math.sin(y))
    end
    print("Cannot take the hyperbolic cosine of " .. n)
end

--[[
sinh(x+iy) = sinh(x) cosh(iy) + cosh(x) sinh(iy)
          = sinh(x) cos(y) + i cosh(x) sin(y)
--]]

function math.sinh(n)
    if type(n) == "number" then return __math.sinh(n) end
    if type(n) == "table"
        and n.is_a
        and n:is_a(Complex)
        then
            local x = n:real()
            local y = n:imaginary()
            return Complex(__math.sinh(x)*__math.cos(y), __math.cosh(x)*__math.sin(y))
    end
    print("Cannot take the hyperbolic sine of " .. n)
end

--[[
tan(x+iy) = (sin(x) cos(x) + i sinh(y) cosh(y))
            /(cos^2(x) cosh^2(y) + sin^2(x) sinh^2(y))
--]]

function math.tan(n)
    if type(n) == "number" then return __math.tan(n) end
    if type(n) == "table"
        and n.is_a
        and n:is_a(Complex)
        then
            local x = n:real()
            local y = n:imaginary()
            local cx = __math.cos(x)
            local sx = __math.sin(x)
            local chy = __math.cosh(y)
            local shy = __math.sinh(y)
            local d = cx^2 * chy^2 + sx^2 * shy^2
            if d == 0 then
                return false
            end
            return Complex(sx*cx/d,shy*chy/d)
    end
    print("Cannot take the tangent of " .. n)
end

--[[
tanh(x+iy) = i tan(y - ix)
           = (sin(x) cos(x) + i sinh(y) cosh(y))
            /(cos^2(x) cosh^2(y) + sin^2(x) sinh^2(y))
           = (sinh(x) cosh(x) + i sin(y) cos(y))
            /(cos^2(y) cosh^2(x) + sin^2(y) sinh^2(x))
--]]

function math.tanh(n)
    if type(n) == "number" then return __math.tanh(n) end
    if type(n) == "table"
        and n.is_a
        and n:is_a(Complex)
        then
            local x = n:real()
            local y = n:imaginary()
            local cy = __math.cos(y)
            local sy = __math.sin(y)
            local chx = __math.cosh(x)
            local shx = __math.sinh(x)
            local d = cy^2 * chx^2 + sy^2 * shx^2
            if d == 0 then
                return false
            end
            return Complex(shx*chx/d,sy*cy/d)
    end
    print("Cannot take the hyperbolic tangent of " .. n)
end

--[[
log(r e^(i a)) = log(r) + i (a + 2 k pi)
--]]

function math.log(n,k)
    if type(n) == "number" then
        if k then
            return Complex(__math.log(n), 2*k*math.pi)
        else
            return __math.log(n)
        end
    end
    k = k or 0
    if type(n) == "table"
        and n.is_a
        and n:is_a(Complex)
        then
            return Complex(__math.log(n:len()),n:arg() + 2*k*math.pi)
    end
    print("Cannot take the logarithm of " .. n)
end

if cmodule.loaded "TestSuite" then
    
    testsuite.addTest({
        name = "Complex",
        setup = function()
    local z = Complex(2,4)
    local w = Complex(-1,1)
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

return Complex

--]==]
