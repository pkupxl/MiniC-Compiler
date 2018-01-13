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
whitespace  [ \t\n]+
%option yylineno

%%
"if"	      {return IF;}
"return"      {return RETURN;} 
"goto"	      {return GOTO;}
"call"        {return CALL;}
"end"	      {return END;}
"load"	      {return LOAD;}
"loadaddr"    {return LOADADDR;}
"store"	      {return STORE;}
"malloc"      {return MALLOC;}
"!="          {strcpy(tokenString,yytext);return NE;} 
"=="          {strcpy(tokenString,yytext);return EQ;} 
"="           {strcpy(tokenString,yytext);return ASSIGN;} 
"+"           {strcpy(tokenString,yytext);return ADD;}
"-"           {strcpy(tokenString,yytext);return SUB;}
"*"           {strcpy(tokenString,yytext);return MUL;}
"/"           {strcpy(tokenString,yytext);return DIV;}
"%"           {strcpy(tokenString,yytext);return MOD;}
"&&"          {strcpy(tokenString,yytext);return AND;}
"||"          {strcpy(tokenString,yytext);return OR;}
">"           {strcpy(tokenString,yytext);return G;}
"<"           {strcpy(tokenString,yytext);return L;}
"!"           {strcpy(tokenString,yytext);return NOT;}
":"           {return yytext[0];}
"["           {return yytext[0];}
"]"           {return yytext[0];}
[l][0-9]+     {strcpy(tokenString,yytext); return LABEL; }
{number}      {val=atoi(yytext);return INTEGER;}
[v][0-9]+     {strcpy(tokenString,yytext); return ID;}
[s|t|a][0-9]+|[x][0]  {strcpy(tokenString,yytext); return Reg;}
[f][_][a-zA-Z]+[0-9]*  {strcpy(tokenString,yytext); return FUNC; }
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

