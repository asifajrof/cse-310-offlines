///1705092
///309 offline 1 symbol table symbolinfo

#ifndef OFFLINE_1_SYMTAB_SYMINF_H
#define OFFLINE_1_SYMTAB_SYMINF_H


#include<iostream>
#include<cstring>

using namespace std;

class SymbolInfo
{
    string name, type;
    SymbolInfo* next;

public:
    void setName(string name)
    {
        this->name = name;
    }
    string getName()
    {
        return this->name;
    }
    void setType(string type)
    {
        this->type = type;
    }
    string getType()
    {
        return this->type;
    }
    void setNext(SymbolInfo* next)
    {
        this->next = next;
    }
    SymbolInfo* getNext()
    {
        return this->next;
    }
    void showSymbol()
    {
        cout<<"<";
        cout<<this->name;
        cout<<" : ";
        cout<<this->type;
        cout<<">";
    }
    void createSymbol(string name, string type)
    {
        this->name = name;
        this->type = type;
        this->next = nullptr;
    }

    SymbolInfo()
    {
        this->createSymbol("","");
    }

    SymbolInfo(string name, string type)
    {
        this->createSymbol(name,type);
    }
};

#endif //OFFLINE_1_SYMTAB_SYMINF_H
