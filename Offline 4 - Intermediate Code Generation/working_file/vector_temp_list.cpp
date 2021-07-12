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
	vector <string> temp_var;
	temp_var.push_back("temp0");
	temp_var.push_back("temp1");
	temp_var.push_back("temp2");
	temp_var.push_back("temp3");
	string a;
	cout<<temp_var.size()<<endl;
	a = temp_var.back();
	temp_var.pop_back();
	cout<<a<<endl;
	cout<<temp_var.size()<<endl;
	a = temp_var.back();
	temp_var.pop_back();
	cout<<a<<endl;
	cout<<temp_var.size()<<endl;
	a = temp_var.back();
	temp_var.pop_back();
	cout<<a<<endl;
	cout<<temp_var.size()<<endl;
	a = temp_var.back();
	temp_var.pop_back();
	cout<<a<<endl;
	cout<<temp_var.size()<<endl;
	a = temp_var.back();
	temp_var.pop_back();
	cout<<a<<endl;
	cout<<temp_var.size()<<endl;
	a = temp_var.back();
	temp_var.pop_back();
	cout<<a<<endl;
	cout<<temp_var.size()<<endl;
	a = temp_var.back();
	temp_var.pop_back();
	cout<<a<<endl;
	cout<<temp_var.size()<<endl;
	cout<<"reached\n";
	cout<<temp_var.size()<<endl;
	return 0;
}