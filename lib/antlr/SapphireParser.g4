parser grammar SapphireParser;

options {
	tokenVocab = SapphireLexer;
}

file: NL* headerList? NL* statementList? EOF;
headerList: header (NL+ header)* NL*;
statementList: statement (NL+ statement)* NL*;

header: importHeader;
importHeader:
	ImportKeyword NL* string NL* (COLON NL* simpleIdentifier)?;

statement:
	scope
	| conditionalStatement
	| whileStatement
	| defineStatement
	| returnStatement
	| undefineStatement
	| identifier
	| assignStatement;

defineStatement:
	ExportKeyword? DefineKeyword NL* simpleIdentifier NL* functionDefinition? (
		NL* typeDefinition
	)? (NL* assignment)?;
assignStatement: simpleIdentifier NL* assignment;
returnStatement: ReturnKeyword NL* expression?;
undefineStatement: UndefineKeyword NL* simpleIdentifier;
conditionalStatement: ifBlock NL* elifBlock* NL* elseBlock?;
whileStatement: WhileKeyword condition NL* scope;

functionDefinition: typeArguments? NL* functionArguments;
typeDefinition: COLON NL* type;
typeArguments: LSSTHAN typeArgument (COMMA typeArgument)* COMMA? GRTTHAN;
typeArgument: typeIdentifier NL* typeDefinition?;

ifBlock: IfKeyword NL* condition NL* scope;
elifBlock: ElifKeyword NL* condition NL* scope;
elseBlock: ElseKeyword NL* scope;

condition: LPAREN NL* expression NL* RPAREN;
assignment: EQUALS NL* expression;

expression:
	scope
	| dict
	| tuple
	| list
	| literalConstant
	| string
	| type
	| identifier;

scope: LBRACKET NL* statementList? RBRACKET;

literalConstant:
	Number
	| Boolean
	| ThisKeyword
	| RootKeyword
	| NoneKeyword;

exprList: expression (COMMA expression)* COMMA?;
exprDict: exprDictEntry ( COMMA exprDictEntry)* COMMA?;
exprDictEntry: expression COLON expression;
functionArguments: LPAREN argumentList? RPAREN;
argumentList: argument (COMMA argument)* COMMA?;
argument: simpleIdentifier (COLON type)?;

functionCall: typeList? LPAREN exprList? RPAREN;
dict: LSSTHAN LSQUARE exprDict? RSQUARE GRTTHAN;
tuple: LPAREN exprList RPAREN;
list: LSQUARE exprList? RSQUARE;
identifier: (Identifier DOT)? Identifier functionCall?;
simpleIdentifier: Identifier;
typeIdentifier: TypeIdentifier;
string: OpenQuote stringContents* CloseQuote;
stringContents: Text | Escaped | UniEscaped;

type:
	complexType
	| AnyKeyword
	| NoneKeyword
	| StringKeyword
	| NumberKeyword
	| BooleanKeyword
	| ScopeKeyword
	| TypeKeyword
	| typeIdentifier;

complexType: complexTypeName typeList?;
complexTypeName: (
		ListKeyword
		| DictionaryKeyword
		| TupleKeyword
		| FunctionKeyword (COLON type)?
	);

typeList: LSSTHAN type (COMMA type)* COMMA? GRTTHAN;