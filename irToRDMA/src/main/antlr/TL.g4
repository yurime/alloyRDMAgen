grammar TL;

parse
 : program EOF
 ;

block
 : statement*
 ;

program
 : node+ output*
 ;


node
 : Node Number process+ 
 ;


process
 : Process Number decl statement*
 ;

decl
 : sharedDecl? localDecl?
 ;
 
statement
 : assignment ';'
 | ifStatement
 | whileStatement
 | put ';'
 | get ';'
 | rga ';'
 | cas ';'
 | putF ';'
 | getF ';'
 | rgaF ';'
 | casF ';'
 | load ';'
 | store ';'
 | lcas ';'
 | pollcq ';'
 | assumption ';'
 | assertion ';'
 | ifStatement ';'
 ;

load
 : Load '(' Identifier '=' Identifier ')'
 ;

store
 : Store '(' Identifier '=' rhs  ')'
 ;


lcas
 : LCas '(' Identifier '=' rhs '?' Number ')'
 ;
 
pollcq
 : PollCQ '(' Number ')'
 ;
 
put
 : Put '(' Identifier ','  Number ',' Identifier ')'
 | Put '(' Identifier '^'  Number ',' Identifier ')'
 ;

get
 : Identifier '=' Get  '(' Identifier ',' Number ')'
 | Identifier '=' Get  '(' Identifier '^' Number ')'
 ;

rga
 : Identifier '=' Rga '(' Identifier ',' Number ',' Number ')'
 | Identifier '=' Rga '(' Identifier '^' Number ',' Number ')' 
 ;

cas
 : Identifier '=' Cas '(' Identifier ',' Number ',' Number  ',' Number ')'
 | Identifier '=' Cas '(' Identifier '^' Number ',' Number  ',' Number ')'
 ;

putF
 : PutF '(' Identifier ','  Number ',' Identifier ')'
 | PutF '(' Identifier '^'  Number ',' Identifier ')'
 ;

getF
 : Identifier '=' GetF  '(' Identifier ',' Number ')'
 | Identifier '=' GetF  '(' Identifier '^' Number ')'
 ;

rgaF
 : Identifier '=' RgaF '(' Identifier ',' Number ',' Number ')'
 | Identifier '=' RgaF '(' Identifier '^' Number ',' Number ')'
 ;

casF
 : Identifier '=' CasF '(' Identifier ',' Number ',' Number  ',' Number ')'
 | Identifier '=' CasF '(' Identifier '^' Number ',' Number  ',' Number ')'
 ;

rhs
 : Number | Identifier
 ;

localDecl
 : Local varDeclList ';'
 ;

sharedDecl
 : Shared varDeclList ';'
 ;

varDeclList
 : varDecl (',' varDecl)*
 ;

varDecl
 : Identifier ('=' Number)?
 ;

assignment
 : Identifier '=' expression
 ;

assertion
 : Assert '(' simpleExpression ')'
 ;

assumption
 : Assume '(' simpleExpression ')'
 ;

output
 : Output '(' simpleExpression ')' ';'
 ;

ifStatement
 : If simpleExpression Then block End
 ;

whileStatement
 : While expression Do block End
 ;

idList
 : Identifier (Comma Identifier)*
 ;

exprList
 : expression (Comma expression)*
 ;

simpleExpression
 : simpleExpression And simpleExpression
 | simpleExpression Or  simpleExpression
 | Excl simpleExpression
 | OParen simpleExpression CParen
 | Identifier Equals rhs
 | Identifier NEquals rhs
 ;

expression
 : Subtract expression                      #unaryMinusExpression
 | Excl expression                          #notExpression
 | expression Multiply  expression          #multiplyExpression
 | expression Divide    expression          #divideExpression
 | expression Modulus   expression          #modulusExpression
 | expression Add       expression          #addExpression
 | expression Subtract  expression          #subtractExpression
 | expression GTEquals  expression          #gtEqExpression
 | expression LTEquals  expression          #ltEqExpression
 | expression GT        expression          #gtExpression
 | expression LT        expression          #ltExpression
 | expression Equals    expression          #eqExpression
 | expression NEquals   expression          #notEqExpression
 | expression And       expression          #andExpression
 | expression Or        expression          #orExpression
 | Number                                   #numberExpression
 | Bool                                     #boolExpression

 | Identifier                               #identifierExpression
 | '(' expression ')'                       #expressionExpression
 ;

list
 : '[' exprList? ']'
 ;

Load     : 'load';
Store    : 'store';
Put      : 'put' ;
Get      : 'get' ;
Rga      : 'rga' ;
Cas      : 'cas' ;
LCas      : 'lcas' ;
PutF      : 'putf' ;
GetF      : 'getf' ;
RgaF      : 'rgaf' ;
CasF      : 'casf' ;
PollCQ   : 'poll_cq';
Shared   : 'shared' ;
Local    : 'local' ;
Node  : 'node';
Process  : 'process';
Assert   : 'assert';
Assume   : 'assume';

Output   : 'output';
Input    : 'input';
If       : 'if';
Else     : 'else';
While    : 'while';
To       : 'to';
Then     : 'then';
Do       : 'do';
End      : 'end';
In       : 'in';
Null     : 'null';

Or       : '||';
And      : '&&';
Equals   : '==';
NEquals  : '!=';
GTEquals : '>=';
LTEquals : '<=';
Excl     : '!';
GT       : '>';
LT       : '<';
Add      : '+';
Subtract : '-';
Multiply : '*';
Divide   : '/';
Modulus  : '%';
OBrace   : '{';
CBrace   : '}';
OBracket : '[';
CBracket : ']';
OParen   : '(';
CParen   : ')';
SColon   : ';';
Assign   : '=';
Comma    : ',';
QMark    : '?';
Colon    : ':';

Bool
 : 'true' 
 | 'false'
 ;

Number
 : Int ('.' Digit*)?
 ;

Identifier
 : [a-zA-Z_] [a-zA-Z_0-9]*
 ;

String
 : ["] (~["\r\n] | '\\\\' | '\\"')* ["]
 | ['] (~['\r\n] | '\\\\' | '\\\'')* [']
 ;

Comment
 : ('//' ~[\r\n]* | '/*' .*? '*/') -> skip
 ;

Space
 : [ \t\r\n\u000C] -> skip
 ;

fragment Int
 : [1-9] Digit*
 | '0'
 ;
  
fragment Digit 
 : [0-9]
 ;