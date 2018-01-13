%{
#include<stdio.h>
#include<iostream>
#include<string.h>
#include<stdlib.h>
using namespace std;
#define YYSTYPE char*
#define MAXTOKENLEN 20
extern FILE*yyin;
extern int yylex();
extern int yylineno;
extern void yyerror(char *message);
extern char tokenString[MAXTOKENLEN+1];
extern int val;
char * copyString(char * s);
char OP[14][3]={" ","==","!=","=","+","-","*","/","%","&&","||",">","<"};
int stk=0;
%}

%token IF RETURN ID INTEGER GOTO CALL END FUNC LABEL LOAD LOADADDR STORE MALLOC Reg
%token EQ NE ASSIGN ADD SUB MUL DIV MOD AND OR G L NOT

%%
Program: Goal 
	;

Goal : 	     Goal Line
	|    
	;
Line :       Id  ASSIGN  INTEGER 
		{
			printf("	.global %s\n",$1);
			printf("	.section .sdata\n");
			printf("	.align 2\n");
			printf("	.type %s, @object\n",$1);
			printf("	.size %s, 4\n",$1);
			printf("%s:\n",$1);
			printf("	.word %d\n",val);
		}
	|    Id  ASSIGN  MALLOC INTEGER	
		{
			printf("	.comm %s,%d,4\n",$1,val*4);
		}

	|    FUNC '[' INTEGER ']' '[' INTEGER ']' 
		{
			stk=(val/4+1)*16;
			printf("	.text\n");
			printf("	.align 2\n");
			printf("	.global %s\n",tokenString+2);
			printf("	.type %s,@function\n",tokenString+2);//碰到函数名时去掉前面的f_
			printf("%s:\n",tokenString+2);		
			printf("	add sp,sp,%d\n",-stk);
			printf("	sw ra,%d(sp)\n",stk-4);
		}

	|    END FUNC		
		{
			printf("	.size %s,.-%s\n",tokenString+2,tokenString+2);
			stk=0;
		}

	|	REG  ASSIGN  REG  OP2  REG   
		{
			if(strcmp($4,OP[1])==0) //==
			{
				printf("	xor %s,%s,%s\n",$1,$3,$5);
				printf("	seqz %s,%s\n",$1,$1);
			}
			else if(strcmp($4,OP[2])==0) //!=
			{
				printf("	xor %s,%s,%s\n",$1,$3,$5);
				printf("	snez %s,%s\n",$1,$1);
			}
		/*	else if(strcmp($4,OP[3])==0) //=
			{
				
			}*/
			else if(strcmp($4,OP[4])==0)  //+
			{
				printf("	add %s,%s,%s\n",$1,$3,$5);
			}
			else if(strcmp($4,OP[5])==0)  //-
			{
				printf("	sub %s,%s,%s\n",$1,$3,$5);
			}
			else if(strcmp($4,OP[6])==0)  //*
			{
				printf("	mul %s,%s,%s\n",$1,$3,$5);
			}
			else if(strcmp($4,OP[7])==0)  ///
			{
				printf("	div %s,%s,%s\n",$1,$3,$5);
			}
			else if(strcmp($4,OP[8])==0)// %
			{
				printf("	rem %s,%s,%s\n",$1,$3,$5);
			}
			else if(strcmp($4,OP[9])==0) //&&
			{
				printf("	and %s,%s,%s\n",$1,$3,$5);
				printf("	snez %s,%s\n",$1,$1);
			}
			else if(strcmp($4,OP[10])==0)//||
			{
				printf("	or %s,%s,%s\n",$1,$3,$5);
				printf("	snez %s,%s\n",$1,$1);
			}
			else if(strcmp($4,OP[11])==0)//>
			{
				printf("	sgt %s,%s,%s\n",$1,$3,$5);
			}
			else if(strcmp($4,OP[12])==0)//<
			{
				printf("	slt %s,%s,%s\n",$1,$3,$5);
			}
		}
		
/*	|	REG  ASSIGN  REG  OP2  INTEGER	
		{
			
		}*/

	|	REG  ASSIGN  OP1  REG	
		{
			if(strcmp($3,OP[5])==0)
			{
				printf("	sub %s,x0,%s\n",$1,$4);
			}
			else 
			{
				printf("	not %s,%s\n",$1,$4);
			}
		}

	|	REG  ASSIGN  REG  {printf("	mv %s,%s\n",$1,$3);}

	|	REG  ASSIGN  INTEGER   {printf("	li %s,%d\n",$1,val);}

	|	REG '[' INTEGER ']' ASSIGN  REG  {printf("	sw %s,-%d(%s)\n",$6,val,$1);}

	|       REG  ASSIGN  REG '[' INTEGER ']'  {printf("	lw %s,-%d(%s)\n",$1,val,$3);}

	|	IF REG LOGICALOP REG GOTO LABEL  
		{
			printf("	beq %s,%s,.%s\n",$2,$4,tokenString);
		}

	|	GOTO  LABEL   {printf("	j .%s\n",tokenString);}

	|	LABEL ':'   {printf(".%s:\n",tokenString);}

	|	CALL  FUNC   
		{
			printf("	call %s\n",tokenString+2);
		}

	|	STORE  REG  INTEGER   {printf("	sw %s,%d(sp)\n",$2,val*4);}

	|	LOAD  INTEGER  REG    {printf("	lw %s,%d(sp)\n",$3,val*4);}

	|	LOAD  Id  REG   
		{
			printf("	lui %s,%%hi(%s)\n",$3,$2);
			printf("	lw %s,%%lo(%s)(%s)\n",$3,$2,$3);
		}

	|       LOADADDR   INTEGER  REG   {printf("	add %s,sp,%d\n",$3,val*4);}

	|	LOADADDR   Id  REG   
		{
			printf("	lui %s,%%hi(%s)\n",$3,$2);
			printf("	add %s,%s,%%lo(%s)\n",$3,$3,$2);
		}

	|       RETURN   
		{
			printf("	lw ra, %d(sp)\n",stk-4);
			printf("	add sp,sp,%d\n",stk);
			printf("	jr ra\n");
		}
	;

REG:  Reg  {$$=copyString(tokenString);}
	;


Id   :  ID {$$=copyString(tokenString);}
	;

LOGICALOP :     EQ {$$=copyString(tokenString);}
	        ;

OP2:    	EQ {$$=copyString(tokenString);}
	|	NE {$$=copyString(tokenString);}
	|	ASSIGN {$$=copyString(tokenString);}
	|	ADD {$$=copyString(tokenString);}
	|	SUB {$$=copyString(tokenString);}
	|	MUL {$$=copyString(tokenString);}
	|	DIV {$$=copyString(tokenString);}
	|	MOD {$$=copyString(tokenString);}
	|	AND {$$=copyString(tokenString);}
	|	OR{$$=copyString(tokenString);}
	|	G {$$=copyString(tokenString);}
	|	L {$$=copyString(tokenString);}
	;

OP1:		NOT {$$=copyString(tokenString);}
	|	SUB {$$=copyString(tokenString);}
	;

%%

int main(int argc,char **argv)
{
    if (argc > 1) 
    {
    	FILE *file1;
    	file1 = fopen(argv[1], "r");
    	if (!file1) 
    	{
       		fprintf(stderr,"could not open %s\n",argv[1]);
       		exit(1);
    	}
    	yyin = file1; 
    }
    yyparse();
    return 0;
}


char * copyString(char * s)
{ 
  int n;
  char * t;
  if (s==NULL) return NULL;
  n = strlen(s)+1;
  t = (char*)malloc(n);
  if (t==NULL)
    printf("Out of memory error at line %d\n",yylineno);
  else strcpy(t,s);
  return t;
}


