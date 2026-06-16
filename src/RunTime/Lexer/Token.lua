local types = require("../RunTimeTypes")

return function(tokenType: types.tokenType, tokenValue: string?): types.token
	local t = {
		tokenType = tokenType,
		tokenValue = tokenValue
	}
	function t:is(tokenType: types.tokenType)
		return t.tokenType == tokenType
	end
	return t 
end