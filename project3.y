/* BISON file
 * Contains the grammar for our ssh parser
 * Also defines the tokens that the scanner will look for
 *
 */

%{
#include "functions.h"
#include "mytable.h"
#include <unistd.h>

#define DEBUGTOKENS 0	//Print messages about what the scanner gives back
#define DEBUGARGV 0	//Print the argv list that the parser builds

void printTokens();
char** makeArgList(int* a, char** argv);
int ListJobs(char** input_argv);
void PrintListJobs();
int ChangeDir(char* directory);

extern char* prompt;
extern int yylex();
extern void yyerror(char*);

//int job_place;
//extern int* i_jobs[1024];
//extern char* jobs[1024];

extern job* bgjobs[];

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
		 {if($1 == 35){
		      if(DEBUGTOKENS)printf("Found a comment: %d\n", $1);
		      sym_table = pushsym(METACHARACTER, "=", "comment");  
		      if(Showtokens)printTokens();
		  }
		  //input_argc = 1;
		 }; 
anytext:	anytext WORD 
		| WORD {sym_table = putsym("WORD", $1, "anytext");}
		| anytext DEFPROMPT 
		| DEFPROMPT {sym_table = putsym("WORD", $1, "anytext");}
		| anytext CD 
		| CD {sym_table = putsym("WORD", $1, "anytext");} 
		| anytext LISTJOBS 
		| LISTJOBS {sym_table = putsym("WORD", $1, "anytext");}
		| anytext BYE 
		| BYE {sym_table = putsym("WORD", $1, "anytext");}
		| anytext RUN 
		| RUN {sym_table = putsym("WORD", $1, "anytext");}
		| anytext ASSIGNTO 
		| ASSIGNTO {sym_table = putsym("WORD", $1, "anytext");}
		| anytext BG 
		| BG {sym_table = putsym("WORD", $1, "anytext");}
		| anytext STRING 
		| STRING {sym_table = putsym("WORD", $1, "anytext");}
		| anytext VARIABLE 
		| VARIABLE {sym_table = putsym("WORD", $1, "anytext");}
		| anytext METACHARACTER 
		| METACHARACTER {sym_table = putsym("WORD", $1, "anytext");}
		;

run_command:	BYE
		 {if(DEBUGTOKENS)printf("Parser got: %s\n", $1);
		  sym_table = putsym(BYE, $1, "bye");
		  if(Showtokens)printTokens();
		  exit(0);}
		|LISTJOBS
		 {if(DEBUGTOKENS)printf("Parser got: %s\n", $1);
		  sym_table = putsym(LISTJOBS, $1, "listjobs");
		  if(Showtokens)printTokens();
	  	  PrintListJobs();
		 }
		|DEFPROMPT STRING
		 {if(DEBUGTOKENS)printf("Parser got: %s should be %s\n", $1, $2);
		  sym_table = putsym(DEFPROMPT, $1, "defprompt");
		  sym_table = putsym(STRING, $2, "prompt");
		  if(Showtokens)printTokens();
  		  strncpy(prompt, $2, MAXSTRINGLENGTH);
		 }
		|CD WORD
		 {if(DEBUGTOKENS)printf("Parser got: %s to %s\n", $1, $2); 
		  sym_table = putsym(CD, $1, "cd");
		  sym_table = putsym(WORD, $2, "directory_name");
		  if(Showtokens)printTokens();
		  ChangeDir($2);
		 }
		|CD VARIABLE
		 {if(DEBUGTOKENS)printf("Parser got: %s to %s\n", $1, $2); 
		  sym_table = putsym(CD, $1, "cd");
		  sym_table = putsym(CD, $2, "directory_name");
		  if(Showtokens)printTokens();
		 }
		|VARIABLE METACHARACTER STRING
		 {if(DEBUGTOKENS)printf("Parser got: %s %c %s\n", $1, $2, $3);
		  if($2 == 61){
		    sym_table = putsym(VARIABLE, $1, "variable");
		    sym_table = putsym(METACHARACTER, "=", "assignment");
		    sym_table = putsym(STRING, $3, "variable_def");
		    //SYSTEMS CALL
		    syscall(SaveVar, $1, $3);
		    if(Showtokens)printTokens();

		  }
		  else{
			yyerror("syntax assignment error");
		  }
		 
		 }
		|ASSIGNTO VARIABLE filename arg_list
		 {if(DEBUGTOKENS)printf("Parser got an assignto line\n");
		  sym_table = pushsym(VARIABLE, $2, "variable");
		  sym_table = pushsym(ASSIGNTO, $1, "assignto");
		  if(Showtokens)printTokens();
		  int input_argc = 0;
		  char** input_argv = malloc(MAXARGNUMS * sizeof(char*)); 
		  symrec* ptr = sym_table;
		  //Argument list order should be correct now 
		  input_argv = makeArgList(&input_argc, input_argv);

		  //Doesn't matter if it's a new variable or not
		  Assignto($2, input_argv);
		 }
		|run
		;

run:		RUN filename
		 {if(DEBUGTOKENS)printf("Parser saw a run without arguments, BG option\n");
		  //if(Showtokens)printf("Usage = run\n");
		  sym_table = pushsym(RUN, $1, "run");
		  //Building the argument list
		  int input_argc = 0; //Number of elements in argv
		  char** input_argv = malloc(MAXARGNUMS * sizeof(char*)); 
		  symrec* ptr = sym_table; 
		  input_argv = makeArgList(&input_argc, input_argv);

		  //Prints all the tokens
		  if(Showtokens)printTokens();

                  // Store the job in jobs array
                  ListJobs(input_argv);
		  runCommand(input_argv, 0);
		  //Call run with these arguments, or just fork and exec?
		  //fork();
		  //execve(input_argv[0], input_argv);
		 }
		|RUN filename BG
		 {if(DEBUGTOKENS)printf("Parser saw a run with BG option, no arguments\n");		  
		  sym_table = pushsym(RUN, $1, "run");
		  sym_table = putsym(BG, $1, "<bg>");
		  

		  //Building the argument list
		  int input_argc = 0; //Number of elements in argv
		  char** input_argv = malloc(MAXARGNUMS * sizeof(char*)); 
		  symrec* ptr = sym_table; 
		  input_argv = makeArgList(&input_argc, input_argv);

		  if(Showtokens)printTokens();

		  // Store the job in jobs array
		  ListJobs(input_argv);
		  runCommand(input_argv, 1);
		 }
		|RUN filename arg_list
		 {if(DEBUGTOKENS)printf("Parser saw a run without BG option\n");
		  sym_table = pushsym(RUN, $1, "run");
		  //Building the argument list
		  int input_argc = 0; //Number of elements in argv
		  char** input_argv = malloc(MAXARGNUMS * sizeof(char*)); 
		  symrec* ptr = sym_table; 
		  input_argv = makeArgList(&input_argc, input_argv);

		  if(Showtokens)printTokens();
		  runCommand(input_argv, 0);
		 }
		|RUN filename arg_list BG
		 {if(DEBUGTOKENS)printf("Parser saw a run with a BG option\n");
		  sym_table = pushsym(RUN, $1, "run");
		  sym_table = putsym(BG, $1, "<bg>");
		  
		  //Building the argument list
		  int input_argc = 0; //Number of elements in argv
		  char** input_argv = malloc(MAXARGNUMS * sizeof(char*)); 
		  symrec* ptr = sym_table; 
		  input_argv = makeArgList(&input_argc, input_argv);

		  if(Showtokens)printTokens();

		  // Store the job in jobs array
                  ListJobs(input_argv);
                  runCommand(input_argv, 1);
		 }
		;
filename:	WORD
		{
		 sym_table = putsym(WORD, $1, "directory_name");
		}	
		;

arg_list:	arg_list argument 
		|argument
		;

argument:	WORD 
		{
		 sym_table = putsym(WORD, $1, "arg");
		}
		|STRING
		{ 
		 sym_table = putsym(STRING, $1, "arg");
		} 
		|VARIABLE
		{ 
		 char tempdef[MAXSTRINGLENGTH] = "";
		 syscall(GetVar, $1, tempdef, MAXSTRINGLENGTH);
		 sym_table = putsym(VARIABLE, tempdef, "arg");
		}
		;
%%

//Prints all the symbols seen in order
void printTokens(){

	symrec* ptr;
	ptr = sym_table;
	printf("\n");
	while(ptr != NULL){	
	  if(ptr->type == METACHARACTER)printf("Token Type = metachar\t");
	  else if(ptr->type == DEFPROMPT)printf("Token Type = keyword\t");
	  else if(ptr->type == CD)	printf("Token Type = keyword\t");
	  else if(ptr->type == LISTJOBS)printf("Token Type = keyword\t");
	  else if(ptr->type == BYE)	printf("Token Type = keyword\t");
	  else if(ptr->type == RUN)	printf("Token Type = keyword\t");
	  else if(ptr->type == ASSIGNTO)printf("Token Type = keyword\t");
	  else if(ptr->type == BG)	printf("Token Type = keyword\t");
	  else if(ptr->type == VARIABLE)printf("Token Type = variable\t");
	  else if(ptr->type == STRING)	printf("Token Type = string\t");
	  else if(ptr->type == WORD)	printf("Token Type = word\t");
	  
	  int i = 1;
	  if(strcmp(ptr->usage, "arg") == 0){
		printf("Token = %s\t\tUsage = %s %d\n",
			ptr->value, ptr->usage, i);
		i++;
	  }
	  else{
	 	 printf("Token = %s\t\tUsage = %s\n",
			ptr->value, ptr->usage);
	  }
		ptr = ptr->next;
	}
}

//Fill an argument list from the symbol table
char** makeArgList(int* input_argc, char** input_argv){
	*input_argc = 0; //Number of elements in argv
	//input_argv = malloc(MAXARGNUMS * sizeof(char*)); 
	symrec* ptr = sym_table;
	while(ptr!=NULL){
	    if(strcmp(ptr->usage, "directory_name") == 0){
		input_argv[*input_argc] = malloc(MAXSTRINGLENGTH);
		if(ptr->type == VARIABLE){
		    char* vardef[MAXSTRINGLENGTH];
		    //Get the variable definition from kernal space
		    syscall(GetVar, ptr->value, vardef, MAXSTRINGLENGTH); 
		    strncpy(input_argv[*input_argc], vardef, MAXSTRINGLENGTH);
		}
		else{
		    strncpy(input_argv[*input_argc], ptr->value, strlen(ptr->value));
		}
		(*input_argc)++;	
	    }
	    if(strcmp(ptr->usage, "arg") == 0){
		input_argv[*input_argc] = malloc(MAXSTRINGLENGTH);
		if(ptr->type == VARIABLE){
		    char* vardef[MAXSTRINGLENGTH];
		    //Get the variable definition from kernal space
		    syscall(GetVar, ptr->value, vardef, MAXSTRINGLENGTH);
		    strncpy(input_argv[*input_argc], ptr->value, strlen(ptr->value));
		}
		else{
		    strncpy(input_argv[*input_argc], ptr->value, strlen(ptr->value));
		}
		(*input_argc)++;
	    }
	    ptr = ptr->next;
		
	}
	ptr = sym_table;
	if(DEBUGARGV){
	    int i;
	    for (i = 0; i < *input_argc; i++){
		printf("Arg %d: %s\n", i, input_argv[i]);
	    }
	}
	return input_argv;
}

int ChangeDir(char* directory)
{
	int k = 0;
   	//printf("Program ChangeDir has been entered. \n");

	//buffer to store the directory_name
	char* buf = malloc(MAXSTRINGLENGTH);
	getwd(buf);

	//changes the directory
	k = chdir(directory);
	
	
	if (!k)
	{
		//double check that the directory has actually changed
		//printf("The directory is now: %s\n", get_current_dir_name());	
	}
	else
	{
		//Syntax is right, but there is no directory to go to
		printf("%s is not a directory.\n", directory);
	}
//	free(buf);
}



//track all jobs running in background
int ListJobs(char** input_argv)
{
	//printf("Program has entered Listjobs.\n");

	//store the command in the array of jobs
	//jobs[job_place] = input_argv[0];
	
	//increment the global variable
        //job_place++;

}

//print all jobs in the background
void PrintListJobs()
{
	//printf("Program will print ListJobs:\n");
	
	int i = 0;//iterator	

	//If there are no background jobs running
	if (bgjobs[i] == NULL)
        {
                printf("There are no background jobs at this time.\n");
        }

	//If Background jobs are present
	printf("Background jobs:\n");

	//while the list still has values and not NULL, print off the jobs 
	while (i < sizeof(bgjobs) && bgjobs[i-1]!=NULL)
        {
                printf("%s     ", bgjobs[i]->name);
                i++;
        }
        printf("\n");

}	
int runCommand(char** input_argv, int background)
{
    pid_t pid;
    int state = -1;
    //char** argv = makeArgList(input_argv);
    if((pid = fork()) == 0){
        execvp(input_argv[0], input_argv);
        exit(1);
    }
    else if(!background){
	//printf("Shell is waiting......\n");
	waitpid(pid, &state, 0);
	kill(pid, SIGKILL);
    }
    else{
	//i_jobs[job_place] = pid;
	job *newjob;
	newjob->pid = pid;
	newjob->name = input_argv[0];
	int i = 0;
	while(bgjobs[i] != NULL){
		i++;
	}
	bgjobs[i] = newjob;	
    }
}


int Assignto (char* varname, char** input_argv)
{
    int pid; 
    if((pid = fork()) == 0) {
	execvp(input_argv[0], input_argv);
        exit(1);
       
    }
    int state;
    if(waitpid(pid, &state, 0) < 0) {
        perror("WAITPID");
        kill(pid, SIGKILL);
    }
    char* result[MAXSTRINGLENGTH];
   //  add to variable list....
    syscall(SaveVar, input_argv[0], result);
} 

