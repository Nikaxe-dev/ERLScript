local types = require("@self/RunTimeTypes")
local lexer = require("@self/Lexer")
local executor = require("@self/Executor")
local runTimeSettings = require("@self/RunTimeSettings")
local value = require("@self/Value")
local parser = require("@self/Parser")
local environment = require("@self/Environment")

local function wrapperFunction(wrapper: (value: any) -> value.value<any>, value: any)
	return function()
		return wrapper(value)
	end
end

return function(settings: types.runTimeSettings)
	local runTime: types.runTime = {
		settings = settings or runTimeSettings(),
		keywords = {"var", "function", "return", "if", "else", "elseif", "while", "for", "break", "continue"},
		
		statementTimeoutLength = 7.5,
	}
	runTime.lexer = lexer(runTime)
	runTime.executor = executor(runTime)
	runTime.parser = parser(runTime)
	runTime.environment = environment()
	
	function runTime:setGlobalScopeVariables()
		self.environment:declareVariable("VERSION", value.stringValue("1.1"))
		
		self.environment:declareVariable("print", value.luaFunctionValue(function(...: value.value<any>)
			local text = ""
			for i, v in ipairs(table.pack(...)) do
				text ..= v:toString() .. " "
			end
			print(text)
			return value.stringValue(text)
		end))

		self.environment:declareVariable("warn", value.luaFunctionValue(function(...: value.value<any>)
			local text = ""
			for i, v in ipairs(table.pack(...)) do
				text ..= v:toString() .. " "
			end
			warn(text)
			return value.stringValue(text)
		end))

		self.environment:declareVariable("error", value.luaFunctionValue(function(...: value.value<any>)
			local text = ""
			for i, v in ipairs(table.pack(...)) do
				text ..= v:toString() .. " "
			end
			error(text)
			return value.stringValue(text)
		end))
		
		self.environment:declareVariable("math", value.tableValue({
			abs = value.luaFunctionValue(function(number: value.numberValue)
				return value.numberValue(math.abs(number.value))
			end),
			acos = value.luaFunctionValue(function(number: value.numberValue)
				return value.numberValue(math.acos(number.value))
			end),
			asin = value.luaFunctionValue(function(number: value.numberValue)
				return value.numberValue(math.asin(number.value))
			end),
			atan = value.luaFunctionValue(function(number: value.numberValue)
				return value.numberValue(math.atan(number.value))
			end),
			atan2 = value.luaFunctionValue(function(x: value.numberValue, y: value.numberValue)
				return value.numberValue(math.atan2(x.value,y.value))
			end),
			ceil = value.luaFunctionValue(function(number: value.numberValue)
				return value.numberValue(math.ceil(number.value))
			end),
			clamp = value.luaFunctionValue(function(x: value.numberValue, min: value.numberValue, max: value.numberValue)
				return value.numberValue(math.clamp(x.value, min.value, max.value))
			end),
			cos = value.luaFunctionValue(function(number: value.numberValue)
				return value.numberValue(math.cos(number.value))
			end),
			cosh = value.luaFunctionValue(function(number: value.numberValue)
				return value.numberValue(math.cosh(number.value))
			end),
			deg = value.luaFunctionValue(function(number: value.numberValue)
				return value.numberValue(math.deg(number.value))
			end),
			exp = value.luaFunctionValue(function(number: value.numberValue)
				return value.numberValue(math.exp(number.value))
			end),
			floor = value.luaFunctionValue(function(number: value.numberValue)
				return value.numberValue(math.floor(number.value))
			end),
			fmod = value.luaFunctionValue(function(x: value.numberValue, y: value.numberValue)
				return value.numberValue(math.fmod(x.value, y.value))
			end),
			frexp = value.luaFunctionValue(function(number: value.numberValue)
				return value.numberValue(math.frexp(number.value))
			end),
			ldexp = value.luaFunctionValue(function(x: value.numberValue, e: value.numberValue)
				return value.numberValue(math.ldexp(x.value, e.value))
			end),
			lerp = value.luaFunctionValue(function(a: value.numberValue, b: value.numberValue, t: value.numberValue)
				return value.numberValue(math.lerp(a.value, b.value, t.value))
			end),
			log = value.luaFunctionValue(function(x: value.numberValue, base: value.numberValue)
				return value.numberValue(math.log(x.value, base.value))
			end),
			log10 = value.luaFunctionValue(function(x: value.numberValue)
				return value.numberValue(math.log10(x.value))
			end),
			map = value.luaFunctionValue(function(x: value.numberValue, inmin: value.numberValue, inmax: value.numberValue, outmin: value.numberValue, outmax: value.numberValue)
				return value.numberValue(math.map(x.value, inmin.value, inmax.value, outmin.value, outmax.value))
			end),
			max = value.luaFunctionValue(function(x: value.numberValue, ...: value.numberValue)
				local biggest = x
				for i, v in ipairs(table.pack(...)) do
					if v.value > biggest.value then
						biggest = v
					end
				end
				return biggest
			end),
			min = value.luaFunctionValue(function(x: value.numberValue, ...: value.numberValue)
				local smallest = x
				for i, v in ipairs(table.pack(...)) do
					if v.value < smallest.value then
						smallest = v
					end
				end
				return smallest
			end),
			modf = value.luaFunctionValue(function(x: value.numberValue)
				return value.numberValue(math.modf(x.value))
			end),
			noise = value.luaFunctionValue(function(x: value.numberValue, y: value.numberValue, z: value.numberValue)
				return value.numberValue(math.noise(x.value, y.value, z.value))
			end),
			pow = value.luaFunctionValue(function(x: value.numberValue, y: value.numberValue)
				return value.numberValue(math.pow(x.value, y.value))
			end),
			rad = value.luaFunctionValue(function(x: value.numberValue)
				return value.numberValue(math.rad(x.value))
			end),
			random = value.luaFunctionValue(function(m: value.numberValue, n: value.numberValue)
				return value.numberValue(math.random(m.value, n.value))
			end),
			randomseed = value.luaFunctionValue(function(seed: value.numberValue)
				return value.numberValue(math.randomseed(seed.value))
			end),
			round = value.luaFunctionValue(function(x: value.numberValue)
				return value.numberValue(math.round(x.value))
			end),
			sign = value.luaFunctionValue(function(x: value.numberValue)
				return value.numberValue(math.sign(x.value))
			end),
			sin = value.luaFunctionValue(function(x: value.numberValue)
				return value.numberValue(math.sin(x.value))
			end),
			sinh = value.luaFunctionValue(function(x: value.numberValue)
				return value.numberValue(math.sinh(x.value))
			end),
			sqrt = value.luaFunctionValue(function(x: value.numberValue)
				return value.numberValue(math.sqrt(x.value))
			end),
			tan = value.luaFunctionValue(function(x: value.numberValue)
				return value.numberValue(math.tan(x.value))
			end),
			tanh = value.luaFunctionValue(function(x: value.numberValue)
				return value.numberValue(math.tanh(x.value))
			end),
			huge = value.numberValue(math.huge),
			pi = value.numberValue(math.pi),
		}))
		
		self.environment:declareVariable("iterator", value.tableValue({
			table = value.luaFunctionValue(function(tableQuery: value.tableValue)
				local entries: {string | number} = {}
				for n, v in pairs(tableQuery.value) do
					table.insert(entries, n)
				end
				
				local index = 0
				return value.luaFunctionValue(function()
					index += 1
					if index <= #entries then
						local tableEntity = tableQuery.value[entries[index]]
						return type(entries[index]) == "string" and value.stringValue(entries[index]) or value.numberValue(entries[index]), tableEntity, value.numberValue(index)
					end
				end)
			end),
			
			string = value.luaFunctionValue(function(stringQuery: value.stringValue)
				local index = 0
				return value.luaFunctionValue(function()
					index += 1
					if index <= #stringQuery.value then
						return value.numberValue(index), value.stringValue(string.sub(stringQuery.value, index, index))
					end
				end)
			end),
			
			number = value.luaFunctionValue(function(numberQuery: value.numberValue)
				local index = 0
				return value.luaFunctionValue(function()
					index += 1
					if index <= numberQuery.value then
						return value.numberValue(index)
					end
				end)
			end)
		}))
		
		self.environment:declareVariable("table", value.tableValue({
			clear = value.luaFunctionValue(function(tableQuery: value.tableValue)
				table.clear(tableQuery)
				return tableQuery
			end),
			
			clone = value.luaFunctionValue(function(tableQuery: value.tableValue)
				return value.tableValue(tableQuery.value)
			end),
			
			concat = value.luaFunctionValue(function(tableQuery: value.tableValue, seperator: value.stringValue, i: value.numberValue, j: value.numberValue)
				i = i and i.value or 1
				j = j and math.min(j.value, #tableQuery.value) or #tableQuery.value
				local text = ""
				for index=i,j do
					if index > j then break end
					text ..= tableQuery.value[index]:toString()
					if index ~= j then
						text ..= seperator.value
					end
				end
				return value.stringValue(text)
			end),
			
			find = value.luaFunctionValue(function(haystack: value.tableValue, needle: value.value<any>, init: number)
				init = init.value or 1
				local index = 0
				for name, value in pairs(haystack.value) do
					index += 1
					if index < init then continue end
					if name == needle.value then
						return value
					end
				end
			end),
			
			insert = value.luaFunctionValue(function(tableQuery: value.tableValue, value: value.value<any>, position: value.numberValue)
				if position then
					table.insert(tableQuery.value, position, value)
				else
					table.insert(tableQuery.value, value)
				end
			end),
			
			parameters = value.luaFunctionValue(function(fun: value.luaFunctionValue, tableQuery: value.tableValue, ...: value.value<any>)
				local a = table.clone(tableQuery.value)
				for i, v in ipairs(table.pack(...)) do
					table.insert(a, v)
				end
				
				if fun.valueType == "function" then
					return self.executor:executeFunctionBody(fun.body, fun.parameters, a, fun.environment)
				elseif fun.valueType == "luaFunction" then
					return fun.value(table.unpack(a))
				end
				return value.nilValue()
			end),
			
			entries = value.luaFunctionValue(function(tableQuery: value.tableValue)
				local entries: {any} = {}
				for n,_ in pairs(tableQuery.value) do
					table.insert(entries, n)
				end
				for i,name in ipairs(entries) do
					if type(name) == "string" or type(name) == "number" then
						entries[i] = (type(name) == "string" and value.stringValue or value.numberValue)(name)
					end
				end
				return value.tableValue(entries)
			end),
			
			len = value.luaFunctionValue(function(tableQuery: value.tableValue)
				return value.numberValue(#tableQuery.value)
			end)
		}))

		self.environment:declareVariable("true", value.booleanValue(true))
		self.environment:declareVariable("false", value.booleanValue(false))
		self.environment:declareVariable("nil", value.nilValue())
	end
	
	runTime:setGlobalScopeVariables()
	for n, v in pairs(runTime.settings.globals) do
		runTime.environment:declareVariable(n, value.fromLuauValue(v, runTime))
	end
	
	function runTime:execute(code: string)
		local tokens = self.lexer:process(code)
		local AST = self.parser:parseTokens(tokens)
		return self.executor:interpretAST(AST, self.environment)
	end
	
	function runTime:runTimeError(errorType: types.error, ...: string)
		error(`[ERLScript ERROR] {errorType}: {table.concat(table.pack(...))}`)
	end
	
	function runTime:runTimeWarn(errorType: types.error, ...: string)
		print(`[ERLScript WARNING] {errorType}: {table.concat(table.pack(...))}`)
	end
	
	return runTime
end