%option noyywrap yylineno

%{
#include<iostream>
#include<cstdio>
#include<cstring>
#include<fstream>
#include "1705092_SymbolTable.h"
using namespace std;
ofstream logFile;
ofstream tokenFile;
int bucketSize = 7;
bool printFlag = 0;
int errorCount = 0;

SymbolTable symbolTable(bucketSize);

void keyWordPrint(string keyWordToken)
{
	tokenFile << keyWordToken << " ";
	logFile << "Line no " << yylineno << ": Token " << keyWordToken << " Lexeme " << yytext << " found" << endl << endl;
}

void opPuncPrint(string opPuncType)
{
	tokenFile << "<" << opPuncType << ", " << yytext << "> ";
	logFile << "Line no " << yylineno << ": Token <" << opPuncType << "> Lexeme " << yytext << " found" << endl << endl;
}

void numberPrint(string numberType)
{
	opPuncPrint(numberType);
}

void identifierPrint(string type)
{
	opPuncPrint(type);
}

void charPrint(string str)
{
	char ch;
	str.erase(str.begin());
	str.erase(str.end()-1);
	if(str.size() > 1)	//special
	{
		str.erase(str.begin());
		if(str[0] == 'n')
			ch = '\n';
		else if(str[0] == 't')
			ch = '\t';
		else if(str[0] == '\\')
			ch = '\\';
		else if(str[0] == '\'')
			ch = '\'';
		else if(str[0] == '\"')
			ch = '\"';
		else if(str[0] == 'a')
			ch = '\a';
		else if(str[0] == 'f')
			ch = '\f';
		else if(str[0] == 'r')
			ch = '\r';
		else if(str[0] == 'b')
			ch = '\b';
		else if(str[0] == 'v')
			ch = '\v';
		else if(str[0] == '0')
			ch = '\0';
	}
	else
		ch = str[0];
	tokenFile << "<CONST_CHAR, " << ch << "> ";
	logFile << "Line no " << yylineno << ": Token <CONST_CHAR> Lexeme " << yytext << " found --> <CONST_CHAR, " << ch << ">" << endl << endl;
}

void stringPrint()
{
	string modifiedString = "";
	int lineNo = yylineno;
	for(int i=0; i<strlen(yytext); i++)
	{
		if(yytext[i] == '\n')	lineNo--;
		else if(yytext[i] != '\\')
		{
			modifiedString.push_back(yytext[i]);
		}
		else
		{
			i++;
			if(yytext[i] == 'n')
				modifiedString.push_back('\n');
			else if(yytext[i] == 't')
				modifiedString.push_back('\t');
			else if(yytext[i] == '\\')
				modifiedString.push_back('\\');
			else if(yytext[i] == '\'')
				modifiedString.push_back('\'');
			else if(yytext[i] == '\"')
				modifiedString.push_back('\"');
			else if(yytext[i] == 'a')
				modifiedString.push_back('\a');
			else if(yytext[i] == 'f')
				modifiedString.push_back('\f');
			else if(yytext[i] == 'r')
				modifiedString.push_back('\r');
			else if(yytext[i] == 'b')
				modifiedString.push_back('\b');
			else if(yytext[i] == 'v')
				modifiedString.push_back('\v');
			else if(yytext[i] == '0')
				modifiedString.push_back('\0');
			else if(yytext[i] == '\r' && yytext[i+1] == '\n'){
				lineNo--;
				i++;
			}
			else if(yytext[i] == '\n')
				lineNo--;
			else
			{
				modifiedString.push_back('\\');
				modifiedString.push_back(yytext[i]);
			}
		}
	}
	tokenFile << "<STRING, " << modifiedString << "> ";
	logFile << "Line no " << lineNo << ": Token <STRING> Lexeme " << yytext << " found --> <STRING, " << modifiedString << ">" << endl << endl;
}

void errorPrint(string errorType)
{
	int lineNo = yylineno;
	for(int i=0; i<strlen(yytext); i++)
	{
		if(yytext[i] == '\n')	lineNo--;
	}
	logFile << "Error at line no " << lineNo << ": " << errorType << " " << yytext << endl << endl;
}

void commentPrint()
{
	int lineNo = yylineno;
	for(int i=0; i<strlen(yytext); i++)
	{
		if(yytext[i] == '\n')	lineNo--;
	}
	logFile << "Line no " << lineNo << ": Token <COMMENT> Lexeme " << yytext << " found" << endl << endl;
}
%}

WhiteSpace [ \t\f\r\v]+
Digit [0-9]
Letter [a-zA-Z]
AlphaNumerical [a-zA-Z0-9_]

%%

\n				{
					//newline
				}

{WhiteSpace}	{
					//whitespace
				}

"if"			{
					keyWordPrint("<IF>");
				}

"else"			{
					keyWordPrint("<ELSE>");
				}
				
"for"			{
					keyWordPrint("<FOR>");
				}

"while"			{
					keyWordPrint("<WHILE>");
				}

"do"			{
					keyWordPrint("<DO>");
				}

"break"			{
					keyWordPrint("<BREAK>");
				}

"int"			{
					keyWordPrint("<INT>");
				}

"char"			{
					keyWordPrint("<CHAR>");
				}

"float"			{
					keyWordPrint("<FLOAT>");
				}

"double"		{
					keyWordPrint("<DOUBLE>");
				}

"void"			{
					keyWordPrint("<VOID>");
				}

"return"		{
					keyWordPrint("<RETURN>");
				}

"switch"		{
					keyWordPrint("<SWITCH>");
				}

"case"			{
					keyWordPrint("<CASE>");
				}

"default"		{
					keyWordPrint("<DEFAULT>");
				}

"continue"		{
					keyWordPrint("<CONTINUE>");
				}

"+"|"-"			{
					opPuncPrint("ADDOP");
				}

"*"|"/"|"%"		{
					opPuncPrint("MULOP");
				}

"++"|"--"		{
					opPuncPrint("INCOP");
				}

"<"|"<="|">"|">="|"=="|"!="	{
					opPuncPrint("RELOP");
				}

"="				{
					opPuncPrint("ASSIGNOP");
				}

"&&"|"||"		{
					opPuncPrint("LOGICOP");
				}

"!"				{
					opPuncPrint("NOT");
				}

"("				{
					opPuncPrint("LPAREN");
				}

")"				{
					opPuncPrint("RPAREN");
				}

"{"				{
					opPuncPrint("LCURL");
					symbolTable.enterScope();
				}

"}"				{
					opPuncPrint("RCURL");
					symbolTable.exitScope();
				}

"["				{
					opPuncPrint("LTHIRD");
				}

"]"				{
					opPuncPrint("RTHIRD");
				}

","				{
					opPuncPrint("COMMA");
				}

";"				{
					opPuncPrint("SEMICOLON");
				}

{Digit}+		{
					numberPrint("CONST_INT");
					printFlag = symbolTable.insertSymbol(yytext,"CONST_INT");
					if(printFlag)	symbolTable.printAll(logFile);
				}

({Digit}+(\.{Digit}+)?((E|e)[+-]?{Digit}+)?)	|
(\.{Digit}+((E|e)[+-]?{Digit}+)?)	{
					numberPrint("CONST_FLOAT");
					printFlag = symbolTable.insertSymbol(yytext,"CONST_FLOAT");
					if(printFlag)	symbolTable.printAll(logFile);
				}
				
({Digit}+\.)	|
({Digit}+(\.{Digit}*)?((E|e)[+-]?({Digit}*\.{Digit}*)*))	{
					errorPrint("Ill formed number");
					errorCount++;
				}
				
({Digit}*\.{Digit}*)*((E|e)[+-]?{Digit}+)?	{
					errorPrint("Too many decimal points");
					errorCount++;
				}
				
({Letter}+|_+){AlphaNumerical}*	{
					identifierPrint("ID");
					printFlag = symbolTable.insertSymbol(yytext,"ID");
					if(printFlag)	symbolTable.printAll(logFile);
				}

{AlphaNumerical}+	{
					errorPrint("Invalid prefix on ID or invalid suffix on Number");
					errorCount++;
				}
				
\'(([^\'\\\n])|(\\[nt\\\'\"afrbv0]))\'	{
					charPrint(yytext);
					printFlag = symbolTable.insertSymbol(yytext,"CONST_CHAR");
					if(printFlag)	symbolTable.printAll(logFile);
				}
				
\'([^\'\n]+)([^\'\n]+)\'	{
					errorPrint("Multi character constant error");
					errorCount++;
				}

(\'){2}			{
					errorPrint("Empty character constant error");
					errorCount++;
				}

\'(([^\'\\\n])|(\\[nt\\\'\"afrbv0]))*	{
					errorPrint("Unterminated character");
					errorCount++;
				}

\"(((\\\")|(\\(\r)?\n)|(\\[^\"\n]))?([^\"\\\n])?)*\"	{
					stringPrint(); 
				}

\"(((\\\")|(\\(\r)?\n)|(\\[^\"\n]))?([^\"\\\n])?)*	{
					errorPrint("Unterminated String");
					errorCount++;
				}

\/\/([^\n]?(\\(\r)?\n)?)*	{
					commentPrint();
				}

\/\*([^\*\/]?((\*[^\/])|([^\*]\/))?)*\*\/	{
					commentPrint();
				}

\/\*([^\*\/]?((\*[^\/])|([^\*]\/))?)*	{
					errorPrint("Unterminated Comment");
					errorCount++;
				}

<<EOF>>			{
					symbolTable.printAll(logFile);
					logFile << "Total lines: " << yylineno << endl;
					logFile << "Total errors: " << errorCount << endl;
					return 0;
				}

.				{
					errorPrint("Unrecognized character");
					errorCount++;
				}
				
%%

int main(int argc, char *argv[])
{
	if(argc != 2)
	{
		cout << "provide input file" << endl;
		return 0;
	}
	
	FILE *fin = fopen(argv[1], "r");
	if(fin == nullptr)
	{
		cout << "cannot open input file" << endl;
		return 0;
	}
	
	logFile.open("1705092_log.txt");
	tokenFile.open("1705092_token.txt");
	
	yyin = fin;
	yylineno = 1;
	yylex();
	fclose(yyin);
	tokenFile.close();
	logFile.close();
	return 0;
}
