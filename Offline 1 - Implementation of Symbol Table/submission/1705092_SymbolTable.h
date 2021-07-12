///1705092
///309 offline 1 symbol table symboltable

#ifndef OFFLINE_1_SYMTAB_SYMTAB_H
#define OFFLINE_1_SYMTAB_SYMTAB_H


#include<iostream>
#include<cstring>

using namespace std;

class SymbolTable
{
    int total_bucket;
    ScopeTable* currentScope;
    SymbolInfo* symbol;
    int currentScopeID;
public:
    void enterScope();
    void exitScope();
    bool insertSymbol(string name, string type);
    bool removeSymbol(string name);
    SymbolInfo* lookUpSymbol(string name);
    void printCurrent();
    void printAll();

    void setTotal_bucket(int total_bucket)
    {
        this->total_bucket = total_bucket;
    }
    int getTotal_bucket()
    {
        return this->total_bucket;
    }

    SymbolTable();
    SymbolTable(int total_bucket);
    ~SymbolTable();
};

SymbolTable::SymbolTable()
{
    this->total_bucket = 1;
    this->currentScope = nullptr;
    this->currentScopeID = 0;
    this->symbol = nullptr;
    this->enterScope();
}

SymbolTable::SymbolTable(int total_bucket)
{
    this->total_bucket = total_bucket;
    this->currentScope = nullptr;
    this->currentScopeID = 0;
    this->symbol = nullptr;
    this->enterScope();
}

SymbolTable::~SymbolTable()
{
    ///write destructor
    delete this->currentScope;
    delete this->symbol;
}

void SymbolTable::enterScope()
{
    ScopeTable* temp;
    temp = this->currentScope;
    this->currentScope = new ScopeTable(this->total_bucket,this->currentScopeID+1,temp);
    this->currentScopeID = 0;
    cout<<"New ScopeTable with id "<<this->currentScope->getUniqueID()<<" created"<<endl;
}

void SymbolTable::exitScope()
{
    ScopeTable* temp;
    temp = this->currentScope;
    if(temp == nullptr)
        return;
    this->currentScopeID = (int)(temp->getUniqueID().back()-'0');
    this->currentScope = temp->getParentScope();
    cout<<"ScopeTable with id "<<temp->getUniqueID()<<" removed"<<endl;
    delete temp;
    //if(currentScope == nullptr)
    //{
        //cout<<"end of all scope"<<endl;
        //exit(1);
    //}
}

bool SymbolTable::insertSymbol(string name, string type)
{
    this->symbol = new SymbolInfo(name, type);
    return this->currentScope->insertSymbol(this->symbol);
}

bool SymbolTable::removeSymbol(string name)
{
    return this->currentScope->deleteSymbol(name);
}

SymbolInfo* SymbolTable::lookUpSymbol(string name)
{
    ScopeTable* temp;
    temp = this->currentScope;
    SymbolInfo* found;
    while(temp){
        found = temp->lookUp(name);
        if(found)
            return found;
        else
            temp = temp->getParentScope();
    }
    //not found
    cout<<"Not found"<<endl;
    return found;
}

void SymbolTable::printCurrent()
{
    this->currentScope->printTable();
}

void SymbolTable::printAll()
{
    ScopeTable* temp;
    temp = this->currentScope;
    while(temp){
        temp->printTable();
        cout<<endl;
        temp = temp->getParentScope();
    }
}

#endif //OFFLINE_1_SYMTAB_SYMTAB_H
