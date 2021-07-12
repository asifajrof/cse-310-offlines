%option noyywrap yylineno

%{
#include<iostream>
#include<cstdio>
#include<string>
#include<cstring>
#include<fstream>
#include "1705092_SymbolTable.h"
#define YYSTYPE SymbolInfo*	//define before y.tab.h
#include "y.tab.h"

using namespace std;

extern YYSTYPE yylval;
extern SymbolTable symbolTable;
void yyerror(char *);
extern int errorCount;
extern ofstream logFile;
extern ofstream errorFile;

void errorPrint(string errorName,  int lineNo = yylineno);
%}

digit [0-9]
letter [A-Za-z]
delim [ \t\f\r\v]
newline \n
id (_|{letter})(_|{letter}|{digit})*
integer {digit}+
number ({digit}+(\.{digit}+)?((E|e)[+-]?{digit}+)?)|(\.{digit}+((E|e)[+-]?{digit}+)?)

%%
{delim}+		{
					//whitespace 
				}

{newline}		{
					//newline
				}

"if"			{	return IF;}

"else"			{	return ELSE;}

"for"			{	return FOR;}

"while"			{	return WHILE;}

"int"			{	return INT;}

"float"			{	return FLOAT;}

"void"			{	return VOID;}

"char"			{	return CHAR;}

"return"		{	return RETURN;}

"println"|"printf"	{	return PRINTLN;}

"+"|"-"			{
					SymbolInfo* si = new  SymbolInfo(yytext, "ADDOP");
					yylval = (YYSTYPE)si;
					return ADDOP;
				}

"*"|"/"|"%"		{
					SymbolInfo* si = new  SymbolInfo(yytext, "MULOP");
					yylval = (YYSTYPE)si;
					return MULOP;
				}

"++"			{	return INCOP;}

"--"			{	return DECOP;}

"="				{	return ASSIGNOP;}

"<"|"<="|">"|">="|"=="|"!="	{
					SymbolInfo* si = new  SymbolInfo(yytext, "RELOP");
					yylval = (YYSTYPE)si;
					return RELOP;
				}

"&&"|"||"		{
					SymbolInfo* si = new  SymbolInfo(yytext, "LOGICOP");
					yylval = (YYSTYPE)si;
					return LOGICOP;
				}

"!"				{	return NOT;}

"("				{	return LPAREN;}

")"				{	return RPAREN;}

"{"				{	return LCURL;}

"}"				{	return RCURL;}

"["				{	return LTHIRD;}

"]"				{	return RTHIRD;}

","				{	return COMMA;}

";"				{	return SEMICOLON;}

{integer}		{
					SymbolInfo* si = new  SymbolInfo(yytext, "CONST_INT");
					yylval = (YYSTYPE)si;
					return CONST_INT;
				}

{number}		{
					SymbolInfo* si = new  SymbolInfo(yytext, "CONST_FLOAT");
					yylval = (YYSTYPE)si;
					return CONST_FLOAT;
				}

({digit}+\.)	|
({digit}+(\.{digit}*)?((E|e)[+-]?({digit}*\.{digit}*)*))	{
					errorPrint("Ill formed number");
					errorCount++;
					SymbolInfo* si = new  SymbolInfo(yytext, "CONST_FLOAT");
					yylval = (YYSTYPE)si;
					return CONST_FLOAT;
				}
				
({digit}*\.{digit}*)*((E|e)[+-]?{digit}+)?	{
					errorPrint("Too many decimal points");
					errorCount++;
					SymbolInfo* si = new  SymbolInfo(yytext, "CONST_FLOAT");
					yylval = (YYSTYPE)si;
					return CONST_FLOAT;
				}

{id}	 		{
					SymbolInfo* si = new  SymbolInfo(yytext, "ID");
					yylval = (YYSTYPE)si;
					return ID;
				}

[a-zA-Z0-9_]+	{
					errorPrint("Invalid prefix on ID or invalid suffix on Number");
					errorCount++;
					SymbolInfo* si = new  SymbolInfo(yytext, "ID");
					yylval = (YYSTYPE)si;
					return ID;
				}
				
\'(([^\'\\\n])|(\\[nt\\\'\"afrbv0]))\'	{
					SymbolInfo *si = new  SymbolInfo(yytext, "CONST_CHAR");
					yylval = (YYSTYPE)si;
					return CONST_CHAR;
				}
				
\'([^\'\n]+)([^\'\n]+)\'	{
					errorPrint("Multi character constant error");
					errorCount++;
					SymbolInfo *si = new  SymbolInfo(yytext, "CONST_CHAR");
					yylval = (YYSTYPE)si;
					return CONST_CHAR;
				}

(\'){2}			{
					errorPrint("Empty character constant error");
					errorCount++;
					SymbolInfo *si = new  SymbolInfo(yytext, "CONST_CHAR");
					yylval = (YYSTYPE)si;
					return CONST_CHAR;
				}

\'(([^\'\\\n])|(\\[nt\\\'\"afrbv0]))*	{
					errorPrint("Unterminated character");
					errorCount++;
					SymbolInfo *si = new  SymbolInfo(yytext, "CONST_CHAR");
					yylval = (YYSTYPE)si;
					return CONST_CHAR;
				}

\/\/([^\n]?(\\(\r)?\n)?)*	{
					//commentPrint();
				}

\/\*([^\*\/]?((\*[^\/])|([^\*]\/))?)*\*\/	{
					//commentPrint();
				}

\/\*([^\*\/]?((\*[^\/])|([^\*]\/))?)*	{
					//errorPrint("Unterminated Comment");
					//errorCount++;
				}

.				{
					errorPrint("Unrecognized character " + (string)yytext);
					errorCount++;
				}
%%