%{
#include<stdio.h>
#include<iostream>
#include<string.h>
#include<stdlib.h>
#include<bitset>
#include"global.h"
#include<string>
using std::bitset;
using namespace std;
#define YYSTYPE TreeNode *	
#define MAXTOKENLEN 20          //token的最长长度
#define MAXGLOBALNUM 150        //全局变量最多的个数
#define bitsetsize 150          //记录活跃性的变量的个数
extern FILE*yyin;
extern int yylex();
extern int yylineno;
extern void yyerror(char *message);
extern char tokenString[MAXTOKENLEN+1];
extern int val;
char * copyString(char * s);

TreeNode*root;   //语法树的根节点

struct Systable * newTable(); //创建符号表的函数         

TreeNode* newTreeNode();    //生成语法树的节点

int Getnum(TreeNode*root,char*name);    //在符号表中查找特定变量的位置

void LiveAnalysis();     //活性分析

int globalnum=0;     //全局变量的个数

void Init();

void BuildSystable();   //建立符号表

void BuildNextLink();   //活性分析时需要知道每条语句的下一条可能执行语句.对于控制语句可能不是物理上的下一条语句,需要进行记录

void Translate();   //翻译函数


//针对不同的语句生成不同的Tigger代码的函数
void GenGlobalVarDefn(TreeNode*t);

void GenVarEqRvOpRv(TreeNode*t);

void GenVarEqOpRv(TreeNode*t);

void GenVarEqRv(TreeNode*t);

void GenVarRvEqRv(TreeNode*t);

void GenVarEqVarRv(TreeNode*t);

void GenIfRvOpRvGotol(TreeNode*t);

void GenGotol(TreeNode*t);

void Genl(TreeNode*t);

void GenParamRv(TreeNode*t);

void GenVarEqCall(TreeNode*t);

void GenReturnVar(TreeNode*t);


//分配寄存器的函数
int allocate(TreeNode*t, int index);

//删除之后不活跃的变量所占用的寄存器的函数
void DeleteUseless(TreeNode*t,int index);

//所有的寄存器
char Reg[28][4]={"x0","s0","s1","s2","s3","s4","s5","s6","s7","s8","s9","s10","s11",
"t0","t1","t2","t3","t4","t5","t6","a0","a1","a2","a3","a4","a5","a6","a7"};

int S11Val=0;


int paramcount=0;

//操作符数组
char OP[14][3]={" ","==","!=","=","+","-","*","/","%","&&","||",">","<"};

//记录寄存器中存的当前是哪个变量
int Regused[29]={0};
%}


%token IF VAR RETURN ID INTEGER GOTO CALL PARAM END FUNC LABEL 
%token EQ NE ASSIGN ADD SUB MUL DIV MOD AND OR G L NOT
%%
Program: Goal {	$$=$1; root=$$; /*printf("Success!!\n");*/}
	;

Goal : 	     Goal VarDefn 
	     {
		TreeNode *t = $1;
              	if (t != NULL){
                   while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $2;
                     $$ = $1; 
	      	}else $$ = $2;
	     }

	|    Goal FuncDefn
	     {
		TreeNode *t = $1;
              	if (t != NULL){
                   while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $2;
                     $$ = $1; 
	      	}else $$ = $2;
	     }
	|    {$$=NULL;}

	;

VarDefn :    VAR  ID	{$$=newTreeNode();$$->nodekind=VarDefnK;$$->name=copyString(tokenString);$$->size=0;}

	|    VAR  INTEGER  ID	{$$=newTreeNode();$$->nodekind=VarDefnK;$$->name=copyString(tokenString);$$->size=val;}

	;

FuncDefn:     FUNC '[' ']' FuncContent END FUNC		
		{$$=newTreeNode();$$->nodekind=FuncK;$$->Child[0]=$4;$$->paramnum=0;$$->name=copyString(tokenString);}

	|     FUNC '[' Integer ']' FuncContent END FUNC	
		{$$=newTreeNode();$$->nodekind=FuncK;$$->Child[0]=$5;$$->paramnum=$3->val;$$->name=copyString(tokenString);}

	;

FuncContent:	FuncContent VarDefn 
		{
			TreeNode *t = $1;
              		if (t != NULL){
                   	while (t->sibling != NULL)
                        	t = t->sibling;
                     	t->sibling = $2;
                     	$$ = $1; 
	      		}else $$ = $2;
			$2->Pre=t;
		}

	|	FuncContent EXP   
		{
			TreeNode *t = $1;
              		if (t != NULL){
                   	while (t->sibling != NULL)
                        	t = t->sibling;
                     	t->sibling = $2;  
                     	$$ = $1; 
	      		}else $$ = $2;
			$2->Pre=t;
		}

	|	{$$=NULL;}

	;

EXP:		Id ASSIGN  RightValue OP2 RightValue
		{$$=newTreeNode();$$->nodekind=ExpK;$$->Child[0]=$1;$$->Child[1]=$3;$$->Child[2]=$5;
		 $$->expkind=1;	$$->op=$4->op;}

	|	Id ASSIGN  OP1 RightValue	
		{$$=newTreeNode();$$->nodekind=ExpK;$$->Child[0]=$1;$$->Child[1]=$4;
		$$->expkind=2;	$$->op=$3->op;}

	|	Id ASSIGN  RightValue	{$$=newTreeNode();$$->nodekind=ExpK;$$->Child[0]=$1;$$->Child[1]=$3;
		$$->expkind=3;	}	
		

	|	Id '[' RightValue ']' ASSIGN RightValue	
		{$$=newTreeNode();$$->nodekind=ExpK;$$->Child[0]=$1;$$->Child[1]=$3;$$->Child[2]=$6;
		$$->expkind=4;}

	|	Id ASSIGN Id '[' RightValue ']'		
		{$$=newTreeNode();$$->nodekind=ExpK;$$->Child[0]=$1;$$->Child[1]=$3;$$->Child[2]=$5;
		$$->expkind=5;}

	|	IF RightValue OP2 RightValue GOTO LABEL	
		{$$=newTreeNode();$$->nodekind=ExpK;$$->Child[0]=$2;$$->Child[1]=$4;
		$$->expkind=6;$$->op=$3->op;$$->name=copyString(tokenString);}

	|       GOTO LABEL	
		{$$=newTreeNode();$$->nodekind=ExpK;$$->expkind=7;$$->name=copyString(tokenString);}

	|	LABEL ':'	
		{$$=newTreeNode();$$->nodekind=ExpK;$$->expkind=8;$$->name=copyString(tokenString);}

	|	PARAM RightValue	
		{$$=newTreeNode();$$->nodekind=ExpK;$$->expkind=9;$$->Child[0]=$2;}

	|	Id ASSIGN CALL FUNC	
		{$$=newTreeNode();$$->nodekind=ExpK;$$->expkind=10;$$->Child[0]=$1;$$->name=copyString(tokenString);}

	|	RETURN RightValue	
		{$$=newTreeNode();$$->nodekind=ExpK;$$->expkind=11;$$->Child[0]=$2;}
	;

RightValue:	Id{$$=$1;$$->name=$1->name;$$->op=0;}	
	|	Integer	{$$=$1;$$->val=$1->val;$$->op=1;}
	;

Id:  ID {$$=newTreeNode();$$->name=copyString(tokenString);$$->op=0;}
	;

Integer :INTEGER {$$=newTreeNode();$$->val=val;$$->op=1;}
	;

OP2:    	EQ {$$=newTreeNode();$$->op=1;}
	|	NE {$$=newTreeNode();$$->op=2;}
	|	ASSIGN {$$=newTreeNode();$$->op=3;}
	|	ADD {$$=newTreeNode();$$->op=4;}
	|	SUB {$$=newTreeNode();$$->op=5;}
	|	MUL{$$=newTreeNode();$$->op=6;}
	|	DIV {$$=newTreeNode();$$->op=7;}
	|	MOD {$$=newTreeNode();$$->op=8;}
	|	AND {$$=newTreeNode();$$->op=9;}
	|	OR {$$=newTreeNode();$$->op=10;}
	|	G {$$=newTreeNode();$$->op=11;}
	|	L {$$=newTreeNode();$$->op=12;}
	;

OP1:		NOT{$$=newTreeNode();$$->op=13;}
	|	SUB{$$=newTreeNode();$$->op=5;}
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
    Init();
    LiveAnalysis();
	
  //  printf("LiveOK\n");

    Translate();
    return 0;
}

//对于每个函数建立一个符号表,这是给符号表分配空间的函数
struct Systable * newTable()
{
	struct Systable * t= (struct Systable *)malloc(MAXGLOBALNUM*sizeof(Systable));
	return t;
}

TreeNode* newTreeNode()
{
	TreeNode*t=(TreeNode*)malloc(sizeof(TreeNode));
	t->Child[0]=NULL;
	t->Child[1]=NULL;
	t->Child[2]=NULL;
	t->sibling=NULL;
	t->Table=NULL;
     	t->Belong=NULL;
	t->Pre=NULL;
	t->End=NULL;
	t->Next[0]=NULL;
	t->Next[1]=NULL;
	return t;
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

//遍历语法树并建立符号表的函数
void BuildSystable()
{
	TreeNode*t=root;
	while(t!=NULL)
	{
		if(t->nodekind!=FuncK)//如果不是函数定义节点,那么是全局变量定义节点,把它加到全局符号表
		{
			Global[globalnum].id=t->name;
			Global[globalnum].size=t->size;
			Global[globalnum].isglobal=1;
			globalnum=globalnum+1;
			t=t->sibling;
		}
		else//是函数定义节点,进入该函数
		{
			TreeNode*tmp=t;
			t=t->sibling;
			tmp->Table=newTable();//创建一个属于该函数的符号表
			for(int i=0;i<globalnum;++i)//首先将当前的所有全局变量加入符号表
			{
				tmp->size++;
				tmp->Table[tmp->size].id=Global[i].id;
				tmp->Table[tmp->size].size=Global[i].size;
				tmp->Table[tmp->size].isglobal=1;
				tmp->Table[tmp->size].location=tmp->stacksize;
				tmp->stacksize++;
			}
			for(int i=0;i<tmp->paramnum;++i)//将所有参数加入符号表
			{
				tmp->size++;
				tmp->Table[tmp->size].id=(char*)malloc(3*sizeof(char*));
				tmp->Table[tmp->size].id[0]='p';
				tmp->Table[tmp->size].id[1]=char('0'+i-0);
				tmp->Table[tmp->size].id[2]='\0';
				tmp->Table[tmp->size].size=0;
				tmp->Table[tmp->size].location=tmp->stacksize;
				tmp->Table[tmp->size].paramnum=i+1;
				tmp->stacksize++;
				tmp->Table[tmp->size].isglobal=0;
			}
			
			if(tmp->Child[0]==NULL)continue;

			tmp->Child[0]->Belong=tmp;

			tmp=tmp->Child[0];

			while(tmp!=NULL)
			{
				if(tmp->nodekind==VarDefnK)//扫描该函数的语句,如果是变量定义,加入符号表
				{
					tmp->Belong->size++;
					tmp->Belong->Table[tmp->Belong->size].id=tmp->name;
					tmp->Belong->Table[tmp->Belong->size].size=tmp->size;
					tmp->Belong->Table[tmp->Belong->size].isglobal=0;
					tmp->Belong->Table[tmp->Belong->size].location=tmp->Belong->stacksize;
					if(tmp->size==0)
					{
						tmp->Belong->stacksize++;
					}
					else 
					{
						tmp->Belong->stacksize+=tmp->size;
					}	
				}
				if(tmp->sibling!=NULL)
				{
					tmp->sibling->Belong=tmp->Belong;
				}
				else
				{
					tmp->Belong->End=tmp;
				}
				tmp=tmp->sibling;
			}
		}
	}
/*	t=root;
	while(t!=NULL)
	{
		if(t->nodekind==FuncK)
		{
			printf("%s\n",t->name);
			for(int i=1;i<=t->size;++i)
			{
				printf("%s %d\n",t->Table[i].id,i);
			}	
		}
		t=t->sibling;
	}*/
}

void BuildNextLink()//线性扫描的时候需要知道每个节点的后继节点是谁,该函数建立起这种联系供后续线性扫描使用
{
	TreeNode* t=root;
	while(t!=NULL)
	{
		if(t->nodekind!=FuncK)
		{
			
			t=t->sibling;
			continue;
		}
		TreeNode*tmp1=t->Child[0];
			
		if(t->Child[0]==NULL)continue;
	
		while(tmp1!=NULL)
		{
			if(tmp1->nodekind==ExpK && tmp1->expkind==6) 
			{
				TreeNode*tmp2=t->Child[0];
				while(tmp2!=NULL)
				{
					if(tmp2->nodekind==ExpK && tmp2->expkind == 8 && strcmp(tmp1->name,tmp2->name)==0)
					{
						tmp1->Next[0]=tmp1->sibling;
						tmp1->Next[1]=tmp2;
						break;
					}
					tmp2=tmp2->sibling;
				}
			}

			else if(tmp1->nodekind==ExpK && tmp1->expkind==7)  
			{
				TreeNode*tmp2=t->Child[0];
				while(tmp2!=NULL)
				{
					if(tmp2->nodekind==ExpK && tmp2->expkind == 8 && strcmp(tmp1->name,tmp2->name)==0)
					{
						tmp1->Next[0]=tmp2;
						break;
					}
					tmp2=tmp2->sibling;
				}
			}
			else
			{
				tmp1->Next[0]=tmp1->sibling;
			}
			tmp1=tmp1->sibling;
		}
		t=t->sibling;
	}
}


void Init()
{
	BuildSystable();
	BuildNextLink();
}	



int Getnum(TreeNode*root,char*name)//在特定的符号表中查找相应的变量
{
	TreeNode*belong=root->Belong;
	for(int i=1;i<=belong->size;++i)
	{
		if(strcmp(belong->Table[i].id,name)==0)
		{
			return i;
		}
	}
}

void LiveAnalysis()//用线性扫描的算法进行活性分析
{
	TreeNode*t=root;//先遍历语法树,将每条语句的use和define记录好
	while(t!=NULL)
	{
		if(t->nodekind!=FuncK)
		{
			t=t->sibling;
			continue;
		}
		TreeNode*tmp=t->Child[0];
		t=t->sibling;
		while(tmp!=NULL)
		{
			if(tmp->nodekind==VarDefnK)
			{
				tmp=tmp->sibling;
				continue;
			}
			if(tmp->expkind==1)
			{
				tmp->define[Getnum(tmp,tmp->Child[0]->name)]=1;
			//	cout<<tmp->Child[0]->name<<" ";
				if(tmp->Child[1]->op==0)
				{
					tmp->use[Getnum(tmp,tmp->Child[1]->name)]=1;
				//	cout<<tmp->Child[1]->name<<" ";
				}
				if(tmp->Child[2]->op==0)
				{
					tmp->use[Getnum(tmp,tmp->Child[2]->name)]=1;
				//	cout<<tmp->Child[2]->name<<" ";
				}
				//cout<<endl;
				
			}
			else if(tmp->expkind==2)
			{
				tmp->define[Getnum(tmp,tmp->Child[0]->name)]=1;
			//	cout<<tmp->Child[0]->name<<" ";
				if(tmp->Child[1]->op==0)
				{
					tmp->use[Getnum(tmp,tmp->Child[1]->name)]=1;
			//		cout<<tmp->Child[1]->name<<" ";
				}
			//	cout<<endl;
			}
			else if(tmp->expkind==3)
			{
				tmp->define[Getnum(tmp,tmp->Child[0]->name)]=1;
			//	cout<<tmp->Child[0]->name<<" ";
				if(tmp->Child[1]->op==0)
				{
			//		cout<<tmp->Child[1]->name<<" ";
					tmp->use[Getnum(tmp,tmp->Child[1]->name)]=1;
				}
			//	cout<<endl;
			}
			else if(tmp->expkind==4)
			{
				tmp->use[Getnum(tmp,tmp->Child[0]->name)]=1;
			//	cout<<tmp->Child[0]->name<<" ";
				if(tmp->Child[1]->op==0){
					tmp->use[Getnum(tmp,tmp->Child[1]->name)]=1;
			//		cout<<tmp->Child[1]->name<<" ";
				}
				if(tmp->Child[2]->op==0)
				{
					tmp->use[Getnum(tmp,tmp->Child[2]->name)]=1;
			//		cout<<tmp->Child[2]->name<<" ";
				}
			//	cout<<endl;
			}
			else if(tmp->expkind==5)
			{
				tmp->define[Getnum(tmp,tmp->Child[0]->name)]=1;
			//	cout<<tmp->Child[0]->name<<" ";
				tmp->use[Getnum(tmp,tmp->Child[1]->name)]=1;
			//	cout<<tmp->Child[1]->name<<" ";
				if(tmp->Child[2]->op==0)
				{
					tmp->use[Getnum(tmp,tmp->Child[2]->name)]=1;
			//		cout<<tmp->Child[2]->name<<" ";
				}
			//	cout<<endl;
			}
			else if(tmp->expkind==6)
			{
				if(tmp->Child[0]->op==0)
				{
					tmp->use[Getnum(tmp,tmp->Child[0]->name)]=1;
			//		cout<<tmp->Child[0]->name<<" ";
				}
				if(tmp->Child[1]->op==0)
				{
					tmp->use[Getnum(tmp,tmp->Child[1]->name)]=1;
			//		cout<<tmp->Child[1]->name<<" ";
				}
			//	cout<<endl;
			}
			else if(tmp->expkind==7)
			{
				
			}
			else if(tmp->expkind==8)
			{
				
			}
			else if(tmp->expkind==9)
			{
				if(tmp->Child[0]->op==0)
				{
			//		cout<<tmp->Child[0]->name<<" ";
					tmp->use[Getnum(tmp,tmp->Child[0]->name)]=1;
				}
			//	cout<<endl;
			}
			else if(tmp->expkind==10)
			{
				tmp->define[Getnum(tmp,tmp->Child[0]->name)]=1;
			//	cout<<tmp->Child[0]->name<<" ";
			//	cout<<endl;
			}
			else if(tmp->expkind==11)
			{
				if(tmp->Child[0]->op==0)
				{
					tmp->use[Getnum(tmp,tmp->Child[0]->name)]=1;
			//		cout<<tmp->Child[0]->name<<" ";
				}
			//	cout<<endl;
			}
			tmp=tmp->sibling;
		}
	}

	t=root;
	while(t!=NULL)//遍历这棵语法树,以函数为单位进行活性分析.
	{
		if(t->nodekind!=FuncK)
		{
			t=t->sibling;
			continue;
		}

		bool flag =true;
		while(flag)
		{
			TreeNode*tmp=t->End;
			bool Change=false;
			while(tmp!=NULL)
			{
				
				if(tmp->Next[0]==NULL)
				{
					tmp->live=tmp->use;
				}
				else
				{
					if(tmp->nodekind==ExpK && tmp->expkind==6)
					{
						
						bitset<bitsetsize> tmpbs = tmp->Next[0]->live|tmp->Next[1]->live;
						tmpbs = tmpbs & (~tmp->define);
						tmpbs = tmpbs | tmp->use;
						if(tmpbs!=tmp->live)
						{
							Change=true;
						}
						tmp->live=tmpbs;
					}
					else
					{
						bitset<bitsetsize> tmpbs = tmp->Next[0]->live;
						tmpbs = tmpbs & (~tmp->define);
						tmpbs = tmpbs | tmp->use;
						if(tmpbs!=tmp->live)
						{
							Change=true;
						}
						tmp->live=tmpbs;
					}
				}
				tmp=tmp->Pre;
			}
			if(!Change)
			{
				flag=false;
			}
		}
		t=t->sibling;
	}
/*
	t=root;
	while(t!=NULL)
	{
		if(t->nodekind!=FuncK)
		{
			t=t->sibling;
			continue;
		}
		TreeNode*tmp=t->Child[0];
		printf("%s\n",t->name);
		t=t->sibling;
		while(tmp!=NULL)
		{
			if(tmp->nodekind==VarDefnK)
			{
				tmp=tmp->sibling;
				continue;
			}
			cout<<tmp->use<<endl;
			tmp=tmp->sibling;
		}
	}
	cout<<endl<<endl;*/
/*
	
	t=root;
	while(t!=NULL)
	{
		if(t->nodekind!=FuncK)
		{
			t=t->sibling;
			continue;
		}
		TreeNode*tmp=t->Child[0];
		printf("%s\n",t->name);
		t=t->sibling;
		while(tmp!=NULL)
		{
			if(tmp->nodekind==VarDefnK)
			{
				tmp=tmp->sibling;
				continue;
			}
			cout<<tmp->define<<endl;
			tmp=tmp->sibling;
		}
	}

	cout<<endl<<endl;*/
/*
	t=root;
	while(t!=NULL)
	{
		if(t->nodekind!=FuncK)
		{
			t=t->sibling;
			continue;
		}
		TreeNode*tmp=t->Child[0];
		printf("%s\n",t->name);
		t=t->sibling;
		while(tmp!=NULL)
		{
			if(tmp->nodekind==VarDefnK)
			{
				tmp=tmp->sibling;
				continue;
			}
			cout<<tmp->live<<endl;
			tmp=tmp->sibling;
		}
	}*/
}



//针对不同的语句,进行翻译
void Translate()
{
	TreeNode*t=root;
	while(t!=NULL)
	{
		if(t->nodekind!=FuncK)
		{	
			GenGlobalVarDefn(t);
			t=t->sibling;
			continue;
		}
		TreeNode*tmp=t->Child[0];

		printf("%s [%d] [%d]\n",t->name,t->paramnum,t->stacksize);
		
		memset(Regused,0,sizeof(Regused));
		
		for(int i=1;i<=t->size;++i)
		{
			if(t->Table[i].isglobal==1)			
			{
				t->Table[i].reg=allocate(tmp,i);
				if(t->Table[i].size>0)
				printf("loadaddr v%d %s\n",i-1,Reg[t->Table[i].reg]);
				continue;
			}
			else if(t->Table[i].size>0)
			{
				t->Table[i].reg=allocate(tmp,i);
				printf("loadaddr %d %s\n",t->Table[i].location,Reg[t->Table[i].reg]);
				continue;
			}
			if(t->Table[i].paramnum>0)
				Regused[19+t->Table[i].paramnum]=i;
		}
		
		

		while(tmp!=NULL)
		{
			for(int i=1;i<bitsetsize;++i)
			{
				if(i>=tmp->Belong->size)break;
				if(tmp->live[i]==1&&tmp->Belong->Table[i].reg==0)
				{
					tmp->Belong->Table[i].reg=allocate(tmp,i);
				}
			}
			
			if(tmp->nodekind==VarDefnK)
			{	
				tmp=tmp->sibling;
				continue;
			}

			if(tmp->expkind==1)
			{
				GenVarEqRvOpRv(tmp);
							
			}
			else if(tmp->expkind==2)
			{
				GenVarEqOpRv(tmp);
			}
			else if(tmp->expkind==3)
			{
				GenVarEqRv(tmp);
			}
			else if(tmp->expkind==4)
			{
				GenVarRvEqRv(tmp);
			}
			else if(tmp->expkind==5)
			{
				GenVarEqVarRv(tmp);
			}
			else if(tmp->expkind==6)
			{
				GenIfRvOpRvGotol(tmp);
			}
			else if(tmp->expkind==7)
			{
				GenGotol(tmp);
			}
			else if(tmp->expkind==8)
			{
				Genl(tmp);
			}
			else if(tmp->expkind==9)
			{
				GenParamRv(tmp);
			}
			else if(tmp->expkind==10)
			{
				GenVarEqCall(tmp);
			}
			else if(tmp->expkind==11)
			{
				for(int i=1;i<=t->size;++i)
				{
					if(t->Table[i].isglobal==0)break;
					if(t->Table[i].reg==0||t->Table[i].size>0)continue;
					printf("loadaddr v%d s11\n",i-1);
					printf("s11[0] = %s\n",Reg[t->Table[i].reg]);
				}
				GenReturnVar(tmp);
			}
			tmp=tmp->sibling;
		}
		
		
		printf("end %s\n",t->name);
		t=t->sibling;
	}
}

int Calculate(int x,int y,int op)
{
	int ans;
	if(op==1)
		ans=int(x==y);
	else if(op==2)
		ans=int(x!=y);
	else if(op==3)
		ans=int(x=y);
	else if(op==4)
		ans=x+y;
	else if(op==5)
		ans=x-y;
	else if(op==6)
		ans=x*y;
	else if(op==7)
		ans=x/y;
	else if(op==8)
		ans=x%y;
	else if(op==9)
		ans=int(x&&y);
	else if(op==10)
		ans=int(x||y);
	else if(op==11)
		ans=int(x>y);
	else if(op==12)
		ans=int(x<y);
	return ans;
}


void GenGlobalVarDefn(TreeNode*t)
{
	int id=0;
	for(id=0;id<globalnum;++id)
	{
		if(strcmp(t->name,Global[id].id)==0)
			break;
	}
	if(t->size==0)
	{
				
		printf("v%d = 0\n",id);
	}
	else
	{
		printf("v%d = malloc %d\n",id,4*t->size);
	}
}



void GenVarEqRvOpRv(TreeNode*t)
{
	int id0=Getnum(t,t->Child[0]->name);
	if(t->Belong->Table[id0].reg==0)
	{
		allocate(t,id0);	
	}
	int reg0=t->Belong->Table[id0].reg;

	if(t->Child[1]->op==0 && t->Child[2]->op==0)
	{
		int id1=Getnum(t,t->Child[1]->name);
		int id2=Getnum(t,t->Child[2]->name);
		if(t->Belong->Table[id1].reg==0)
		{
			allocate(t,id1);
		/*	if(t->Belong->Table[id1].isglobal==0)
			{
				printf("load %d %s\n",t->Belong->Table[id1].location,Reg[t->Belong->Table[id1].reg]);
			}*/
			if(t->Belong->Table[id1].isglobal==1)
			{
				printf("load v%d %s\n",id1-1,Reg[t->Belong->Table[id1].reg]);
			}
		}
		int reg1=t->Belong->Table[id1].reg;
		if(t->Belong->Table[id2].reg==0)
		{
			allocate(t,id2);
		/*	if(t->Belong->Table[id2].isglobal==0)
			{
				printf("load %d %s\n",t->Belong->Table[id2].location,Reg[t->Belong->Table[id2].reg]);
			}*/
			if(t->Belong->Table[id2].isglobal==1)
			{
				printf("load v%d %s\n",id2-1,Reg[t->Belong->Table[id2].reg]);
			}
		}
		int reg2=t->Belong->Table[id2].reg;

		printf("%s = %s %s %s\n",Reg[reg0],Reg[reg1],OP[t->op],Reg[reg2]);
		

		DeleteUseless(t,id0);
		DeleteUseless(t,id1);
		DeleteUseless(t,id2);
	}
	else if(t->Child[1]->op==0 && t->Child[2]->op==1)	
	{
					
		int id1=Getnum(t,t->Child[1]->name);
		if(t->Belong->Table[id1].reg==0)
		{
			allocate(t,id1);
		/*	if(t->Belong->Table[id1].isglobal==0)
			{
				printf("load %d %s\n",t->Belong->Table[id1].location,Reg[t->Belong->Table[id1].reg]);
			}*/
			if(t->Belong->Table[id1].isglobal==1)
			{
				printf("load v%d %s\n",id1-1,Reg[t->Belong->Table[id1].reg]);
			}
		}

		int reg1=t->Belong->Table[id1].reg;
		printf("s11 = %d\n",t->Child[2]->val);
		printf("%s = %s %s s11\n",Reg[reg0],Reg[reg1],OP[t->op]);
		

		DeleteUseless(t,id0);
		DeleteUseless(t,id1);
	}	
	else if(t->Child[1]->op==1 && t->Child[2]->op==0)	
	{
					
		int id1=Getnum(t,t->Child[2]->name);
		if(t->Belong->Table[id1].reg==0)
		{
			allocate(t,id1);
		      /*if(t->Belong->Table[id1].isglobal==0)
			{
				printf("load %d %s\n",t->Belong->Table[id1].location,Reg[t->Belong->Table[id1].reg]);
			}*/
			if(t->Belong->Table[id1].isglobal==1)
			{
				printf("load v%d %s\n",id1-1,Reg[t->Belong->Table[id1].reg]);
			}
		}
		int reg1=t->Belong->Table[id1].reg;
	
		printf("s11 = %d\n",t->Child[1]->val);
		printf("%s = s11 %s %s\n",Reg[reg0],OP[t->op],Reg[reg1]);
		
		DeleteUseless(t,id0);
		DeleteUseless(t,id1);
	}/*
	else if(t->Child[1]->op==1 && t->Child[2]->op==1)	
	{
		int tmp=Calculate(t->Child[1]->val,t->Child[2]->val,t->op);
		printf("%s = %d\n",Reg[reg0],tmp);
		DeleteUseless(t,id0);
	}*/

	if(t->Belong->Table[id0].isglobal==1)
	{
		printf("loadaddr v%d s11\n",id0-1);
		printf("s11[0] = %s\n", Reg[reg0]);
	}
}

void GenVarEqOpRv(TreeNode*t)
{
	int id0=Getnum(t,t->Child[0]->name);
	if(t->Belong->Table[id0].reg==0)
	{
		allocate(t,id0);	
	}
	int reg0=t->Belong->Table[id0].reg;

	if(t->Child[1]->op==0)
	{
		int id1=Getnum(t,t->Child[1]->name);
					
		if(t->Belong->Table[id1].reg==0)
		{
			allocate(t,id1);	
			/*if(t->Belong->Table[id1].isglobal==0)
			{
				printf("load %d %s\n",t->Belong->Table[id1].location,Reg[t->Belong->Table[id1].reg]);
			}*/
			if(t->Belong->Table[id1].isglobal==1)
			{
				printf("load v%d %s\n",id1-1,Reg[t->Belong->Table[id1].reg]);
			}	
		}
		
		int reg1=t->Belong->Table[id1].reg;
			
		printf("%s = %s %s\n",Reg[reg0],OP[t->op],Reg[reg1]);

		DeleteUseless(t,id0);
		DeleteUseless(t,id1);
	}
/*	else
	{
		int tmp=0;
		if(t->op==5)
			tmp=-t->Child[1]->val;
		else if(t->op==13)
			tmp=int(!t->Child[1]->val);

		printf("%s = %d\n",Reg[reg0],tmp);

		DeleteUseless(t,id0);
		
	}*/

	if(t->Belong->Table[id0].isglobal==1)
	{
		printf("loadaddr v%d s11\n",id0-1);
		printf("s11[0] = %s\n", Reg[reg0]);
	}
}

void GenVarEqRv(TreeNode*t)
{
	int id0=Getnum(t,t->Child[0]->name);
	if(t->Belong->Table[id0].reg==0)
	{
		allocate(t,id0);	
	}
	int reg0=t->Belong->Table[id0].reg;

	if(t->Child[1]->op==0)
	{
		int id1=Getnum(t,t->Child[1]->name);
					
		if(t->Belong->Table[id1].reg==0)
		{
			allocate(t,id1);	
		/*	if(t->Belong->Table[id1].isglobal==0)
			{
				printf("load %d %s\n",t->Belong->Table[id1].location,Reg[t->Belong->Table[id1].reg]);
			}*/
			if(t->Belong->Table[id1].isglobal==1)
			{
				printf("load v%d %s\n",id1-1,Reg[t->Belong->Table[id1].reg]);
			}	
		}
		
		int reg1=t->Belong->Table[id1].reg;
			
		printf("%s = %s\n",Reg[reg0],Reg[reg1]);
	
		DeleteUseless(t,id0);
		DeleteUseless(t,id1);
	}
	else
	{
		printf("%s = %d\n",Reg[reg0],t->Child[1]->val);

		DeleteUseless(t,id0);
	}
/*
	if(t->Belong->Table[id0].isglobal==1)
	{
		printf("loadaddr v%d s11\n",id0-1);
		printf("s11[0] = %s\n", Reg[reg0]);
	}*/
}


void GenVarRvEqRv(TreeNode*t)
{
	int id0=Getnum(t,t->Child[0]->name);
	if(t->Belong->Table[id0].reg==0)
	{
		allocate(t,id0);
		
		if(t->Belong->Table[id0].isglobal==1)
		{
			printf("loadaddr v%d %s\n",id0-1,Reg[t->Belong->Table[id0].reg]);
		}
		if(t->Belong->Table[id0].isglobal==0)
		{	
			printf("loadaddr %d %s\n",t->Belong->Table[id0].location,Reg[t->Belong->Table[id0].reg]);
		}
	}
	int reg0=t->Belong->Table[id0].reg;


	
	if(t->Child[1]->op==0 && t->Child[2]->op==0)
	{
		int id1=Getnum(t,t->Child[1]->name);
		int id2=Getnum(t,t->Child[2]->name);

		if(t->Belong->Table[id1].reg==0)
		{
			allocate(t,id1);
		/*	if(t->Belong->Table[id1].isglobal==0)
			{
				printf("load %d %s\n",t->Belong->Table[id1].location,Reg[t->Belong->Table[id1].reg]);
			}*/
			if(t->Belong->Table[id1].isglobal==1)
			{
				printf("load v%d %s\n",id1-1,Reg[t->Belong->Table[id1].reg]);
			}
		}


		int reg1=t->Belong->Table[id1].reg;
		if(t->Belong->Table[id2].reg==0)
		{
			allocate(t,id2);
		/*	if(t->Belong->Table[id2].isglobal==0)
			{
				printf("load %d %s\n",t->Belong->Table[id2].location,Reg[t->Belong->Table[id2].reg]);
			}*/
			if(t->Belong->Table[id2].isglobal==1)
			{
				printf("load v%d %s\n",id2-1,Reg[t->Belong->Table[id2].reg]);
			}
		}

		int reg2=t->Belong->Table[id2].reg;
		printf("s11 = %s + %s\n",Reg[reg0],Reg[reg1]);
		printf("s11[0] = %s\n",Reg[reg2]);

		DeleteUseless(t,id0);
		DeleteUseless(t,id1);
		DeleteUseless(t,id2);
	}
/*	else if(t->Child[1]->op==0 && t->Child[2]->op==1)	
	{
					
		int id1=Getnum(t,t->Child[1]->name);
		if(t->Belong->Table[id1].reg==0)
		{
			allocate(t,id1);
			if(t->Belong->Table[id1].isglobal==0)
			{
				printf("load %d %s\n",t->Belong->Table[id1].location,Reg[t->Belong->Table[id1].reg]);
			}
			else if(t->Belong->Table[id1].isglobal==1)
			{
				printf("load v%d %s\n",id1-1,Reg[t->Belong->Table[id1].reg]);
			}
		}
		int reg1=t->Belong->Table[id1].reg;
		


		printf("s11 = %s + %s\n",Reg[reg0],Reg[reg1]);
		printf("s11[0] = %d\n",t->Child[2]->val);
	
		DeleteUseless(t,id0);
		DeleteUseless(t,id1);
	
	}	
	else if(t->Child[1]->op==1 && t->Child[2]->op==0)	
	{
					
		int id1=Getnum(t,t->Child[2]->name);
		if(t->Belong->Table[id1].reg==0)
		{
			allocate(t,id1);
			if(t->Belong->Table[id1].isglobal==0)
			{
				printf("load %d %s\n",t->Belong->Table[id1].location,Reg[t->Belong->Table[id1].reg]);
			}
			else if(t->Belong->Table[id1].isglobal==1)
			{
				printf("load v%d %s\n",id1-1,Reg[t->Belong->Table[id1].reg]);
			}
		}
		int reg1=t->Belong->Table[id1].reg;
		printf("%s[%d] = %s\n",Reg[reg0],t->Child[1]->val,Reg[reg1]);

		DeleteUseless(t,id0);
	}
	else if(t->Child[1]->op==1 && t->Child[2]->op==1)	
	{
		printf("%s[%d] = %d\n",Reg[reg0],t->Child[1]->val,t->Child[2]->val);

		DeleteUseless(t,id0);
	}*/
}

void GenVarEqVarRv(TreeNode*t)
{
	int id0=Getnum(t,t->Child[0]->name);
	if(t->Belong->Table[id0].reg==0)
	{
		allocate(t,id0);	
	}
	int reg0=t->Belong->Table[id0].reg;

	int id1=Getnum(t,t->Child[1]->name);
	if(t->Belong->Table[id1].reg==0)
	{
		allocate(t,id1);
		if(t->Belong->Table[id1].isglobal==1)
		{
			printf("loadaddr v%d %s\n",id1-1,Reg[t->Belong->Table[id1].reg]);
		}
		if(t->Belong->Table[id1].isglobal==0)
		{	
			printf("loadaddr %d %s\n",t->Belong->Table[id1].location,Reg[t->Belong->Table[id1].reg]);
		}
	}
	int reg1=t->Belong->Table[id1].reg;

	if(t->Child[2]->op==0)
	{
		int id2=Getnum(t,t->Child[2]->name);
		if(t->Belong->Table[id2].reg==0)
		{
			allocate(t,id2);
			if(t->Belong->Table[id2].isglobal==1)
			{
				printf("load v%d %s\n",id2-1,Reg[t->Belong->Table[id2].reg]);
			}
		}
		int reg2=t->Belong->Table[id2].reg;
		printf("s11= %s + %s\n",Reg[reg1],Reg[reg2]);
		printf("%s = s11[0]\n",Reg[reg0]);

		DeleteUseless(t,id0);
		DeleteUseless(t,id1);
		DeleteUseless(t,id2);
	}
/*	else if(t->Child[2]->op==1)
	{
		printf("%s = %s[%d]\n",Reg[reg0],Reg[reg1],t->Child[2]->val);

		DeleteUseless(t,id0);
		DeleteUseless(t,id1);
	}*/
	if(t->Belong->Table[id0].isglobal==1)
	{
		printf("loadaddr v%d s11\n",id0-1);
		printf("s11[0] = %s\n", Reg[reg0]);
	}
}

void GenIfRvOpRvGotol(TreeNode*t)
{
//	if(t->Child[0]->op==0 && t->Child[1]->op==0)
//	{
		int id0=Getnum(t,t->Child[0]->name);
	//	int id1=Getnum(t,t->Child[1]->name);

		if(t->Belong->Table[id0].reg==0)
		{
			allocate(t,id0);
			if(t->Belong->Table[id0].isglobal==1)
			{
				printf("load v%d %s\n",id0-1,Reg[t->Belong->Table[id0].reg]);
			}
		}
		int reg0=t->Belong->Table[id0].reg;

	/*	if(t->Belong->Table[id1].reg==0)
		{
			allocate(t,id1);
			if(t->Belong->Table[id1].isglobal==1)
			{
				printf("load v%d %s\n",id1-1,Reg[t->Belong->Table[id1].reg]);
			}
		}
		int reg1=t->Belong->Table[id1].reg;*/
		printf("if %s %s x0 goto %s\n",Reg[reg0],OP[t->op],t->name);

		DeleteUseless(t,id0);
	//	DeleteUseless(t,id1);
//	}

/*
	else if(t->Child[0]->op==0 && t->Child[1]->op==1)	
	{
					
		int id0=Getnum(t,t->Child[0]->name);
		if(t->Belong->Table[id0].reg==0)
		{
			allocate(t,id0);
		}
		int reg0=t->Belong->Table[id0].reg;
		printf("s11 = %d\n",t->Child[1]->val);
		printf("if %s %s s11 goto %s\n",Reg[reg0],OP[t->op],t->name);

		DeleteUseless(t,id0);
	}	

	else if(t->Child[0]->op==1 && t->Child[1]->op==0)	
	{		
		int id1=Getnum(t,t->Child[1]->name);
		if(t->Belong->Table[id1].reg==0)
		{
			allocate(t,id1);
		}
		int reg1=t->Belong->Table[id1].reg;
		printf("s11 = %d\n",t->Child[0]->val);
		printf("if s11 %s %s goto %s\n",OP[t->op],Reg[reg1],t->name);
	
		DeleteUseless(t,id1);
	}
	else if(t->Child[0]->op==1 && t->Child[1]->op==1)	
	{
		int tmp=Calculate(t->Child[0]->val,t->Child[1]->val,t->op);
		if(tmp!=0)
			printf("goto %s\n",t->name);
	}*/
}

void GenGotol(TreeNode*t)
{
	printf("goto %s\n",t->name);
}

void Genl(TreeNode*t)
{
	printf("%s:\n",t->name);
}

void GenParamRv(TreeNode*t)
{
/*	if(t->Child[0]->op==1)
	{
		int i;
		for(i=20;i<=27;++i)
		{
			if(!Regused[i])
			{
				Regused[i]=-1;
				break;
			}
		}
		printf("%s = %d\n",Reg[i],t->Child[0]->val);
		return;
	}*/
	if(paramcount==0)
	{
		for(int i=20;i<=27;++i)
		{
			if(Regused[i])
			{
				printf("store %s %d\n",Reg[i],t->Belong->Table[Regused[i]].location);
			}
			else break;
		}
	}
	
	int id0=Getnum(t,t->Child[0]->name);

	

	if(t->Belong->Table[id0].reg==0)
	{

		allocate(t,id0);

/*		printf("\n\n\n\n");
		printf("%s\n",t->Child[0]->name);
		printf("%d\n",t->Belong->Table[id0].isglobal);
		printf("\n\n\n\n");*/
		
		

		if(t->Belong->Table[id0].isglobal==1)
		{
			printf("load v%d %s\n",id0-1,Reg[t->Belong->Table[id0].reg]);
		}
	}
	int reg0=t->Belong->Table[id0].reg;
	
	

	printf("%s = %s\n",Reg[20+paramcount],Reg[reg0]);

	paramcount++;

	DeleteUseless(t,id0);
}

void GenVarEqCall(TreeNode*t)
{
	paramcount=0;
	for(int i=1;i<=t->Belong->size;++i)
	{
	/*	if(t->Belong->Table[i].isglobal==1&&t->Belong->Table[i].reg!=0)
		{
			printf("loadaddr v%d s11\n",i-1);
			printf("s11[0] = %s\n",Reg[t->Belong->Table[i].reg]);
			continue;
		}*/
		if(t->Belong->Table[i].reg==0)continue;
		if(t->Belong->Table[i].paramnum>0)continue;
		printf("store %s %d\n",Reg[t->Belong->Table[i].reg],t->Belong->Table[i].location);
	}
	printf("call %s\n",t->name);

	int id0=Getnum(t,t->Child[0]->name);

	int bj=0;
	if(t->Belong->Table[id0].reg==0)
	{
		bj=1;
		allocate(t,id0);
	}

	int reg0=t->Belong->Table[id0].reg;

	printf("%s = a0\n",Reg[reg0]);
	
	DeleteUseless(t,id0);

	if(t->Belong->Table[id0].isglobal==1)
	{
		printf("loadaddr v%d s11\n",id0-1);
		printf("s11[0] = %s\n", Reg[reg0]);
	}
	
	for(int i=1;i<=t->Belong->size;++i)
	{
		if(i==id0)
		{
			if(bj==1)continue;
		}
	/*	if(t->Belong->Table[i].isglobal==1&&t->Belong->Table[i].reg!=0)
		{
			printf("load v%d %s\n",i-1,Reg[t->Belong->Table[i].reg]);
			continue;
		}*/
		if(t->Belong->Table[i].reg==0)continue;
		
		printf("load %d %s\n",t->Belong->Table[i].location,Reg[t->Belong->Table[i].reg]);
	}

}

void GenReturnVar(TreeNode*t)
{
/*	if(t->Child[0]->op==1)
	{
		printf("a0 = %d\n",t->Child[0]->val);
	}
	else
	{*/
		int id0=Getnum(t,t->Child[0]->name);

		if(t->Belong->Table[id0].reg==0)
		{
			allocate(t,id0);


		}
		int reg0=t->Belong->Table[id0].reg;
		if(Regused[20]!=0)
		{
		//	printf("store a0 %d\n",t->Belong->Table[Regused[20]].location);
		}
		printf("a0 = %s\n",Reg[reg0]);	

		DeleteUseless(t,id0);
//	}
	
	printf("return\n");

	if(Regused[20]!=0)
	{
	//	printf("store a0 %d\n",t->Belong->Table[Regused[20]].location);
	}

}


//如果某个变量之后都不活跃,那么释放它所占用的寄存器
void DeleteUseless(TreeNode*t,int index)
{
	if(t->sibling==NULL)return;
	if(t->Belong->Table[index].isglobal==1)return;
	int flag=0;
	while(t->sibling!=NULL)
	{
		if(t->sibling->live[index]!=0)
		{
			flag=1;
			break;
		}
		t=t->sibling;
	}
	if(flag==0)
	{
		Regused[t->Belong->Table[index].reg]=0;
		t->Belong->Table[index].reg=0;
	}
}

//分配寄存器
int allocate(TreeNode*t,int index)
{
	if(t->Belong->Table[index].paramnum>0)
	{
		int tmp=19+t->Belong->Table[index].paramnum;
		t->Belong->Table[index].reg=tmp;
		Regused[tmp]=index;
		return tmp;
	}

	for(int i=13;i<=19;++i)
	{
		if(!Regused[i])
		{
			Regused[i]=index;
			t->Belong->Table[index].reg=i;
			return i;
		}
	}
	for(int i=1;i<=11;++i)
	{
		if(!Regused[i])
		{
			Regused[i]=index;
			t->Belong->Table[index].reg=i;
			return i;
		}
	}
	
	


//	printf("Register Not Enough!!!\n");
//	exit(0);
}
