#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
typedef enum  {StmtK,ExpK,VarDeclK,FuncDefnK,FuncDeclK} NodeKind;//节点的种类
typedef enum  {SpecialK,IfK,IfelseK,WhileK,IDAssignK,ArrayAssignK,ReturnK,VarDefnK} StmtKind;//语句的种类
typedef enum  {TwoopK,OneopK,ConstK,IdK,CallK,ArrayK} ExpKind;//表达式的种类
typedef enum  {Integer,Boolean} ExpType;//表达式的值的类型



#define MAXCHILDREN 3
typedef struct treeNode
{ 
     struct treeNode * Child[MAXCHILDREN];//子节点
     struct treeNode * sibling; //兄弟节点
     NodeKind nodekind; //节点种类
     union { StmtKind stmt; ExpKind exp;} kind;//记录具体语句的种类或者表达式的种类
     ExpType type;  //如果节点种类为ExpK,其表达式值的类型记录在type中 
     char *name;    //记录该语句中含有的Id的名字
     int start;     //如果是函数定义节点,记录该函数所使用的变量在符号表中的起始位置
     int lableindex; //如果该语句含有label,记录是第几个label
     int varindex;  //记录该语句中的变量分配到Eeyore中变量的下标
     union { 
	     int paramnum;//如果是函数定义节点,记录该函数有几个参数
	     int size;    //如果是变量定义节点而且是数组,记录该数组的大小,一般变量设为0
	     int op;	  //如果是含有操作符的表达式节点,记录该操作符是哪一类操作符
	     int val;	  //如果是常数节点,直接记录它的值
	   }attr; 
}TreeNode;
