%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include"y.tab.h"
#define MAXTOKENLEN 20
char tokenString[MAXTOKENLEN+1];
int val;
%}


digit       [0-9]
number      {digit}+
letter      [a-zA-Z]
identifier  {letter}+
whitespace  [ \t\n]+
%option yylineno

%%
"if"	      {return IF;}
"var"         {return VAR;}
"return"      {return RETURN;} 
"goto"	      {return GOTO;}
"call"        {return CALL;}
"end"	      {return END;}
"param"	      {return PARAM;}
"!="          {return NE;} 
"=="          {return EQ;} 
"="           {return ASSIGN;} 
"+"           {return ADD;}
"-"           {return SUB;}
"*"           {return MUL;}
"/"           {return DIV;}
"%"           {return MOD;}
"&&"          {return AND;}
"||"          {return OR;}
">"           {return G;}
"<"           {return L;}
"!"           {return NOT;}
":"           {return yytext[0];}
"["           {return yytext[0];}
"]"           {return yytext[0];}
[l][0-9]+     {strcpy(tokenString,yytext); return LABEL; }
{number}      {val=atoi(yytext);return INTEGER;}
[a-zA-Z]+[0-9]*  {strcpy(tokenString,yytext); return ID;}
[a-zA-Z|_]+[0-9]*  {strcpy(tokenString,yytext); return FUNC; }
{whitespace}  {}
%%

int yywrap()
{
	return 1;
}

void yyerror(char *message)
{
    printf("%d %s\n",yylineno,message);
    exit(0);
}

