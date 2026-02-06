local types = require("./RunTimeTypes")
local nodes = require("./Parser/Nodes")
local value = require("./Value")
local environmentConstructor = require("./Environment")

return function(runTime): types.executor
	local executor: types.executor = {
		runTime = runTime,
	}

	function executor:interpretAST(node: nodes.node, environment: types.environment): value.value<any>
		--environment = environment or self.runTime.environment
		if node:is("numericLiteral") then
			return value.numberValue((node::nodes.numericLiteral).value)
		elseif node:is("stringLiteral") then
			return value.stringValue((node::nodes.stringLiteral).value)
		elseif node:is("identifier") then
			local value = environment:lookUpVariable((node::nodes.identifier).symbol)
			if not value then
				return self.runTime:runTimeError("referenceError", `Variable '{(node::nodes.identifier).symbol}' not found.`)
			end
			return value
		elseif node:is("memberExpression") then
			local node: nodes.memberExpression = node
			local tableValue = self:interpretAST(node.object, environment) :: value.tableValue

			if not table.find(value.tableTypes, tableValue.valueType) then
				self.runTime:runTimeError("typeError", `Type of '{tableValue.valueType}' cannot be indexed.`)
			end
			
			if tableValue.valueType == "instance" then
				local val: value.value<any>
				if node.computed then
					val = value.fromLuauValue(tableValue.value[self:interpretAST(node.property, environment).value], self.runTime)
				else
					val = value.fromLuauValue(tableValue.value[node.property.symbol], self.runTime)
				end
				if val.valueType == "luaFunction" then
					val.takesSelf = true
					val.usesLuaTypes = true
					val.self = tableValue.value
				end
				return val
			else
				if node.computed then
					return tableValue.value[self:interpretAST(node.property, environment).value] or value.nilValue()
				else
					return tableValue.value[(node.property::nodes.identifier).symbol] or value.nilValue()
				end
			end
		elseif node:is("tableLiteral") then
			local luaTable: {[string | number]: value.value<any>} = {}
			local node: nodes.tableLiteral = node
			for key, value in pairs(node.properties) do
				luaTable[key] = self:interpretAST(value, environment)
			end
			return value.tableValue(luaTable)
		elseif node:is("callExpression") then
			local node: nodes.callExpression = node
			local arguments: {value.value<any>} = {}
			for i, v in ipairs(node.args) do
				table.insert(arguments, self:interpretAST(v, environment))
			end
			local functionValue: value.functionValue = self:interpretAST(node.calle, environment)
			if not functionValue then
				self.runTime:runTimeError("typeError", "Attempt to call a nil value")
			end

			if functionValue.valueType == "function" then
				return self:executeFunctionBody(functionValue.body, functionValue.parameters, arguments, functionValue.environment)
			elseif functionValue.valueType == "luaFunction" then
				local functionValue: value.luaFunctionValue = functionValue
				if functionValue.usesLuaTypes then
					for i,v in ipairs(arguments) do
						arguments[i] = value.toLuauValue(v)
					end
				end
				
				local ret
				
				if functionValue.takesSelf then
					ret = functionValue.value(functionValue.self, unpack(arguments))
				else
					ret = functionValue.value(unpack(arguments))
				end
				
				if functionValue.usesLuaTypes then
					return value.fromLuauValue(ret)
				else
					return ret
				end
			else
				self.runTime:runTimeError("typeError", `Type of '{functionValue.valueType}' cannot be called as a function.`)
			end
		elseif node:is("ifStatement") then
			local node: nodes.ifStatement = node
			local lastEvaluated: value.value<any> = value.nilValue()
			for index, clause in ipairs(node.clauses) do
				local conditionTrue: boolean = false
				if clause:is("ifClause") or clause:is("elseIfClause") then
					local clause: nodes.ifClause = clause
					local conditionValue = self:interpretAST(clause.condition, environment)

					if conditionValue.valueType == "boolean" then conditionTrue = conditionValue.value else
						conditionTrue = conditionValue.valueType ~= "nil"
					end
				elseif clause:is("elseClause") then conditionTrue = true end
				
				local tempEnvironment = environmentConstructor(environment)
				if conditionTrue then
					lastEvaluated = self:executeBody(clause.body, tempEnvironment)
					break
				end
			end
			return lastEvaluated
		elseif node:is("whileStatement") then
			local node: nodes.whileStatement = node
			local conditionValue = self:interpretAST(node.condition)
			local doCondition = conditionValue.value and conditionValue.valueType ~= "nil"

			if doCondition then
				local lastEvaluated: value.value<any> = value.nilValue()
				local startTime = tick()
				while true do
					local tempEnvironment = environmentConstructor(environment)
					conditionValue = self:interpretAST(node.condition)
					doCondition = conditionValue.value and conditionValue.valueType ~= "nil"
					if not doCondition then break end
					
					lastEvaluated = self:executeBody(node.body, tempEnvironment)
					if lastEvaluated.valueType == "breakSignal" then
						return lastEvaluated.value
					end
					if lastEvaluated.valueType == "continue" then
						continue
					end
					
					if tick() - startTime > self.runTime.statementTimeoutLength then
						return self.runTime:runTimeError("timeoutError", `While statement timed out, took more than {self.runTime.statementTimeoutLength} seconds to execute.`)
					end
				end
			end
		elseif node:is("forStatement") then
			local node: nodes.forStatement = node
			local loopValue = self:interpretAST(node.loopObject, environment)
			
			local iterator: (query: value.value<any>) -> () -> ...value.value<any>
			
			local iteratorLibrary: value.tableValue = environment:lookUpVariable("iterator")
			
			if loopValue.valueType == "number" then
				iterator = iteratorLibrary.value.number.value(loopValue).value
			elseif loopValue.valueType == "string" then
				iterator = iteratorLibrary.value.string.value(loopValue).value
			elseif loopValue.valueType == "table" then
				iterator = iteratorLibrary.value.table.value(loopValue).value
			elseif loopValue.valueType == "luaFunction" then
				iterator = loopValue.value
			elseif loopValue.valueType == "function" then
				local loopValue: value.functionValue = loopValue
				iterator = function()
					return table.unpack(self:executeFunctionBody(loopValue.body, loopValue.parameters, {}, loopValue.environment).value or {})
				end
			else
				self.runTime:runTimeError("typeError", `Value of type '{loopValue.valueType}' does not support for loops.`)
			end
			
			local startTime = tick()
			local lastEvaluated = value.nilValue()
			while true do
				local arguments: {value.value<any>} = table.pack(iterator())
				if #arguments < 1 then break end
				
				local tempEnvironment = environmentConstructor(environment)
				
				for i, v in ipairs(arguments) do
					if node.parameters[i] then
						tempEnvironment:declareVariable(node.parameters[i], v)
					end
				end
				
				lastEvaluated = self:executeBody(node.body, tempEnvironment)
				if lastEvaluated.valueType == "breakSignal" then
					return lastEvaluated.value
				end
				if lastEvaluated.valueType == "continue" then
					continue
				end
				
				if tick() - startTime > self.runTime.statementTimeoutLength then
					return self.runTime:runTimeError("timeoutError", `While statement timed out, took more than {self.runTime.statementTimeoutLength} seconds to execute.`)
				end
			end
			
			return lastEvaluated
		elseif node:is("property") then
			return self:interpretAST((node::nodes.property).value, environment)
		elseif node:is("binaryExpression") then
			return executor:evaluateBinaryExpression(node, environment)
		elseif node:is("programRoot") then
			return executor:interpretProgramRoot(node, environment)
		elseif node:is("functionDeclaration") then
			local node: nodes.functionDeclaration = node
			local functionValue = value.functionValue(node.identifier, node.parameters, environmentConstructor(environment), node.body)
			if node.identifier then
				if node.identifier:is("identifier") then
					environment:declareVariable(node.identifier.symbol, functionValue)
				elseif node.identifier:is("memberExpression") then
					local identifier: nodes.memberExpression = node.identifier
					local tableValue = self:interpretAST(identifier.object, environment)

					if identifier.computed then
						tableValue.value[self:interpretAST(identifier.property, environment).value] = functionValue
					else
						tableValue.value[identifier.property.symbol] = functionValue
					end
				end
			end
			return functionValue
		elseif node:is("variableDeclaration") then
			local value = self:interpretAST((node::nodes.variableDeclaration).value, environment)
			environment:declareVariable((node::nodes.variableDeclaration).identifier,value)
			return value
		elseif node:is("variableAssignment") then
			local node: nodes.variableAssignment = node
			local value = self:interpretAST(node.value, environment)
			local prefix = (node::nodes.variableAssignment).prefix

			if type(node.identifier) == "string" then
				if prefix then
					local currentVariableValue = environment:lookUpVariable(node.identifier)
					if not currentVariableValue then
						return self.runTime:runTimeError("referenceError", `Variable '{(node::nodes.variableAssignment).identifier}' not found.`)
					end
					value = self:twoValueOperation(currentVariableValue, value, prefix)
				end

				if not environment:setVariable((node::nodes.variableAssignment).identifier,value) then
					return self.runTime:runTimeError("referenceError", `Variable '{(node::nodes.variableAssignment).identifier}' not found.`)
				end
				return value
			elseif type(node.identifier) == "table" and node.identifier.nodeType == "memberExpression" then
				local currentPropertyValue = self:interpretAST(node.identifier, environment)
				if prefix then
					if not currentPropertyValue then
						return self.runTime:runTimeError("referenceError", `Property doesnt exist, cannot apply prefix on it`)
					end
					value = self:twoValueOperation(currentPropertyValue, value, prefix)
				end

				local identifier: nodes.memberExpression = node.identifier
				local tableValue: value.tableValue = self:interpretAST(identifier.object, environment)

				if identifier.computed then
					tableValue.value[self:interpretAST(identifier.property, environment).value] = value
				else
					if typeof(tableValue.value) == "table" then
						tableValue.value[identifier.property.symbol] = value
					else
						tableValue.value[identifier.property.symbol] = value.value
					end
				end
				return value
			end
		elseif node:is("returnStatement") then
			if not node.value then return value.returnSignal(value.nilValue()) end
			return value.returnSignal(self:interpretAST(node.value, environment))
		elseif node:is("breakStatement") then
			local node: nodes.breakFromLoopStatement = node
			return value.breakSignal(node.value and self:interpretAST(node.value, environment) or value.nilValue())
		elseif node:is("continueStatement") then
			return value.continueSignal()
		else
			print("Unrecognized Node:", node)
			return self.runTime:runTimeError("syntaxError", `Unrecognized AST Node of type {node.nodeType} detected when interpreting AST.`)
		end
	end

	function executor:evaluateNumericBinaryExpression(left, right, operation)
		if operation == "+" then
			return value.numberValue(left.value + right.value)
		elseif operation == "/" then
			return value.numberValue(left.value / right.value)
		elseif operation == "-" then
			return value.numberValue(left.value - right.value)
		elseif operation == "*" then
			return value.numberValue(left.value * right.value)
		elseif operation == "%" then
			return value.numberValue(left.value % right.value)
		elseif operation == ">=" then
			return value.booleanValue(left.value >= right.value)
		elseif operation == "<=" then
			return value.booleanValue(left.value <= right.value)
		elseif operation == ">" then
			return value.booleanValue(left.value > right.value)
		elseif operation == "<" then
			return value.booleanValue(left.value < right.value)
		end
	end

	function executor:evaluateBooleanBinaryExpression(left, right, operation)
		if operation == "or" then
			return value.booleanValue(left.value or right.value)
		elseif operation == "and" then
			return value.booleanValue(left.value and right.value)
		elseif operation == "not" then
			return value.booleanValue(not right.value)
		end
	end

	function executor:evaluateStringBinaryExpression(left, right, operation)
		if operation == "+" then
			return value.stringValue(left.value .. right.value)
		else
			return self.runTime:runTimeError("syntaxError", `Operation '{operation}' not supported on string types.`)
		end
	end

	function executor:twoValueOperation(left, right, operator)
		if left and right then
			if operator == "==" then
				return value.booleanValue(left.valueType == right.valueType and left.value == right.value)
			elseif operator == "~=" then
				return value.booleanValue(left.value ~= right.value)
			end
			
			if left.valueType == "number" and right.valueType == "number" then
				return self:evaluateNumericBinaryExpression(left, right, operator)
			end

			if left.valueType == "string" and right.valueType == "string" then
				return self:evaluateStringBinaryExpression(left, right, operator)
			end

			if ((left.valueType == "number" and right.valueType == "string") or (right.valueType == "number" and left.valueType == "string")) and operator == "+" then
				return value.stringValue(left.value .. right.value)
			end

			if left.valueType == "string" and right.valueType == "number" and operator == "*" then
				local text = ""
				for i = 1, right.value do
					text ..= left.value
				end
				return value.stringValue(text)
			end
		end

		if (not left or left.valueType == "boolean") and right.valueType == "boolean" then
			return self:evaluateBooleanBinaryExpression(left, right, operator)
		end

		return value.nilValue()
	end

	function executor:evaluateBinaryExpression(binop: nodes.binaryExpression, environment)
		local left = binop.left and self:interpretAST(binop.left, environment) or nil
		local right = binop.right and self:interpretAST(binop.right, environment) or nil
		return executor:twoValueOperation(left, right, binop.operator)
	end
	
	function executor:executeBody(body: {nodes.node}, environment)
		local lastEvaluated: value.value<any> = value.nilValue()
		for index, statement in ipairs(body) do
			lastEvaluated = self:interpretAST(statement, environment)
			if lastEvaluated and (lastEvaluated.valueType == "breakSignal" or lastEvaluated.valueType == "continueSignal" or lastEvaluated.valueType == "returnSignal") then
				return lastEvaluated
			end
		end
		return lastEvaluated
	end
	
	function executor:executeFunctionBody(body: {nodes.node}, parameters: {string}, arguments: {value.value<any>}, environment: types.environment)
		for i, v in ipairs(parameters) do
			environment:declareVariable(v, arguments[i] or value.nilValue())
		end
		
		local result = self:executeBody(body, environment)
		if result.valueType == "returnSignal" then
			return result.value
		end
		return result
	end

	function executor:interpretProgramRoot(programRoot: nodes.programRoot, environment)
		local result = self:executeBody(programRoot.body, environment)
		if result.valueType == "returnSignal" then
			return result.value
		end
		return result
	end

	return executor
end