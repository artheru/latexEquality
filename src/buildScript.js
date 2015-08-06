var exec=require("child_process").exec;

exec("jison latexParser/latex.jison -o ../latex.js");
exec("jison mathParser/syntax.jison -o ../math.js");