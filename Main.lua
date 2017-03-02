--Project: Library Maths
--Version: 2.1
--Dependencies:
--Comments:


VERSION = 2.1
clearProjectData()
-- DEBUG = true
-- Use this function to perform your initial setup
function setup()
    if AutoGist then
        autogist = AutoGist("Library Maths","A library of classes and functions for mathematical objects.",VERSION)
        autogist:backup(true)
    end
    if not cmodule then
        openURL("http://loopspace.mathforge.org/discussion/36/my-codea-libraries")
        print("You need to enable the module loading mechanism.")
        print("See http://loopspace.mathforge.org/discussion/36/my-codea-libraries")
        print("Touch the screen to exit the program.")
        draw = function()
        end
        touched = function()
            close()
        end
        return
    end
    --displayMode(FULLSCREEN_NO_BUTTONS)
    cmodule "Library Maths"
    cmodule.path("Library Base", "Library UI", "Library Utilities")
    cimport "TestSuite"
    Complex = cimport "Complex"
    -- cimport "ComplexExt"
    -- Quaternion = cimport "Quaternion"
    -- cimport "QuaternionExt"
    cimport "VecExt"
    --displayMode(FULLSCREEN)
    local Touches = cimport "Touch"
    local UI = cimport "UI"
    cimport "Menu"
    touches = Touches()
    ui = UI(touches)
    ui:systemmenu()
    testsuite.initialise({ui = ui})
    fps = {}
    for k=1,20 do
        table.insert(fps,1/60)
    end
    afps = 60
    parameter.watch("math.floor(20/afps)")
    q = vec4(1,0,0,0)
    parameter.watch("q")
    parameter.watch("q:tomatrix()")
    parameter.watch("vec3(0,1,0)^q")
    print("Rotation",qRotation(1,vec3(0,1,0)))
    print("Gravity",qGravity())
    a = vec2(3,4)
    b = vec2(6,7)
    print(a*b)
    q = vec4(1,2,3,4)
    v = vec3(1,2,3)
    print(v:toQuaternion())
    print(modelMatrix())
    print(q:toangleaxis())
    testRotations()
end

function draw()
    -- q:updateReferenceFrame()
    touches:draw()
    table.remove(fps,1)
    table.insert(fps,DeltaTime)
    afps = 0
    for k,v in ipairs(fps) do
        afps = afps + v
    end
    background(75, 104, 90, 255)
    ui:draw()
end

function touched(touch)
    touches:addTouch(touch)
end

function orientationChanged(o)
end

function fullscreen()
end

function reset()
end

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
