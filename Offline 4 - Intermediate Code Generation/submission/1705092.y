%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<string>
#include<fstream>
#include<sstream>
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
ofstream codeFile;
//ofstream optimizedCodeFile;

int bucketSize = 30;
int errorCount = 0;
SymbolTable symbolTable(bucketSize);
//vector<SymbolInfo*>* siVectorTemp = new vector<SymbolInfo*>();

bool isEnterValid = true;
bool isExited = false;
int forcedLineNo = 1;
bool funcInserted = false;

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

int labelCount = 0;
int tempCount = 0;

bool mainFound = false;
bool printCall = false;

string returnLabel;
string finalAsmCode = ".MODEL SMALL\n\n.STACK 100H\n\n";
string dataSegment = ".DATA\n";
string printlnDef = "\n" + (string)"PRINTLN PROC" + "\n"
				  + "\t" + "PUSH BP" + "\n"
				  + "\t" + "MOV BP, SP" + "\n"
				  + "\t" + "PUSH AX" + "\n"
				  + "\t" + "PUSH BX" + "\n"
				  + "\t" + "PUSH CX" + "\n"
				  + "\t" + "PUSH DX" + "\n\n"
				  + "\t" + "MOV AX, [BP + 4]" + "\n"
				  + "\t" + "XOR CX, CX" + "\n"
				  + "\t" + "MOV BX, 10" + "\n\n"
				  + "\t" + "CMP AX, 0" + "\n"
				  + "\t" + "JGE DIV_REPEAT" + "\n"
				  + "\t" + "MOV DL, '-'" + "\n"
				  + "\t" + "MOV AH, 02H" + "\n"
				  + "\t" + "INT 21H" + "\n"
				  + "\t" + "MOV AX, [BP + 4]" + "\n"
				  + "\t" + "NEG AX" + "\n"
				  + "DIV_REPEAT" + ":" + "\n"
				  + "\t" + "XOR DX, DX" + "\n"
				  + "\t" + "DIV BX" + "\n"
				  + "\t" + "PUSH DX" + "\n"
				  + "\t" + "INC CX" + "\n\n"
				  + "\t" + "AND AX, AX" + "\n"
				  + "\t" + "JNZ DIV_REPEAT" + "\n"
				  + ";Show Digit from stack" + "\n"
				  + "POP_STACK" + ":" + "\n"
				  + "\t" + "POP DX" + "\n"
				  + "\t" + "OR DL, 30H" + "\n"
				  + "\t" + "MOV AH, 02H" + "\n"
				  + "\t" + "INT 21H" + "\n"
				  + "\t" + "LOOP POP_STACK" + "\n\n"
				  + "\t" + "MOV AH, 02H" + "\n"
				  + "\t" + "MOV DL, 0AH" + "\n"
				  + "\t" + "INT 21H" + "\n"
				  + "\t" + "MOV DL, 0DH" + "\n"
				  + "\t" + "INT 21H" + "\n\n"
				  + "\t" + "POP DX" + "\n"
				  + "\t" + "POP CX" + "\n"
				  + "\t" + "POP BX" + "\n"
				  + "\t" + "POP AX" + "\n"
				  + "\t" + "POP BP" + "\n"
				  + "\t" + "RET 2" + "\n"
				  + "PRINTLN ENDP" + "\n";

string newLabel()
{
    string str = "Label";
    str = str + "_" + to_string(labelCount++);
    return str;
}

vector <string> tempVarList{(string)"temp" + (string)"_" + to_string(tempCount++)};

string newTemp()
{
	//cout<<"newTemp called"<<endl;
	string str = tempVarList.back();
	tempVarList.pop_back();
	//cout<<"popped temp : "<<str<<endl;
	if(tempVarList.size()<1){
		//cout<<"new popped. inserting in DS : " << str <<endl;
		dataSegment = dataSegment + "\t" + str + "\t" + "DW" + "\t" + "?" + "\n";
		//cout<<"pushing new : "<<"temp_"<<tempCount<<endl;
		tempVarList.push_back((string)"temp" + (string)"_" + to_string(tempCount++));
	}
	//cout<<endl;
	return str;
}

void tempPushBack(string str){
	if(str.length() > 5){
		//temp_ -> 5
		if(str.compare(0,5,(string)"temp_") == 0){
			//temp found
			tempVarList.push_back(str);
			cout << "Line " << yylineno << " : ";
			cout << "tempVar pushBack : " << str << endl;
		}
	}
}

bool checkMovOp(string a1, string a2, string b1, string b2)
{
	if((a1 == b1 && a2 == b2) || (a1 == b2 && a2 == b1)){
		return true;
	}
	else{
		return false;
	}
}

void optimizeCode(string filepath)
{
	ifstream oldFile;
	ofstream newFile;
	oldFile.open(filepath);
	newFile.open("optimized_code.asm");
	int lineCount = 0;
	bool movFound = false;
	bool ignoreLine = false;
	string mov11, mov12, mov21, mov22;
	string line, word1 = "";
	getline(oldFile,line);
	lineCount++;
	while(!oldFile.eof()){
		stringstream ss(line);
		ss >> word1;
		if(word1 != "" && word1[0] != ';'){
			if(word1 == "MOV"){
				if(movFound){
					//consecutive move
					getline(ss, mov21, ',');
					getline(ss, mov22);
					ignoreLine = checkMovOp(mov11, mov12, mov21, mov22);
					mov11 = mov21;
					mov12 = mov22;
				}
				else{
					movFound = true;
					getline(ss, mov11, ',');
					getline(ss, mov12);
				}
			}
			else{
				movFound = false;
			}
		}
		if(ignoreLine){
			ignoreLine = false;
			cout<<"Line " << lineCount <<" skipped : "<<line<<endl;
		}
		else{
			newFile<<line<<endl;
		}
		getline(oldFile, line);
		lineCount++;
		word1 = "";
    }
	newFile<<line;
	oldFile.close();
	newFile.close();
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
			
			/*asm code block*/
			$$->setAsmName($1->getAsmName());
			$$->asmCode = $1->asmCode;
			
			if(errorCount == 0){
				finalAsmCode = finalAsmCode + dataSegment
							 + "\n" + ".CODE" + "\n"
							 + printlnDef + "\n"
							 + $$->asmCode + "\n";
				if(mainFound){
					finalAsmCode = finalAsmCode + "END main";
				}
				else{
					cout<<"Warning!!! main proc not found."<<endl;
				}
				
				//file write
				codeFile << finalAsmCode;
			}
			/****************/
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
			
			/*asm code block*/
			$$->setAsmName($1->getAsmName());
			$$->asmCode = $1->asmCode + $2->asmCode;
			/****************/
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
			
			/*asm code block*/
			$$->setAsmName($1->getAsmName());
			$$->asmCode = $1->asmCode;
			/****************/
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
		
		/*asm code block*/
		$$->setAsmName($1->getAsmName());
		$$->asmCode = $1->asmCode;
		/****************/
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
		
		/*asm code block*/
		$$->setAsmName($1->getAsmName());
		$$->asmCode = $1->asmCode;
		/****************/
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
		
		/*asm code block*/
		$$->setAsmName($1->getAsmName());
		$$->asmCode = $1->asmCode;
		/****************/
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
						isExited = true;
					}

dummy_forced_line : {
						forcedLineNo = yylineno;
					}

func_declaration : type_specifier ID LPAREN parameter_list RPAREN {
	$2->setSpecifiedType("function");
	$2->setAsmName($2->getName());
	$2->setReturnType($1->getReturnType());
	$2->setParameterList(new vector<SymbolInfo*>());
	*$2->getParameterList() = *$4->getParameterList();
	$2->setDefined(false);
	funcInserted = symbolTable.insertSymbol($2);	//will not push if already there
	symbolTable.enterScope();
	isEnterValid = false;
	isExited = false;
	for(int i=0; i<$4->getParameterList()->size(); i++){
		if($4->getParameterList()->at(i)->getType() != "type_specifier"){
			bool inserted = symbolTable.insertSymbol($4->getParameterList()->at(i));
			if(!inserted){
				errorPrint("Multiple declaration of " + $4->getParameterList()->at(i)->getName());
				errorCount++;
			}
		}
	}
} dummy_forced_line SEMICOLON dummy_exit_no_brace	{
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $4->getName() + ");\n", "func_declaration");
					$$->setSpecifiedType($2->getSpecifiedType());
					$$->setReturnType($2->getReturnType());
					$$->setParameterList(new vector<SymbolInfo*>());
					*$$->getParameterList() = *$2->getParameterList();
					$$->setDefined($2->getDefined());

					ruleMathcedPrint("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
					matchedCodePrint($$->getName());

					//check func
					SymbolInfo* foundSymbol = symbolTable.lookUpCurrentScope($2->getName());
					
					if(funcInserted){
						//new function
						//symbolTable.insertSymbol($2);
					}
					else{
						errorPrint("Multiple declaration of " + foundSymbol->getName(), forcedLineNo);
						errorCount++;
					}
				}
				 | type_specifier ID LPAREN RPAREN dummy_forced_line SEMICOLON	{
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();\n", "func_declaration");
					$2->setSpecifiedType("function");
					$2->setAsmName($2->getName());
					$$->setSpecifiedType($2->getSpecifiedType());
					$2->setReturnType($1->getReturnType());
					$$->setReturnType($2->getReturnType());
					$2->setParameterList(new vector<SymbolInfo*>());
					$$->setParameterList(new vector<SymbolInfo*>());
					$2->setDefined(false);
					$$->setDefined($2->getDefined());
					
					
					ruleMathcedPrint("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON");
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
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN {
	returnLabel = "Return_" + $2->getName();
	$2->setSpecifiedType("function");
	$2->setAsmName($2->getName());
	$2->setReturnType($1->getReturnType());
	$2->setParameterList(new vector<SymbolInfo*>());
	*$2->getParameterList() = *$4->getParameterList();
	$2->setDefined(true);
	funcInserted = symbolTable.insertSymbol($2);	//will not push if already there
	
	symbolTable.enterScope();
	isEnterValid = false;
	isExited = false;
	
	for(int i=0; i<$4->getParameterList()->size(); i++){
		if($4->getParameterList()->at(i)->getType() != "type_specifier"){
			bool inserted = symbolTable.insertSymbol($4->getParameterList()->at(i));
			if(!inserted){
				errorPrint("Multiple declaration of " + $4->getParameterList()->at(i)->getName());
				errorCount++;
			}
			else{
				/*asm code block*/
				$4->getParameterList()->at(i)->setAsmName("[BP + " + to_string(4 + i+i) + "]");
				/****************/
			}
		}
	}
} dummy_forced_line compound_statement dummy_exit_no_brace	{
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $4->getName() + ")" + $8->getName() + "\n", "func_definition");
					$$->setSpecifiedType($2->getSpecifiedType());
					$$->setReturnType($2->getReturnType());
					$$->setParameterList(new vector<SymbolInfo*>());
					*$$->getParameterList() = *$2->getParameterList();
					$$->setDefined($2->getDefined());
					
					ruleMathcedPrint("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");
					matchedCodePrint($$->getName());

					//check func
					bool noError = true;
					SymbolInfo* foundSymbol = symbolTable.lookUpCurrentScope($2->getName());
					
					if(funcInserted){
						//new function
						//symbolTable.insertSymbol($2);
					}
					else{
						//check if func
						if(foundSymbol->getSpecifiedType() == "function"){
							if(!foundSymbol->getDefined()){
								//only declared. check type
								if($2->getReturnType() != foundSymbol->getReturnType()){
									errorPrint("Return type mismatch with declaration of function " + foundSymbol->getName(), forcedLineNo);
									errorCount++;
									noError = false;
								}
								else if($2->getParameterList()->size() != foundSymbol->getParameterList()->size()){
									errorPrint("Number of arguments mismatch with declaration of function " + foundSymbol->getName(), forcedLineNo);
									errorCount++;
									noError = false;
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
											noError = false;
											foundSymbol->setDefined(false);
										}
									}
								}
							}
							else{
								//multiple definition
								errorPrint("Multiple definition of " + foundSymbol->getName(), forcedLineNo);
								errorCount++;
								noError = false;
							}
						}
						else{
							//not a func
							errorPrint("Multiple declaration of " + foundSymbol->getName(), forcedLineNo);
							errorCount++;
							noError = false;
						}
					}
					if(noError){
						/*asm code block*/
						string asmCodeSection = "";
						if($2->getName() == "main"){
							//main function
							mainFound = true;
							asmCodeSection = asmCodeSection + "\n" + "main PROC" + "\n"
											+ "\t" + "MOV AX, @DATA" + "\n"
											+ "\t" + "MOV DS, AX" + "\n"
											+ $8->asmCode + "\n"
											+ returnLabel + ":" + "\n"
											+ "\t" + "MOV AH, 4CH" + "\n"
											+ "\t" + "INT 21H" + "\n"
											+ "main ENDP" + "\n";
						}
						else{
							asmCodeSection = asmCodeSection +  "\n" + $2->getName() + " PROC" + "\n"
											+ "\t" + "PUSH BP" + "\n"
											+ "\t" + "MOV BP, SP" + "\n"
											+ "\t" + "PUSH AX" + "\n"
											+ "\t" + "PUSH BX" + "\n"
											+ $8->asmCode + "\n"
											+ returnLabel + ":" + "\n"
											+ "\t" + "POP BX" + "\n"
											+ "\t" + "POP AX" + "\n"
											+ "\t" + "POP BP" + "\n"
											+ "\t" + "RET " + to_string($2->getParameterList()->size() + $2->getParameterList()->size()) + "\n"
											+ $2->getName() + " ENDP" + "\n";
						}
						$$->asmCode = asmCodeSection;
						/****************/
					}
				}
				| type_specifier ID LPAREN RPAREN dummy_forced_line {
					returnLabel = "Return_" + $2->getName();
					$2->setSpecifiedType("function");
					$2->setAsmName($2->getName());
					$2->setReturnType($1->getReturnType());
					$2->setParameterList(new vector<SymbolInfo*>());
					$2->setDefined(true);
					funcInserted = symbolTable.insertSymbol($2);	//will not push if already there
				} compound_statement	{
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "()" + $7->getName() + "\n", "func_definition");
					$$->setSpecifiedType($2->getSpecifiedType());
					$$->setReturnType($2->getReturnType());
					$$->setParameterList(new vector<SymbolInfo*>());
					$$->setDefined($2->getDefined());

					ruleMathcedPrint("func_definition : type_specifier ID LPAREN RPAREN compound_statement");
					matchedCodePrint($$->getName());

					//check func
					bool noError = true;
					SymbolInfo* foundSymbol = symbolTable.lookUpCurrentScope($2->getName());
					
					if(funcInserted){
						//new function
						//symbolTable.insertSymbol($2);
					}
					else{
						//check if func
						if(foundSymbol->getSpecifiedType() == "function"){
							if(!foundSymbol->getDefined()){
								//only declared. check type
								if($2->getReturnType() != foundSymbol->getReturnType()){
									errorPrint("Return type mismatch with declaration of function " + foundSymbol->getName(), forcedLineNo);
									errorCount++;
									noError = false;
								}
								else if($2->getParameterList()->size() != foundSymbol->getParameterList()->size()){
									errorPrint("Number of arguments mismatch with declaration of function " + foundSymbol->getName(), forcedLineNo);
									errorCount++;
									noError = false;
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
											noError = false;
										}
									}
								}
							}
							else{
								//multiple definition
								errorPrint("Multiple definition of " + foundSymbol->getName(), forcedLineNo);
								errorCount++;
								noError = false;
							}
						}
						else{
							//not a func
							errorPrint("Multiple declaration of " + foundSymbol->getName(), forcedLineNo);
							errorCount++;
							noError = false;
						}
					}
					if(noError){
						/*asm code block*/
						string asmCodeSection = "";
						if($2->getName() == "main"){
							//main function
							mainFound = true;
							asmCodeSection = asmCodeSection +  "\n" + "main PROC" + "\n"
											+ "\t" + "MOV AX, @DATA" + "\n"
											+ "\t" + "MOV DS, AX" + "\n"
											+ $7->asmCode + "\n"
											+ returnLabel + ":" + "\n"
											+ "\t" + "MOV AH, 4CH" + "\n"
											+ "\t" + "INT 21H" + "\n"
											+ "main ENDP" + "\n";
						}
						else{
							asmCodeSection = asmCodeSection +  "\n" + $2->getName() + " PROC" + "\n"
											+ "\t" + "PUSH BP" + "\n"
											+ "\t" + "MOV BP, SP" + "\n"
											+ "\t" + "PUSH AX" + "\n"
											+ "\t" + "PUSH BX" + "\n"
											+ $7->asmCode + "\n"
											+ returnLabel + ":" + "\n"
											+ "\t" + "POP BX" + "\n"
											+ "\t" + "POP AX" + "\n"
											+ "\t" + "POP BP" + "\n"
											+ "\t" + "RET" + "\n"
											+ $2->getName() + " ENDP" + "\n";
						}
						$$->asmCode = asmCodeSection;
						/****************/
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
						
						/*asm code block*/
						$$->setAsmName($3->getAsmName());
						$$->asmCode = $3->asmCode;
						/****************/
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
							else{
								/*asm code block*/
								$2->getParameterList()->at(i)->setAsmName($2->getParameterList()->at(i)->getName() + "_" + symbolTable.getCurrentScopeID());

								if($2->getParameterList()->at(i)->getSpecifiedType() == "array"){
									dataSegment = dataSegment + "\t" + $2->getParameterList()->at(i)->getAsmName() + "\t" + "DW" + "\t" + to_string($2->getParameterList()->at(i)->getArrSize()) + " DUP (?)" + "\n";
								}
								else{
									dataSegment = dataSegment + "\t" + $2->getParameterList()->at(i)->getAsmName() + "\t" + "DW" + "\t" + "?" + "\n";
								}
								/****************/
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
					$3->setAsmName($3->getName());
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
					$3->setAsmName($3->getName());
					$3->setArrSize(stoi($5->getName()));
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
					$1->setAsmName($1->getName());
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
					$1->setAsmName($1->getName());
					$1->setArrSize(stoi($3->getName()));
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
				
				/*asm code block*/
				$$->setAsmName($1->getAsmName());
				$$->asmCode = $1->asmCode;
				/****************/
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
				
				/*asm code block*/
				$$->setAsmName($1->getAsmName());
				$$->asmCode = $1->asmCode + $2->asmCode;
				/****************/
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
				
				/*asm code block*/
				$$->setAsmName($1->getAsmName());
				$$->asmCode = $1->asmCode;
				/****************/
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
				
				/*asm code block*/
				$$->setAsmName($1->getAsmName());
				$$->asmCode = $1->asmCode;
				/****************/
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
				
				/*asm code block*/
				$$->setAsmName($1->getAsmName());
				$$->asmCode = $1->asmCode;
				/****************/
			}
		  | FOR dummy_enter_no_brace LPAREN expression_statement expression_statement expression RPAREN statement dummy_exit_no_brace	{
				$$ = new SymbolInfo("for(" + $4->getName() + $5->getName() + $6->getName() + ")" + $8->getName(),"statement");
				$$->setSpecifiedType("for");
				$$->setParameterList(new vector<SymbolInfo*>());
				
				ruleMathcedPrint("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
				matchedCodePrint($$->getName());
				
				/*asm code block*/
				string LabelCheck = newLabel();
				string LabelOut = newLabel();
				
				string asmCodeSection = $4->asmCode;
				asmCodeSection = asmCodeSection + "\n" + LabelCheck + ":" + "\n"
								+ $5->asmCode + "\n"
								+ "\t" + "MOV AX, " + $5->getAsmName() + "\n"
								+ "\t" + "CMP AX, 0" + "\n"
								+ "\t" + "JE " + LabelOut + "\n"
								+ "\t" + $8->asmCode + $6->asmCode + "\n"
								+ "\t" + "JMP " + LabelCheck + "\n"
								+ LabelOut + ":" + "\n";
				//temp_var
				tempPushBack($5->getAsmName());

				$$->setAsmName($8->getAsmName());
				$$->asmCode = asmCodeSection;
				/****************/
			}
		  | IF dummy_enter_no_brace LPAREN expression RPAREN statement dummy_exit_no_brace	%prec LOWER_THAN_ELSE	{
				$$ = new SymbolInfo("if(" + $4->getName() + ")" + $6->getName(), "statement");
				$$->setSpecifiedType("if");
				$$->setParameterList(new vector<SymbolInfo*>());
				
				ruleMathcedPrint("statement : IF LPAREN expression RPAREN statement");
				matchedCodePrint($$->getName());
				
				/*asm code block*/
				string LabelOut = newLabel();
				
				string asmCodeSection = $4->asmCode;
				asmCodeSection = asmCodeSection + "\n\t" + "MOV AX, " + $4->getAsmName() + "\n"
								+ "\t" + "CMP AX, 0" + "\n"
								+ "\t" + "JE " + LabelOut + "\n"
								+ "\t" + $6->asmCode + "\n"
								+ LabelOut + ":" + "\n";
								
				//temp_var
				tempPushBack($4->getAsmName());

				$$->setAsmName($6->getAsmName());
				$$->asmCode = asmCodeSection;
				/****************/
			}
		  | IF dummy_enter_no_brace LPAREN expression RPAREN statement dummy_exit_no_brace ELSE dummy_enter_no_brace statement dummy_exit_no_brace	{
				$$ = new SymbolInfo("if(" + $4->getName() + ")" + $6->getName() + "else" + $10->getName(),"statement");
				$$->setSpecifiedType("if_else");
				$$->setParameterList(new vector<SymbolInfo*>());
				
				ruleMathcedPrint("statement : IF LPAREN expression RPAREN statement ELSE statement");
				matchedCodePrint($$->getName());
				
				/*asm code block*/
				string LabelElse = newLabel();
				string LabelOut = newLabel();
				
				string asmCodeSection = $4->asmCode;
				asmCodeSection = asmCodeSection + "\n\t" + "MOV AX, " + $4->getAsmName() + "\n"
								+ "\t" + "CMP AX, 0" + "\n"
								+ "\t" + "JE " + LabelElse + "\n"
								+ "\t" + $6->asmCode + "\n"
								+ "\t" + "JMP " + LabelOut + "\n"
								+ LabelElse + ":" + "\n"
								+ "\t" + $10->asmCode + "\n"
								+ LabelOut + ":" + "\n";

				//temp_var
				tempPushBack($4->getAsmName());
				
				$$->setAsmName($6->getAsmName());
				$$->asmCode = asmCodeSection;
				/****************/
			}
		  | WHILE dummy_enter_no_brace LPAREN expression RPAREN statement dummy_exit_no_brace	{
				$$ = new SymbolInfo("while(" + $4->getName() + ")" + $6->getName(),"statement");
				$$->setSpecifiedType("while");
				$$->setParameterList(new vector<SymbolInfo*>());
				
				ruleMathcedPrint("statement : WHILE LPAREN expression RPAREN statement");
				matchedCodePrint($$->getName());
				
				/*asm code block*/
				string LabelCheck = newLabel();
				string LabelOut = newLabel();
				
				string asmCodeSection = "";
				asmCodeSection = asmCodeSection + "\n" + LabelCheck + ":" + "\n"
								+ $4->asmCode + "\n"
								+ "\t" + "MOV AX, " + $4->getAsmName() + "\n"
								+ "\t" + "CMP AX, 0" + "\n"
								+ "\t" + "JE " + LabelOut + "\n"
								+ "\t" + $6->asmCode + "\n"
								+ "\t" + "JMP " + LabelCheck + "\n"
								+ LabelOut + ":" + "\n";

				//temp_var
				tempPushBack($4->getAsmName());
				
				$$->setAsmName($6->getAsmName());
				$$->asmCode = asmCodeSection;
				/****************/
			}
		  | PRINTLN LPAREN ID RPAREN SEMICOLON	{
				$$ = new SymbolInfo("printf(" + $3->getName() + ");\n","statement");
				$$->setParameterList(new vector<SymbolInfo*>());
				$3->setSpecifiedType("variable");
				$3->setAsmName($3->getName());
				$3->setReturnType("int");	//default type
	
				SymbolInfo* foundSymbol = symbolTable.lookUpSymbol($3->getName());
				if(foundSymbol == nullptr){
					errorPrint("Undeclared variable " + $3->getName());
					errorCount++;
				}
				else if(foundSymbol->getSpecifiedType() != $3->getSpecifiedType()){
					errorPrint("Type mismatch. " + foundSymbol->getName() + " is a " + foundSymbol->getSpecifiedType());
					errorCount++;
					$3->setSpecifiedType(foundSymbol->getSpecifiedType());
				}
				else{
					/*asm code block*/
					printCall = true;
					$$->setAsmName("");
					
					string asmCodeSection = "";
					asmCodeSection = asmCodeSection + "\n\t" + "PUSH " + foundSymbol->getAsmName() + "\n"
									+ "\t" + "CALL PRINTLN" + "\n";

					$$->asmCode = asmCodeSection;
					/****************/
				}
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
				else{
					/*asm code block*/
					string asmCodeSection = $2->asmCode;
					asmCodeSection = asmCodeSection + "\n\t" + "MOV DX, " + $2->getAsmName() + "\n"
									+ "\t" + "JMP " + returnLabel + "\n";
					
					//temp_var
					//tempPushBack($2->getAsmName());
					
					$$->setAsmName($2->getAsmName());
					$$->asmCode = asmCodeSection;
					/****************/
				}
			}
		  ;
	  
expression_statement : SEMICOLON	{
						$$ = new SymbolInfo(";\n", "expression_statement");
						
						$$->setParameterList(new vector<SymbolInfo*>());

						ruleMathcedPrint("expression_statement : SEMICOLON");
						matchedCodePrint($$->getName());
						
						/*asm code block*/
						$$->setAsmName("1");
						$$->asmCode = "";
						/****************/
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
						
						/*asm code block*/
						$$->setAsmName($1->getAsmName());
						string asmCodeSection = "\n;" + to_string(yylineno) + ": " + $$->getName() + $1->asmCode;	//comment for asmCode
						$$->asmCode = asmCodeSection;
						/****************/
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
				
				/*asm code block*/
				$1->setAsmName(foundSymbol->getAsmName());
				$1->asmCode = foundSymbol->asmCode;

				$$->setAsmName($1->getAsmName());
				$$->asmCode = $1->asmCode;
				/****************/
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
			
			bool noError = true;
			if(foundSymbol == nullptr){
				errorPrint("Undeclared variable " + $1->getName());
				errorCount++;
				noError = false;
			}
			else if(foundSymbol->getSpecifiedType() != $$->getSpecifiedType()){
				errorPrint("Type mismatch. " + foundSymbol->getName() + " is a " + foundSymbol->getSpecifiedType());
				errorCount++;
				noError = false;
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
				noError = false;
			}
			if($3->getReturnType() != "int"){
				errorPrint("Expression inside third brackets not an integer : " + $3->getName());
				errorCount++;
				noError = false;
			}
			
			if(noError){
				/*asm code block*/
				$1->setAsmName(foundSymbol->getAsmName());
				$1->asmCode = foundSymbol->asmCode;
				
				string asmCodeSection = $1->asmCode + $3->asmCode;
				asmCodeSection = asmCodeSection + "\n\t" + "MOV BX, " + $3->getAsmName() + "\n"
								+ "\t" + "ADD BX, BX" + "\n";	//2 byte
				
				//temp_var
				//tempPushBack($3->getAsmName());
				
				$$->setAsmName($1->getAsmName());
				$$->asmCode = asmCodeSection;
				/****************/
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
				
				/*asm code block*/
				$$->setAsmName($1->getAsmName());
				$$->asmCode = $1->asmCode;
				/****************/
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
				
				bool noError = true;
				if($3->getReturnType() == "void"){
					errorPrint("Void function used in expression : " + $3->getName());
					errorCount++;
					noError = false;
				}
				else if($1->getReturnType() != $3->getReturnType()){
					if($1->getReturnType() != "float" || $3->getReturnType() != "int"){
						//int to float -> convert ok
						errorPrint("Type mismatch in assignment");
						errorCount++;
						noError = false;
					}
				}
				if(noError){
					/*asm code block*/
					// string tempVar = newTemp();
					// dataSegment = dataSegment + "\t" + tempVar + "\t" + "DW" + "\t" + "?" + "\n";
					
					string variable;
					if($1->getSpecifiedType() == "array"){
						variable = $1->getAsmName() + "[BX]";
					}
					else{
						variable = $1->getAsmName();
					}
					
					string asmCodeSection = $3->asmCode + $1->asmCode;
					asmCodeSection = asmCodeSection + "\n\t" + "MOV AX, " + $3->getAsmName() + "\n"
									+ "\t" + "MOV " + variable + ", AX" + "\n";

					//temp_var
					tempPushBack($3->getAsmName());
					
					$$->setAsmName(variable);
					$$->asmCode = asmCodeSection;
					/****************/
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
					
					/*asm code block*/
					$$->setAsmName($1->getAsmName());
					$$->asmCode = $1->asmCode;
					/****************/
				}
				 | rel_expression LOGICOP rel_expression	{
					$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "logic_expression");
					$$->setSpecifiedType($1->getSpecifiedType());
					$$->setReturnType("int");
					$$->setParameterList(new vector<SymbolInfo*>());

					ruleMathcedPrint("logic_expression : rel_expression LOGICOP rel_expression");
					matchedCodePrint($$->getName());
					
					bool noError = true;
					if($1->getReturnType() == "void"){
						errorPrint("Void function used in expression : " + $1->getName());
						errorCount++;
						noError = false;
					}
					if($3->getReturnType() == "void"){
						errorPrint("Void function used in expression : " + $3->getName());
						errorCount++;
						noError = false;
					}
					if(noError){
						/*asm code block*/
						string Label1 = newLabel();
						string LabelOut = newLabel();
						
						string tempVar = newTemp();
						
						string relJump, valStore, valStoreAlt;
						if($2->getName() == "&&"){
							relJump = "JE";
							valStore = "1";
							valStoreAlt = "0";
						}
						else{
							relJump = "JNE";
							valStore = "0";
							valStoreAlt = "1";
						}
						
						string asmCodeSection = $1->asmCode + $3->asmCode;
						asmCodeSection = asmCodeSection + "\n\t" + "MOV AX, " + $1->getAsmName() + "\n"
										+ "\t" + "CMP AX, 0" + "\n"
										+ "\t" + relJump + " " + Label1 + "\n"
										+ "\t" + "MOV AX, " + $3->getAsmName() + "\n"
										+ "\t" + "CMP AX, 0" + "\n"
										+ "\t" + relJump + " " + Label1 + "\n"
										+ "\n\t" + "MOV " + tempVar + ", " + valStore + "\n"
										+ "\t" + "JMP " + LabelOut + "\n"
										+ Label1 + ":" + "\n"
										+ "\t" + + "MOV " + tempVar + ", " + valStoreAlt + "\n"
										+ LabelOut + ":" + "\n";
						
						//temp_var
						//tempPushBack($1->getAsmName());
						//temp_var
						//tempPushBack($3->getAsmName());

						$$->setAsmName(tempVar);
						$$->asmCode = asmCodeSection;
						/****************/
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
					
					/*asm code block*/
					$$->setAsmName($1->getAsmName());
					$$->asmCode = $1->asmCode;
					/****************/
				}
				| simple_expression RELOP simple_expression	{
					$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "rel_expression");
					$$->setSpecifiedType($1->getSpecifiedType());
					$$->setReturnType("int");
					$$->setParameterList(new vector<SymbolInfo*>());

					ruleMathcedPrint("rel_expression : simple_expression RELOP simple_expression");
					matchedCodePrint($$->getName());
					
					bool noError = true;
					if($1->getReturnType() == "void"){
						errorPrint("Void function used in expression : " + $1->getName());
						errorCount++;
						noError = false;
					}
					if($3->getReturnType() == "void"){
						errorPrint("Void function used in expression : " + $3->getName());
						errorCount++;
						noError = false;
					}
					
					if(noError){
						/*asm code block*/
						string LabelTrue = newLabel();
						string LabelOut = newLabel();
						
						string tempVar = newTemp();
						//dataSegment = dataSegment + "\t" + tempVar + "\t" + "DW" + "\t" + "?" + "\n";
						
						string asmCodeSection = $1->asmCode + $3->asmCode;
						asmCodeSection = asmCodeSection + "\n\t" + "MOV AX, " + $1->getAsmName() + "\n"
										+ "\t" + "CMP AX, " + $3->getAsmName() + "\n";
										
						//temp_var
						//tempPushBack($1->getAsmName());
						//tempPushBack($3->getAsmName());
						
						string relJump;
						if($2->getName() == "<"){
							relJump = "JL";
						}
						else if($2->getName() == "<="){
							relJump = "JLE";
						}
						else if($2->getName() == ">"){
							relJump = "JG";
						}
						else if($2->getName() == ">="){
							relJump = "JGE";
						}
						else if($2->getName() == "=="){
							relJump = "JE";
						}
						else{
							relJump = "JNE";
						}
						
						asmCodeSection = asmCodeSection + "\t" + relJump + " " + LabelTrue + "\n"
										+ "\t" + "MOV " + tempVar + ", 0" + "\n"
										+ "\t" + "JMP " + LabelOut + "\n"
										+ LabelTrue + ":" + "\n"
										+ "\t" + + "MOV " + tempVar + ", 1" + "\n"
										+ LabelOut + ":" + "\n";
						
						$$->setAsmName(tempVar);
						$$->asmCode = asmCodeSection;
						/****************/
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
						
						/*asm code block*/
						$$->setAsmName($1->getAsmName());
						$$->asmCode = $1->asmCode;
						/****************/
					}
				  | simple_expression ADDOP term	{
						$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "simple_expression");
						$$->setSpecifiedType($1->getSpecifiedType());
						$$->setReturnType("int");
						$$->setParameterList(new vector<SymbolInfo*>());

						ruleMathcedPrint("simple_expression : simple_expression ADDOP term");
						matchedCodePrint($$->getName());
						
						bool noError = true;
						if($1->getReturnType() == "void"){
							errorPrint("Void function used in expression : " + $1->getName());
							errorCount++;
							noError = false;
						}
						if($3->getReturnType() == "void"){
							errorPrint("Void function used in expression : " + $3->getName());
							errorCount++;
							noError = false;
						}
						if($1->getReturnType() == "float" || $3->getReturnType() == "float"){
							$$->setReturnType("float");
						}
						
						if(noError){
							/*asm code block*/
							string tempVar = newTemp();
							//dataSegment = dataSegment + "\t" + tempVar + "\t" + "DW" + "\t" + "?" + "\n";
							string asmCodeSection = $1->asmCode + $3->asmCode;
							
							string addop;
							if($2->getName() == "+"){
								addop = "ADD";
							}
							else{
								addop = "SUB";
							}
							
							asmCodeSection = asmCodeSection + "\n\t" + "MOV AX, " + $1->getAsmName() + "\n"
											+ "\t" + addop + " AX, " + $3->getAsmName() + "\n"
											+ "\t" + "MOV " + tempVar + ", AX" + "\n";
											
							//temp_var
							//tempPushBack($1->getAsmName());
							//tempPushBack($3->getAsmName());
							
							$$->setAsmName(tempVar);
							$$->asmCode = asmCodeSection;
							/****************/
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
			
			/*asm code block*/
			$$->setAsmName($1->getAsmName());
			$$->asmCode = $1->asmCode;
			/****************/
		}
     |	term MULOP unary_expression	{
			$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "unary_expression");
			$$->setSpecifiedType($1->getSpecifiedType());
			$$->setParameterList(new vector<SymbolInfo*>());
			$$->setReturnType("int");

			ruleMathcedPrint("term : term MULOP unary_expression");
			matchedCodePrint($$->getName());
			
			bool noError = true;
			if($1->getReturnType() == "void"){
				errorPrint("Void function used in expression : " + $1->getName());
				errorCount++;
				noError = false;
			}
			if($3->getReturnType() == "void"){
				errorPrint("Void function used in expression : " + $3->getName());
				errorCount++;
				noError = false;
			}
			if($1->getReturnType() == "float" || $3->getReturnType() == "float"){
				$$->setReturnType("float");
			}
			if($2->getName() == "%"){
				$$->setReturnType("int");
				if($1->getReturnType() != "int" || $3->getReturnType() != "int"){
					errorPrint("Non-Integer operand on modulus operator");
					errorCount++;
					noError = false;
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
							noError = false;
						}
					}
					catch(...){
						errorPrint("Undetermined divisor");
						errorCount++;
						noError = false;
					}
				}
			}
			if(noError){
				/*asm code block*/
				string tempVar = newTemp();
				//dataSegment = dataSegment + "\t" + tempVar + "\t" + "DW" + "\t" + "?" + "\n";
				string asmCodeSection = $1->asmCode + $3->asmCode;
				
				if($2->getName() == "*"){
					asmCodeSection = asmCodeSection + "\n\t" + "MOV AX, " + $1->getAsmName() + "\n"
									+ "\t" + "MOV BX, " + $3->getAsmName() + "\n"
									+ "\t" + "IMUL BX" + "\n"
									+ "\t" + "MOV " + tempVar + ", AX" + "\n";
				}
				
				else{
					// % /
					asmCodeSection = asmCodeSection + "\n\t" + "MOV AX, " + $1->getAsmName() + "\n"
									+ "\t" + "CWD" + "\n"
									+ "\t" + "MOV BX, " + $3->getAsmName() + "\n"
									+ "\t" + "IDIV BX" + "\n";
					if($2->getName() == "%"){
						asmCodeSection = asmCodeSection + "\t" + "MOV " + tempVar + ", DX" + "\n";
					}
					else{
						// /
						asmCodeSection = asmCodeSection + "\t" + "MOV " + tempVar + ", AX" + "\n";
					}
				}
				
				//temp_var
				//tempPushBack($1->getAsmName());
				//tempPushBack($3->getAsmName());
				
				$$->setAsmName(tempVar);
				$$->asmCode = asmCodeSection;
				/****************/
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
					else{
						/*asm code block*/
						if($1->getName() == "-"){
							string tempVar = newTemp();
							//dataSegment = dataSegment + "\t" + tempVar + "\t" + "DW" + "\t" + "?" + "\n";
							
							string asmCodeSection = $2->asmCode;
							asmCodeSection = asmCodeSection + "\n\t" + "MOV AX, " + $2->getAsmName() + "\n"
											+ "\t" + "NEG AX" + "\n"
											+ "\t" + "MOV " + tempVar + ", AX" + "\n";
											
							//temp_var
							//tempPushBack($2->getAsmName());
						
							$$->setAsmName(tempVar);
							$$->asmCode = asmCodeSection;
						}
						else{
							//+
							$$->setAsmName($2->getAsmName());
							$$->asmCode = $2->asmCode;
						}
						/****************/
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
					else{
						/*asm code block*/
						string Label1 = newLabel();
						string LabelOut = newLabel();
						string tempVar = newTemp();
						//dataSegment = dataSegment + "\t" + tempVar + "\t" + "DW" + "\t" + "?" + "\n";
						
						string asmCodeSection = $2->asmCode;
						asmCodeSection = asmCodeSection + "\n\t" + "MOV AX, " + $2->getAsmName() + "\n"
										+ "\t" + "CMP AX, 0" + "\n"
										+ "\t" + "JE " + Label1 + "\n"
										+ "\t" + "MOV " + tempVar + ", 0" + "\n"
										+ "\t" + "JMP " + LabelOut + "\n"
										+ Label1 + ":" + "\n"
										+ "\t" + + "MOV " + tempVar + ", 1" + "\n"
										+ LabelOut + ":" + "\n";
										
						//temp_var
						//tempPushBack($2->getAsmName());
						
						$$->setAsmName(tempVar);
						$$->asmCode = asmCodeSection;
						/****************/
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
					
					/*asm code block*/
					$$->setAsmName($1->getAsmName());
					$$->asmCode = $1->asmCode;
					/****************/
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
			
			/*asm code block*/
			if($1->getSpecifiedType() == "array"){
				string arrVal = newTemp();
				//dataSegment = dataSegment + "\t" + arrVal + "\t" + "DW" + "\t" + "?" + "\n";
				
				string asmCodeSection = $1->asmCode;
				asmCodeSection = asmCodeSection + "\n\t" + "MOV AX, " + $1->getAsmName() + "[BX]" + "\n"
								+ "\t" + "MOV " + arrVal + ", AX" + "\n";
				$$->setAsmName(arrVal);
				$$->asmCode = asmCodeSection;
			}
			else{
				$$->setAsmName($1->getAsmName());
				$$->asmCode = $1->asmCode;
			}
			/****************/
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
			
			bool noError = true;
			if(foundSymbol == nullptr){
				errorPrint("Undeclared function " + $1->getName());
				errorCount++;
				noError = false;
				$1->setReturnType("int");
				$$->setReturnType($1->getReturnType());
			}
			else if(foundSymbol->getSpecifiedType() != $$->getSpecifiedType()){
				errorPrint(foundSymbol->getSpecifiedType() + " " + $1->getName() + " used as function");
				errorCount++;
				noError = false;
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
					noError = false;
				}
				else if($1->getParameterList()->size() > foundSymbol->getParameterList()->size()){
					errorPrint("too many arguments to function " + $1->getName());
					errorCount++;
					noError = false;
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
							noError = false;
						}
					}
				}
			}
			if(noError){
				/*asm code block*/
				$1->setAsmName(foundSymbol->getAsmName());
				$$->setAsmName($1->getAsmName());
				
				string asmCodeSection = $3->asmCode;
				asmCodeSection = asmCodeSection + "\n";
				
				for(int i=$1->getParameterList()->size()-1; i>=0; i--){
					asmCodeSection = asmCodeSection + "\t" + "PUSH " + $1->getParameterList()->at(i)->getAsmName() + "\n";
				}
				
				asmCodeSection = asmCodeSection + "\t" + "CALL " + $1->getAsmName() + "\n";
				
				if($1->getReturnType() != "void"){
					string returnVal = newTemp();
					//dataSegment = dataSegment + "\t" + returnVal + "\t" + "DW" + "\t" + "?" + "\n";
					asmCodeSection = asmCodeSection + "\t" + "MOV " + returnVal + ", DX" + "\n";
					$$->setAsmName(returnVal);
				}
				$$->asmCode = asmCodeSection;
				/****************/
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
			
			/*asm code block*/
			$$->asmCode = $2->asmCode;
			$$->setAsmName($2->getAsmName());
			/****************/
		}
		| CONST_INT	{
			$$ = new SymbolInfo($1->getName(), "factor");
			$$->setSpecifiedType("constant");
			$$->setReturnType("int");
			$$->setParameterList(new vector<SymbolInfo*>());

			ruleMathcedPrint("factor : CONST_INT");
			matchedCodePrint($$->getName());
			
			/*asm code block*/
			$$->asmCode = $1->asmCode;
			$1->setAsmName($1->getName());
			$$->setAsmName($1->getAsmName());
			/****************/
		}
		| CONST_FLOAT	{
			$$ = new SymbolInfo($1->getName(), "factor");
			$$->setSpecifiedType("constant");
			$$->setReturnType("float");
			$$->setParameterList(new vector<SymbolInfo*>());

			ruleMathcedPrint("factor : CONST_FLOAT");
			matchedCodePrint($$->getName());
			
			/*asm code block*/
			$$->asmCode = $1->asmCode;
			$1->setAsmName($1->getName());
			$$->setAsmName($1->getAsmName());
			/****************/
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
			else{
				/*asm code block*/
				string beforeIncVar = newTemp();
				//dataSegment = dataSegment + "\t" + beforeIncVar + "\t" + "DW" + "\t" + "?" + "\n";
				
				string variable;
				if($1->getSpecifiedType() == "array"){
					variable = $1->getAsmName() + "[BX]";
				}
				else{
					variable = $1->getAsmName();
				}
				
				string asmCodeSection = $1->asmCode;
				asmCodeSection = asmCodeSection + "\n\t" + "MOV AX, " + variable + "\n"
								+ "\t" + "MOV " + beforeIncVar + ", AX" + "\n"
								+ "\t" + "INC " + variable + "\n";

				$$->asmCode = asmCodeSection;
				$$->setAsmName(beforeIncVar);
				/****************/
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
			else{
				/*asm code block*/
				string beforeDecVar = newTemp();
				//dataSegment = dataSegment + "\t" + beforeDecVar + "\t" + "DW" + "\t" + "?" + "\n";
				
				string variable;
				if($1->getSpecifiedType() == "array"){
					variable = $1->getAsmName() + "[BX]";
				}
				else{
					variable = $1->getAsmName();
				}
				
				string asmCodeSection = $1->asmCode;
				asmCodeSection = asmCodeSection + "\n\t" + "MOV AX, " + variable + "\n"
								+ "\t" + "MOV " + beforeDecVar + ", AX" + "\n"
								+ "\t" + "DEC " + variable + "\n";

				$$->asmCode = asmCodeSection;
				$$->setAsmName(beforeDecVar);
				/****************/
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
					
					/*asm code block*/
					$$->asmCode = $1->asmCode;
					$$->setAsmName($1->getAsmName());
					/****************/
				}
			  |	{
					$$ = new SymbolInfo("", "arguments");
					$$->setParameterList(new vector<SymbolInfo*>());

					ruleMathcedPrint("argument_list : ");
					matchedCodePrint($$->getName());
					
					/*asm code block*/
					/****************/
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
					
					/*asm code block*/
					$$->asmCode = $1->asmCode + $3->asmCode;
					$$->setAsmName($1->getAsmName());
					/****************/
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
				else{
					$$->getParameterList()->push_back($1);	//argument list
					
					/*asm code block*/
					$$->asmCode = $1->asmCode;
					$$->setAsmName($1->getAsmName());
					/****************/
				}
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
	codeFile.open("code.asm");
	//optimizedCodeFile.open("optimized_code.asm");
 
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
	codeFile.close();
	optimizeCode("code.asm");
	//optimizedCodeFile.close();
	return 0;
}

