var syn=require('./math.js').parser;
var latex=require('./latex.js').parser;

var http=require('http');
var url=require('url');

function reformat(inStr){
	inStr.replace()
}

function compare(request, response){
	var result="undetermined";
	
	var urlP = url.parse(request.url, true)
	if (urlP.pathname!=listenPath) { //only respond to test?in1=xxxxxx.
		response.end(); return;
	}
	
	function preprocess(inStr){ //\b fix for lexer
		function fixSlashB(str){
			return str
				.replace(/(\d)([a-z])/g,"$1 $2")
				.replace(/([a-z])(\d)/g,"$1 $2");
		}
		function texify(str){
			return latex.parse(str);
		}
		return texify(fixSlashB(inStr));
	}
	
	//Math Functions:
	
	function equalN(a,b){
		if (a==b) return true;
		if (Math.abs(a-b)<threshold) return true;
		return false;
	}
	function genRand(){
		var maxRange=10;
		var minRange=-10;
		return Math.random()*(maxRange-minRange)+minRange;
	}
	
	
	var functionList={
		expression:function(in1T, in2T){
			var args={}, a, b;
			do{
				a=in1T.eva(args);
				b=in2T.eva(args);
				for(var k in args)
					args[k]=genRand();
			}while(isNaN(a) && isNaN(b))
			//console.log(a,b);
			return equalN(a,b);
		},
		set:function(in1T, in2T){
			var args={};
			var a=in1T.eva(args);
			var b=in2T.eva(args);
			//console.log(a);
			//console.log(b);
			function compareSet(a,b){
				for (var i=0; i<a.length; ++i){
					var inside=false;
					for (var j=0; j<b.length; ++j)
						if (equalN(a[i],b[j])) inside=true;
					if (!inside) return false;
				}
				for (var i=0; i<b.length; ++i){
					var inside=false;
					for (var j=0; j<a.length; ++j)
						if (equalN(a[i],b[j])) inside=true;
					if (!inside) return false;
				}
				return true;
			}
			return compareSet(a,b);
		},
		formula:function(in1T, in2T){
			var args={};
			in1T.eva(args);
			
			function sign(inN){
				if (Math.abs(inN)<threshold) return 0;
				if (inN<0) return -1;
				return 1;
			}
			var d=0.001;
			for (var iters=0; iters<10; ++iters) if (!function(){
				//Random Starting Point.
				for (var key in args)
					args[key]=genRand(); //(-10,10)
					
				var balance;
				for (var itersInner=0; itersInner<10; ++itersInner){
					balance=in1T.eva(args);
					if (isNaN(balance)) return true; //just consider it's a same point...
					
					//Calculating Slope
					var slope={}, step=0;
					for (var key in args){
						args[key]=args[key]-d;
						slope[key]=balance-in1T.eva(args);
						args[key]=args[key]+d;
						step+=slope[key]*slope[key];
					}
					step=Math.sqrt(step);
					
					//Guess step.
					var l=balance/(step/d); //initial guess
					var nargs={};
					do {
						for (var key in args)
							nargs[key]=args[key]-l*(slope[key]/step);
						var newBalance=in1T.eva(nargs);
						var result=sign(balance)*sign(newBalance);
						if (result>=0) break;
						l/=2;
					}while(true);
					
					for(var key in args) args[key]=nargs[key];
				}
				
				var a=in1T.eva(args);
				var b=in2T.eva(args);
				if (Math.abs(a)<threshold && Math.abs(a-b)>threshold) return false; 
				return true;
			}()) return false;
			return true;
		},
		sections:function(in1T, in2T){
			var args={};
			var a=in1T.eva(args);
			var b=in2T.eva(args);
			//console.log(a);
			//console.log(b);
			function sectionEqu(s1,s2){
				if (equalN(s1.left,s2.left) &&
					equalN(s1.right,s2.right)&&
					s1.lType==s2.lType &&
					s1.rType==s2.rType)
					return true;
				return false;
			}
			function compareSet(a,b){
				for (var i=0; i<a.length; ++i){
					var inside=false;
					for (var j=0; j<b.length; ++j)
						if (sectionEqu(a[i],b[j])) inside=true;
					if (!inside) return false;
				}
				for (var i=0; i<b.length; ++i){
					var inside=false;
					for (var j=0; j<a.length; ++j)
						if (sectionEqu(a[j],b[i])) inside=true;
					if (!inside) return false;
				}
				return true;
			}
			return compareSet(a,b);
		}
	}
	
	try{
		var params=urlP.query;
		console.info("Incoming.\n\tin1:%s\n\tin2:%s.", params.in1, params.in2);
		var in1T=preprocess(params.in1);
		var in2T=preprocess(params.in2)
		
		console.info("Preprocessed.\n\tin1:%s\n\tin2:%s",in1T,in2T);
		
		if (in1T==in2T) 
			result="Equal";
		else{
			in1T= syn.parse(in1T);
			in2T= syn.parse(in2T);
			
			var threshold=0.000001;
			if (in1T.type!=in2T.type) 
				result="Unequal";
			else 
				result=functionList[in1T.type](in1T,in2T)?"Equal":"Unequal";
		}
		
		console.log("%s for in1:%s, in2:%s",result,params.in1, params.in2);
	}
	catch(e){
		console.error("** Failed for in1:%s, in2:%s:",params.in1, params.in2);
		console.error(e);
	}
	response.writeHead(200, {'Content-Type': 'text/plain'})
	response.write(result);
	response.end();
}

var server=http.createServer(compare);

var port=9000;
var listenPath="/test";

server.listen(9000,function(){
	console.log("Server started, listening on port: %d, and path: %s", port, listenPath);
});
