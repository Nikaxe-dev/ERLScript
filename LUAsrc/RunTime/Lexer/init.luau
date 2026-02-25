local types = require("./RunTimeTypes")
local token = require(script.Token)

return function(runTime: types.runTime)
	local lexer: types.lexer = {
		runTime = runTime,
		
		text = "",
		position = 0,
		character = "",
		tokens = {},
	}
	
	function lexer:addToken(token: types.token)
		table.insert(self.tokens, token)
	end
	
	function lexer:advance()
		if self.position == string.len(self.text) then
			self.character = nil
			return
		end
		
		self.position += 1
		self.character = string.sub(self.text, self.position, self.position)
		
		return self.character
	end
	
	function lexer:makeIdentifier()
		local result = ""
		for _=1,string.len(self.text) do
			if not self.character then continue end
			if string.match(self.character, "%a") or self.character == "_" or tonumber(self.character) then
				result ..= self.character
				self:advance()
			else
				self.position -= 1
				break
			end
		end
		
		return table.find(self.runTime.keywords, result) and token("KEYWORD", result) or token("IDENTIFIER", result)
	end
	
	function lexer:makeNumber()
		local result = ""
		local index = 1
		while self.character ~= nil do
			if tonumber(self.character) or self.character == "." or (self.character == "-" and index == 1) then
				result ..= self.character
				self:advance()
			else
				self.position -= 1
				break
			end
			index += 1
		end
		return token("NUMBER", tonumber(result))
	end
	
	function lexer:canMakeMultiCharacterToken(operation)
		for i = 0, #operation-1 do
			local character = string.sub(self.text, self.position+i, self.position+i)
			if character ~= string.sub(operation,i+1,i+1) then
				return false
			end
		end
		return true
	end
	
	function lexer:process(text)
		self.text = text
		self.position = -1
		
		self.tokens = {}
		self.currentText = text or self.currentText
		
		self:advance()
		
		local insideString = false
		local stringText = ""
		
		while self.character do
			if self.character then
				if not insideString then
					local post = string.sub(self.text, self.position+1, self.position+1) or ""
					local prev = string.sub(self.text, self.position-1, self.position-1) or ""
					
					if table.find({""," ", "\n", "\t"}, self.character) then
					elseif self.character == "(" then
						self:addToken(token("LPAREN"))
					elseif self.character == ")" then
						self:addToken(token("RPAREN"))
					elseif self.character == "{" then
						self:addToken(token("LBRACKET"))
					elseif self.character == "}" then
						self:addToken(token("RBRACKET"))
					elseif self.character == "[" then
						self:addToken(token("LBRACE"))
					elseif self.character == "]" then
						self:addToken(token("RBRACE"))
					elseif self.character == "," then
						self:addToken(token("COMMA"))
					elseif self.character == "." and not tonumber(post) then
						--local prev = string.sub(self.text, self.position-1, self.position-1)
						--local next = string.sub(self.text, self.position+1, self.position+1)
						--if prev and next then
						--	if not tonumber(prev) and not tonumber(next) then
						--		self:addToken(token("DOT"))
						--	end
						--end
						self:addToken(token("DOT"))
					elseif self:canMakeMultiCharacterToken("or") then
						self:addToken(token("OPERATION", "or"))
						self:advance()
					elseif self:canMakeMultiCharacterToken("and") then
						self:addToken(token("OPERATION", "and"))
						self:advance()
						self:advance()
					elseif self:canMakeMultiCharacterToken("not") then
						self:addToken(token("NOT"))
						self:advance()
						self:advance()
					elseif self:canMakeMultiCharacterToken("==") then
						self:addToken(token("OPERATION", "=="))
						self:advance()
					elseif self:canMakeMultiCharacterToken("~=") then
						self:addToken(token("OPERATION", "~="))
						self:advance()
					elseif self:canMakeMultiCharacterToken(">=") then
						self:addToken(token("OPERATION", ">="))
						self:advance()
					elseif self:canMakeMultiCharacterToken("<=") then
						self:addToken(token("OPERATION", "<="))
						self:advance()
					elseif self.character == "<" or self.character == ">" then
						self:addToken(token("OPERATION", self.character))
					elseif self.character == "=" then
						self:addToken(token("COMPARE", self.character))
					elseif string.match(self.character, "%a") or self.character == "_" then
						self:addToken(self:makeIdentifier())
					elseif tonumber(self.character) or self.character == "." or (self.character == "-" and (tonumber(post) or post == ".") and not tonumber(prev)) then
						self:addToken(self:makeNumber())
					elseif table.find({"+","-","*","/","%"}, self.character) then
						self:addToken(token("OPERATION", self.character))
					end
					self:advance()
				end
				
				if table.find({`'`,`"`,"`"}, self.character) then
					if insideString then
						self:addToken(token("STRING", stringText))
					else
						stringText = ""
					end
					self:advance()
					insideString = not insideString
				end
				
				if insideString then
					stringText ..= self.character
					self:advance()
				end
			end
		end
		
		self:addToken(token("EOF"))
		return self.tokens
	end
	
	return lexer
end