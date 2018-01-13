%{
#include<stdio.h>
#include<string.h>
#include"y.tab.h"
#define MAXTOKENLEN 20   //设置最长的token长度为20
char tokenString[MAXTOKENLEN+1];//通过tokenString将当前的token传到minic.y
int val; //通过val将当前token的值传到minic.y
%}


digit       [0-9]
number      {digit}+
letter      [a-zA-Z]
identifier  {letter}+
whitespace  [ \t\n]+
%option yylineno

%%
"if"          {return IF;}
"else"        {return ELSE;}
"while"       {return WHILE;}
"int"         {return INT;}
"return"      {return RETURN;} 
"main"        {strcpy(tokenString,yytext);return MAIN;}
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


";"           {return yytext[0];}
","           {return yytext[0];}
"("           {return yytext[0];}
")"           {return yytext[0];}
"["           {return yytext[0];}
"]"           {return yytext[0];}
"{"           {return yytext[0];} 
"}"           {return yytext[0];}
{number}      {val=atoi(yytext);return INTEGER;}
{identifier}{digit}*  {strcpy(tokenString,yytext);return ID;}
"//"[^\n]*    {} //过滤单行注释
"/*".*"*/"    {} //过滤多行注释
{whitespace}  {} //过滤空格换行符等

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

