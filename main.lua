local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

local Window = Rayfield:CreateWindow({
	Name = "Rayfield Test Window",
	LoadingTitle = "Please Wait",
	LoadingSubtitle = "Rayfield Example",
	ConfigurationSaving = {
		Enabled = false
	},
	KeySystem = false
})

local Tab = Window:CreateTab("Main", 4483362458)

Tab:CreateLabel("Hello! Rayfield is working!")

Tab:CreateButton({
	Name = "Click Me!",
	Callback = function()
		print("Button clicked!")
	end,
})
