/* description: Parses end evaluates mathematical expressions. */

/* lexical grammar */
%lex
%%
\s+           {/* skip whitespace */}
"\big" {}
"\left" {}
"\right" {}
([0-9](\s)*)+("."(\s)*([0-9](\s)*)+)?  {return 'NUMBER';}
"*"                   {return '*';}
"\cdot"               {return '*';}
"\times"              {return "*";}
"/"                   {return '/';}
"div"                 {return "/";}
"-"                   {return '-';}
"+"                   {return '+';}
"^"                   {return '^';}
"_"                   {return '_';}
"("                   {return '(';}
")"                   {return ')';}
"["                   {return '[';}
"\lbrack"             {return '[';}
"]"                   {return ']';}
"\rbrack"             {return ']';}
"\{"                  {return "LBRACELET"; }
"\}"                  {return "RBRACELET"; }
"{"                   {return "{";}
"}"                   {return "}";}
"{"                   {return "{"; }
"}"                   {return "}"; }
"\frac"               {return "FRAC"}
"\sqrt"               {return "SQRT"}
"\infty" {return "INF"}
"\inf"   {return "INF"}
"\overrightarrow" {return "VEC"}
"\vec"            {return "VEC"}
"\cup"   {return "CUP"}
"\emptyset" {return "EMPTYSET"}
[a-z]                 {return 'VAR'; console.log(yytext);}
"\geq" {return "GEQ";}
"\leq" {return "LEQ";}
"<" {return "<";}
">" {return ">";}
"=" {return "=";}
"," {return ",";}
"\phi" {return "VAR";}
"\in" {return "IN";}
"\pm" {return "PM";}
"\pi" {return "CONST";}

<<EOF>>               {return 'EOF';}

/lex

/* operator associations and precedence */

%left '+' '-'
%left '*' '/'
%left '^'

%start somethingMath

%% /* language grammar */

somethingMath
    : expr EOF
        {	//Expression.
			var ret={
				type:"expression",
				eva:function(args){
					return $1(args);
				}
			};
			return ret;
		}
    | LBRACELET elements RBRACELET EOF
		{	//Set.
			var ret={
				type:"set",
				eva:function(args){
					var result=[];
					for (var i=0; i<$2.length; ++i)
						result.push($2[i](args));
					return result;
				}
			}
			return ret;
		}
	| formula EOF
		{	//Formula.
			var ret={
				type:"formula",
				eva:function(args){
					return $1(args);
				}
			}
			return ret;
		}
	| sections EOF
		{	//Sections, like (-Inf,1]U[2,+Inf)
			var ret={
				type: "sections",
				eva:function(args){
					return $1(args);
				}
			}
			//console.log($1+" ");
			return ret;
		}
	;

formula
	: expr "=" expr
		{
			$$ = function(args){
				var left=$1(args);
				var right=$3(args);
				return left-right;
			}
		}
	;

sections
	: section
		{
			$$ = function(args){
				//console.log("first");
				return [$1(args)];
			}
		}
	| sections CUP section
		{
			$$ = function(args){
				//console.log("nop");
				var tmp=$1(args);
				tmp.push($3(args));
				return tmp;
			}
		}
	;
	
section
	: "(" expr "," expr ")"
		{
			$$ = function(args){
				return {
					left: $2(args),
					right: $4(args),
					lType:"open",
					rType:"open"
				}
			}
		}
	| "[" expr "," expr ")"
		{
			$$ = function(args){
				return {
					left: $2(args),
					right: $4(args),
					lType:"closed",
					rType:"open"
				}
			}
		}
	| "(" expr "," expr "]"
		{
			$$ = function(args){
				return {
					left: $2(args),
					right: $4(args),
					lType:"open",
					rType:"closed"
				}
			}
		}
	| "[" expr "," expr "]"
		{
			$$ = function(args){
				return {
					left: $2(args),
					right: $4(args),
					lType:"closed",
					rType:"closed"
				}
			}
		}
	;
	
elements
	: expr
		{
			$$=[$1];
		}
	| elements "," expr
		{
			var tmp=$1;
			tmp.push($3);
			$$=tmp;
		}
	;
	
piece
	: '{' expr '}'
        {$$ = function(args){
				return $2(args);
			};
		}
	;

term
    : NUMBER
        {$$ = function(args){
				return Number(yytext.replace(/\s/g, ""));
			}
		}
	| INF
		{$$ = function(args){
				return Infinity;
			}
		}
	| CONST
        {$$ = function(args){
				switch (yytext){
					case "\\pi":
						return 3.1415926;	
				}
			}
		}
	| term '^' term
        {$$ = function(args){
				//console.log($1(args), $4(args));
				return Math.pow($1(args), $3(args));
			};
		}
	| term '^' piece
        {$$ = function(args){
				//console.log($1(args), $4(args));
				return Math.pow($1(args), $3(args));
			};
		}
	| FRAC piece piece
        {$$ = function(args){
				return $2(args) / $3(args);
			};
		}
	| SQRT '[' expr ']' piece
        {$$ = function(args){
				return Math.pow($5(args),1/$3(args));
			};
		}
	| SQRT piece
        {$$ = function(args){
				return Math.sqrt($2(args));
			};
		}
	| VAR
        {$$ = function(args){
				if (typeof args[yytext]=="undefined") 
					args[yytext]=Math.random();
				return args[yytext];
			};
		}
	| '(' expr ')'
        {$$ = function(args){
			return $2(args);
		};}
    ;

factor
	: term
		{ $$ = $1 }
	| term factor 
        {$$ = function(args){
				//console.log('*');
				return $1(args) * $2(args);
			};
		}
	;

prefix
	: factor
		{ $$ = $1 }
	| '-' factor
        {$$ = function(args){
				//console.log('U-');
				return -$2(args);
			};
		}
	| '+' factor
        {$$ = function(args){
				//console.log('U+');
				return $2(args);
			};
		}
	;

	
expr2
	: prefix
		{ $$ = $1 }
    | expr2 '*' prefix
        {$$ = function(args){
				return $1(args) * $3(args);
			};
		}
    | expr2 '/' prefix
        {$$ = function(args){
				return $1(args) / $3(args);
			};
		}
	;
		
expr
	: expr2
		{ $$ = $1 }
    | expr '+' expr2
        {$$ = function(args){
				//console.log('+');
				return $1(args) + $3(args);
			};
		}
    | expr '-' expr2
        {$$ = function(args){
				//console.log('-');
				return $1(args) - $3(args);
			};
		}
    ;