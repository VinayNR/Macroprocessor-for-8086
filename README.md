# Macroprocessor-for-8086
A Macroprocessor for 8086 written in lex and yacc, which are token lexical analysers and syntactical parsers.

Lex and Yacc are the tools that are needed to write system softwares such as assemblers, loaders, linkers, compilers and macroprocessors.
This project preprocesses an input assembly program written in 8086 assembly language and identifies all the macros and replaces them with their contents during their invocations.
Not elaborating on the specifics needed to understand the source directories, this essentially produces a C source code that is finally run as a normal executable on a Shell.

Requirements : 
Flex (can be found at https://github.com/westes/flex/releases)
Bison (can be found at https://www.gnu.org/software/bison/)

Run:
lex lexer.l
yacc -d parser.y
This generates the C Source code which can then be run using any C compiler (GCC)
