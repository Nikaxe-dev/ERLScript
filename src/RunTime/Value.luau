type environment = {
	parent: environment?,
	variables: {[string]: value<any>},
	declareVariable: (self: environment, name: string, value: value<any>) -> value<any>,
	setVariable: (self: environment, name: string, value: value<any>) -> value<any>?,
	lookUpVariable: (self: environment, name: string) -> value<any>,
	resolve: (self: environment, name: string) -> environment
}

local nodes = require("./Parser/Nodes")

export type value<T> = {
	toString: (self: value<any>) -> string,
	valueType: string,
	value: T,
}
local function value(type: string, content: any): value<any>
	local res = {
		valueType = type,
		value = content
	}
	function res:toString()
		return `{type}({tostring(content)})`
	end
	return res
end

local module = {}

export type stringValue = value<string>
module.stringValue = function(content: string): stringValue
	local res = value("string", content)
	function res:toString()
		return self.value
	end
	return res
end

export type booleanValue = value<boolean>
module.booleanValue = function(content: boolean): booleanValue
	local res = value("boolean", content)
	function res:toString()
		return res.value and "true" or "false"
	end
	return res
end

export type numberValue = value<number>
module.numberValue = function(content: number): numberValue
	local number = value("number", content)
	function number:toString()
		return tostring(self.value)
	end
	return number
end

export type nilValue = value<nil>
module.nilValue = function(): nilValue
	local res = value("nil", nil)
	function res:toString()
		return "nil"
	end
	return res
end

export type functionValue = value<nil> & {
	name: string,
	parameters: {string},
	environment: environment,
	body: {nodes.node}
}
module.functionValue = function(name: string, parameters: {string}, environment: environment, body: {nodes.node}): functionValue
	local res: functionValue = value("function")
	res.name = name
	res.parameters = parameters
	res.environment = environment
	res.body = body
	return res
end

export type tableValue = value<{[string | number]: value<any>}>
module.tableValue = function(content: any): tableValue
	return value("table", content)
	--return useReference and value("function", runTime.valueReferences[content]) or value("function", module.tableReference(runTime, content))
end

export type luaFunctionValue = value<(...value<any>) -> any>
module.luaFunctionValue = function(fun: (...any) -> any): luaFunctionValue
	return value("luaFunction", fun)
end

module.breakSignal = function(expressionValue: value<any>)
	return value("breakSignal", expressionValue)
end
module.returnSignal = function(expressionValue: value<any>)
	return value("returnSignal", expressionValue)
end
module.continueSignal = function()
	return value("continueSignal")
end

module.fromLuauValue = function(value: any, runTime: any?): value<any>
	local type = typeof(value)
	if type == "string" then
		return module.stringValue(value)
	end
	if type == "number" then
		return module.numberValue(value)
	end
	if type == "boolean" then
		return module.booleanValue(value)
	end
	if type == "function" then
		return module.luaFunctionValue(value)
	end
	if type == "table" then
		local newTable = {}
		for i, v in ipairs(value) do
			table.insert(newTable, module.fromLuauValue(v, runTime))
		end
		for n, v in pairs(value) do
			newTable[n] = module.fromLuauValue(v, runTime)
		end
		return module.tableValue(runTime, newTable)
	end
	return module.nilValue()
end

return module