%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include"minic.h"
#define MAXTOKENLEN 20
#define MAXCHILDREN 3
#define MAXTOKENNUM 10000

#define YYSTYPE TreeNode *


extern void yyerror(char *message);


char * copyString(char * s);

void PrintTree(TreeNode*root);
void BuildSystable(TreeNode*root);


void Myparse(TreeNode*root);
TreeNode* newTreeNode();
extern int yylex();
extern FILE*yyin;
extern FILE*yyout;
extern char tokenString[MAXTOKENLEN+1];
extern int val;
extern int yylineno;
TreeNode *root;


char OP[15][3]={" ","+","-","*","\\","%","<",">","&&","||","==","!="};

#define TABLESIZE 1000
struct Table
{
    char *name;//该变量的名字
    int num;   //该变量转到eeyore之后的下标
    int kind;  //该变量是原生变量还是参数 o or 1 stand for p or T
}tableEntity[TABLESIZE];
int pos=0;


int Tcount=0; //记录原生变量用了几个
int tcount=0; //记录临时变量用了几个
int lablecount=0; //记录label的标号用了几个


%}






%token IF ELSE WHILE INT RETURN ID INTEGER MAIN
%token EQ NE ASSIGN ADD SUB MUL DIV MOD AND OR G L NOT
%left ASSIGN
%left OR
%left AND
%left EQ NE
%left G L
%left ADD SUB 
%left MUL DIV MOD
%right NOT 
%nonassoc UMINUS

%%



Goal :  PreMain MainFunc    //main函数之前的部分连成一个串,定义成PreMain
	{ 
		TreeNode *t = $1;
                if (t != NULL)
                { while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $2;  
                     $$ = $1;
		 }
                else $$ = $2;
		root=$$;    //整个程序的开始节点存在root中
       	} 
        ;

PreMain:    PreMain VarDefn    
	    { 
	      TreeNode *t = $1;
              if (t != NULL){
                   while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $2;
                     $$ = $1; 
	      }else $$ = $2;
            }
          | PreMain FuncDefn
	    { 
	      TreeNode *t = $1;
              if (t != NULL){
                   while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $2;
                     $$ = $1; 
	      }else $$ = $2;
            }
          | PreMain FuncDecl
	    { 
	      TreeNode *t = $1;
              if (t != NULL){
                   while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $2;
                     $$ = $1; 
	      }else $$ = $2;
            }
          | {$$=NULL;}
          ;







MainFunc:   INT Main '(' ')' '{' s1 '}' 
	    {
		$$=newTreeNode();
		$$->name=$2->name;
		$$->nodekind=FuncDefnK;
		$$->Child[0]=$6;
		$$->attr.paramnum=0;
	    }
	    ;

Main : MAIN {$$=newTreeNode();$$->name=copyString(tokenString);}
	;

VarDefn:   
           INT Id ';'
	   {
	      $$=newTreeNode();
	      $$->nodekind=StmtK;
	      $$->kind.stmt=VarDefnK;
	      $$->name=$2->name;
	      $$->attr.size=0;
	   }
          |INT Id '[' INTEGER  ']' ';'
	   {
	      $$=newTreeNode();
	      $$->nodekind=StmtK;
	      $$->kind.stmt=VarDefnK;
	      $$->name=$2->name;
	      $$->attr.size=4*val;
	   }
          ;

FuncDefn:  INT Id '('  Varlist ')' '{' s1 '}'
	   {
		$$=newTreeNode();
		$$->name=$2->name;
		$$->nodekind=FuncDefnK;
		$$->Child[0]=$7;
		$$->Child[1]=$4;
		if($4!=NULL)
			$$->attr.paramnum=$4->attr.paramnum;
		else $$->attr.paramnum=0;
	   }
          ;

s1:  s1 Statement
	        {
		        TreeNode*t=$1;
			if(t!=NULL){
				while(t->sibling!=NULL)
					t=t->sibling;
				t->sibling=$2;
				$$=$1;
			}else{$$=$2;}
		}
             |{$$=NULL;}
             ;

FuncDecl:   INT Id '(' Varlist ')' ';'
	   {
		$$=newTreeNode();
		$$->nodekind=FuncDeclK;
		$$->name=$2->name;
		$$->Child[0]=$4;
		if($4!=NULL)
			$$->attr.paramnum=$4->attr.paramnum;
		else $$->attr.paramnum=0;
	   }
            ;

Id :ID {$$=newTreeNode();$$->name=copyString(tokenString);}
	;

Varlist:   VarDecl s2
	{ 
		$$=$1;
		$$->sibling=$2;
		if($2!=NULL)
			$$->attr.paramnum=$2->attr.paramnum+1;
		else $$->attr.paramnum=1;
	}
          |{$$=NULL;}
          ;

s2:  s2 ',' VarDecl
	{ 
	      TreeNode *t = $1;
              if (t != NULL){
                   while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $3;
                     $$ = $1; 
		     $$->attr.paramnum=$1->attr.paramnum+1;
	      }
	      else {
		$$=$3;
		$$->attr.paramnum=1;
    	      }	
	}
    |{$$=NULL;}
    ;

VarDecl:   INT Id 
	   {
		$$=newTreeNode();
		$$->name=$2->name;
		$$->nodekind=VarDeclK;
		$$->attr.size=0;
	   }
          |INT Id '[' INTEGER ']'
	   {
		$$=newTreeNode();
		$$->nodekind=VarDeclK;
		$$->name=$2->name;
		$$->attr.size=4*val;
	   }
          ;


















Statement: 
           '{' s1 '}' {$$=newTreeNode();$$->nodekind=StmtK;$$->kind.stmt=SpecialK;$$->Child[0]=$2;}
          | IF '(' Exp ')' Statement 
		{
			$$=newTreeNode();
			$$->nodekind=StmtK;
			$$->kind.stmt=IfK;
			$$->Child[0]=$3;
			$$->Child[1]=$5;
		}
          | IF '(' Exp ')' Statement ELSE Statement
		{
			$$=newTreeNode();
			$$->nodekind=StmtK;
			$$->kind.stmt=IfelseK;
			$$->Child[0]=$3;
			$$->Child[1]=$5;
			$$->Child[2]=$7;
		}
          | WHILE '(' Exp ')' Statement
		{
			$$=newTreeNode();
			$$->nodekind=StmtK;
			$$->kind.stmt=WhileK;
			$$->Child[0]=$3;
			$$->Child[1]=$5;
		}
          | Id ASSIGN Exp ';'
		{
			$$=newTreeNode();
			$$->nodekind=StmtK;
			$$->name=$1->name;
			$$->kind.stmt=IDAssignK;
			$$->Child[0]=$3;
		}
          | Id '[' Exp ']' ASSIGN Exp ';'
		{
			$$=newTreeNode();
			$$->name=$1->name;
			$$->nodekind=StmtK;
			$$->kind.stmt=ArrayAssignK;
			$$->Child[0]=$3;
			$$->Child[1]=$6;
		}
          | VarDefn
		{
			$$=$1;
		}
          | RETURN Exp ';'
		{
			$$=newTreeNode();
			$$->nodekind=StmtK;
			$$->kind.stmt=ReturnK;
			$$->Child[0]=$2;
		}
          ;

Exp:  
        Exp ADD Exp 
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=TwoopK;
	$$->Child[0]=$1;
	$$->Child[1]=$3;
	$$->attr.op=1;
	$$->type=Integer;
	}
      | Exp SUB Exp
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=TwoopK;
	$$->Child[0]=$1;
	$$->Child[1]=$3;
	$$->attr.op=2;
	$$->type=Integer;
	}
      | Exp MUL Exp 
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=TwoopK;
	$$->Child[0]=$1;
	$$->Child[1]=$3;
	$$->attr.op=3;
	$$->type=Integer;
	}
      | Exp DIV Exp 
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=TwoopK;
	$$->Child[0]=$1;
	$$->Child[1]=$3;
	$$->attr.op=4;
	$$->type=Integer;
	}
      | Exp MOD Exp 
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=TwoopK;
	$$->Child[0]=$1;
	$$->Child[1]=$3;
	$$->attr.op=5;
	$$->type=Integer;
	}
      | Exp AND Exp 
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=TwoopK;
	$$->Child[0]=$1;
	$$->Child[1]=$3;
	$$->attr.op=8;
	$$->type=Boolean;
	}
      | Exp OR Exp 
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=TwoopK;
	$$->Child[0]=$1;
	$$->Child[1]=$3;
	$$->attr.op=9;
	$$->type=Boolean;
	}
      | Exp L Exp   
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=TwoopK;
	$$->Child[0]=$1;
	$$->Child[1]=$3;
	$$->attr.op=6;
	$$->type=Boolean;
	}
      | Exp G Exp  
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=TwoopK;
	$$->Child[0]=$1;
	$$->Child[1]=$3;
	$$->attr.op=7;
	$$->type=Boolean;
	} 
      | Exp EQ Exp  
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=TwoopK;
	$$->Child[0]=$1;
	$$->Child[1]=$3;
	$$->attr.op=10;
	$$->type=Boolean;
	}
      | Exp NE Exp  
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=TwoopK;
	$$->Child[0]=$1;
	$$->Child[1]=$3;
	$$->attr.op=11;
	$$->type=Boolean;
	}
      | Exp '[' Exp ']' 
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=ArrayK;
	$$->Child[0]=$1;
	$$->Child[1]=$3;
	}
      | INTEGER    
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=ConstK;
	$$->attr.val=val;
	}
      | Id    
    	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->name=$1->name;
	$$->kind.exp=IdK;
	}
      | NOT Exp   
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=OneopK;
	$$->Child[0]=$2;
	$$->attr.op=12;
	}
      | SUB Exp   %prec UMINUS
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->kind.exp=OneopK;
	$$->Child[0]=$2;
	$$->attr.op=13;
	}
      | Id '(' idlist ')'
	{
	$$=newTreeNode();
	$$->nodekind=ExpK;
	$$->name=$1->name;
	$$->kind.exp=CallK;
	$$->Child[0]=$3;
	}
      | '(' Exp ')'{$$=$2;}
      ;

idlist:  
         Id s3 {$$=newTreeNode();$$->name=$1->name;$$->sibling=$2;}
        |{$$=NULL;}
        ;

s3: 
    s3 ',' Id{TreeNode *t = $1;
                if (t != NULL)
                { while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $3;
                     $$ = $1;
		 }
                else {$$ = $3;}}
   |{$$=NULL;}
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
    Myparse(root);
    return 0;
}




TreeNode* newTreeNode()
{
	TreeNode*t=(TreeNode*)malloc(sizeof(TreeNode));
	for (int i=0;i<MAXCHILDREN;i++) t->Child[i] = NULL;
    		t->sibling = NULL;
	return t;
}




char * copyString(char * s)
{ 
  int n;
  char * t;
  if (s==NULL) return NULL;
  n = strlen(s)+1;
  t = malloc(n);
  if (t==NULL)
    printf("Out of memory error at line %d\n",yylineno);
  else strcpy(t,s);
  return t;
}



void PrintTree(TreeNode*root)
{
	if(root==NULL)return;
	else if(root->nodekind==FuncDefnK)
	{
		printf("FuncDefn\n");
		PrintTree(root->Child[0]);
		PrintTree(root->Child[1]);
		PrintTree(root->sibling);
	}
	else if(root->nodekind==FuncDeclK)
	{
		printf("FuncDecl\n");
		PrintTree(root->Child[0]);
		PrintTree(root->sibling);
	}
	else if(root->nodekind==VarDeclK)
	{
		printf("VarDecl\n");
		PrintTree(root->sibling);
	}
	else if(root->nodekind==StmtK)
	{
		if(root->kind.stmt==IfK)
		{
			printf("Statement:Ifk\n");
			PrintTree(root->Child[0]);
			PrintTree(root->Child[1]);
		}
		else if(root->kind.stmt==IfelseK)
		{
			printf("Statement:Ifelsek\n");
			PrintTree(root->Child[0]);
			PrintTree(root->Child[1]);
			PrintTree(root->Child[2]);
		}
		else if(root->kind.stmt==WhileK)
		{
			printf("Statement:Whilek\n");
			PrintTree(root->Child[0]);
			PrintTree(root->Child[1]);
		}
		else if(root->kind.stmt==IDAssignK)
		{
			printf("Statement:IDAssignK\n");
			PrintTree(root->Child[0]);
		}	
		else if(root->kind.stmt==ArrayAssignK)
		{
			printf("Statement:ArrayAssignK\n");
			PrintTree(root->Child[0]);
		}	
		else if(root->kind.stmt==ReturnK)
		{
			printf("Statement:ReturnK\n");
			PrintTree(root->Child[0]);
		}	
		else if(root->kind.stmt==VarDefnK)
		{
			printf("Statement:VarDefnK\n");
		}
		else {PrintTree(root->Child[0]);}	
		PrintTree(root->sibling);
	}
	else if(root->nodekind ==ExpK )
	{
		printf("expK\n");
	}
}

/*
void BuildSystable(TreeNode*root)
{
	if(root==NULL)return;
	else if(root->nodekind==FuncDefnK)
	{
		root->start=pos;
		BuildSystable(root->Child[1]);
		BuildSystable(root->Child[0]);
		BuildSystable(root->sibling);
		pos=root->start;
	}

	else if(root->nodekind==FuncDeclK)
	{
		BuildSystable(root->sibling);
	}
	else if(root->nodekind==VarDeclK)
	{
		TreeNode*t=root;
		for(int i=0;i<root->attr.paramnum;++i)
		{
			tableEntity[pos+i].name=t->name
		}
		pos++;

		BuildSystable(root->sibling);
	}

	else if(root->nodekind==StmtK)
	{
		if(root->kind.stmt==IfK)
		{
			BuildSystable(root->Child[0]);
			BuildSystable(root->Child[1]);
		}
		else if(root->kind.stmt==IfelseK)
		{
			BuildSystable(root->Child[0]);
			BuildSystable(root->Child[1]);
			BuildSystable(root->Child[2]);
		}
		else if(root->kind.stmt==WhileK)
		{
			BuildSystable(root->Child[0]);
			BuildSystable(root->Child[1]);
		}
		else if(root->kind.stmt==IDAssignK)
		{
			for(int i=pos-1;i>=0;--i)
			{
				if(strcmp(root->name,tableEntity[i].name)==0)
				{
					root->index.varindex=tableEntity[i].num;
					break;
				}
			}
			BuildSystable(root->Child[0]);
		}	
		else if(root->kind.stmt==ArrayAssignK)
		{
			for(int i=pos-1;i>=0;--i)
			{
				if(strcmp(root->name,tableEntity[i].name)==0)
				{
					root->index.varindex=tableEntity[i].num;
					break;
				}
			}
			BuildSystable(root->Child[0]);
			BuildSystable(root->Child[1]);
		}	
		else if(root->kind.stmt==ReturnK)
		{
			BuildSystable(root->Child[0]);
		}	
		else if(root->kind.stmt==VarDefnK)
		{
			tableEntity[pos].name=root->name;
			tableEntity[pos].num=Tcount;
			pos++;
			Tcount++;	
		}	
		else 
		{
			root->start=pos;
			BuildSystable(root->Child[0]);
			pos=root->start;
		}
		BuildSystable(root->sibling);
	}
	else if(root->nodekind ==ExpK )
	{
		if(root->kind.exp==TwoopK)
		{
			BuildSystable(root->Child[0]);
			BuildSystable(root->Child[1]);
		}
		else if(root->kind.exp==OneopK)
		{
			BuildSystable(root->Child[0]);
		}
		else if(root->kind.exp==ConstK)
		{
			
		}
		else if(root->kind.exp==IdK)
		{
			for(int i=pos-1;i>=0;--i)
			{
				if(strcmp(root->name,tableEntity[i].name)==0)
				{
					root->index.varindex=tableEntity[i].num;
					break;
				}
			}
		}
		else if(root->kind.exp==CallK)
		{
			TreeNode*t=root->Child[0];
			while(t!=NULL)
			{
				for(int i=pos-1;i>=0;--i)
				{
					if(strcmp(t->name,tableEntity[i].name)==0)
					{
						t->index.varindex=tableEntity[i].num;
						break;
					}
				}
				t=t->sibling;
			}
		}
		else if(root->kind.exp==ArrayK)
		{
			BuildSystable(root->Child[0]);
			BuildSystable(root->Child[1]);
		}
	}
}
*/




void Myparse(TreeNode*root)
{
	//如果该节点为空,直接返回
	if(root==NULL)return;
	//遇到函数声明节点,直接跳过,到它的兄弟节点,因为函数声明不需要翻译
	else if(root->nodekind==FuncDeclK)
	{
		tableEntity[pos].name=root->name;
		tableEntity[pos].num=root->attr.paramnum;
		tableEntity[pos].kind=2;
		pos++;
		Myparse(root->sibling);
	}	
	//遇到变量声明节点直接返回,因为只在建语法树的时候需要它,已经算好参数个数了
	//之后声明的变量已经在参数pi里了
	else if(root->nodekind==VarDeclK)
	{
		return;
	}
	else if(root->nodekind==FuncDefnK)//遇到函数定义节点
	{
		int find=0;
		for(int i=0;i<pos;++i)
		{
			if(strcmp(root->name,tableEntity[i].name)==0)
			{
				find=1;
				break;
			}
		}
		if(find==0)
		{
			tableEntity[pos].name=root->name;
			tableEntity[pos].num=root->attr.paramnum;
			tableEntity[pos].kind=2;
			pos++;
		}
		root->start=pos;  //首先记录当前符号表位置
		//函数开始,根据eeyore语法输出函数名和参数个数
		printf("f_%s[%d]\n",root->name,root->attr.paramnum);
		//将该函数的参数全部加入符号表
		TreeNode*t=root->Child[1];
		for(int i=0;i<root->attr.paramnum;i++)
		{
			tableEntity[pos].name=t->name;
			tableEntity[pos].num=i;
			tableEntity[pos].kind=0;
			pos++;
			t=t->sibling;
		}
		Myparse(root->Child[0]);//遍历函数体
		//函数结束,根据eeyore语法输出函数结束语句
		printf("end f_%s\n",root->name);
		pos=root->start;	//重新设置符号表位置
		Myparse(root->sibling);	//遍历完该函数之后遍历下一个节点(它的兄弟)
	}
	
	else if(root->nodekind==StmtK)//遇到statement节点
	{
		if(root->kind.stmt==VarDefnK)//如果是变量定义节点
		{
			//针对变量是否为数组生成不同的eeyore语句
			if(root->attr.size==0)
			{
				printf("var T%d\n",Tcount);
			}
			else{
				printf("var %d T%d\n",root->attr.size,Tcount);
			}
			//将定义的变量加入符号表中并更新Tcount和pos
			for(int i=0;i<pos;++i)
			{
				if(strcmp(root->name,tableEntity[i].name)==0)
				{
					printf("id already exit\n");
					exit(0);
				}
			}
			root->varindex=Tcount;
			tableEntity[pos].name=root->name;
			tableEntity[pos].num=Tcount;
			tableEntity[pos].kind=1;
			pos++;
			Tcount++;
		}


		else if(root->kind.stmt==IfK)//遇到if语句
		{
			Myparse(root->Child[0]);//首先计算if中判断条件的值并存在某个临时变量中
			root->lableindex=lablecount;//设置一个label
			lablecount++;
			//如果判断条件不满足,跳转
			printf("if t%d == 0 goto l%d\n",root->Child[0]->varindex,root->lableindex);
			//判断条件满足时执行if中的语句		
			Myparse(root->Child[1]);
			printf("l%d:\n",root->lableindex);//判断条件不满足时跳转目标
		}

		else if(root->kind.stmt==IfelseK)//遇到if-else语句
		{
			Myparse(root->Child[0]);//首先计算if中判断条件的值并存在某个临时变量中
			root->lableindex=lablecount;//设置2个label
			lablecount=lablecount+2;  
			//如果判断条件不满足,跳转到else之前的label
			printf("if t%d == 0 goto l%d\n",root->Child[0]->varindex,root->lableindex);
			//判断条件满足时执行if中的语句
			Myparse(root->Child[1]);
			//执行完之后立刻跳转
			printf("goto l%d\n",root->lableindex+1);
			//判断条件不满足时跳转目标
			printf("l%d:\n",root->lableindex);
			//执行else中的语句
			Myparse(root->Child[2]);
			//执行完if中的语句后立刻跳转到的位置
			printf("l%d:\n",root->lableindex+1);
		}


		else if(root->kind.stmt==WhileK)//遇到while语句
		{
			root->lableindex=lablecount;//设置两个label
			lablecount=lablecount+2;
			printf("l%d:\n",root->lableindex);//下一次循环跳回的位置
			//首先计算while中判断条件的值并存在某个临时变量中
			Myparse(root->Child[0]); 
			//如果判断条件不满足,跳转
			printf("if t%d == 0 goto l%d\n",root->Child[0]->varindex,root->lableindex+1);	
			//while循环体
			Myparse(root->Child[1]);
			//跳转到下一次循环
			printf("goto l%d\n",root->lableindex);
			//判断条件不满足时的跳转目标
			printf("l%d:\n",root->lableindex+1);
		}
		
		else if(root->kind.stmt==ReturnK)//遇到return语句
		{
			Myparse(root->Child[0]);//将返回的值存到return节点中的临时变量中
			printf("return t%d\n",root->Child[0]->varindex);
		}

		else if(root->kind.stmt==IDAssignK)//遇到赋值给变量的语句
		{
			Myparse(root->Child[0]);
			int t=-1;
			for(int i=pos-1;i>=0;--i)//首先在符号表中查找该变量
			{
				if(strcmp(tableEntity[i].name,root->name)==0)
				{
					t=i;break;
				}
			}
			if(t==-1)//假如该变量在符号表中不存在,报错
			{
				printf("id undefined!!!\n");
				exit(0);
			}
			if(tableEntity[t].kind==0)//如果该变量为参数
				printf("p%d = t%d\n",tableEntity[t].num,root->Child[0]->varindex);
			else{	//该变量为原生变量
				printf("T%d = t%d\n",tableEntity[t].num,root->Child[0]->varindex);
			}
		}
		else if(root->kind.stmt==ArrayAssignK)//遇到赋值给数组元素的语句
		{
			Myparse(root->Child[0]);
			Myparse(root->Child[1]);
			int t=-1;
			for(int i=pos-1;i>=0;--i)//首先在符号表中查找该数组名
			{
				if(strcmp(tableEntity[i].name,root->name)==0)
				{
					t=i;break;
				}
			}
			if(t==-1)//如果该数组名不存在,报错
			{
				printf("id undefined!!!\n");
				exit(0);
			}
			printf("t%d = 4*t%d\n",root->Child[0]->varindex,root->Child[0]->varindex);
			if(tableEntity[t].kind==0)//该数组为参数
				printf("p%d[t%d] = t%d\n",tableEntity[t].num,root->Child[0]->varindex,root->Child[1]->varindex);
			else{//该数组为原生变量
				printf("T%d[t%d] = t%d\n",tableEntity[t].num,root->Child[0]->varindex,root->Child[1]->varindex);
			}
		}
		else{//SpecialK的情形
			Myparse(root->Child[0]);
		}
		Myparse(root->sibling);	//扫描下一个节点
	}



	else if(root->nodekind==ExpK)//遇到表达式节点
	{	
		printf("var t%d\n",tcount);//创建一个临时变量记录该表达式的值
		root->varindex=tcount;
		tcount++;
		if(root->kind.exp==TwoopK)//如果是带双目运算符的表达式,先计算两分量的值,再赋给该表达式
		{
			Myparse(root->Child[0]);
			Myparse(root->Child[1]);
			printf("t%d = t%d %s t%d\n",root->varindex,root->Child[0]->varindex,
			OP[root->attr.op],root->Child[1]->varindex);
		}
		else if(root->kind.exp==OneopK)//单目运算符的情形
		{
			Myparse(root->Child[0]);//先计算分量的值,再赋给该表达式
			if(root->attr.op==12)
				printf("t%d = !t%d\n",root->varindex,root->Child[0]->varindex);
			else if(root->attr.op==13)
				printf("t%d = -t%d\n",root->varindex,root->Child[0]->varindex);
		}
		else if(root->kind.exp==ConstK)//表达式为常量的情形
		{
			printf("t%d = %d\n",root->varindex,root->attr.val);
		}
		else if(root->kind.exp==IdK)//表达式为Id的情形
		{
			int t=-1;
			for(int i=pos-1;i>=0;--i)//在符号表中查找该Id
			{
				if(strcmp(tableEntity[i].name,root->name)==0)
				{
					t=i;break;
				}
			}
			if(t==-1)//如果没找到,报错
			{
				printf("id undefined!!!\n");
				exit(0);
			}
			if(tableEntity[t].kind==0)
				printf("t%d = p%d\n",root->varindex,tableEntity[t].num);
			else{
				printf("t%d = T%d\n",root->varindex,tableEntity[t].num);
			}
		}
		else if(root->kind.exp==CallK)//表达式为函数调用的情形
		{
			char s1[7]={'g','e','t','i','n','t'};//内置四个函数做特殊判断
			char s2[8]={'g','e','t','c','h','a','r'};	
			char s3[8]={'p','u','t','c','h','a','r'};	
			char s4[7]={'p','u','t','i','n','t'};		
			int pn=0;
			TreeNode*t=root->Child[0];
			while(t!=NULL)//计算调用函数时输入了多少变量
			{
				pn++;
				t=t->sibling;
			}
			if(strcmp(root->name,s1)==0||strcmp(root->name,s2)==0)
			{
				if(pn!=0)
				{
					printf("paramnum not match!!");
					exit(0);
				}
			}
			else if(strcmp(root->name,s3)==0||strcmp(root->name,s4)==0)
			{
				if(pn!=1)
				{
					printf("paramnum not match!!");
					exit(0);
				}
			}
			else{
			
				int tmp=-1;
				for(int i=pos-1;i>=0;--i)//在符号表中找到函数名
				{
					if(strcmp(tableEntity[i].name,root->name)==0)
					{
						tmp=i;break;
					}
				}
				if(tmp==-1)//函数未定义就使用
				{
					printf("Func Not Defined!!\n");
					exit(0);
				}
				if(pn!=tableEntity[tmp].num)//函数参数个数不匹配
				{
					printf("paramnum not match!!");
					exit(0);
				}
			}
			t=root->Child[0];
			while(t!=NULL)//查找该函数对应的所有参数,并以param的形式输出
			{
				int tmp=-1;
				for(int i=pos-1;i>=0;--i)
				{
					if(strcmp(tableEntity[i].name,t->name)==0)
					{
						tmp=i;break;
					}
				}
				if(tmp==-1)//如果有某个参数在符号表中未找到,报错
				{
					printf("id undefined!!!\n");
					exit(0);
				}
				if(tableEntity[tmp].kind==0)
					printf("param p%d\n",tableEntity[tmp].num);
				else{
					printf("param T%d\n",tableEntity[tmp].num);
				}
				t=t->sibling;
			}
			printf("t%d = call f_%s\n",root->varindex,root->name);
		}
		else if(root->kind.exp==ArrayK)//如果表达式是数组元素 
		{
			Myparse(root->Child[0]);
			Myparse(root->Child[1]);
			printf("t%d = 4*t%d\n",root->Child[1]->varindex,root->Child[1]->varindex);
			printf("t%d = t%d [t%d]\n",root->varindex,root->Child[0]->varindex,root->Child[1]->varindex);
		}
	}
}
