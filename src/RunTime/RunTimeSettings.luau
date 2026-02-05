local types = require("./RunTimeTypes")

return function(): types.runTimeSettings
	return {
		globals = {}
	}
end