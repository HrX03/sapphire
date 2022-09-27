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
	ExportKeyword? DefineKeyword NL* simpleIdentifier NL* functionArguments? (
		NL* COLON NL* type
	)? (NL* assignment)?;
assignStatement: simpleIdentifier NL* assignment;
returnStatement: ReturnKeyword NL* expression?;
undefineStatement: UndefineKeyword NL* simpleIdentifier;
conditionalStatement: ifBlock elifBlock* elseBlock?;
whileStatement: WhileKeyword condition scope;

ifBlock: IfKeyword condition scope;
elifBlock: ElifKeyword condition scope;
elseBlock: ElseKeyword scope;

condition: LPAREN expression RPAREN;
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

functionCall: LPAREN exprList? RPAREN;
dict: LSSTHAN LSQUARE exprDict? RSQUARE GRTTHAN;
tuple: LPAREN exprList? RPAREN;
list: LSQUARE exprList? RSQUARE;
identifier: (Identifier DOT)? Identifier functionCall?;
simpleIdentifier: Identifier;
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
	| TypeKeyword;

complexType: complexTypeName typeList?;
complexTypeName: (
		ListKeyword
		| DictionaryKeyword
		| TupleKeyword
		| FunctionKeyword (COLON type)?
	);

typeList: LSSTHAN type (COMMA type)* COMMA? GRTTHAN;