%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include "1.h"
extern FILE * yyin;
extern FILE * yyout;
int num = 1, inside_macro = 0, inside_macro_invoc = 0, num_of_arg, val;
char store[300], name[30];

NAMTAB * nam_head = NULL;
DEFTAB * def_head = NULL;
ARGTAB * arg_head = NULL;
DEFTAB * def_node = NULL;
VARTAB * var_head = NULL;
DEFTAB * temp = NULL;

void create_def_tab()
{
    def_node = (DEFTAB*)malloc(sizeof(DEFTAB));
    def_node->pos = num++;
    def_node->num_of_arg = def_node->occurence = 0;
    def_node->arg = NULL;
    def_node->next = NULL;
}

void arg_def_tab(char * s)
{
    ARGLIST * temp = (ARGLIST*)malloc(sizeof(ARGLIST));
    strcpy(temp->name, s);
    temp->posn = ++def_node->num_of_arg;
    temp->next = NULL;
    if(def_node->arg == NULL)
        def_node->arg = temp;
    else
    {
        ARGLIST * p = def_node->arg;
        while(p->next)
            p = p->next;
        p->next = temp;
    }
}

void accumulate(char * s)
{
    char buf[10];
    ARGLIST * temp = def_node->arg;
    while(temp)
    {
        if(strcmp(temp->name, s)==0)
        {
            sprintf(buf, "%d", temp->posn);
            strcat(store, buf);
            strcat(store, " ");
            return;
        }
        temp = temp->next;
    }
    strcat(store, s);
    strcat(store, " ");
}

void add_def_tab()
{
    strcpy(def_node->array, store);
    if(def_head == NULL)
        def_head = def_node;
    else
    {
        def_node->next = def_head;
        def_head = def_node;
    }
    strcpy(store, "");
    def_node = NULL;
}

DEFTAB * get_def_node(int val)
{
    DEFTAB * temp = def_head;
    while(temp)
    {
        if(temp->pos == val)
            return temp;
        temp = temp->next;
    }
    return NULL;
}

int get_arg_number(int val)
{
    DEFTAB * temp = get_def_node(val);
    return temp->num_of_arg;
}

void add_nam_tab(char * str)
{
    NAMTAB * temp = (NAMTAB*) malloc(sizeof(NAMTAB));
    strcpy(temp->name, str);
    temp->pos = num;
    temp->next = NULL;
    if(nam_head == NULL)
        nam_head = temp;
    else
    {
        temp->next = nam_head;
        nam_head = temp;
    }
}

void add_arg_tab(char * str)
{
    ARGTAB * temp = (ARGTAB*) malloc(sizeof(ARGTAB));
    strcpy(temp->args, str);
    temp->next = NULL;
    if(arg_head == NULL)
        arg_head = temp;
    else
    {
        ARGTAB * p = arg_head;
        while(p->next)
            p = p->next;
        p->next = temp;
    }
}

int check_nam_tab(char * str)
{
    NAMTAB * temp = nam_head;
    while(temp)
    {
        if(strcmp(temp->name, str) == 0)
            return temp->pos;
        temp = temp->next;
    }
    return 0;
}

void add_value(int val)
{
    VARTAB * temp = (VARTAB *) malloc(sizeof(VARTAB));
    temp->val = val;
    strcpy(temp->name, name);
    temp->next = NULL;
    if(var_head == NULL)
        var_head = temp;
    else
    {
        VARTAB * p = var_head;
        while(p->next)
            p = p->next;
        p->next = temp;
    }
}

int det_value(int c)
{
    ARGTAB * p = arg_head;
    VARTAB * temp = var_head;
    while(--c)
        p = p->next;
    while(temp)
    {
        if(strcmp(temp->name, p->args) == 0)
            return temp->val;
        temp = temp->next;
    }
    return 0;
}

void disp_nam_tab()
{
    printf("\nNAME TABLE-:");
    NAMTAB * temp = nam_head;
    while(temp)
    {
        printf("\n%s-%d", temp->name, temp->pos);
        temp=temp->next;
    }
}

void disp_def_tab()
{
    printf("\nDEFINITION TABLE-:");
    DEFTAB * temp = def_head;
    while(temp)
    {
        printf("\nPos = %d",temp->pos);
        printf("\nParameters:");
        ARGLIST * temp2 = temp->arg;
        while(temp2)
        {
            printf("%s ",temp2->name);
            temp2 = temp2->next;
        }
        printf("\nBody:%s\n", temp->array);
        temp=temp->next;
    }
}

%}

%union
{
    int ival;
	  float fval;
	  char *sval;
}

%token ENDM END COMMA NEWLINE DATA ELSE ENDIF IF
%token <sval> MACRO MACRO_BODY MACRO_PARAM MACRO_INVOC CMD VAR DOT LABEL J_CMD DEC
%token <ival> VALUE

%start SS

%%

SS : S END { fprintf(yyout, "%s", "END"); } NEWLINE;

S : DOT1 NEWLINE1 S
    | DATA { fprintf(yyout, ".DATA"); } NEWLINE1 DEC1 S
    | MACRO {
        inside_macro = 1; add_nam_tab($1); create_def_tab();
    } PARAM NEWLINE1 S
    | MACRO_INVOC {
        val = check_nam_tab($1);
        inside_macro_invoc = 1;
        if(!val) {
            printf("\nMacro Not Present!\n");
            exit(0);
        }
        else
            num_of_arg = get_arg_number(val);
    } PARAM {
        if(num_of_arg!=0) {
            printf("\nArguments Mismatch\n");
            exit(0);
        }
        else
        {
            temp = get_def_node(val);
            temp->occurence++;
            for(int i=0;i<strlen(temp->array)-2;i++)
            {
                if(temp->array[i] == ' ' && temp->array[i+1] <= temp->num_of_arg+48 && temp->array[i+1]>48 && (temp->array[i+2] == ' ' || temp->array[i+2] == '\n'))
                {
                    int x = temp->array[i+1]-48;
                    ARGTAB * p = arg_head;
                    while(--x)
                        p = p->next;
                    fprintf(yyout, " %s", p->args);
                    i++;
                }

                else if(temp->array[i] == '!')
                {
                    int flag = det_value(temp->array[i+2] - '0');
                    i = i+3;      // due to extra space between ! and the parameter
                    if(flag)
                    {
                        while(temp->array[i]!='+' && temp->array[i]!='-')
                        {
                            if(temp->array[i] == ' ' && temp->array[i+1] <= temp->num_of_arg+48 && temp->array[i+1]>48 && (temp->array[i+2] == ' ' || temp->array[i+2] == '\n'))
                            {
                                int x = temp->array[i+1]-48;
                                ARGTAB * p = arg_head;
                                while(--x)
                                    p = p->next;
                                fprintf(yyout, " %s", p->args);
                                i++;
                            }
                            else if(temp->array[i] == ':')
                                fprintf(yyout, "%d:", temp->occurence);
                            else if(temp->array[i] == '&')
                                fprintf(yyout, "%d", temp->occurence);
                            else
                                fprintf(yyout, "%c", temp->array[i]);
                            i++;
                        }
                        while(temp->array[i]!='-')
                            i++;
                        i++;
                    }
                    else
                    {
                        while(temp->array[i]!='+')
                            i++;
                        i++;
                        while(temp->array[i]!='-')
                        {
                            if(temp->array[i] == ' ' && temp->array[i+1] <= temp->num_of_arg+48 && temp->array[i+1]>48 && (temp->array[i+2] == ' ' || temp->array[i+2] == '\n'))
                            {
                                int x = temp->array[i+1]-48;
                                ARGTAB * p = arg_head;
                                while(--x)
                                    p = p->next;
                                fprintf(yyout, " %s", p->args);
                                i++;
                            }
                            else
                                fprintf(yyout, "%c", temp->array[i]);
                            i++;
                        }
                    }
                }
                else if(temp->array[i] == ':')
                    fprintf(yyout, "%d:", temp->occurence);
                else if(temp->array[i] == '&')
                    fprintf(yyout, "%d", temp->occurence);
                else
                    fprintf(yyout, "%c", temp->array[i]);
            }
            free(arg_head);
            arg_head = NULL;
        }
    } NEWLINE1 S
    | BODY S
    | ENDM { inside_macro = 0; add_def_tab(); } S
    | NEWLINE1 S
    | ;

DEC1 : DEC { strcpy(name, $1); fprintf(yyout, "%s DB ", $1); } VALUE1 NEWLINE1 DEC1 | ;

VALUE1 : VALUE { add_value($1); fprintf(yyout, "%d", $1); } ;

PARAM : MACRO_PARAM {
            if(inside_macro)
                arg_def_tab($1);
            else
            {
                add_arg_tab($1);
                num_of_arg--;
            }
        } COMMA1 PARAM
        | MACRO_PARAM {
            if(inside_macro)
                arg_def_tab($1);
            else
            {
                add_arg_tab($1);
                num_of_arg--;
            }
        }
        | ;

BODY : LBL CMD1 NEWLINE1 BODY
     | CMD1 NEWLINE1 BODY
     | LBL CMD1 VAR1 NEWLINE1 BODY
     | CMD1 VAR1 NEWLINE1 BODY
     | LBL CMD1 VAR1 COMMA1 VAR2 NEWLINE1 BODY
     | CMD1 VAR1 COMMA1 VAR2 NEWLINE1 BODY
     | J_CMD1 NEWLINE1 BODY
     | IF1 VAR1 NEWLINE1 BODY ELSE1 NEWLINE1 BODY ENDIF1 NEWLINE1 BODY
     | IF1 VAR1 NEWLINE1 BODY ENDIF1 NEWLINE1 BODY
     | ;

IF1 : IF { accumulate("!"); }

ELSE1 : ELSE { accumulate("+"); }

ENDIF1 : ENDIF { accumulate("-"); }

LBL : LABEL { if(inside_macro)accumulate($1); else fprintf(yyout, "%s", $1); };

DOT1 : DOT { fprintf(yyout, "%s", $1); } ;

CMD1 : CMD { if(inside_macro)accumulate($1); else fprintf(yyout, "%s", $1); } ;

J_CMD1 : J_CMD { if(inside_macro)accumulate($1); else fprintf(yyout, "%s", $1); } ;

VAR2 : VAR { if(inside_macro) { accumulate(","); accumulate($1); } else fprintf(yyout, "%s", $1); } ;

VAR1 : VAR { if(inside_macro)accumulate($1); else fprintf(yyout, "%s", $1); } ;

NEWLINE1 : NEWLINE { if(inside_macro)accumulate("\n"); else fprintf(yyout, "\n"); } ;

COMMA1 : COMMA { if(!inside_macro_invoc && !inside_macro)fprintf(yyout, ","); } ;

%%

int main()
{
    char file[40];
    printf("\nEnter the input file:");
    scanf("%s", file);
    yyin = fopen(file, "r");
    yyout = fopen("b.txt", "w");
    yyparse();
    printf("\nValid \n");
    disp_nam_tab();
    printf("\n");
    disp_def_tab();
    printf("\n");
}

yyerror()
{
    printf("\nInvalid \n");
    exit(0);
}
