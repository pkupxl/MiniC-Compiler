#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <bitset>
#include <iostream>
using namespace std;
using std::bitset;
#define MAXGLOBALNUM 150      //全局变量的最多个数
#define bitsetsize 150        //记录活跃性的变量的最多个数
typedef enum  {VarDefnK,ExpK,FuncK} NodeKind;//节点类型
struct Systable
{ 
    char *id;//变量的名字
    int location=0; //记录临时变量在栈中的位置
    int size=0;	//如果是数组,记录数组的大小
    int isglobal=0; //是否是全局的变量
    int paramnum=0;  //记录当前变量是该函数的第几个参数,如果不是参数,设为0.
    int reg=0;  //记录哪个寄存器包含了该变量
};

struct Systable Global[MAXGLOBALNUM];//全局符号表

typedef struct treeNode 
{ 
     struct treeNode * Child[3]; //子节点
     struct treeNode * sibling;  //兄弟节点
     struct Systable * Table;    //指向该节点对应的符号表的指针
     struct treeNode * Belong;   //Belong记录该节点是在哪个FuncDefn节点之下的,以便快速定位到该节点所属于的函数
     struct treeNode * Pre;      //由于活性分析的时候是从后往前扫的,Pre记录当前语句的前一条语句
     struct treeNode * End;      //End记录一个函数节点里最后一条语句,以便快速从最后一条语句往前做活性分析
     struct treeNode * Next[2];  //活性分析时需要知道每条语句的下一条可能执行语句.对于控制语句可能不是物理上的下一条语句,需要进行记录
     NodeKind nodekind;    //节点类型
     int expkind=0;   //表达式类型
     int op=0;        //操作符的类型
     char *name;      //记录变量名
     int size=0;      //如果是数组,记录数组的大小
     int val=0;      //如果是变量,记录变量的值
     int paramnum=0;     //对于函数定义节点,需要记录其有多少个参数
     int stacksize=0;    //对于函数定义节点,需要记录该函数的栈空间的大小
     //对于每条语句对应的节点,需要记录该语句中哪些变量是define的,哪些是use,哪些是活跃的
     bitset<bitsetsize> use;      
     bitset<bitsetsize> define;
     bitset<bitsetsize> live;
}TreeNode;



