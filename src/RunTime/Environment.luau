local value = require("./Value")
local types = require("./RunTimeTypes")

return function(parent: types.environment?): types.environment
	local environment: types.environment = {
		parent = parent,
		variables = {}
	}
	function environment:declareVariable(name: string, value: value.value<any>)
		environment.variables[name] = value
		return value
	end
	function environment:setVariable(name, value)
		local variableEnvironment = self:resolve(name)
		if variableEnvironment and variableEnvironment.variables[name] then
			variableEnvironment.variables[name] = value
			return value
		end
	end
	function environment:lookUpVariable(name: string)
		local environment = self:resolve(name)
		if environment then
			return environment.variables[name]
		end
	end
	function environment:resolve(name: string)
		if self.variables[name] ~= nil then return self end
		
		if self.parent then
			return self.parent:resolve(name)
		end
	end
	return environment
end