%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<string>
//#include<cmath>
#include<fstream>
#include<vector>
#include "1705092_SymbolTable.h"
#define YYSTYPE SymbolInfo*

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
extern int yylineno;

ofstream logFile;
ofstream errorFile;
int bucketSize = 30;
int errorCount = 0;
SymbolTable symbolTable(bucketSize);
vector<SymbolInfo*>* siVectorTemp = new vector<SymbolInfo*>();
bool isEnterValid = true;
bool isExited = false;
int forcedLineNo = 1;

void yyerror(char *s)
{
	logFile << "Error at line " << yylineno << ": " << s << endl << endl;
    return;
}

void ruleMathcedPrint(string ruleName, int lineNo = yylineno)
{
	logFile << "Line " << lineNo << ":" << ruleName << endl << endl;
}

void errorPrint(string errorName,  int lineNo = yylineno)
{
	logFile << "Error at line " << lineNo << ":" << errorName << endl << endl;
	errorFile << "Error at line " << lineNo << ":" << errorName << endl << endl;
}

void matchedCodePrint(string matchedCode)
{
	logFile << matchedCode << endl << endl << endl;
}
%}

%token ID CONST_INT CONST_FLOAT CONST_CHAR INT FLOAT VOID CHAR
%token IF ELSE FOR WHILE PRINTLN RETURN
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON
%token ADDOP MULOP INCOP DECOP ASSIGNOP NOT LOGICOP RELOP

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%%

start : program	{
			$$ = new SymbolInfo($1->getName(), "start");
			$$->setReturnType($1->getReturnType());
			$$->setParameterList(new vector<SymbolInfo*>());
			if($1->getParameterList() != nullptr){
				*$$->getParameterList() = *$1->getParameterList();
			}

			ruleMathcedPrint("start : program");
			//matchedCodePrint($$->getName());
		}
	  ;

program : program unit {
			$$ = new SymbolInfo($1->getName() + $2->getName(), "program");
			$$->setReturnType($1->getReturnType());
			$$->setParameterList(new vector<SymbolInfo*>());
			if($1->getParameterList() != nullptr){
				*$$->getParameterList() = *$1->getParameterList();
			}

			ruleMathcedPrint("program : program unit");
			matchedCodePrint($$->getName());
		}
		| unit	{
			$$ = new SymbolInfo($1->getName(), "program");
			$$->setReturnType($1->getReturnType());
			$$->setParameterList(new vector<SymbolInfo*>());
			if($1->getParameterList() != nullptr){
				*$$->getParameterList() = *$1->getParameterList();
			}

			ruleMathcedPrint("program : unit");
			matchedCodePrint($$->getName());
		}
		;
	
unit : var_declaration	{
		$$ = new SymbolInfo($1->getName(), "unit");
		$$->setReturnType($1->getReturnType());
		$$->setParameterList(new vector<SymbolInfo*>());
		if($1->getParameterList() != nullptr){
			*$$->getParameterList() = *$1->getParameterList();
		}

		ruleMathcedPrint("unit : var_declaration");
		matchedCodePrint($$->getName());
	}
     | func_declaration	{
		$$ = new SymbolInfo($1->getName(), "unit");
		$$->setReturnType($1->getReturnType());
		$$->setParameterList(new vector<SymbolInfo*>());
		if($1->getParameterList() != nullptr){
			*$$->getParameterList() = *$1->getParameterList();
		}

		ruleMathcedPrint("unit : func_declaration");
		matchedCodePrint($$->getName());
	}
     | func_definition	{
		$$ = new SymbolInfo($1->getName(), "unit");
		$$->setReturnType($1->getReturnType());
		$$->setParameterList(new vector<SymbolInfo*>());
		if($1->getParameterList() != nullptr){
			*$$->getParameterList() = *$1->getParameterList();
		}

		ruleMathcedPrint("unit : func_definition");
		matchedCodePrint($$->getName());
	}
     ;

dummy_enter_no_brace : {
						//cout<<"\ndummy no brace enter. line : "<<yylineno<<endl;
						symbolTable.enterScope();
						isEnterValid = false;
						isExited = false;
					}

dummy_exit_no_brace : {
						if(!isExited){
							//cout<<"\ndummy no brace exit. line : "<<yylineno<<endl;
							symbolTable.printAll(logFile);
							symbolTable.exitScope();
						}
						isEnterValid = true;
						isExited = false;
					}

dummy_enter_brace : {
						if(isEnterValid){
							//cout<<"\ndummy brace enter. line : "<<yylineno<<endl;
							symbolTable.enterScope();
						}
						isEnterValid = true;
						isExited = true;
					}

dummy_exit_brace : {
						//cout<<"\ndummy brace exit. line : "<<yylineno<<endl;
						symbolTable.printAll(logFile);
						symbolTable.exitScope();
					}

dummy_forced_line : {
						forcedLineNo = yylineno;
					}

func_declaration : type_specifier ID LPAREN dummy_enter_no_brace parameter_list RPAREN {
	for(int i=0; i<$5->getParameterList()->size(); i++){
		if($5->getParameterList()->at(i)->getType() != "type_specifier"){
			bool inserted = symbolTable.insertSymbol($5->getParameterList()->at(i));
			if(!inserted){
				errorPrint("Multiple declaration of " + $5->getParameterList()->at(i)->getName());
				errorCount++;
			}
		}
	}
} dummy_forced_line SEMICOLON dummy_exit_no_brace	{
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $5->getName() + ");\n", "func_declaration");
					$2->setSpecifiedType("function");
					$$->setSpecifiedType($2->getSpecifiedType());
					$2->setReturnType($1->getReturnType());
					$$->setReturnType($2->getReturnType());
					$2->setParameterList(new vector<SymbolInfo*>());
					$$->setParameterList(new vector<SymbolInfo*>());
					*$2->getParameterList() = *$5->getParameterList();
					*$$->getParameterList() = *$2->getParameterList();
					$2->setDefined(false);
					$$->setDefined($2->getDefined());

					ruleMathcedPrint("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
					matchedCodePrint($$->getName());

					//check func
					SymbolInfo* foundSymbol = symbolTable.lookUpCurrentScope($2->getName());
					
					if(foundSymbol == nullptr){
						//new function
						symbolTable.insertSymbol($2);
					}
					else{
						errorPrint("Multiple declaration of " + foundSymbol->getName(), forcedLineNo);
						errorCount++;
					}
				}
				 | type_specifier ID LPAREN RPAREN dummy_forced_line SEMICOLON	{
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();\n", "func_declaration");
					$2->setSpecifiedType("function");
					$$->setSpecifiedType($2->getSpecifiedType());
					$2->setReturnType($1->getReturnType());
					$$->setReturnType($2->getReturnType());
					$2->setParameterList(new vector<SymbolInfo*>());
					$$->setParameterList(new vector<SymbolInfo*>());
					$2->setDefined(false);
					$$->setDefined($2->getDefined());
					
					
					ruleMathcedPrint("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
					matchedCodePrint($$->getName());

					//check func
					SymbolInfo* foundSymbol = symbolTable.lookUpCurrentScope($2->getName());
					
					if(foundSymbol == nullptr){
						//new function
						symbolTable.insertSymbol($2);
					}
					else{
						errorPrint("Multiple declaration of " + foundSymbol->getName(), forcedLineNo);
						errorCount++;
					}
				}
				 ;
		 
func_definition : type_specifier ID LPAREN dummy_enter_no_brace parameter_list RPAREN {
	for(int i=0; i<$5->getParameterList()->size(); i++){
		if($5->getParameterList()->at(i)->getType() != "type_specifier"){
			bool inserted = symbolTable.insertSymbol($5->getParameterList()->at(i));
			if(!inserted){
				errorPrint("Multiple declaration of " + $5->getParameterList()->at(i)->getName());
				errorCount++;
			}
		}
	}
} dummy_forced_line compound_statement dummy_exit_no_brace	{
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $5->getName() + ")" + $9->getName() + "\n", "func_definition");
					$2->setSpecifiedType("function");
					$$->setSpecifiedType($2->getSpecifiedType());
					$2->setReturnType($1->getReturnType());
					$$->setReturnType($2->getReturnType());
					$2->setParameterList(new vector<SymbolInfo*>());
					$$->setParameterList(new vector<SymbolInfo*>());
					*$2->getParameterList() = *$5->getParameterList();
					*$$->getParameterList() = *$2->getParameterList();
					$2->setDefined(true);
					$$->setDefined($2->getDefined());
					
					ruleMathcedPrint("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");
					matchedCodePrint($$->getName());

					//check func
					SymbolInfo* foundSymbol = symbolTable.lookUpCurrentScope($2->getName());
					
					if(foundSymbol == nullptr){
						//new function
						symbolTable.insertSymbol($2);
					}
					else{
						//check if func
						if(foundSymbol->getSpecifiedType() == "function"){
							if(!foundSymbol->getDefined()){
								//only declared. check type
								if($2->getReturnType() != foundSymbol->getReturnType()){
									errorPrint("Return type mismatch with declaration of function " + foundSymbol->getName(), forcedLineNo);
									errorCount++;
								}
								else if($2->getParameterList()->size() != foundSymbol->getParameterList()->size()){
									errorPrint("Number of arguments mismatch with declaration of function " + foundSymbol->getName(), forcedLineNo);
									errorCount++;
								}
								else{
									//check type of arguments
									bool typeMatched;
									foundSymbol->setDefined(true);
									for(int i=0; i<$2->getParameterList()->size(); i++){
										typeMatched = true;
										if($2->getParameterList()->at(i)->getReturnType() != foundSymbol->getParameterList()->at(i)->getReturnType()){
											typeMatched = false;
										}
										if(!typeMatched){
											errorPrint("Type mismatch with declaration in " + to_string(i+1) + "th argument of function " + foundSymbol->getName(), forcedLineNo);
											errorCount++;
											foundSymbol->setDefined(false);
										}
									}
								}
							}
							else{
								//multiple definition
								errorPrint("Multiple definition of " + foundSymbol->getName(), forcedLineNo);
								errorCount++;
							}
						}
						else{
							//not a func
							errorPrint("Multiple declaration of " + foundSymbol->getName(), forcedLineNo);
							errorCount++;
						}
					}
				}
				| type_specifier ID LPAREN RPAREN dummy_forced_line compound_statement	{
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "()" + $6->getName() + "\n", "func_definition");
					$2->setSpecifiedType("function");
					$$->setSpecifiedType($2->getSpecifiedType());
					$2->setReturnType($1->getReturnType());
					$$->setReturnType($2->getReturnType());
					$2->setParameterList(new vector<SymbolInfo*>());
					$$->setParameterList(new vector<SymbolInfo*>());
					$2->setDefined(true);
					$$->setDefined($2->getDefined());

					ruleMathcedPrint("func_definition : type_specifier ID LPAREN RPAREN compound_statement");
					matchedCodePrint($$->getName());

					//check func
					SymbolInfo* foundSymbol = symbolTable.lookUpCurrentScope($2->getName());
					
					if(foundSymbol == nullptr){
						//new function
						symbolTable.insertSymbol($2);
					}
					else{
						//check if func
						if(foundSymbol->getSpecifiedType() == "function"){
							if(!foundSymbol->getDefined()){
								//only declared. check type
								if($2->getReturnType() != foundSymbol->getReturnType()){
									errorPrint("Return type mismatch with declaration of function " + foundSymbol->getName(), forcedLineNo);
									errorCount++;
								}
								else if($2->getParameterList()->size() != foundSymbol->getParameterList()->size()){
									errorPrint("Number of arguments mismatch with declaration of function " + foundSymbol->getName(), forcedLineNo);
									errorCount++;
								}
								else{
									//check type of arguments
									bool typeMatched;
									for(int i=0; i<$2->getParameterList()->size(); i++){
										typeMatched = true;
										if($2->getParameterList()->at(i)->getReturnType() != foundSymbol->getParameterList()->at(i)->getReturnType()){
											typeMatched = false;
										}
										if(!typeMatched){
											errorPrint("Type mismatch with declaration in " + to_string(i+1) + "th argument of function " + foundSymbol->getName(), forcedLineNo);
											errorCount++;
										}
									}
								}
							}
							else{
								//multiple definition
								errorPrint("Multiple definition of " + foundSymbol->getName(), forcedLineNo);
								errorCount++;
							}
						}
						else{
							//not a func
							errorPrint("Multiple declaration of " + foundSymbol->getName(), forcedLineNo);
							errorCount++;
						}
					}
				}
				;				

parameter_list : parameter_list COMMA type_specifier ID	{
					$$ = new SymbolInfo($1->getName() + "," + $3->getName() + " " + $4->getName(), "parameter_list");
					$4->setSpecifiedType("variable");
					$4->setReturnType($3->getReturnType());
					$$->setReturnType($4->getReturnType());
					$$->setParameterList(new vector<SymbolInfo*>());
					*$$->getParameterList() = *$1->getParameterList();

					ruleMathcedPrint("parameter_list : parameter_list COMMA type_specifier ID");
					matchedCodePrint($$->getName());

					if($4->getReturnType() != "void")
						$$->getParameterList()->push_back($4);	//parameter list
					else{
						errorPrint("Variable type can not be void");
						errorCount++;
					}
				}
			   | parameter_list COMMA type_specifier	{
					$$ = new SymbolInfo($1->getName() + "," + $3->getName(), "parameter_list");
					$$->setReturnType($3->getReturnType());
					$$->setParameterList(new vector<SymbolInfo*>());
					*$$->getParameterList() = *$1->getParameterList();

					ruleMathcedPrint("parameter_list : parameter_list COMMA type_specifier");
					matchedCodePrint($$->getName());

					if($3->getReturnType() != "void")
						$$->getParameterList()->push_back($3);	//parameter list
				}
			   | type_specifier ID	{
					$$ = new SymbolInfo($1->getName() +  " " + $2->getName(), "parameter_list");
					$2->setSpecifiedType("variable");
					$2->setReturnType($1->getReturnType());
					$$->setReturnType($2->getReturnType());
					$$->setParameterList(new vector<SymbolInfo*>());

					ruleMathcedPrint("parameter_list : type_specifier ID");
					matchedCodePrint($$->getName());

					if($2->getReturnType() != "void")
						$$->getParameterList()->push_back($2);	//parameter list
					else{
						errorPrint("Variable type can not be void");
						errorCount++;
					}
				}
			   | type_specifier	{
					$$ = new SymbolInfo($1->getName(), "parameter_list");
					$$->setReturnType($1->getReturnType());
					$$->setParameterList(new vector<SymbolInfo*>());

					ruleMathcedPrint("parameter_list : type_specifier");
					matchedCodePrint($$->getName());

					if($1->getReturnType() != "void")
						$$->getParameterList()->push_back($1);	//parameter list
				}
			   ;

compound_statement : LCURL dummy_enter_brace statements RCURL dummy_exit_brace	{
						$$ = new SymbolInfo("{\n" + $3->getName() + "}\n", "compound_statement");
						$$->setSpecifiedType($3->getSpecifiedType());
						$$->setReturnType($3->getReturnType());
						$$->setParameterList(new vector<SymbolInfo*>());
						if($3->getParameterList() != nullptr){
							*$$->getParameterList() = *$3->getParameterList();
						}

						ruleMathcedPrint("compound_statement : LCURL statements RCURL");
						matchedCodePrint($$->getName());
					}
					| LCURL dummy_enter_brace RCURL dummy_exit_brace	{
						$$ = new SymbolInfo("{}\n", "compound_statement");
						$$->setSpecifiedType("blank");
						$$->setParameterList(new vector<SymbolInfo*>());

						ruleMathcedPrint("compound_statement : LCURL RCURL");
						matchedCodePrint($$->getName());
					}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON	{
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + ";\n", "var_declaration");
					$$->setReturnType($1->getReturnType());
					$$->setParameterList(new vector<SymbolInfo*>());
					if($2->getParameterList() != nullptr){
						*$$->getParameterList() = *$2->getParameterList();
					}

					ruleMathcedPrint("var_declaration : type_specifier declaration_list SEMICOLON");
					matchedCodePrint($$->getName());

					if($1->getReturnType() == "void"){
						errorPrint("Variable type can not be void");
						errorCount++;
						//$1->setReturnType("int");
						//$$->setReturnType($1->getReturnType());
					}
					else{
						for(int i=0; i<$2->getParameterList()->size(); i++){
							$2->getParameterList()->at(i)->setReturnType($1->getReturnType());
							bool inserted = symbolTable.insertSymbol($2->getParameterList()->at(i));
							if(!inserted){
								errorPrint("Multiple declaration of " + $2->getParameterList()->at(i)->getName());
								errorCount++;
							}
						}
					}
				}
				;
 		 
type_specifier : INT	{
					$$ = new SymbolInfo("int", "type_specifier");
					$$->setSpecifiedType("int");
					$$->setReturnType("int");
					$$->setParameterList(new vector<SymbolInfo*>());

					ruleMathcedPrint("type_specifier : INT");
					matchedCodePrint($$->getName());
				}
			   | FLOAT	{
					$$ = new SymbolInfo("float", "type_specifier");
					$$->setSpecifiedType("float");
					$$->setReturnType("float");
					$$->setParameterList(new vector<SymbolInfo*>());

					ruleMathcedPrint("type_specifier : FLOAT");
					matchedCodePrint($$->getName());
				}
			   | VOID	{
					$$ = new SymbolInfo("void", "type_specifier");
					$$->setSpecifiedType("void");
					$$->setReturnType("void");
					$$->setParameterList(new vector<SymbolInfo*>());

					ruleMathcedPrint("type_specifier : VOID");
					matchedCodePrint($$->getName());
				}
			   ;
 		
declaration_list : declaration_list COMMA ID	{
					$$ = new SymbolInfo($1->getName() + "," + $3->getName(), "declaration_list");
					$3->setSpecifiedType("variable");
					$$->setSpecifiedType($3->getSpecifiedType());
					$$->setReturnType($3->getReturnType());
					$3->setParameterList(new vector<SymbolInfo*>());
					$$->setParameterList(new vector<SymbolInfo*>());
					if($1->getParameterList() != nullptr){
						*$$->getParameterList() = *$1->getParameterList();
					}

					ruleMathcedPrint("declaration_list : declaration_list COMMA ID");
					matchedCodePrint($$->getName());

					$$->getParameterList()->push_back($3);	//declaration list
				}
				 | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD	{
					$$ = new SymbolInfo($1->getName() + "," + $3->getName() + "[" + $5->getName() + "]", "declaration_list");
					$3->setSpecifiedType("array");
					$$->setSpecifiedType($3->getSpecifiedType());
					$$->setReturnType($3->getReturnType());
					$3->setParameterList(new vector<SymbolInfo*>());
					$$->setParameterList(new vector<SymbolInfo*>());
					if($1->getParameterList() != nullptr){
						*$$->getParameterList() = *$1->getParameterList();
					}

					ruleMathcedPrint("declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");
					matchedCodePrint($$->getName());

					$$->getParameterList()->push_back($3);	//declaration list

				}
				 | ID	{
					$$ = new SymbolInfo($1->getName(), "declaration_list");
					$1->setSpecifiedType("variable");
					$$->setSpecifiedType($1->getSpecifiedType());
					$$->setReturnType($1->getReturnType());
					$1->setParameterList(new vector<SymbolInfo*>());
					$$->setParameterList(new vector<SymbolInfo*>());

					ruleMathcedPrint("declaration_list : ID");
					matchedCodePrint($$->getName());

					$$->getParameterList()->push_back($1);	//declaration list
				}
				 | ID LTHIRD CONST_INT RTHIRD	{
					$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", "declaration_list");
					$1->setSpecifiedType("array");
					$$->setSpecifiedType($1->getSpecifiedType());
					$$->setReturnType($1->getReturnType());
					$1->setParameterList(new vector<SymbolInfo*>());
					$$->setParameterList(new vector<SymbolInfo*>());

					ruleMathcedPrint("declaration_list : ID LTHIRD CONST_INT RTHIRD");
					matchedCodePrint($$->getName());

					$$->getParameterList()->push_back($1);	//declaration list
				}
 		  ;
 		  
statements : statement	{
				$$ = new SymbolInfo($1->getName(), "statements");
				$$->setSpecifiedType($1->getSpecifiedType());
				$$->setReturnType($1->getReturnType());
				$$->setParameterList(new vector<SymbolInfo*>());
				if($1->getParameterList() != nullptr){
					*$$->getParameterList() = *$1->getParameterList();
				}

				ruleMathcedPrint("statements : statement");
				matchedCodePrint($$->getName());
			}
		   | statements statement	{
				$$ = new SymbolInfo($1->getName() + $2->getName(), "statements");
				$$->setSpecifiedType($1->getSpecifiedType());
				$$->setReturnType($1->getReturnType());
				$$->setParameterList(new vector<SymbolInfo*>());
				if($1->getParameterList() != nullptr){
					*$$->getParameterList() = *$1->getParameterList();
				}

				ruleMathcedPrint("statements : statements statement");
				matchedCodePrint($$->getName());
			}
		   ;
	   
statement : var_declaration	{
				$$ = new SymbolInfo($1->getName(), "statement");
				$$->setSpecifiedType($1->getSpecifiedType());
				$$->setReturnType($1->getReturnType());
				$$->setParameterList(new vector<SymbolInfo*>());
				if($1->getParameterList() != nullptr){
					*$$->getParameterList() = *$1->getParameterList();
				}

				ruleMathcedPrint("statement : var_declaration");
				matchedCodePrint($$->getName());
			}
		  | expression_statement	{
				$$ = new SymbolInfo($1->getName(), "statement");
				$$->setSpecifiedType($1->getSpecifiedType());
				$$->setReturnType($1->getReturnType());
				$$->setParameterList(new vector<SymbolInfo*>());
				if($1->getParameterList() != nullptr){
					*$$->getParameterList() = *$1->getParameterList();
				}

				ruleMathcedPrint("statement : expression_statement");
				matchedCodePrint($$->getName());
			}
		  | compound_statement	{
				$$ = new SymbolInfo($1->getName(), "statement");
				$$->setSpecifiedType($1->getSpecifiedType());
				$$->setReturnType($1->getReturnType());
				$$->setParameterList(new vector<SymbolInfo*>());
				if($1->getParameterList() != nullptr){
					*$$->getParameterList() = *$1->getParameterList();
				}

				ruleMathcedPrint("statement : compound_statement");
				matchedCodePrint($$->getName());
			}
		  | FOR dummy_enter_no_brace LPAREN expression_statement expression_statement expression RPAREN statement dummy_exit_no_brace	{
				$$ = new SymbolInfo("for(" + $4->getName() + $5->getName() + $6->getName() + ")" + $8->getName(),"statement");
				$$->setSpecifiedType("for");
				$$->setParameterList(new vector<SymbolInfo*>());
				
				ruleMathcedPrint("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
				matchedCodePrint($$->getName());
			}
		  | IF dummy_enter_no_brace LPAREN expression RPAREN statement dummy_exit_no_brace	%prec LOWER_THAN_ELSE	{
				$$ = new SymbolInfo("if(" + $4->getName() + ")" + $6->getName(), "statement");
				$$->setSpecifiedType("if");
				$$->setParameterList(new vector<SymbolInfo*>());
				
				ruleMathcedPrint("statement : IF LPAREN expression RPAREN statement");
				matchedCodePrint($$->getName());
			}
		  | IF dummy_enter_no_brace LPAREN expression RPAREN statement dummy_exit_no_brace ELSE dummy_enter_no_brace statement dummy_exit_no_brace	{
				$$ = new SymbolInfo("if(" + $4->getName() + ")" + $6->getName() + "else" + $10->getName(),"statement");
				$$->setSpecifiedType("if_else");
				$$->setParameterList(new vector<SymbolInfo*>());
				
				ruleMathcedPrint("statement : IF LPAREN expression RPAREN statement ELSE statement");
				matchedCodePrint($$->getName());
			}
		  | WHILE dummy_enter_no_brace LPAREN expression RPAREN statement dummy_exit_no_brace	{
				$$ = new SymbolInfo("while(" + $4->getName() + ")" + $6->getName(),"statement");
				$$->setSpecifiedType("while");
				$$->setParameterList(new vector<SymbolInfo*>());
				
				ruleMathcedPrint("statement : WHILE LPAREN expression RPAREN statement");
				matchedCodePrint($$->getName());
			}
		  | PRINTLN LPAREN ID RPAREN SEMICOLON	{
				$$ = new SymbolInfo("printf(" + $3->getName() + ");\n","statement");
				SymbolInfo* foundSymbol = symbolTable.lookUpSymbol($3->getName());
				if(foundSymbol == nullptr){
					errorPrint("Undeclared variable " + $3->getName());
					errorCount++;
				}
				$$->setParameterList(new vector<SymbolInfo*>());

				ruleMathcedPrint("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");
				matchedCodePrint($$->getName());
			}
		  | RETURN expression SEMICOLON	{
				$$ = new SymbolInfo("return " + $2->getName() + ";\n", "statement");
				$$->setSpecifiedType($2->getSpecifiedType());
				$$->setParameterList(new vector<SymbolInfo*>());

				ruleMathcedPrint("statement : RETURN expression SEMICOLON");
				matchedCodePrint($$->getName());
				
				if($2->getReturnType() == "void"){
					errorPrint("Can not return void");
					errorCount++;
				}
			}
		  ;
	  
expression_statement : SEMICOLON	{
						$$ = new SymbolInfo(";\n", "expression_statement");
						
						$$->setParameterList(new vector<SymbolInfo*>());

						ruleMathcedPrint("expression_statement : SEMICOLON");
						matchedCodePrint($$->getName());
					}
					 | expression SEMICOLON	{
						$$ = new SymbolInfo($1->getName() + ";\n", "expression_statement");
						$$->setSpecifiedType($1->getSpecifiedType());
						$$->setReturnType($1->getReturnType());
						$$->setParameterList(new vector<SymbolInfo*>());
						if($1->getParameterList() != nullptr){
							*$$->getParameterList() = *$1->getParameterList();
						}

						ruleMathcedPrint("expression_statement : expression SEMICOLON");
						matchedCodePrint($$->getName());
					}
					 ;
	  
variable : ID	{
			$$ = new SymbolInfo($1->getName(), "variable");
			$1->setSpecifiedType("variable");
			$$->setSpecifiedType($1->getSpecifiedType());
			$1->setReturnType("int");	//default type
			$$->setReturnType($1->getReturnType());
			$1->setParameterList(new vector<SymbolInfo*>());
			$$->setParameterList(new vector<SymbolInfo*>());

			ruleMathcedPrint("variable : ID");
			matchedCodePrint($$->getName());
			
			SymbolInfo* foundSymbol = symbolTable.lookUpSymbol($1->getName());
			
			if(foundSymbol == nullptr){
				errorPrint("Undeclared variable " + $1->getName());
				errorCount++;
			}
			else if(foundSymbol->getSpecifiedType() != $1->getSpecifiedType()){
				errorPrint("Type mismatch. " + foundSymbol->getName() + " is a " + foundSymbol->getSpecifiedType());
				errorCount++;
				$1->setSpecifiedType(foundSymbol->getSpecifiedType());
				$$->setSpecifiedType($1->getSpecifiedType());
				$1->setReturnType(foundSymbol->getReturnType());
				$$->setReturnType($1->getReturnType());
			}
			else{
				//found a variable in symbolTable
				$1->setReturnType(foundSymbol->getReturnType());
				$$->setReturnType($1->getReturnType());
				
				if(foundSymbol->getParameterList() != nullptr){
					*$1->getParameterList() = *foundSymbol->getParameterList();
					*$$->getParameterList() = *$1->getParameterList();
				}
			}
		}
		 | ID LTHIRD expression RTHIRD	{
			$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", "variable");
			$1->setSpecifiedType("array");
			$$->setSpecifiedType($1->getSpecifiedType());
			$1->setReturnType("int");	//default type
			$$->setReturnType($1->getReturnType());
			$1->setParameterList(new vector<SymbolInfo*>());
			$$->setParameterList(new vector<SymbolInfo*>());

			ruleMathcedPrint("variable : ID LTHIRD expression RTHIRD");
			matchedCodePrint($$->getName());
			
			SymbolInfo* foundSymbol = symbolTable.lookUpSymbol($1->getName());
			
			if(foundSymbol == nullptr){
				errorPrint("Undeclared variable " + $1->getName());
				errorCount++;
			}
			else if(foundSymbol->getSpecifiedType() != $$->getSpecifiedType()){
				errorPrint("Type mismatch. " + foundSymbol->getName() + " is a " + foundSymbol->getSpecifiedType());
				errorCount++;
				$1->setSpecifiedType(foundSymbol->getSpecifiedType());
				$$->setSpecifiedType($1->getSpecifiedType());
				$1->setReturnType(foundSymbol->getReturnType());
				$$->setReturnType($1->getReturnType());
			}
			else{
				//found an array in symbolTable
				$1->setReturnType(foundSymbol->getReturnType());
				$$->setReturnType($1->getReturnType());

				if(foundSymbol->getParameterList() != nullptr){
					*$1->getParameterList() = *foundSymbol->getParameterList();
					*$$->getParameterList() = *$1->getParameterList();
				}
			}
			if($3->getReturnType() == "void"){
				errorPrint("Void function used in expression : " + $3->getName());
				errorCount++;
			}
			if($3->getReturnType() != "int"){
				errorPrint("Expression inside third brackets not an integer : " + $3->getName());
				errorCount++;
			}
		}
		 ;
	 
expression : logic_expression	{
				$$ = new SymbolInfo($1->getName(), "expression");
				$$->setSpecifiedType($1->getSpecifiedType());
				$$->setReturnType($1->getReturnType());
				$$->setParameterList(new vector<SymbolInfo*>());
				if($1->getParameterList() != nullptr){
					*$$->getParameterList() = *$1->getParameterList();
				}

				ruleMathcedPrint("expression : logic_expression");
				matchedCodePrint($$->getName());
			}
		   | variable ASSIGNOP logic_expression	{
				$$ = new SymbolInfo($1->getName() + "=" + $3->getName(), "expression");
				$$->setSpecifiedType($1->getSpecifiedType());
				$$->setReturnType($1->getReturnType());
				$$->setParameterList(new vector<SymbolInfo*>());
				if($1->getParameterList() != nullptr){
					*$$->getParameterList() = *$1->getParameterList();
				}

				ruleMathcedPrint("expression : variable ASSIGNOP logic_expression");
				matchedCodePrint($$->getName());
				
				if($3->getReturnType() == "void"){
					errorPrint("Void function used in expression : " + $3->getName());
					errorCount++;
				}
				else if($1->getReturnType() != $3->getReturnType()){
					if($1->getReturnType() != "float" || $3->getReturnType() != "int"){
						//int to float -> convert ok
						errorPrint("Type mismatch in assignment");
						errorCount++;
					}
				}
			}
		   ;
			
logic_expression : rel_expression	{
					$$ = new SymbolInfo($1->getName(), "logic_expression");
						$$->setSpecifiedType($1->getSpecifiedType());
						$$->setReturnType($1->getReturnType());
						$$->setParameterList(new vector<SymbolInfo*>());
						if($1->getParameterList() != nullptr){
							*$$->getParameterList() = *$1->getParameterList();
						}
						ruleMathcedPrint("logic_expression : rel_expression");
						matchedCodePrint($$->getName());
				}
				 | rel_expression LOGICOP rel_expression	{
					$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "logic_expression");
					$$->setSpecifiedType($1->getSpecifiedType());
					$$->setReturnType("int");
					$$->setParameterList(new vector<SymbolInfo*>());

					ruleMathcedPrint("logic_expression : rel_expression LOGICOP rel_expression");
					matchedCodePrint($$->getName());
					
					if($1->getReturnType() == "void"){
						errorPrint("Void function used in expression : " + $1->getName());
						errorCount++;
					}
					if($3->getReturnType() == "void"){
						errorPrint("Void function used in expression : " + $3->getName());
						errorCount++;
					}
				}
				 ;
			
rel_expression	: simple_expression	{
					$$ = new SymbolInfo($1->getName(), "rel_expression");
						$$->setSpecifiedType($1->getSpecifiedType());
						$$->setReturnType($1->getReturnType());
						$$->setParameterList(new vector<SymbolInfo*>());
						if($1->getParameterList() != nullptr){
							*$$->getParameterList() = *$1->getParameterList();
						}
						ruleMathcedPrint("rel_expression : simple_expression");
						matchedCodePrint($$->getName());
				}
				| simple_expression RELOP simple_expression	{
					$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "rel_expression");
					$$->setSpecifiedType($1->getSpecifiedType());
					$$->setReturnType("int");
					$$->setParameterList(new vector<SymbolInfo*>());

					ruleMathcedPrint("rel_expression : simple_expression RELOP simple_expression");
					matchedCodePrint($$->getName());
					
					if($1->getReturnType() == "void"){
						errorPrint("Void function used in expression : " + $1->getName());
						errorCount++;
					}
					if($3->getReturnType() == "void"){
						errorPrint("Void function used in expression : " + $3->getName());
						errorCount++;
					}
				}
				;
				
simple_expression : term	{
						$$ = new SymbolInfo($1->getName(), "simple_expression");
						$$->setSpecifiedType($1->getSpecifiedType());
						$$->setReturnType($1->getReturnType());
						$$->setParameterList(new vector<SymbolInfo*>());
						if($1->getParameterList() != nullptr){
							*$$->getParameterList() = *$1->getParameterList();
						}
						ruleMathcedPrint("simple_expression : term");
						matchedCodePrint($$->getName());
					}
				  | simple_expression ADDOP term	{
						$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "simple_expression");
						$$->setSpecifiedType($1->getSpecifiedType());
						$$->setReturnType("int");
						$$->setParameterList(new vector<SymbolInfo*>());

						ruleMathcedPrint("simple_expression : simple_expression ADDOP term");
						matchedCodePrint($$->getName());
						
						if($1->getReturnType() == "void"){
							errorPrint("Void function used in expression : " + $1->getName());
							errorCount++;
						}
						if($3->getReturnType() == "void"){
							errorPrint("Void function used in expression : " + $3->getName());
							errorCount++;
						}
						if($1->getReturnType() == "float" || $3->getReturnType() == "float"){
							$$->setReturnType("float");
						}
					}
				  ;
					
term :	unary_expression	{
			$$ = new SymbolInfo($1->getName(), "unary_expression");
			$$->setSpecifiedType($1->getSpecifiedType());
			$$->setReturnType($1->getReturnType());
			$$->setParameterList(new vector<SymbolInfo*>());
			if($1->getParameterList() != nullptr){
				*$$->getParameterList() = *$1->getParameterList();
			}
			ruleMathcedPrint("term : unary_expression");
			matchedCodePrint($$->getName());
		}
     |	term MULOP unary_expression	{
			$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "unary_expression");
			$$->setSpecifiedType($1->getSpecifiedType());
			$$->setParameterList(new vector<SymbolInfo*>());
			$$->setReturnType("int");

			ruleMathcedPrint("term : term MULOP unary_expression");
			matchedCodePrint($$->getName());
			
			if($1->getReturnType() == "void"){
				errorPrint("Void function used in expression : " + $1->getName());
				errorCount++;
			}
			if($3->getReturnType() == "void"){
				errorPrint("Void function used in expression : " + $3->getName());
				errorCount++;
			}
			if($1->getReturnType() == "float" || $3->getReturnType() == "float"){
				$$->setReturnType("float");
			}
			if($2->getName() == "%"){
				$$->setReturnType("int");
				if($1->getReturnType() != "int" || $3->getReturnType() != "int"){
					errorPrint("Non-Integer operand on modulus operator");
					errorCount++;
				}
			}
			if($2->getName() != "*"){
				if($3->getSpecifiedType() == "constant"){
					try{
						float divisor = stof($3->getName());
						if(divisor == 0){
							if($2->getName() == "/")
								errorPrint("Divide by Zero");
							else if($2->getName() == "%")
								errorPrint("Modulus by Zero");
							errorCount++;
						}
					}
					catch(...){
						errorPrint("Undetermined divisor");
						errorCount++;
					}
				}
			}
		}
     ;

unary_expression : ADDOP unary_expression	{
					$$ = new SymbolInfo($1->getName() + $2->getName(), "unary_expression");
					$$->setSpecifiedType($2->getSpecifiedType());
					$$->setReturnType($2->getReturnType());
					$$->setParameterList(new vector<SymbolInfo*>());
					if($2->getParameterList() != nullptr){
						*$$->getParameterList() = *$2->getParameterList();
					}
					ruleMathcedPrint("unary_expression : ADDOP unary_expression");
					matchedCodePrint($$->getName());
					
					if($2->getReturnType() == "void"){
						errorPrint("Void function used in expression : "  + $2->getName());
						errorCount++;
						$$->setReturnType("int");
					}
				 }
				 | NOT unary_expression	{
					$$ = new SymbolInfo("!" + $2->getName(), "unary_expression");
					$$->setSpecifiedType($2->getSpecifiedType());
					$$->setReturnType($2->getReturnType());
					$$->setParameterList(new vector<SymbolInfo*>());
					if($2->getParameterList() != nullptr){
						*$$->getParameterList() = *$2->getParameterList();
					}
					ruleMathcedPrint("unary_expression : NOT unary_expression");
					matchedCodePrint($$->getName());
					
					if($2->getReturnType() == "void"){
						errorPrint("Void function used in expression : " + $2->getName());
						errorCount++;
						$$->setReturnType("int");
					}
				 }
				 | factor	{
					$$ = new SymbolInfo($1->getName(), "unary_expression");
					$$->setSpecifiedType($1->getSpecifiedType());
					$$->setReturnType($1->getReturnType());
					$$->setParameterList(new vector<SymbolInfo*>());
					if($1->getParameterList() != nullptr){
						*$$->getParameterList() = *$1->getParameterList();
					}
					ruleMathcedPrint("unary_expression : factor");
					matchedCodePrint($$->getName());
				 }
				 ;
	
factor	: variable	{
			$$ = new SymbolInfo($1->getName(), "factor");
			$$->setSpecifiedType($1->getSpecifiedType());
			$$->setReturnType($1->getReturnType());
			$$->setParameterList(new vector<SymbolInfo*>());
			if($1->getParameterList() != nullptr){
				*$$->getParameterList() = *$1->getParameterList();
			}
			
			ruleMathcedPrint("factor : variable");
			matchedCodePrint($$->getName());
		}
		| ID LPAREN argument_list RPAREN	{
			$$ = new SymbolInfo($1->getName() + "(" + $3->getName() + ")", "factor");
			$$->setSpecifiedType("function");
			$1->setParameterList(new vector<SymbolInfo*>());
			$$->setParameterList(new vector<SymbolInfo*>());
			if($3->getParameterList() != nullptr){
				*$1->getParameterList() = *$3->getParameterList();
				*$$->getParameterList() = *$3->getParameterList();
			}

			ruleMathcedPrint("factor : ID LPAREN argument_list RPAREN");
			matchedCodePrint($$->getName());

			SymbolInfo* foundSymbol = symbolTable.lookUpSymbol($1->getName());
			
			if(foundSymbol == nullptr){
				errorPrint("Undeclared function " + $1->getName());
				errorCount++;
				$1->setReturnType("int");
				$$->setReturnType($1->getReturnType());
			}
			else if(foundSymbol->getSpecifiedType() != $$->getSpecifiedType()){
				errorPrint(foundSymbol->getSpecifiedType() + " " + $1->getName() + " used as function");
				errorCount++;
				$1->setReturnType(foundSymbol->getReturnType());
				$$->setReturnType($1->getReturnType());
			}
			else{
				//found a function in symbolTable
				$1->setReturnType(foundSymbol->getReturnType());
				$$->setReturnType($1->getReturnType());
				if($1->getParameterList()->size() < foundSymbol->getParameterList()->size()){
					errorPrint("too few arguments to function " + $1->getName());
					errorCount++;
				}
				else if($1->getParameterList()->size() > foundSymbol->getParameterList()->size()){
					errorPrint("too many arguments to function " + $1->getName());
					errorCount++;
				}
				else{
					//check type of arguments
					bool typeMatched;
					for(int i=0; i<$1->getParameterList()->size(); i++){
						typeMatched = true;
						if($1->getParameterList()->at(i)->getReturnType() != foundSymbol->getParameterList()->at(i)->getReturnType()){
							typeMatched = false;
							if($1->getParameterList()->at(i)->getReturnType() == "int" && foundSymbol->getParameterList()->at(i)->getReturnType() == "float"){
								//int to float -> convert ok
								typeMatched = true;
							}
						}
						if(!typeMatched){
							errorPrint("Type mismatch in " + to_string(i+1) + "th argument of function " + $1->getName());
							errorCount++;
						}
					}
				}
			}
		}
		| LPAREN expression RPAREN	{
			$$ = new SymbolInfo("(" + $2->getName() + ")", "factor");
			$$->setSpecifiedType($2->getSpecifiedType());
			$$->setReturnType($2->getReturnType());
			$$->setParameterList(new vector<SymbolInfo*>());
			if($2->getParameterList() != nullptr){
				*$$->getParameterList() = *$2->getParameterList();
			}
			
			ruleMathcedPrint("factor : LPAREN expression RPAREN");
			matchedCodePrint($$->getName());
		}
		| CONST_INT	{
			$$ = new SymbolInfo($1->getName(), "factor");
			$$->setSpecifiedType("constant");
			$$->setReturnType("int");
			$$->setParameterList(new vector<SymbolInfo*>());

			ruleMathcedPrint("factor : CONST_INT");
			matchedCodePrint($$->getName());
		}
		| CONST_FLOAT	{
			$$ = new SymbolInfo($1->getName(), "factor");
			$$->setSpecifiedType("constant");
			$$->setReturnType("float");
			$$->setParameterList(new vector<SymbolInfo*>());

			ruleMathcedPrint("factor : CONST_FLOAT");
			matchedCodePrint($$->getName());
		}
		| variable INCOP	{
			$$ = new SymbolInfo($1->getName() + "++", "factor");
			$$->setSpecifiedType($1->getSpecifiedType());
			$$->setReturnType($1->getReturnType());
			$$->setParameterList(new vector<SymbolInfo*>());
			if($1->getParameterList() != nullptr){
				*$$->getParameterList() = *$1->getParameterList();
			}
			ruleMathcedPrint("factor : variable INCOP");
			matchedCodePrint($$->getName());
			
			if($1->getReturnType() == "void"){
				errorPrint("INCOP called on void type");
				errorCount++;
				$$->setReturnType("int");
			}
		}
		| variable DECOP	{
			$$ = new SymbolInfo($1->getName() + "--", "factor");
			$$->setSpecifiedType($1->getSpecifiedType());
			$$->setReturnType($1->getReturnType());
			$$->setParameterList(new vector<SymbolInfo*>());
			if($1->getParameterList() != nullptr){
				*$$->getParameterList() = *$1->getParameterList();
			}
			ruleMathcedPrint("factor : variable DECOP");
			matchedCodePrint($$->getName());
			
			if($1->getReturnType() == "void"){
				errorPrint("DECOP called on void type");
				errorCount++;
				$$->setReturnType("int");
			}
		}
		;
	
argument_list : arguments	{
					$$ = new SymbolInfo($1->getName(), "arguments");
					$$->setSpecifiedType($1->getSpecifiedType());
					$$->setReturnType($1->getReturnType());
					$$->setParameterList(new vector<SymbolInfo*>());
					*$$->getParameterList() = *$1->getParameterList();

					ruleMathcedPrint("argument_list : arguments");
					matchedCodePrint($$->getName());
				}
			  |	{
					$$ = new SymbolInfo("", "arguments");
					$$->setParameterList(new vector<SymbolInfo*>());

					ruleMathcedPrint("argument_list : ");
					matchedCodePrint($$->getName());
				}
			  ;
	
arguments : arguments COMMA logic_expression	{
				$$ = new SymbolInfo($1->getName() + "," + $3->getName(), "arguments");
				$$->setSpecifiedType($1->getSpecifiedType());
				$$->setReturnType($1->getReturnType());
				$$->setParameterList(new vector<SymbolInfo*>());
				*$$->getParameterList() = *$1->getParameterList();

				ruleMathcedPrint("arguments : arguments COMMA logic_expression");
				matchedCodePrint($$->getName());
				
				if($3->getReturnType() == "void"){
					errorPrint("Invalid use of type 'void' in arguments");
					errorCount++;
				}
				else{
					$$->getParameterList()->push_back($3);	//argument list
				}
			}
		  | logic_expression	{
				$$ = new SymbolInfo($1->getName(), "arguments");
				$$->setSpecifiedType($1->getSpecifiedType());
				$$->setReturnType($1->getReturnType());
				$$->setParameterList(new vector<SymbolInfo*>());

				ruleMathcedPrint("arguments : logic_expression");
				matchedCodePrint($$->getName());
				
				if($1->getReturnType() == "void"){
					errorPrint("Invalid use of type 'void' in arguments");
					errorCount++;
				}
				else
					$$->getParameterList()->push_back($1);	//argument list
			}
		  ;
 

%%
int main(int argc,char *argv[])
{
	if(argc < 2)
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

	logFile.open("log.txt");
	errorFile.open("error.txt");
 
	yyin = fin;
	yylineno = 1;
	yyparse();
	
	logFile<<endl;
	symbolTable.printAll(logFile);
	
	logFile<<endl;
	logFile<<"Total lines: " << yylineno << endl;
	logFile<<"Total errors: " << errorCount << endl;
	//errorFile<<"Total errors: " << errorCount << endl;
	

	fclose(yyin);
	errorFile.close();
	logFile.close();
	return 0;
}

