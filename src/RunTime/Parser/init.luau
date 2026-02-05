local types = require("./RunTimeTypes")
local value = require("./Value")
local nodes = require("@self/Nodes")
local environment = require("./Environment")

return function(runTime): types.parser
	local parser: types.parser = {
		runTime = runTime,

		tokens = {},
		token = nil,
		position = 0,
		stringCharacter = nil,
	}

	function parser:advance()
		if self.position == #self.tokens then
			self.token = nil
			return
		end

		self.position += 1
		self.token = self.tokens[self.position]

		return self.token
	end

	function parser:parseTokens(tokens: {types.token}): nodes.programRoot
		self.tokens = tokens
		self.position = 0
		self.token = self:advance()
		self.stringCharacter = nil
		
		local program = nodes.programRoot({})
		
		while not self.token:is("EOF") do
			table.insert(program.body, self:createStatement())
		end
		
		return program
	end
	
	function parser:parseForStatement()
		if self.token:is("KEYWORD") and self.token.tokenValue == "for" then
			self:advance()
			if not self.token:is("LPAREN") then
				return self.runTime:runTimeError("syntaxError", `Expected open parenthesis to start for statement parameters, got {self.token.tokenType}({self.token.tokenValue})`)
			end
			
			self:advance()
			local parameters: {string} = {}
			if not self.token:is("RPAREN") then
				if self.token:is("IDENTIFIER") then
					table.insert(parameters, self.token.tokenValue)
					self:advance()
					while not self.token:is("EOF") and not self.token:is("RPAREN") and self.token:is("COMMA") do
						self:advance()
						if self.token:is("IDENTIFIER") then
							table.insert(parameters, self.token.tokenValue)
						else
							return self.runTime:runTimeError("syntaxError", `Expected identifier in for statement parameters, got {self.token.tokenType}({self.token.tokenValue})`)
						end
						self:advance()
					end
				else
					return self.runTime:runTimeError("syntaxError", `Expected identifier in for statement parameters, got {self.token.tokenType}({self.token.tokenValue})`)
				end
			end
			
			if not self.token:is("RPAREN") then
				return self.runTime:runTimeError("syntaxError", `Expected closed parenthesis to end for statement parameters, got {self.token.tokenType}({self.token.tokenValue})`)
			end
			
			self:advance()
			if not self.token:is("LPAREN") then
				return self.runTime:runTimeError("syntaxError", `Expected opened parenthesis to start for statement loop object, got {self.token.tokenType}({self.token.tokenValue})`)
			end
			self:advance()
			
			local loopObject = self:createStatement()
			
			if not self.token:is("RPAREN") then
				return self.runTime:runTimeError("syntaxError", `Expected closed parenthesis to end for statement loop object, got {self.token.tokenType}({self.token.tokenValue})`)
			end
			self:advance()
			
			if not self.token:is("LBRACKET") then
				return self.runTime:runTimeError("syntaxError", `Expected opened bracket to start for statement code block, got {self.token.tokenType}({self.token.tokenValue})`)
			end
			self:advance()
			
			local body: {nodes.node} = {}
			while not self.token:is("EOF") and not self.token:is("RBRACKET") do
				table.insert(body, self:createStatement())
			end
			
			if not self.token:is("RBRACKET") then
				return self.runTime:runTimeError("syntaxError", `Expected closed brackets for for statement code block, got {self.token.tokenType}({self.token.tokenValue})`)
			end
			self:advance()
			
			return nodes.forStatement(body, parameters, loopObject)
		else
			return self:parseWhileStatement()
		end
	end
	
	function parser:parseWhileStatement()
		if self.token:is("KEYWORD") and self.token.tokenValue == "while" then
			-- (while) ( condition ) { body }
			
			self:advance()
			if not self.token:is("LPAREN") then
				return self.runTime:runTimeError("syntaxError", `Expected open parenthesis to start while statement condition, got {self.token.tokenType}({self.token.tokenValue})`)
			end
			
			self:advance()
			local condition = self:createStatement()
			if not self.token:is("RPAREN")  then
				return self.runTime:runTimeError("syntaxError", `Expected closed parenthesis to end while statement condition, got {self.token.tokenType}({self.token.tokenValue})`)
			end
			
			self:advance()
			if not self.token:is("LBRACKET") then
				return self.runTime:runTimeError("syntaxError", `Expected open brackets for while statement code block, got {self.token.tokenType}({self.token.tokenValue})`)
			end
			self:advance()
			
			local body: {nodes.node} = {}
			while not self.token:is("EOF") and not self.token:is("RBRACKET") do
				table.insert(body, self:createStatement())
			end
			
			if not self.token:is("RBRACKET") then
				return self.runTime:runTimeError("syntaxError", `Expected closed brackets for while statement code block, got {self.token.tokenType}({self.token.tokenValue})`)
			end
			self:advance()
			
			return nodes.whileStatement(condition, body)
		else
			return self:parseIfStatement()
		end
	end
	
	function parser:parseIfStatement()
		if self.token:is("KEYWORD") and self.token.tokenValue == "if" then
			local clauses: {nodes.clause} = {}
			
			self:advance()
			if not self.token:is("LPAREN") then
				return self.runTime:runTimeError("syntaxError", "Expected open parenthesis to start if statement")
			end
			self:advance()
			local condition = self:createStatement()
			if not self.token:is("RPAREN") then
				return self.runTime:runTimeError("syntaxError", `Expected closed parenthesis, got {self.token.tokenType}({self.token.tokenValue})`)
			end
			
			self:advance()
			if not self.token:is("LBRACKET") then
				return self.runTime:runTimeError("syntaxError", `Expected open brackets for if statement code block, got {self.token.tokenType}({self.token.tokenValue})`)
			end
			self:advance()
			
			local body: {nodes.node} = {}
			while not self.token:is("EOF") and not self.token:is("RBRACKET") do
				table.insert(body, self:createStatement())
			end
			
			if not self.token:is("RBRACKET") then
				return self.runTime:runTimeError("syntaxError", `Expected closed brackets for if statement code block, got {self.token.tokenType}({self.token.tokenValue})`)
			end
			self:advance()
			
			table.insert(clauses, nodes.ifClause(body, condition))
			
			while not self.token:is("EOF") and self.token:is("KEYWORD") do
				if self.token.tokenValue == "else" then
					self:advance()
					if not self.token:is("LBRACKET") then
						return self.runTime:runTimeError("syntaxError", `Expected open brackets for if statement code block, got {self.token.tokenType}({self.token.tokenValue})`)
					end
					self:advance()
					
					local body: {nodes.node} = {}
					while not self.token:is("EOF") and not self.token:is("RBRACKET") do
						table.insert(body, self:createStatement())
					end
					
					if not self.token:is("RBRACKET") then
						return self.runTime:runTimeError("syntaxError", `Expected closed brackets for if statement code block, got {self.token.tokenType}({self.token.tokenValue})`)
					end
					self:advance()
					
					table.insert(clauses, nodes.elseClause(body))
					break
				elseif self.token.tokenValue == "elseif" then
					self:advance()
					if not self.token:is("LPAREN") then
						return self.runTime:runTimeError("syntaxError", `Expected opened parenthesis to start elseif clause, got {self.token.tokenType}({self.token.tokenValue})`)
					end
					
					self:advance()
					local condition = self:createExpression()
					if not self.token:is("RPAREN") then
						return self.runTime:runTimeError("syntaxError", `Expected closed parenthesis, got {self.token.tokenType}({self.token.tokenValue})`)
					end
					
					self:advance()

					local body: {nodes.node} = {}
					while not self.token:is("EOF") and not self.token:is("RBRACKET") do
						table.insert(body, self:createStatement())
					end

					if not self.token:is("RBRACKET") then
						return self.runTime:runTimeError("syntaxError", `Expected closed brackets for if statement code block, got {self.token.tokenType}({self.token.tokenValue})`)
					end
					self:advance()
					
					table.insert(clauses, nodes.elseIfClause(body, condition))
				else
					break
				end
			end
			
			return nodes.ifStatement(clauses)
		else
			return self:createExpression()
		end
	end
	
	function parser:createStatement()
		return self:parseForStatement()
	end
	
	function parser:createExpression()
		return self:parseTableExpression()
	end
	
	function parser:parseTableExpression()
		if not self.token:is("LBRACKET") then
			return self:parseComparisonExpression()
		end
		self:advance()
		local properties: {[string | number]: nodes.property} = {}
		while not self.token:is("EOF") and not self.token:is("RBRACKET") do
			if self.token:is("COMMA") then self:advance() end
			
			local compareToken = self.tokens[self.position+1]
			if compareToken:is("COMPARE") or compareToken.tokenValue == "=" then
				local identifierToken = self.token
				self:advance()
				self:advance()
				local value = self:createStatement()
				properties[identifierToken.tokenValue] = nodes.property(identifierToken.tokenValue, value)
			else
				local expression = self:createExpression()
				table.insert(properties, nodes.property(nil, expression))
			end
		end
		
		if not self.token:is("RBRACKET") then
			return self.runTime:runTimeError("syntaxError", "Expected closing bracket to end table declaration.")
		end
		
		self:advance()
		
		return nodes.tableLiteral(properties)
	end
	
	function parser:parseComparisonExpression()
		local left = self:parseBooleanExpression()
		
		while table.find({"~=","==","<=",">=", ">", "<"}, self.token.tokenValue) do
			local operator = self.token.tokenValue
			self:advance()
			local right = self:parseBooleanExpression()
			left = nodes.binaryExpression(left, right, operator)
		end
		
		return left
	end
	
	function parser:parseBooleanExpression()
		local left = self:parseAdditiveExpression()
		
		while self.token.tokenValue == "and" or self.token.tokenValue == "or" do
			local operator = self.token.tokenValue
			self:advance()
			local right = self:parseAdditiveExpression()
			left = nodes.binaryExpression(left, right, operator)
		end
		
		return left
	end
	
	function parser:parseAdditiveExpression()
		local left = self:parseMultiplicitiveExpression()
		
		while self.token.tokenValue == "+" or self.token.tokenValue == "-" do
			local operator = self.token.tokenValue
			self:advance()
			local right = self:parseMultiplicitiveExpression()
			left = nodes.binaryExpression(left, right, operator)
		end
		
		return left
	end
	
	function parser:parseMultiplicitiveExpression()
		local left = self:parseCallMemberExpression()

		while self.token.tokenValue == "/" or self.token.tokenValue == "*" or self.token.tokenValue == "%" do
			local operator = self.token.tokenValue
			self:advance()
			local right = self:parseCallMemberExpression()
			left = nodes.binaryExpression(left, right, operator)
		end

		return left
	end
	
	-- foo.x() foo["x"]()
	
	function parser:parseCallMemberExpression()
		--local member = self:parseMemberExpression()
		
		--if self.token:is("LPAREN") then
		--	return self:parseCallExpression(member)
		--end
		
		--return member
		
		local expression = self:parseMemberExpression()
		
		while true do
			if self.token:is("LPAREN") then
				expression = self:parseCallExpression(expression)
			elseif self.token:is("DOT") or self.token:is("LBRACE") then
				local operator = self.token
				self:advance()
				
				local property
				local computed
				
				if operator:is("DOT") then
					computed = false
					property = self:parsePrimaryExpression()
					
					if not property:is("identifier") then
						return self.runTime:runTimeError("syntaxError", "Dot operator must be followed by an identifier.")
					end
				else
					computed = true
					property = self:createExpression()
					if not self.token:is("RBRACE") then
						return self.runTime:runTimeError("syntaxError", "Missing closing brace in computed property")
					end
					self:advance()
				end
				
				expression = nodes.memberExpression(expression, property, computed)
			else
				break
			end
		end
		
		return expression
	end
	
	function parser:parseCallExpression(caller)
		local callExpression = nodes.callExpression(self:parseCallArguments(), caller)
		
		if self.token:is("LPAREN") then
			callExpression = self:parseCallExpression(callExpression)
		end
		
		return callExpression
	end
	
	function parser:parseCallArguments()
		if not self.token:is("LPAREN") then
			self.runTime:runTimeError("syntaxError", "Expected open parenthesis")
		end
		self:advance()
		local args = self.token:is("RPAREN") and {} or self:parseArgumentsList()
		if not self.token:is("RPAREN") then
			self.runTime:runTimeError("syntaxError", "Missing closing parenthesis inside function call")
		end
		self:advance()
		return args
	end
	
	function parser:parseArgumentsList()
		local args = {self:createStatement()}
		
		while not self.token:is("EOF") and self.token:is("COMMA") do
			self:advance()
			table.insert(args, self:createStatement())
		end
		
		return args
	end
	
	function parser:parseMemberExpression()
		local object = self:parsePrimaryExpression()
		
		while self.token:is("DOT") or self.token:is("LBRACE") do
			local operator = self.token
			self:advance()
			local property: nodes.expression
			local computed: boolean
			
			if operator:is("DOT") then
				computed = false
				property = self:parsePrimaryExpression()
				
				local prefixToken = self.tokens[self.position + 1]
				local assignmentToken = self.token
				
				if prefixToken and prefixToken.tokenValue == "=" then
					prefixToken, assignmentToken = assignmentToken, prefixToken
				end
				
				if assignmentToken and assignmentToken.tokenValue == "=" then
					local memberExpression = nodes.memberExpression(object, property, computed)
					
					if prefixToken:is("OPERATION") then
						self:advance()
						self:advance()
						return nodes.variableAssignment(memberExpression, self:createExpression(), prefixToken.tokenValue)
					end
					
					self:advance()
					return nodes.variableAssignment(memberExpression, self:createExpression())
				end
				
				if not property:is("identifier") then
					return self.runTime:runTimeError("syntaxError", "Cannot use dot operator without right side being an identifier.")
				end
			else
				computed = true
				property = self:createExpression()
				if not self.token:is("RBRACE") then
					self.runTime:runTimeError("syntaxError", "Missing closing brace in computed value")
				end
				self:advance()
				
				local prefixToken = self.tokens[self.position + 1]
				local assignmentToken = self.token
				
				if prefixToken.tokenValue == "=" then
					prefixToken, assignmentToken = assignmentToken, prefixToken
				end
				
				if assignmentToken.tokenValue == "=" then
					local memberExpression = nodes.memberExpression(object, property, computed)
					
					if prefixToken:is("OPERATION") then
						self:advance()
						self:advance()
						return nodes.variableAssignment(memberExpression, self:createExpression(), prefixToken.tokenValue)
					end
					
					self:advance()
					return nodes.variableAssignment(memberExpression, self:createExpression())
				end
			end
			
			object = nodes.memberExpression(object, property, computed)
		end
		
		return object
	end
	
	-- Orders of prescidence
	-- AsignmentExpression
	-- MemberExpression
	-- FunctionCall
	-- LogicalExpression
	-- ComparisonExpression
	-- AdditiveExpression
	-- MultiplicitiveExpression
	-- UnaryExpression
	-- PrimaryExpression
	
	function parser:parsePrimaryExpression()
		local token = self.token
		if token:is("IDENTIFIER") then
			local prev = self.tokens[self.position-1]
			if prev and prev:is("DOT") then
				self:advance()
				return nodes.identifier(token.tokenValue)
			end
			
			local assignmentOperator = self.tokens[self.position+1]
			local secondary = self.tokens[self.position+2]
			if assignmentOperator.tokenValue == "=" then
				self:advance()
				self:advance()
				local value = self:createExpression()
				return nodes.variableAssignment(token.tokenValue, value)
			elseif assignmentOperator:is("OPERATION") and secondary.tokenValue == "=" then
				self:advance()
				self:advance()
				self:advance()
				local value = self:createExpression()
				return nodes.variableAssignment(token.tokenValue, value, assignmentOperator.tokenValue)
			end
			self:advance()
			return nodes.identifier(token.tokenValue)
		elseif token:is("NOT") then
			self:advance()
			return nodes.binaryExpression(nil, self:createExpression(), "not")
		elseif token:is("NUMBER") then
			self:advance()
			return nodes.numericLiteral(tonumber(token.tokenValue))
		elseif token:is("STRING") then
			self:advance()
			return nodes.stringLiteral(token.tokenValue, self.stringCharacter)
		elseif token:is("LPAREN") then
			self:advance()
			local value = self:createExpression()
			if not self.token:is("RPAREN") then
				return self.runTime:runTimeError("syntaxError", "Expected closing parenthesis.")
			end
			self:advance()
			return value
		elseif token:is("KEYWORD") then
			if token.tokenValue == "var" then
				local identifierToken = self:advance()
				local assignmentOperator = self:advance()
				self:advance()
				local value = self:createExpression()
				return nodes.variableDeclaration(identifierToken.tokenValue, value)
			elseif token.tokenValue == "function" then
				local identifier: nodes.expression? = nil
				
				self:advance()
				
				if not self.token:is("LPAREN") then
					local name = self:parseMemberExpression()
					
					if not name:is("identifier") and not name:is("memberExpression") then
						self.runTime:runTimeError("syntaxError", `Cannot declare function name with anything other than a property of a table and an identifier.`)
					end
					
					if name then
						identifier = name
					end
				end
				
				local paramIdentifiers: {nodes.identifier} = self:parseCallArguments()
				local parameters: {string} = {}
				for index, identifier in ipairs(paramIdentifiers) do
					if not identifier:is("identifier") then
						self.runTime:runTimeError("syntaxError", `Inside function declaration expected parameter '{identifier.symbol}' to be of type string.`)
					end
					table.insert(parameters, identifier.symbol)
				end
				
				if not self.token:is("LBRACKET") then
					self.runTime:runTimeError("syntaxError", "Expected open bracket in function declaration for code block")
				end
				self:advance()
				
				local body: {nodes.node} = {}
				
				while not self.token:is("EOF") and not self.token:is("RBRACKET") do
					table.insert(body, self:createStatement())
				end
				
				if not self.token:is("RBRACKET") then
					self.runTime:runTimeError("syntaxError", "Expected closing bracket to end function declaration & code block")
				end
				self:advance()
				
				return nodes.functionDeclaration(identifier, parameters, body)
			elseif token.tokenValue == "return" then
				self:advance()
				local expr = nil
				if self.token and not self.token:is("RBRACKET") and not self.token:is("EOF") then
					expr = self:createStatement()
				end
				return nodes.returnStatement(expr)
			elseif token.tokenValue == "break" then
				self:advance()
				local expr = nil
				if self.token and not self.token:is("RBRACKET") and not self.token:is("EOF") then
					expr = self:createStatement()
				end
				return nodes.breakStatement(expr)
			elseif token.tokenValue == "continue" then
				self:advance()
				return nodes.continueStatement()
			else
				self:advance()
			end
		elseif token:is("RBRACKET") then
			self:advance()
		else
			print("Position & tokens table: ", self.position, self.tokens)
			return self.runTime:runTimeError("syntaxError", `Unexpected token '({token.tokenType}{token.tokenValue and `, {token.tokenValue}` or ""})' found during parsing!`)
		end
	end

	return parser
end