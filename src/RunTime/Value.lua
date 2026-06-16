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

export type luaFunctionValue = value<(...value<any>) -> any> & {takesSelf: boolean, usesLuaTypes: boolean, self: value<any>}
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

export type instanceValue = value<Instance>
module.instanceValue = function(instance: Instance): instanceValue
	local res: instanceValue = value("instance", instance)
	function res:toString()
		return res.value:GetFullName()
	end
	return res
end

export type vector3Value = value<Vector3>
module.vector3Value = function(vector: Vector3)
	return value("vector3", vector)
end

export type vector2Value = value<Vector2>
module.vector2Value = function(vector: Vector2)
	return value("vector2", vector)
end

export type udim2Value = value<UDim2>
module.udim2Value = function(udim2: UDim2)
	return value("udim2", udim2)
end

export type udimValue = value<UDim2>
module.udimValue = function(udim: UDim)
	return value("udim", udim)
end

export type color3Value = value<Color3>
module.color3Value = function(color: Color3)
	return value("color3", color)
end

export type cframeValue = value<CFrame>
module.cframeValue = function(cframe: CFrame)
	return value("cframe", cframe)
end

module.tableTypes = {"table","instance","vector3","vector2","udim2","udim","color3"}
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
		for n, v in pairs(value) do
			newTable[n] = module.fromLuauValue(v)
		end
		return module.tableValue(newTable)
	end
	if type == "Instance" then
		return module.instanceValue(value)
	end
	if type == "Vector3" then
		return module.vector3Value(value)
	end
	if type == "Vector2" then
		return module.vector2Value(value)
	end
	if type == "UDim2" then
		return module.udim2Value(value)
	end
	if type == "UDim" then
		return module.udimValue(value)
	end
	if type == "Color3" then
		return module.color3Value(value)
	end
	if type == "CFrame" then
		return module.cframeValue(value)
	end
	return module.nilValue()
end

module.toLuauValue = function(value: value<any>): any
	if table.find({"string","boolean","number","nil","luaFunction","vector3","vector2","udim2","udim","color3","instance"}, value.valueType) then
		return value.value
	end
	return value
end

return module