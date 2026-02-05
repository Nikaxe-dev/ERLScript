local value = require(script.Parent.Value)
local nodes = require(script.Parent.Parser.Nodes)

export type lexer = {
	runTime: runTime,

	text: string,
	position: number,
	character: string,
	tokens: {token},

	process: (self: lexer, text: string?) -> {token},
	advance: (self: lexer) -> nil,
	addToken: (self: lexer, token: token) -> nil,
	makeIdentifier: (self: lexer) -> nil,
	makeNumber: (self: lexer) -> nil,
	canMakeMultiCharacterToken: (self: lexer, operation: string) -> boolean?,
}

export type executor = {
	runTime: runTime,
	
	interpretAST: (self: executor, node: nodes.node, environment: environment) -> value.value<any>?,
	evaluateBinaryExpression: (self: executor, binop: nodes.expression, environment: environment) -> value.value<any>,
	interpretProgramRoot: (self: executor, programRoot: nodes.programRoot, environment: environment) -> value.value<any>,
	evaluateNumericBinaryExpression: (self: executor, value1: value.numberValue, value2: value.numberValue, operator: string) -> value.numberValue,
	evaluateStringBinaryExpression: (self: executor, value1: value.stringValue, value2: value.stringValue, operator: string) -> value.stringValue,
	evaluateBooleanBinaryExpression: (self: executor, value1: value.booleanValue, value2: value.booleanValue, operator: string) -> value.booleanValue,
	twoValueOperation: (self: executor, left: value.value<any>, right: value.value<any>, operator: string) -> value.value<any>,
	executeBody: (self: executor, body: {nodes.node}, environment: environment) -> value.value<any>,
	executeFunctionBody: (self: executor, body: {nodes.node}, parameters: {string}, arguments: {value.value<any>}, environment: environment) -> value.value<any>
}

export type parser = {
	runTime: runTime,
	
	tokens: {token},
	token: token,
	position: number,
	stringCharacter: string?,
	
	advance: (self: parser) -> token,
	parseTokens: (self: parser, tokens: {token}) -> nodes.programRoot,
	createStatement: (self: parser) -> nodes.node,
	createExpression: (self: parser) -> nodes.expression,
	parsePrimaryExpression: (self: parser) -> nodes.expression,
	parseAdditiveExpression: (self: parser) -> nodes.expression,
	parseMultiplicitiveExpression: (self: parser) -> nodes.expression,
	parseTableExpression: (self: parser) -> nodes.expression,
	parseCallMemberExpression: (self: parser) -> nodes.expression,
	parseCallExpression: (self: parser, caller: nodes.expression) -> nodes.expression,
	parseCallArguments: (self: parser) -> {nodes.expression},
	parseArgumentsList: (self: parser) -> {nodes.expression},
	parseMemberExpression: (self: parser) -> nodes.expression,
	parseBooleanExpression: (self: parser) -> nodes.expression,
	parseComparisonExpression: (self: parser) -> nodes.expression,
	parseIfStatement: (self: parser) -> nodes.ifStatement,
	parseWhileStatement: (self: parser) -> nodes.whileStatement,
	parseForStatement: (self: parser) -> nodes.forStatement,
}

export type runTimeSettings = {
	globals: {
		[string]: any
	}
}

export type runTime = {
	environment: environment,
	
	keywords: {string},

	settings: runTimeSettings,

	lexer: lexer,
	executor: executor,
	parser: parser,

	execute: (self: runTime, code: string) -> value.value<any>,
	
	runTimeError: (self: runTime, errorType: error, ...string) -> string,
	runTimeWarn: (self: runTime, errorType: error, ...string) -> string,
	setGlobalScopeVariables: (self: runTime) -> nil,
	
	statementTimeoutLength: number,
}

export type tokenType =
| "NUMBER"
| "STRING"
| "STRINGCHARACTER"
| "BOOLEAN"
| "IDENTIFIER"
| "KEYWORD"
| "LPAREN"
| "RPAREN"
| "OPERATION"
| "NOT"
| "COMPARE"
| "COMMA"
| "DOT"
| "EOF"
| "LBRACKET"
| "RBRACKET"
| "LBRACE"
| "RBRACE"

export type error =
| "typeError"
| "referenceError"
| "syntaxError"
| "timeoutError"

export type token = {
	tokenType: tokenType,
	tokenValue: string?,
	is: (self: token, type: tokenType) -> boolean,
}

export type environment = {
	parent: environment?,
	variables: {[string]: value.value<any>},
	declareVariable: (self: environment, name: string, value: value.value<any>) -> value.value<any>,
	setVariable: (self: environment, name: string, value: value.value<any>) -> value.value<any>?,
	lookUpVariable: (self: environment, name: string) -> value.value<any>,
	resolve: (self: environment, name: string) -> environment
}

return nil