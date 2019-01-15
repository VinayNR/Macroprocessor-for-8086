%{
#include "y.tab.h"
#include<stdio.h>
#include<string.h>
int macro_body = 0, after_macro_def = 0, after_instr = 0, after_macro_call = 0;
int i, j;
char str[50];
%}

%Start condition
%%
".MODEL SMALL"|".CODE" {
    BEGIN 0;
    strcpy(str, yytext);
    yylval.sval = str;
    return DOT;
}

".DATA" {
    BEGIN condition;
    return DATA;
}

<condition>[a-zA-Z]+(" DB"|" DW"|" EQU") {
    for(i=0;yytext[i]!=' ';i++)
        str[i] = yytext[i];
    str[i] = '\0';
    yylval.sval = str;
    return DEC;
}

<condition>[0-9]+ {
    yylval.ival = atoi(yytext);
    return VALUE;
}

([a-zA-Z0-9]+)(" MACRO") {
    after_macro_def = 1;
    for(i=0;yytext[i]!=' ';i++)
        str[i] = yytext[i];
    str[i] = '\0';
    yylval.sval = str;
    return MACRO;
}

"IF" {
    after_instr=1;
    return IF;
}

"ELSE" return ELSE;

"ENDIF" return ENDIF;

"END" return END;

"ENDM" {
    macro_body = after_macro_def = after_macro_call = after_instr = 0;
    return ENDM;
}

"AAA"|"AAD"|"AAM"|"AAS"|"ADC"|"ADD"|"AND"|"CALL"|"CBW"|"CLC"|"CLD"|"CLI"|"CMC"|"CMP" {
        after_instr=1;
        strcpy(str,yytext);
        return CMD;
}

"MOV"|"MUL"|"NEG"|"NOP"|"NOT"|"OR"|"OUT"|"POP"|"PUSH"|"RCL"|"INT"|"LEA" {
        after_instr=1;
        strcpy(str,yytext);
        return CMD;
}

("JMP"|"JE"|"JNE"|"JLE"|"JGE")[ ][_a-zA-Z0-9]+ {
        strcpy(str,yytext);
        strcat(str,"&");
        yylval.sval = str;
        return J_CMD;
}

[a-zA-Z0-9]+[:] {
        strcpy(str,yytext);
        yylval.sval = str;
        return LABEL;
}

[a-zA-Z0-9]+ {
    if(after_macro_def == 1 || after_macro_call == 1)
    {
        strcpy(str,yytext);
        yylval.sval = str;
        printf("\nFound MACRO_PARAM:%s",yytext);
        return MACRO_PARAM;
    }
    else if(after_instr == 1)
    {
        strcpy(str,yytext);
        return VAR;
    }
    else if(macro_body == 0)
    {
        strcpy(str,yytext);
        yylval.sval = str;
        printf("\n\nFound Macro Invocation:%s",yytext);
        after_macro_call = 1;
        return MACRO_INVOC;
    }
}

[ ]*[;](.)* {  }

,  return COMMA;

\n {
        after_instr = 0;
        if(after_macro_def == 1)
        {
            macro_body = 1;
            after_macro_def = 0;
        }
        else if(after_macro_call == 1)
            after_macro_call = 0;
        return NEWLINE;
    }

%%
