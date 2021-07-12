#include<iostream>
#include<cstdlib>
#include<cstring>
#include<string>
#include<fstream>
#include<vector>
using namespace std;
int labelCount = 0;
int tempCount = 0;

string newLabel()
{
    string str = "Label";
    str = str + "_" + to_string(labelCount++);
    return str;
}

string newTemp()
{
    string str = "temp";
    str = str + "_" + to_string(tempCount++);
    return str;
}

int foo(int, int){
	return 0;
}

int main()
{
	cout<<newLabel()<<endl;
	cout<<newLabel()<<endl;
	cout<<newTemp()<<endl;
	cout<<newTemp()<<endl;
	cout<<newLabel()<<endl;
	cout<<newLabel()<<endl;
	cout<<newTemp()<<endl;
	cout<<newTemp()<<endl;
	string a = "";
	a = a + "abcd" + "\n"
	+ "\t" + "def" + "\n";
	cout <<a;
	string abc = "10";
	int number = stoi(abc);
	cout<<number<<endl;
	foo(1,2);

	string printlnDef = (string)"PRINTLN PROC" + "\n"
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
	cout<<endl<<endl<<endl;
	cout<<printlnDef;
	return 0;
}