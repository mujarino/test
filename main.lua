local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/mujarino/test/refs/heads/main/Rayfield%20Lib%20Source.lua"))()

local Window = Rayfield:CreateWindow({
    Name = "Test UI",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Rayfield Test",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

local MainTab = Window:CreateTab("Main", 4483362458)

local myToggle = false

MainTab:CreateToggle({
    Name = "Example Toggle",
    CurrentValue = false,
    Flag = "ExampleToggle",
    Callback = function(value)
        myToggle = value
        print("Toggle is now:", value)
    end,
})

MainTab:CreateButton({
    Name = "Example Button",
    Callback = function()
        print("Button clicked. Toggle is:", myToggle)
        Rayfield:Notify("Button Pressed", "You clicked the button", 4483362458)
    end,
})
