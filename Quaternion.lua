--[==[
-- Quaternions
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

--[[
This is a class for handling quaternion numbers.  It was originally
designed as a way of encoding rotations of 3 dimensional space.
--]]

local Quaternion = class()

--[[
A quaternion can either be specified by giving the four coordinates as
real numbers or by giving the scalar part and the vector part.
--]]

local error = error or print

function Quaternion:init(...)
    -- you can accept and set parameters here
    if arg.n == 4 then
        -- four numbers
        self.q = vec4(arg[1],arg[2],arg[3],arg[4])
    elseif arg.n == 2 then
        -- real number plus vector
        self.q = vec4(arg[1],arg[2].x,arg[2].y,arg[2].z)
    elseif arg.n == 1 then
        if type(arg[1]) == "userdata" then
            self.q = vec4(arg[1].x,arg[1].y,arg[1].z,arg[1].w)
        elseif type(arg[1]) == "table" and arg[1].is_a and arg[1]:is_a(Quaternion) then
            self.q = vec4(arg[1].q.x,arg[1].q.y,arg[1].q.z,arg[1].q.w)
        else
            error("Incorrect type of argument to Quaternion")
        end
    else
        error("Incorrect number of arguments to Quaternion")
    end
end

--[[
Test if we are zero.
--]]

function Quaternion:is_zero()
    return self.q == vec4(0,0,0,0)
end

--[[
Test if we are real.
--]]

function Quaternion:is_real()
    -- are we the zero vector
    if self.q.y ~= 0 or self.q.z ~= 0 or self.q.w ~= 0 then
        return false
    end
    return true
end

--[[
Test if the real part is zero.
--]]

function Quaternion:is_imaginary()
    -- are we the zero vector
    if self.q.x ~= 0 then
        return false
    end
    return true
end

--[[
Test for equality.
--]]

function Quaternion:is_eq(q)
    return self.q == q.q
end

--[[
Defines the "==" shortcut.
--]]

function Quaternion:__eq(q)
    return self:is_eq(q)
end

--[[
The inner product of two quaternions.
--]]

function Quaternion:dot(q)
    return self.q:dot(q.q)
end

--[[
Makes "q .. p" return the inner product.

Probably a bad choice and likely to be removed in future versions.


function Quaternion:__concat(q)
    return self:dot(q)
end
--]]
--[[
Length of a quaternion.
--]]

function Quaternion:len()
    return self.q:len()
end

--[[
Often enough to know the length squared, which is quicker.
--]]

function Quaternion:lenSqr()
    return self.q:lenSqr()
end

--[[
Distance between two quaternions.
--]]

function Quaternion:dist(q)
    return self.q:dist(q.q)
end

--[[
Often enough to know the distance squared, which is quicker.
--]]

function Quaternion:distSqr(q)
    return self.q:distSqr(q.q)
end

--[[
Normalise a quaternion to have length 1, if possible.
--]]

function Quaternion:normalise()
    return Quaternion(self.q:normalize())
end

function Quaternion:normalize()
    return Quaternion(self.q:normalize())
end

--[[
Scale the quaternion.
--]]

function Quaternion:scale(l)
    return Quaternion(self.q * l)
end

--[[
Add two quaternions.
--]]

function Quaternion:add(q)
    if type(q) == "number" then
        return Quaternion(self.q.x + q, self.q.y, self.q.z, self.q.w)
    else
        return Quaternion(self.q + q.q)
    end
end

--[[
q + p
--]]

function Quaternion:__add(q)
    if type(q) == "number" then
        return Quaternion(self.q.x + q, self.q.y, self.q.z, self.q.w)
    elseif type(self) == "number" then
        return Quaternion(self + q.q.x, q.q.y, q.q.z, q.q.w)
    else
        return Quaternion(self.q + q.q)
    end
end

--[[
Subtraction
--]]

function Quaternion:subtract(q)
    return Quaternion(self.q - q.q)
end

--[[
q - p
--]]

function Quaternion:__sub(q)
    if type(q) == "number" then
        return Quaternion(self.q.x - q, self.q.y, self.q.z, self.q.w)
    elseif type(self) == "number" then
        return Quaternion(self - q.q.x, - q.q.y, - q.q.z, - q.q.w)
    else
        return Quaternion(self.q - q.q)
    end
end

--[[
Negation (-q)
--]]

function Quaternion:__unm()
    return Quaternion(-self.q)
end

--[[
Length (#q)
--]]

function Quaternion:__len()
    return self:len()
end

--[[
Multiply the current quaternion on the right.

Corresponds to composition of rotations.
--]]

function Quaternion:multiplyRight(q)
    local a,b,c,d
    a = self.q.x * q.q.x - self.q.y * q.q.y - self.q.z * q.q.z - self.q.w * q.q.w
    b = self.q.x * q.q.y + self.q.y * q.q.x + self.q.z * q.q.w - self.q.w * q.q.z
    c = self.q.x * q.q.z - self.q.y * q.q.w + self.q.z * q.q.x + self.q.w * q.q.y
    d = self.q.x * q.q.w + self.q.y * q.q.z - self.q.z * q.q.y + self.q.w * q.q.x
    return Quaternion(a,b,c,d)
end

--[[
q * p
--]]

function Quaternion:__mul(q)
    if type(q) == "number" then
        return self:scale(q)
    elseif type(self) == "number" then
        return q:scale(self)
    elseif type(q) == "table" and q.is_a and q:is_a(Quaternion) then
        return self:multiplyRight(q)
    end
end

--[[
Multiply the current quaternion on the left.

Corresponds to composition of rotations.
--]]

function Quaternion:multiplyLeft(q)
    return q:multiplyRight(self)
end

--[[
Conjugation (corresponds to inverting a rotation).
--]]

function Quaternion:conjugate()
    return Quaternion(self.q.x, - self.q.y, - self.q.z, - self.q.w)
end

function Quaternion:co()
    return self:conjugate()
end

--[[
Reciprocal: 1/q
--]]

function Quaternion:reciprocal()
    if self:is_zero() then
        error("Cannot reciprocate a zero quaternion")
        return false
    end
    local q = self:conjugate()
    local l = self:lenSqr()
    q = q:scale(1/l)
    return q
end

--[[
Integral powers.
--]]

function Quaternion:power(n)
    if n ~= math.floor(n) then
        error("Only able to do integer powers")
        return false
    end
    if n == 0 then
        return Quaternion(1,0,0,0)
    elseif n > 0 then
        return self:multiplyRight(self:power(n-1))
    elseif n < 0 then
        return self:reciprocal():power(-n)
    end
end

--[[
q^n

This is overloaded so that a non-number exponent returns the
conjugate.  This means that one can write things like q^* or q^"" to
get the conjugate of a quaternion.
--]]

function Quaternion:__pow(n)
    if type(n) == "number" then
        return self:power(n)
    elseif type(n) == "table" and n.is_a and n:is_a(Quaternion) then
        return self:multiplyLeft(n):multiplyRight(n:reciprocal())
    else
        return self:conjugate()
    end
end

--[[
Division: q/p
--]]

function Quaternion:__div(q)
    if type(q) == "number" then
        return self:scale(1/q)
    elseif type(self) == "number" then
        return q:reciprocal():scale(self)
    elseif type(q) == "table" and q.is_a and q:is_a(Quaternion) then
        return self:multiplyRight(q:reciprocal())
    end
end


--[[
Interpolation functions, we assume the input to be already normalised
for speed.  If you cannot guarantee this, renormalise the input first.
The constructor functions do do the renormalisation.
--]]

--[[
Linear interpolation, renormalised
--]]

function Quaternion:lerp(q,t)
    if not t then
        return Quaternion.unit():lerp(self,q)
    end
    local v
    if self.q == -q.q then
        -- antipodal points, need a midpoint
        v = vec4(self.q.y,-self.q.x,self.q.w,-self.q.z)
        v = (1 - 2*t)*self.q + (1-math.abs(2*t-1))*v
    else
        v = (1-t)*self.q + t*q.q
    end
    return Quaternion(v:normalize())
end

--[[
Spherical interpolation
--]]

function Quaternion:slerp(q,t)
    if not t then
        return Quaternion.unit():slerp(self,q)
    end
    local v
    if self.q == -q.q then
        -- antipodal points, need a midpoint
        v = vec4(self.q.y,-self.q.x,self.q.w,-self.q.z)
        t = 2*t
    elseif self.q == q.q then
        return Quaternion(self)
    else
        v = q.q
    end
    local ca = self.q:dot(v)
    local sa = math.sqrt(1 - math.pow(ca,2))
    if sa == 0 then
        return Quaternion(self)
    end
    local a = math.acos(ca)
    sa = math.sin(a*t)/sa
    v = (math.cos(a*t) - ca*sa)*self.q+ sa*v
    return Quaternion(v)
end

--[[
Constructor for normalised linear interpolation.
--]]

function Quaternion:make_lerp(q)
    if not q then
        return Quaternion.unit():make_lerp(self)
    end
    local v,w
    w = self.q:normalize()
    if self.q == -q.q then
        -- antipodal points, need a midpoint
        v = vec4(w.y,-w.x,w.w,-w.z)
        return function(t)
            local u = (1 - 2*t)*w + (1-math.abs(2*t-1))*v
            return Quaternion(u:normalize())
        end
    else
        v = q.q:normalize()
        return function(t)
            local u = (1-t)*w + t*v
            return Quaternion(u:normalize())
        end
    end
end

--[[
Spherical interpolation
--]]

function Quaternion:make_slerp(q)
    if not q then
        return Quaternion.unit():make_slerp(self)
    end
    local v,f,u
    if self.q == -q.q then
        -- antipodal points, need a midpoint
        v = vec4(self.q.y,-self.q.x,self.q.w,-self.q.z)
        f = 2
    elseif self.q == q.q then
        return function(t)
            return Quaternion(self)
        end
    else
        v = q.q
        f = 1
    end
    v = v:normalize()
    u = self.q:normalize()
    local ca = u:dot(v)
    local sa = math.sqrt(1 - math.pow(ca,2))
    if sa == 0 then
        return function(t)
            return Quaternion(self)
        end
    end
    local a = math.acos(ca)
    v = (v - ca*self.q)/sa
    return function(t)
        local u = math.cos(a*f*t)*self.q + math.sin(a*f*t)*v
        return Quaternion(u)
    end
end

--[[
Returns the real part.
--]]

function Quaternion:real()
    return self.q.x
end

--[[
Returns the vector (imaginary) part as a Vec3 object.
--]]

function Quaternion:vector()
    return vec3(self.q.y, self.q.z, self.q.w)
end

--[[
Represents a quaternion as a string.
--]]

function Quaternion:tostring()
    local s
    local im ={{self.q.y,"i"},{self.q.z,"j"},{self.q.w,"k"}}
    if self.q.x ~= 0 then
        s = string.format("%.3f",self.q.x)
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

function Quaternion:__tostring()
    return self:tostring()
end

function Quaternion:__concat(s)
    if type(s) == "string" then
        return self:tostring() .. s
    elseif type(s) == "table" and s.is_a and s:is_a(Quaternion) then
        return self .. s:tostring()
    end
end

function Quaternion:tomatrix()
    local a,b,c,d = self.q.x,-self.q.y,-self.q.z,-self.q.w
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

--[[
(Not a class function)

Returns a quaternion corresponding to the current gravitational vector
so that after applying the corresponding rotation, the y-axis points
in the gravitational direction and the x-axis is in the plane of the
iPad screen.

When we have access to the compass, the x-axis behaviour might change.
--]]

--[[

function Quaternion.Gravity()
    local gxy, gy, gygxy, a, b, c, d
    if Gravity.x == 0 and Gravity.y == 0 then
        return Quaternion(1,0,0,0)
    else
        gy = - Gravity.y
        gxy = math.sqrt(math.pow(Gravity.x,2) + math.pow(Gravity.y,2))
        gygxy = gy/gxy
        a = math.sqrt(1 + gxy - gygxy - gy)/2
        b = math.sqrt(1 - gxy - gygxy + gy)/2
        c = math.sqrt(1 - gxy + gygxy - gy)/2
        d = math.sqrt(1 + gxy + gygxy + gy)/2
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
        return Quaternion(a,b,c,d)
    end
end
--]]

function Quaternion:Gravity()
    local qg,qx
    if not self then
        qx = Quaternion.ReferenceFrame()
    else
        qx = self
    end
    local y = vec3(0,-1,0)^qx
    qg = y:rotateTo(Gravity)
    return qg*qx
end

local frame = {
        vec3(1,0,0),
        vec3(0,1,0),
        vec3(0,0,1)
    }
local qzyx = Quaternion(1,0,0,0)

--[[
Needs to be run once every frame!
--]]

function Quaternion:updateReferenceFrame()
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
    local qz = Quaternion.Rotation(RotationRate.z*DeltaTime,z.x,z.y,z.z)
    local qy = Quaternion.Rotation(RotationRate.y*DeltaTime,y.x,y.y,y.z)
    local qx = Quaternion.Rotation(RotationRate.x*DeltaTime,x.x,x.y,x.z)
    if self then
        local q = qz * qy * qx * self
        self.q = q.q
    else
        qzyx = qz * qy * qx * qzyx
        return qzyx
    end
end

function Quaternion:ReferenceFrame()
    return self or qzyx
end

--[[
Converts a rotation to a quaternion.  The first argument is the angle
to rotate, the rest must specify an axis, either as a Vec3 object or
as three numbers.
--]]

function Quaternion.Rotation(a,...)
    local q,c,s
    q = Quaternion(0,...)
    q = q:normalise()
    c = math.cos(a/2)
    s = math.sin(a/2)
    q = q:scale(s)
    q = q:add(c)
    return q
end

--[[
The unit quaternion.
--]]

function Quaternion.unit()
    return Quaternion(1,0,0,0)
end

--[[
Extensions to vec3 type.
--]]

do
    local mt = getmetatable(vec3())

--[[
Promote to a quaternion with 0 real part.
--]]

mt["toQuaternion"] = function (self)
    return Quaternion(0,self.x,self.y,self.z)
end

--[[
Apply a quaternion as a rotation (assumes unit quaternion for speed).
--]]

mt["applyQuaternion"] = function (self,q)
    local x = self:toQuaternion()
    x = q:multiplyRight(x)
    x = x:multiplyRight(q:conjugate())
    return x:vector()
end

mt["__pow"] = function (self,q)
    if type(q) == "table" then
        if q:is_a(Quaternion) then
                return self:applyQuaternion(q)
        end
    end
    return false
end

mt["rotateTo"] = function (self,v)
    if v:lenSqr() == 0 or self:lenSqr() == 0 then
        return Quaternion(1,0,0,0)
    end
    local u = self:normalize()
    v = u + v:normalize()
    if v:lenSqr() == 0 then
        -- Opposite vectors, no canonical direction
        local a,b,c = math.abs(u.x), math.abs(u.y), math.abs(u.z)
        if a < b and a < c then
            v = vec3(0,-u.z,u.y)
        elseif b < c then
            v = vec3(u.z,0,-u.x)
        else
            v = vec3(u.y,-u.x,0)
        end
    end
    v = v:normalize()
    return Quaternion(u:dot(v),u:cross(v))
end

end

if cmodule.loaded "TestSuite" then
    
    testsuite.addTest({
        name = "Quaternion",
        setup = function()
            local q = Quaternion(.3,.4,.5,.6)
            local qq = Quaternion(.2,vec3(.4,-.5,.1))
            for k,v in ipairs({
                {"Quaternion", q},
                {"Sum", q + qq},
                {"Sum (number)", q + 5},
                {"Sum (number)", 5 + q},
                {"Subtract", q - qq},
                {"Subtract (number)", q - 5},
                {"Subtract (number)", 5 - q},
                {"Product", q * qq},
                {"Scale (right)", q * 5},
                {"Scale (left)", 5 * q},
                {"Divison", q / qq},
                {"by number", q / 5},
                {"of number", 5 / q},
                {"Length", q:len()},
                {"Length Squared", q:lenSqr()},
            }) do
                print(v[1] .. ": " .. v[2])
            end
        end,
        draw = function()
        end
    })
end

return Quaternion

--]==]
