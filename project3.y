/* BISON file
 * Contains the grammar for our svsh parser
 * Also defines the tokens that the scanner will look for
 *
 */

%{
#include "functions.h"
extern char prompt[];
extern int yylex();
extern void yyerror(char*);
%}

%union{
    char int_token;
    char* str_val;
}
	
%token <int_token> METACHARACTER
%token <str_val> DEFPROMPT CD LISTJOBS BYE RUN ASSIGNTO BG VARIABLE STRING WORD

%start parsetree
%%

parsetree:	line;
line:		comment | run_command;

comment:	METACHARACTER anytext
		 {if($1 == 35)printf("Found a comment: %d\n", $1);}; 
anytext:	anytext WORD | WORD
		| anytext DEFPROMPT | DEFPROMPT
		| anytext CD | CD
		| anytext LISTJOBS | LISTJOBS
		| anytext BYE | BYE
		| anytext RUN | RUN
		| anytext ASSIGNTO | ASSIGNTO
		| anytext BG | BG
		| anytext STRING | STRING
		| anytext VARIABLE | VARIABLE
		| anytext METACHARACTER | METACHARACTER
		;

run_command:	BYE
		 {printf("Parser got: %s\n", $1);
		  exit(0);}
		|LISTJOBS
		 {printf("Parser got: %s\n", $1);}
		|DEFPROMPT STRING
		 {printf("Parser got: %s should be %s\n", $1, $2);}
		|CD WORD
		 {printf("Parser got: %s to %s\n", $1, $2);}
		|VARIABLE METACHARACTER STRING
		 {printf("Parser got: %s %c %s\n", $1, $2, $3);
		  if($2 == '=')printf("An assignment\n");
		 }
		|ASSIGNTO VARIABLE filename arg_list
		 {printf("Parser got an assignto line\n");}
		|run
		;

run:		RUN filename
		 {printf("Parser saw a run without arguments, BG option\n");}
		|RUN filename BG
		 {printf("Parser saw a run with BG option, no arguments\n");}
		|RUN filename arg_list
		 {printf("Parser saw a run without BG option\n");}
		| RUN filename arg_list BG
		 {printf("Parser saw a run with a BG option\n");}
		;
filename:	WORD;
arg_list:	arg_list argument | argument;
argument:	WORD | STRING | VARIABLE;
		
%%
