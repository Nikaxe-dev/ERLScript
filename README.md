# [ERLScript] [V1.1] - Interpreted lua-like programming language

ERLScript is a programming language designed to be easily executed in roblox, being decently customizable & able to be ran multiple times in a single script. Please expect bugs, as this is a new type of project for me, and has been done in my free time.

ERLScript takes syntax from both lua & javaScript, as they are both some of my favourite programming languages to use.

ERLScript also includes a math library in the global scope, which has all luau math functions included.

Example script utilizing ERLScript:
```lua
local ERL = require("path.to.ERLScript")
local runTime = ERL.runTime(ERL.runTimeSettings())

-- Hello from ERLScript!
runTime:execute([[
    print("Hello from ERLScript!")
]])

-- Example for loop, these are done differently from lua & javaScript.
-- Lua equivalent: for index, value in ipairs({1, 2, 3, 4, 5}) do print(index, value) end
runTime:execute([[
    for (name, value, index) ({1, 2, 3, 4, 5}) {
        print(name, value, index)
    }
]])

-- ERLScript supports functions! Even anonymous functions are supported!
runTime:execute([[
    function add(a, b) {
        return a + b
    }
    print(add(10, 5))
    print(function(a, b) {a % b})
]])
```

Don’t expect many updates for this module, as I am currently working on other projects (such as my game) and might end up completely forgetting about this project.