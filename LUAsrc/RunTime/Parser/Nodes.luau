local module = {}

export type nodeType =
| "programRoot"

| "numericLiteral"
| "stringLiteral"

| "identifier"
| "binaryExpression"
| "expression"
| "memberExpression"
| "callExpression"

| "variableDeclaration"
| "variableAssignment"
| "functionDeclaration"

| "returnStatement"
| "breakStatement"
| "continueStatement"

| "ifStatement"
| "clause"
| "ifClause"
| "elseIfClause"
| "elseClause"

| "whileStatement"
| "forStatement"

| "property"
| "tableLiteral"

export type node = {nodeType: nodeType, is: (self: node, nodeType: nodeType) -> boolean}
local function node(nodeType: nodeType): node
	local node: node = {
		nodeType = nodeType
	}
	function node:is(nodeType: nodeType)
		return self.nodeType == nodeType
	end
	return node
end

export type programRoot = node & {
	body: {node}
}
local function programRoot(body: {node}): programRoot
	local res: programRoot = node("programRoot")
	res.body = body
	return res
end

export type expression = node & {}
local function expression(nodeType: nodeType): expression
	return node(nodeType or "expression")
end

export type binaryExpression = expression & {
	left: expression,
	right: expression,
	operator: string
}
local function binaryExpression(left: expression, right: expression, operator: string): binaryExpression
	local res: binaryExpression = expression("binaryExpression")
	res.left = left
	res.right = right
	res.operator = operator
	return res
end

export type identifier = expression & {
	symbol: string
}
local function identifier(symbol: string): identifier
	local res: identifier = expression("identifier")
	res.symbol = symbol
	return res
end

export type numericLiteral = expression & {
	value: number
}
local function numericLiteral(value: number): numericLiteral
	local res: numericLiteral = expression("numericLiteral")
	res.value = value
	return res
end

export type stringLiteral = expression & {
	value: string,
	stringCharacter: string,
}
local function stringLiteral(value: string, stringCharacter: string)
	local res: stringLiteral = expression("stringLiteral")
	res.value = value
	res.stringCharacter = stringCharacter
	return res
end

export type variableDeclaration = node & {
	identifier: string,
	value: expression,
}
local function variableDeclaration(identifier: string, value: expression)
	local res: variableDeclaration = node("variableDeclaration")
	res.value = value
	res.identifier = identifier
	return res
end

export type variableAssignment = node & {
	identifier: expression,
	value: expression,
	prefix: string?,
}
local function variableAssignment(identifier: expression, value: expression, prefix: string?)
	local res: variableAssignment = node("variableAssignment")
	res.value = value
	res.identifier = identifier
	res.prefix = prefix
	return res
end

export type functionDeclaration = node & {
	identifier: expression?,
	parameters: {string},
	body: {node},
}
local function functionDeclaration(identifier: expression?, parameters: {string}, body: {node})
	local res: functionDeclaration = node("functionDeclaration")
	res.identifier = identifier
	res.parameters = parameters
	res.body = body
	return res
end

export type property = node & {
	key: string?,
	value: expression,
}
local function property(key: string?, value: expression)
	local res: property = node("property")
	res.key = key
	res.value = value
	return res
end

export type tableLiteral = node & {
	properties: {[string | number]: property}
}
local function tableLiteral(properties: {[string | number]: property})
	local res: tableLiteral = node("tableLiteral")
	res.properties = properties
	return res
end

export type memberExpression = expression & {
	object: expression,
	property: expression,
	computed: boolean?,
}
local function memberExpression(object: expression, property: expression, computed: boolean?)
	local res: memberExpression = expression("memberExpression")
	res.object = object
	res.property = property
	res.computed = computed
	return res
end

export type callExpression = expression & {
	args: {expression},
	calle: expression
}
local function callExpression(args: {expression}, calle: expression)
	local res: callExpression = expression("callExpression")
	res.args = args
	res.calle = calle
	return res
end

export type returnStatement = node & {
	value: expression
}
local function returnStatement(value: expression)
	local res: returnStatement = node("returnStatement")
	res.value = value
	return res
end

export type value<T> = {
	toString: (self: value<any>) -> string,
	valueType: string,
	value: T,
}

export type breakFromLoopStatement = node & {
	value: expression
}
local function breakStatement(value: expression)
	local res: breakFromLoopStatement = node("breakStatement")
	res.value = value
	return res
end
local function continueStatement()
	return node("continueStatement")
end

module.breakStatement = breakStatement
module.continueStatement = continueStatement

export type clause = node & {
	body: {node},
}
local function clause(type: nodeType, body: {node})
	local res: clause = node(type)
	res.body = body
	return res
end

export type ifClause = clause & {
	condition: expression
}
local function ifClause(body: {node}, condition: expression)
	local res: ifClause = clause("ifClause", body)
	res.condition = condition
	return res
end

export type elseIfClause = clause & {
	condition: expression
}
local function elseIfClause(body: {node}, condition: expression)
	local res: elseIfClause = clause("elseIfClause", body)
	res.condition = condition
	return res
end

export type elseClause = clause
local function elseClause(body: {node})
	return clause("elseClause", body)
end

export type ifStatement = node & {
	clauses: {clause}
}
local function ifStatement(clauses: {clause})
	local res: ifStatement = node("ifStatement")
	res.clauses = clauses
	return res
end

export type whileStatement = node & {
	condition: expression,
	body: {node},
}
local function whileStatement(condition: expression, body: {node})
	local res: whileStatement = node("whileStatement")
	res.condition = condition
	res.body = body
	return res
end

export type forStatement = node & {
	body: {node},
	parameters: {string},
	loopObject: expression
}
local function forStatement(body: {node}, parameters: {string}, loopObject: expression)
	local res: forStatement = node("forStatement")
	res.body = body
	res.parameters = parameters
	res.loopObject = loopObject
	return res
end

module.ifStatement = ifStatement
module.ifClause = ifClause
module.elseIfClause = elseIfClause
module.elseClause = elseClause

module.whileStatement = whileStatement
module.forStatement = forStatement

module.node = node
module.programRoot = programRoot
module.expression = expression
module.binaryExpression = binaryExpression
module.identifier = identifier
module.numericLiteral = numericLiteral
module.stringLiteral = stringLiteral
module.variableDeclaration = variableDeclaration
module.variableAssignment = variableAssignment
module.functionDeclaration = functionDeclaration
module.property = property
module.tableLiteral = tableLiteral
module.callExpression = callExpression
module.memberExpression = memberExpression
module.returnStatement = returnStatement
return module