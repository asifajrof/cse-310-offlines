///1705092
///309 offline 1 symbol table symbolinfo

#include<iostream>
#include<cstring>

#include "1705092_SymbolInfo.h"
#include "1705092_ScopeTable.h"
#include "1705092_SymbolTable.h"
using namespace std;

int main()
{
    freopen("input.txt", "r", stdin);
    freopen("output.txt", "w", stdout);
    int total_bucket;
    cin>>total_bucket;
    SymbolTable symtab(total_bucket);
    char op;
    while(true)
    {
        cin>>op;
        if(op == 'I' || op == 'i')
        {
            string name, type;
            cin>>name>>type;
            bool flag = symtab.insertSymbol(name,type);
            cout<<endl;
        }
        else if(op == 'L' || op == 'l')
        {
            string name;
            cin>>name;
            SymbolInfo* symbol = symtab.lookUpSymbol(name);
            cout<<endl;
        }
        else if(op == 'D' || op == 'd')
        {
            string name;
            cin>>name;
            bool flag = symtab.removeSymbol(name);
            cout<<endl;
        }
        else if(op == 'P' || op == 'p')
        {
            char type;
            cin>>type;
            if(type == 'A' || type == 'a')
                symtab.printAll();
            else if(type == 'C' || type == 'c')
                symtab.printCurrent();
            else
                cout<<"Not valid input for operation"<<endl;
            cout<<endl;
        }
        else if(op == 'S' || op == 's')
        {
            symtab.enterScope();
            cout<<endl;
        }
        else if(op == 'E' || op == 'e')
        {
            symtab.exitScope();
            cout<<endl;
        }
        else if(op == 'T' || op == 't')
        {
            //cout<<"Terminating character found"<<endl;
            break;
        }
        else
            cout<<"Not valid input for operation"<<endl;
    }
    return 0;
}
