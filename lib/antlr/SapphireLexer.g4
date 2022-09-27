lexer grammar SapphireLexer;

tokens { Number }

// numbers
DecNumber: MINUS? Digit+ (DOT Digit+)? -> type(Number);
HexNumber: '0' [xX] HexDigit+ (UNDERSCORE HexDigit+)* -> type(Number);
BinaryNumber: '0' [bB] BinaryDigit+ (UNDERSCORE BinaryDigit+)* -> type(Number);

fragment HexDigit: [0-9a-fA-F];
fragment BinaryDigit: [0-1];
fragment Digit: [0-9];

// strings
OpenQuote: QUOTE -> pushMode(StringCtx);

// characters
COMMA: ',';
DOT: '.';
COLON: ':';
SEMI: ';';
EQUALS: '=';
MINUS: '-';
UNDERSCORE: '_';
QUOTE: '\'';
LSSTHAN: '<' -> pushMode(Inside);
GRTTHAN: '>';
LPAREN: '(' -> pushMode(Inside);
RPAREN: ')';
LSQUARE: '[' -> pushMode(Inside);
RSQUARE: ']';
LBRACKET: '{' -> pushMode(DEFAULT_MODE);
RBRACKET: '}' { try { popMode(); } catch(e) { } };

Boolean: TrueKeyword | FalseKeyword;

// keywords
ImportKeyword: 'import';
ExportKeyword: 'export';
ReturnKeyword: 'return';
DefineKeyword: 'def';
UndefineKeyword: 'undef';
TrueKeyword: 'true';
FalseKeyword: 'false';
ThisKeyword: 'this';
RootKeyword: 'root';
IfKeyword: 'if';
ElifKeyword: 'elif';
ElseKeyword: 'else';
WhileKeyword: 'while';

// keywords: types
AnyKeyword: 'any';
NoneKeyword: 'none';
StringKeyword: 'string';
NumberKeyword: 'num';
BooleanKeyword: 'bool';
ListKeyword: 'list';
DictionaryKeyword: 'dict';
TupleKeyword: 'tuple';
ScopeKeyword: 'scope';
FunctionKeyword: 'fun';
TypeKeyword: 'type';

Comment: '//' ~[\r\n]* -> channel(HIDDEN);
MultiLineComment: '/*' ( MultiLineComment | . )*? '*/' -> channel(HIDDEN);
WS: [ \t\f]+ -> channel(HIDDEN);
NL: ('\r'? '\n' | '\r' | '\f');

Identifier: [a-zA-Z][a-zA-Z0-9_]*;

mode StringCtx;
CloseQuote: QUOTE -> popMode;
Text: ~('\\' | '\'')+;
Escaped: '\\' ('t' | 'b' | 'r' | 'n' | '\'' | '"' | '\\');
UniEscaped: '\\' 'u' HexDigit HexDigit HexDigit HexDigit;

mode Inside;

Inside_DecNumber: DecNumber -> type(Number);
Inside_HexNumber: HexNumber -> type(Number);
Inside_BinaryNumber: BinaryNumber -> type(Number);

Inside_OpenQuote: OpenQuote -> pushMode(StringCtx), type(OpenQuote);

Inside_COMMA: COMMA -> type(COMMA);
Inside_DOT: DOT -> type(DOT);
Inside_COLON: COLON -> type(COLON);
Inside_SEMI: SEMI -> type(SEMI);
Inside_EQUALS: EQUALS -> type(EQUALS);
Inside_MINUS: MINUS -> type(MINUS);
Inside_UNDERSCORE: UNDERSCORE -> type(UNDERSCORE);
Inside_QUOTE: QUOTE -> type(QUOTE);
Inside_LSSTHAN: LSSTHAN -> pushMode(Inside), type(LSSTHAN);
Inside_GRTTHAN: GRTTHAN -> popMode, type(GRTTHAN);
Inside_LPAREN: LPAREN -> pushMode(Inside), type(LPAREN);
Inside_RPAREN: RPAREN -> popMode, type(RPAREN);
Inside_LSQUARE: LSQUARE -> pushMode(Inside), type(LSQUARE);
Inside_RSQUARE: RSQUARE -> popMode, type(RSQUARE);
Inside_LBRACKET: LBRACKET -> pushMode(DEFAULT_MODE), type(LBRACKET);
Inside_RBRACKET: RBRACKET -> popMode, type(RBRACKET);

Inside_Boolean: Boolean -> type(Boolean);

Inside_ExportKeyword: ExportKeyword -> type(ExportKeyword);
Inside_ImportKeyword: ImportKeyword -> type(ImportKeyword);
Inside_ReturnKeyword: ReturnKeyword -> type(ReturnKeyword);
Inside_DefineKeyword: DefineKeyword -> type(DefineKeyword);
Inside_UndefineKeyword: UndefineKeyword -> type(UndefineKeyword);
Inside_TrueKeyword: TrueKeyword -> type(TrueKeyword);
Inside_FalseKeyword: FalseKeyword -> type(FalseKeyword);
Inside_ThisKeyword: ThisKeyword -> type(ThisKeyword);
Inside_RootKeyword: RootKeyword -> type(RootKeyword);
Inside_IfKeyword: IfKeyword -> type(IfKeyword);
Inside_ElifKeyword: ElifKeyword -> type(ElifKeyword);
Inside_ElseKeyword: ElseKeyword -> type(ElseKeyword);
Inside_WhileKeyword: WhileKeyword -> type(WhileKeyword);

Inside_AnyKeyword: AnyKeyword -> type(AnyKeyword);
Inside_NoneKeyword: NoneKeyword -> type(NoneKeyword);
Inside_StringKeyword: StringKeyword -> type(StringKeyword);
Inside_NumberKeyword: NumberKeyword -> type(NumberKeyword);
Inside_BooleanKeyword: BooleanKeyword -> type(BooleanKeyword);
Inside_ListKeyword: ListKeyword -> type(ListKeyword);
Inside_DictionaryKeyword: DictionaryKeyword -> type(DictionaryKeyword);
Inside_TupleKeyword: TupleKeyword -> type(TupleKeyword);
Inside_ScopeKeyword: ScopeKeyword -> type(ScopeKeyword);
Inside_FunctionKeyword: FunctionKeyword -> type(FunctionKeyword);
Inside_TypeKeyword: TypeKeyword -> type(TypeKeyword);

Inside_WS: WS -> type(WS), channel(HIDDEN);
Inside_NL: NL -> type(NL), channel(HIDDEN);

Inside_Identifier: Identifier -> type(Identifier);

mode DEFAULT_MODE;
ErrorCharacter: .;