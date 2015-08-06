/* description: Parses end evaluates mathematical expressions. */

/* lexical grammar */
%lex
%%
\s+           {/* skip whitespace */}
"$"             {}
\\[a-zA-Z]+      {return "CONTROL"}
"_"              {return "CONTROL"}
"^"              {return "CONTROL"}
"\{" {return "CHAR"}
"\}" {return "CHAR"}
"{"           {return "{"}
"}"           {return "}"}
.         {return "CHAR"}

<<EOF>>               {return 'EOF';}

/lex

%start deBracelet

%% /* language grammar */

deBracelet
    : sequence EOF
        {
			var s=genNewState();
			$1(s);
			s=s.seq;
			s=s.replace(/\_\s*\{\}/g, "");
			s=s.replace(/\^\s*\{\}/g, "");
			s=s.replace(/\\sqrt \[\]/g,"\\sqrt");
			//console.log(s);
			return s;
			
		}
    ;

ctrl
	: CONTROL
		{
			$$=function(){
				var type=$1.replace("\\","").toLowerCase();
				var seq=equivalent(type);
				return {cm:getCM(seq), seq:"\\"+seq, type:"ctrl"};
			}
		}
	;
	
subSequence
	: '{' sequence '}'
		{
			$$=function(){
				var tmp=genNewState();
				$2(tmp);
				return {type:"sub", seq:tmp.seq};
			};
		}
	| '{' '}'
		{
			$$=function(){return {type:"sub", seq:""}; };
		}
	;
	
sequence
	: ctrl
		{
			$$=function(current){
				var cntl=$1();
				current.cm.push(cntl.cm);
				current.cm.slice(-1)[0](current, cntl);
			}
		}
	| CHAR
		{
			$$=function(current){
				current.cm.slice(-1)[0](current, {type:"char", seq:$1});
			};
		}
	| subSequence
		{
			$$=function(current){
				current.cm.slice(-1)[0](current, $1());
			};
		}
	| sequence subSequence
		{
			$$=function(current){
				$1(current);
				current.cm.slice(-1)[0](current, $2());
			};
		}
	| sequence ctrl
		{
			$$=function(current){
				$1(current);
				var cntl=$2();
				current.cm.push(cntl.cm);
				current.cm.slice(-1)[0](current, cntl);
			}
		}
	| sequence CHAR
		{
			$$=function(current){
				$1(current);
				current.cm.slice(-1)[0](current, {type:"char", seq:$2});
			};
		}
	;
	
%%

function genNewState(){
	return {
		cm:[function(state, next){
				state.seq+=next.seq; //stripe all {}s.
			}],
		seq:""
	}
}

function omit(state, next){
	state.cm.pop();
}

function genReqs(howmany){
	var tmp="";
	var now=0;
	return function(state, next){
		now+=1;
		if (next.type == "char") tmp += "{"+next.seq+"}";
		else if (next.type == "sub") tmp += "{"+next.seq+"}";
		else if (next.type == "ctrl") tmp += next.seq + " ";
		//console.log(howmany);
		if (now==howmany+1) {
			state.cm.pop();
			state.cm.slice(-1)[0](state,{type:"sub", seq:tmp});
		}
	}
}

function genBrack(howmany){
	var tmp="";
	var brack=false;
	function brackFill(state, next){
		if (next.type=="char"&&next.seq=="]"){
			tmp+="]";
			state.cm.pop();
			state.cm.push(genReqs(howmany));
			state.cm.slice(-1)[0](state,{type:"ctrl",seq:tmp});
		}else{
			tmp+=next.seq;
		}
	}
	return function(state, next){
		if (next.type=="ctrl") tmp+=next.seq+" ";
		else if (next.type=="char" && next.seq=="["){
			tmp+="[";
			state.cm.pop();
			state.cm.push(brackFill);
		}else{
			state.cm.pop();
			state.cm.slice(-1)[0](state,{type:"sub",seq:tmp+"{"+next.seq+"}"});
		}
	}
}
function equivalent(cntl){
	switch(cntl){
		case "overrightarrow": return "vec";
		case "geq": return "ge";
		case "leq": return "le";
		default: return cntl;
	}
}
function getCM(cntl){
	switch (cntl){
		case "sqrt": return genBrack(1);
		case "frac": return genReqs(2);
		case "big": return omit;
		case "left": return omit;
		case "right": return omit;
		case "_": return genReqs(1);
		case "^": return genReqs(1);
		case "vec": return genReqs(1);
		default: return genReqs(0);
	}
}