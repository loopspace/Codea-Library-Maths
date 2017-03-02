--[==[
-- Vec3 class
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

--[[
The "Vec3" class is for handling 3 dimensional vectors and defining a
variety of methods on them.

This is largely superceded by the vec3 userdata.  There are a few extra
methods, but these should really be added to vec3.
--]]

local Vec3 = class()

--[[
A 3-vector is three numbers.
--]]

function Vec3:init(x,y,z)
    self.x = x
    self.y = y
    self.z = z
end

--[[
Test for zero vector.
--]]

function Vec3:is_zero()
    if self.x ~= 0 or self.y ~= 0 or self.z ~= 0 then
        return false
    end
    return true
end

--[[
Test for equality.
--]]

function Vec3:is_eq(v)
    if self.x ~= v.x or self.y ~= v.y or self.z ~= v.z then
        return false
    end
    return true
end        

--[[
Inner product.
--]]

function Vec3:dot(v)
    return self.x * v.x + self.y * v.y + self.z * v.z
end

--[[
Cross product.
--]]

function Vec3:cross(v)
    local x,y,z
    x = self.y * v.z - self.z * v.y
    y = self.z * v.x - self.x * v.z
    z = self.x * v.y - self.y * v.x
    return Vec3(x,y,z)
end

--[[
Apply a given matrix (which is specified as a triple of vectors).
--]]

function Vec3:applyMatrix(a,b,c)
    local u,v,w
    u = a:scale(self.x)
    v = b:scale(self.y)
    w = c:scale(self.z)
    u = u:add(v)
    u = u:add(w)
    return u
end

--[[
Length of the vector
--]]

function Vec3:len()
    return math.sqrt(math.pow(self.x,2) + math.pow(self.y,2) + math.pow(self.z,2))
end

--[[
Squared length of the vector.
--]]

function Vec3:lenSqr()
    return math.pow(self.x,2) + math.pow(self.y,2) + math.pow(self.z,2)
end

--[[
Normalise the vector (if possible) to length 1.
--]]

function Vec3:normalise()
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

function Vec3:scale(l)
    return Vec3(self.x * l,self.y * l,self.z * l)
end

--[[
Add vectors.
--]]

function Vec3:add(v)
    return Vec3(self.x + v.x, self.y + v.y, self.z + v.z)
end

--[[
Subtract vectors.
--]]

function Vec3:subtract(v)
    return Vec3(self.x - v.x, self.y - v.y, self.z - v.z)
end

--[[
Apply a transformation between "absolute" coordinates and "relative"
coordinates.  In the "relative" system, xy are in the iPad screen and
z points straight out.  In the "absolute" system, y is in the
direction of the gravity vector, x is in the plane of the iPad screen,
and z is orthogonal to those two.

This function interprets the vector as being with respect to the
absolute coordinates and returns the corresponding vector in the
relative system.
--]]

function Vec3:absCoords()
    local gxy,l,ga,gb,gc
    gxy = Vec3(-Gravity.y,Gravity.x,0)
    l = gxy:len()
    if l == 0 then
    print("Unable to compute coordinate system, gravity vector is (" .. Gravity.x .. "," .. Gravity.y .. "," .. Gravity.z .. ")")
        return false
    end
    ga = gxy:scale(1/l)
    gb = Vec3(-Gravity.x,-Gravity.y,-Gravity.z)
    gc = Vec3(-Gravity.x * Gravity.z /l, -Gravity.y * Gravity.z /l, l)
    return self:applyMatrix(ga,gb,gc)
end

--[[
Determine whether or not the vector is in front of the "eye" (crude
test for visibility).
--]]

function Vec3:isInFront(e)
    if not e then
        e = Vec3.eye
    end
    if self:dot(e) < e:dot(e) then
        return true
    else
        return false
    end
end

--[[
Project the vector onto the screen using stereographic projection from
the "eye".
--]]

function Vec3:stereoProject(e)
    local t,v
    if not e then
        e = Vec3.eye
    end
    if self.z == e.z then
        -- can't project
        return false
    end
    t = 1 / (1 - self.z / e.z)
    v = self:subtract(e)
    v = v:scale(t)
    v = v:add(e)
    -- hopefully v.z is now 0!
    return vec2(v.x,v.y)
end

--[[
Partial inverse to stereographic projection: given a point on the
screen and a height, we find the point in space at that height which
would project to the point on the screen.
--]]

function Vec3.stereoInvProject(v,e,h)
    local t,u
    if not e then
        e = Vec3.eye
    end
    u = Vec3(v.x,v.y,0)
    t = h / e.z
    u = (1 - t) * u + t * e
    -- hopefully u.z is now h!
    return u
end

--[[
Returns the distance from the eye; useful for sorting objects.
--]]

function Vec3:stereoLevel(e)
    local v
    if not e then
        e = Vec3.eye
    end
    v = self:subtract(e)
    return e:len() - v:len()
end

--[[
Applies a rotation as specified by another 3-vector, with direction
being the axis and magnitude the angle.
--]]

function Vec3:rotate(w)
    local theta, u, v, a, b, c, x
    if w:is_zero() then
        return self
    else
        theta = w:len()
        w = w:normalise()
        if w.x ~= 0 then
                u = Vec3(-w.y/w.x,1,0)
                u = u:normalise()
        else
                u = Vec3(1,0,0)
        end
        v = w:cross(u)
        a = self:dot(u)
        b = self:dot(v)
        c = self:dot(w)
        x = w:scale(c)
        u = u:scale(a * math.cos(theta) + b * math.sin(theta))
        v = v:scale(-a * math.sin(theta) + b * math.cos(theta))
        x = x:add(u)
        x = x:add(v)
        return x
    end
end

--[[
Promote to a quaternion with 0 real part.
--]]

function Vec3:toQuaternion()
    return Quaternion(0,self.x,self.y,self.z)
end

--[[
Apply a quaternion as a rotation.
--]]

function Vec3:applyQuaternion(q)
    local x = self:toQuaternion()
    x = q:multiplyRight(x)
    x = x:multiplyRight(q:conjugate())
    return x:vector()
end

--[[
Inline operators:

u + v
u - v
-u
u * v : cross product (possibly bad choice) or scaling
u / v : scaling
u ^ q : apply quaternion as rotation
u == v : equality
u .. v : dot product (possibly bad choice)

The notation for cross product and dot product may be removed in a
later version.
--]]

function Vec3:__add(v)
    return self:add(v)
end

function Vec3:__sub(v)
    return self:subtract(v)
end

function Vec3:__unm()
    return self:scale(-1)
end

function Vec3:__mul(v)
    if type(self) == "number" then
        return v:scale(self)
    elseif type(v) == "number" then
        return self:scale(v)
    elseif type(v) == "table" then
        if v:is_a(Vec3) then
                return self:cross(v)
        end
    end
    return false
end

function Vec3:__div(l)
    if type(l) == "number" then
        return self:scale(1/l)
    else
        return false
    end
end

function Vec3:__pow(q)
    if type(q) == "table" then
        if q:is_a(Quaternion) then
                return self:applyQuaternion(q)
        end
    end
    return false
end

function Vec3:__eq(v)
    return self:is_eq(v)
end

function Vec3:__concat(v)
    if type(v) == "table" 
        and v:is_a(Vec3) 
        and type(self) == "table"
        and self:is_a(Vec3)
        then
        return self:dot(v)
    else
        if type(v) == "table" 
        and v:is_a(Vec3) then
            return self .. v:tostring()
        else
            return self:tostring() .. v
        end
    end
end

function Vec3:tostring()
    return "(" .. self.x .. "," .. self.y .. "," .. self.z .. ")"
end

function Vec3:__tostring()
    return self:tostring()
end

function Vec3:tovec3()
    return vec3(self.x,self.y,self.z)
end

--[[
The following functions are not class methods but are still related to
vectors.
--]]

--[[
Sets the "eye" for stereographic projection.  Input can either be a
Vec3 object or the information required to specify one.
--]]

function Vec3.SetEye(...)
    if arg.n == 1 then
        Vec3.eye = arg[1]
    elseif arg.n == 3 then
        Vec3.eye = Vec3(unpack(arg))
    else
        print("Wrong number of arguments to Vec3.SetEye (1 or 3 expected, got " .. arg.n .. ")")
        return false
    end
    return true
end

--[[
Some useful Vec3 objects.
--]]

Vec3.eye = Vec3(0,0,1)

Vec3.origin = Vec3(0,0,0)
Vec3.e1 = Vec3(1,0,0)
Vec3.e2 = Vec3(0,1,0)
Vec3.e3 = Vec3(0,0,1)

--[[
Is the line segment a-b over c-d when seen from e?
--]]

function Vec3.isOverLine(a,b,c,d,e)
    if not e then
        e = Vec3.eye
    end
    -- rebase at a
    b = b - a
    c = c - a
    d = d - a
    e = e - a
    -- test signs of various determinants
    a = c:cross(d)
    if a:dot(b) * a:dot(e) < 0 then
        return false
    end
    a = d:cross(e)
    if a:dot(b) * a:dot(c) < 0 then
        return false
    end
    a = e:cross(c)
    if a:dot(b) * a:dot(d) < 0 then
        return false
    end
    -- right direction, is it far enough?
    c = c:subtract(e)
    d = d:subtract(e)
    a = c:cross(d)
    local l = a:dot(b)
    local m = a:dot(e)
    if l * m > 0 and math.abs(l) > math.abs(m) then
        return true
    else
        return false
    end
end

--[[
Is the line segment a-b over the point c when seen from e?
r is the "significant distance"
--]]

function Vec3.isOverPoint(a,b,c,r,e)
    
    if not e then
        e = Vec3.eye
    end
    local aa,bb,ab,ac,bc,d,l
    -- rebase at e
    a = a - e
    b = b - e
    c = c - e
    d = a:cross(b)
    if math.abs(d:dot(c)) > r * d:len() then
        return false
    end
    aa = a:lenSqr()
    bb = b:lenSqr()
    ab = a:dot(b)
    ac = a:dot(c)
    bc = b:dot(c)
    
    if aa * bc < ab * ac then
        return false
    end
    if bb * ac < ab * bc then
        return false
    end
    
    l = math.sqrt((aa * bb - ab * ab) * (aa + bb - 2 * ab))
    
    if (bb - ab) * ac + (aa - ab) * bc < aa * bb - ab * ab + r * l then
        return false
    end
    return true
end

return Vec3

--]==]
