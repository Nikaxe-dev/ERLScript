local types = require("./RunTimeTypes")

return function(): types.runTimeSettings
	return {
		globals = {},
		allowInstances = true,
		allowRequireLUA = true,
	}
end