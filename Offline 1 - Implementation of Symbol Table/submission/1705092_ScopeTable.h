///1705092
///309 offline 1 symbol table scopetable

#ifndef OFFLINE_1_SYMTAB_SCPTAB_H
#define OFFLINE_1_SYMTAB_SCPTAB_H


#include<iostream>
#include<cstring>

using namespace std;

class ScopeTable
{
    SymbolInfo** table;
    int hashFunc(string key);
    int total_bucket;
    ScopeTable* parentScope;
    string uniqueID;
    SymbolInfo* auxLookUp(int index, string key);   ///search for prev or self if bucket head
    int position;

public:
    bool insertSymbol(SymbolInfo* element);
    SymbolInfo* lookUp(string name);
    bool deleteSymbol(string name);
    void printTable();

    void setParentScope(ScopeTable* parentScope)
    {
        this->parentScope = parentScope;
    }
    ScopeTable* getParentScope()
    {
        return this->parentScope;
    }
    void setUniqueID(string uniqueID)
    {
        this->uniqueID = uniqueID;
    }
    void setUniqueID(int ID)
    {
        if(this->parentScope){
            this->uniqueID = this->parentScope->uniqueID + "." + to_string(ID);
        }
        else
            this->uniqueID = to_string(ID);
    }
    string getUniqueID()
    {
        return this->uniqueID;
    }

    void setTotal_bucket(int total_bucket)
    {
        this->total_bucket = total_bucket;
        delete[] this->table;
        this->table = new SymbolInfo*[this->total_bucket];
        SymbolInfo* temp = nullptr;
        for(int i=0; i<this->total_bucket; i++)
        {
            this->table[i] = temp;
        }
    }

    int getTotal_bucket()
    {
        return this->total_bucket;
    }

    ScopeTable();
    ScopeTable(int total_bucket);
    ScopeTable(int total_bucket, int ID, ScopeTable* parentScope);
    ~ScopeTable();
};

ScopeTable::ScopeTable()
{
    this->total_bucket = 1;
    this->position = 0;
    this->parentScope = nullptr;
    this->uniqueID = "1";
    this->table = new SymbolInfo*[this->total_bucket];
    SymbolInfo* temp = nullptr;
    for(int i=0; i<this->total_bucket; i++)
    {
        this->table[i] = temp;
    }
}

ScopeTable::ScopeTable(int total_bucket)
{
    this->total_bucket = total_bucket;
    this->position = 0;
    this->parentScope = nullptr;
    this->uniqueID = "1";
    this->table = new SymbolInfo*[this->total_bucket];
    SymbolInfo* temp = nullptr;
    for(int i=0; i<this->total_bucket; i++)
    {
        this->table[i] = temp;
    }
}

ScopeTable::ScopeTable(int total_bucket, int ID, ScopeTable* parentScope)
{
    this->total_bucket = total_bucket;
    this->position = 0;
    this->parentScope = parentScope;
    this->setUniqueID(ID);
    this->table = new SymbolInfo*[this->total_bucket];
    SymbolInfo* temp = nullptr;
    for(int i=0; i<this->total_bucket; i++)
    {
        this->table[i] = temp;
    }
}

ScopeTable::~ScopeTable()
{
    ///destructor
    delete[] this->table;

}

int ScopeTable::hashFunc(string key)
{
    int sum_ascii = 0;
    for(char & ch : key)
    {
        sum_ascii += (int)ch;
    }
    return sum_ascii % this->total_bucket;
}

SymbolInfo* ScopeTable::auxLookUp(int index,string key)   ///search for prev or self if bucket head
{
    SymbolInfo* temp = this->table[index];
    this->position = 0;

    if(this->table[index] == nullptr)
    {
        return this->table[index];
    }
    else if(this->table[index]->getName() == key)
    {
        return this->table[index];
    }
    while(temp->getNext())
    {
        if(temp->getNext()->getName() == key)
            return temp;
        temp = temp->getNext();
        this->position++;
    }
    return temp;
}

bool ScopeTable::insertSymbol(SymbolInfo* element)
{
    int index;
    index = this->hashFunc(element->getName());
    string success_msg = "Inserted in ScopeTable# "+ this->uniqueID +" at position "+ to_string(index) +", ";
    string unsuccess_msg = " already exists in current ScopeTable";

    SymbolInfo* prev = this->auxLookUp(index, element->getName());
    if(prev == nullptr) ///new bucket
    {
        this->table[index] = element;
        this->table[index]->setNext(nullptr);

        success_msg += to_string(this->position);
        cout<<success_msg<<endl;
        return true;
    }
    else if(this->table[index]->getName() == element->getName())   ///exists in bucket head
    {
        unsuccess_msg = "<"+ this->table[index]->getName() +" : "+ this->table[index]->getType() +">" + unsuccess_msg;
        cout<<unsuccess_msg<<endl;
        return false;
    }
    else if(prev->getNext() == nullptr) ///insert at next
    {
        prev->setNext(element);
        prev->getNext()->setNext(nullptr);

        success_msg += to_string(this->position + 1);
        cout<<success_msg<<endl;
        return true;
    }
    else if(prev->getNext()->getName() == element->getName())   ///exists
    {
        unsuccess_msg = "<"+ prev->getNext()->getName() +" : "+ prev->getNext()->getType() +">" + unsuccess_msg;
        cout<<unsuccess_msg<<endl;
        return false;
    }
    else
    {
        cout<<"throw error in insert of scope table"<<endl;
        return false;
    }
}

SymbolInfo* ScopeTable::lookUp(string name)
{
    int index;
    index = this->hashFunc(name);

    string success_msg = "Found in ScopeTable# "+ this->uniqueID +" at position "+ to_string(index) +", ";
    string unsuccess_msg = "Not found";

    SymbolInfo* prev = this->auxLookUp(index, name);
    if(prev == nullptr) ///bucket empty
    {
        //cout<<unsuccess_msg<<endl;
        return prev;
    }
    else if(this->table[index]->getName() == name)   ///exists in bucket head
    {
        success_msg += to_string(this->position);
        cout<<success_msg<<endl;
        return this->table[index];
    }
    else if(prev->getNext() == nullptr)   ///not in chain, not found
    {
        //cout<<unsuccess_msg<<endl;
        return nullptr;
    }
    else if(prev->getNext()->getName() == name)    ///exists
    {
        success_msg += to_string(this->position + 1);
        cout<<success_msg<<endl;
        return prev->getNext();
    }
    else
    {
        cout<<"throw error in lookup of scope table"<<endl;
        return nullptr;
    }
}

bool ScopeTable::deleteSymbol(string name)
{
    int index;
    index = this->hashFunc(name);

    string success_msg_1 = "Deleted Entry  "+ to_string(index) +", ";
    string success_msg_2 = " from current ScopeTable";
    string unsuccess_msg = name +" Not found";

    SymbolInfo* prev = this->auxLookUp(index, name);
    if(prev == nullptr) ///bucket empty
    {
        cout<<unsuccess_msg<<endl;
        return false;
    }
    else if(this->table[index]->getName() == name)   ///exists in bucket head
    {
        this->table[index] = this->table[index]->getNext(); ///can be nullptr
        cout<<success_msg_1<<this->position<<success_msg_2<<endl;
        return true;
    }
    else if(prev->getNext() == nullptr)   ///not in chain, not found
    {
        cout<<unsuccess_msg<<endl;
        return false;
    }
    else if(prev->getNext()->getName() == name)    ///exists
    {
        SymbolInfo* temp = prev->getNext()->getNext();  ///can be nullptr
        prev->setNext(temp);
        cout<<success_msg_1<<this->position+1<<success_msg_2<<endl;
        return true;
    }
    else
    {
        cout<<"throw error in delete of scope table"<<endl;
        return false;
    }
}

void ScopeTable::printTable()
{
    SymbolInfo* temp;
    cout<<"ScopeTable# "<<this->uniqueID<<endl;
    for(int i=0; i<this->total_bucket; i++)
    {
        cout<<i<<" --> ";
        if(this->table[i])
            temp = this->table[i];
        else
        {
            cout<<endl;
            continue;
        }
        while(true)
        {
            temp->showSymbol();
            temp = temp->getNext();
            if(temp)
                cout<<"  ";
            else
                break;
        }
        cout<<endl;
    }

}

#endif //OFFLINE_1_SYMTAB_SCPTAB_H
