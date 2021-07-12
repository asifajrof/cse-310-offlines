///1705092
///symboltable

#ifndef OFFLINE_1_SYMTAB_SYMTAB_H
#define OFFLINE_1_SYMTAB_SYMTAB_H


#include<iostream>
#include<cstring>
#include<cstdio>
#include<fstream>
#include<vector>

using namespace std;

/*string defSpecifiedType(string type){
	if(type == "CONST_INT")	type = "INT";
	else if(type == "CONST_FLOAT")	type = "FLOAT";
	else if(type == "CONST_CHAR")	type = "CHAR";
	else if(type == "" || type == nullptr)	type = "VOID";
	else type = type;
	return type;
}*/

class SymbolInfo
{
    string name, type, specifiedType, returnType, asmName;
    SymbolInfo* next;
	vector<SymbolInfo*>* parameterList;
	//bool isDeclared;
	bool isDefined;
	int arrSize;

public:
	string asmCode;
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
	void setSpecifiedType(string specifiedType)
    {
        this->specifiedType = specifiedType;
    }
    string getSpecifiedType()
    {
        return this->specifiedType;
    }
	void setReturnType(string returnType)
    {
        this->returnType = returnType;
    }
    string getReturnType()
    {
        return this->returnType;
    }
	void setAsmName(string asmName)
    {
        this->asmName = asmName;
    }
    string getAsmName()
    {
        return this->asmName;
    }
	void setArrSize(int arrSize)
    {
        this->arrSize = arrSize;
    }
    int getArrSize()
    {
        return this->arrSize;
    }
    void setNext(SymbolInfo* next)
    {
        this->next = next;
    }
    SymbolInfo* getNext()
    {
        return this->next;
    }
	void setParameterList(vector<SymbolInfo*>* parameterList)
    {
        this->parameterList = parameterList;
    }
    vector<SymbolInfo*>* getParameterList()
    {
        return this->parameterList;
    }
	//void setDeclared(bool tf){
		//this->isDeclared = tf;
	//}
	//bool getDeclared(){
		//return this->isDeclared;
	//}
	void setDefined(bool tf){
		this->isDefined = tf;
	}
	bool getDefined(){
		return this->isDefined;
	}
    void showSymbol(ofstream& fout)
    {
        fout<<"<";
        fout<<this->name;
        fout<<" : ";
        fout<<this->type;
        fout<<">";
    }
    void createSymbol(string name, string type)
    {
        this->name = name;
        this->type = type;
		this->specifiedType = type;
		this->returnType = "void";
        //this->next = nullptr;
		this->parameterList = nullptr;
		//isDeclared = false;
		this->isDefined = false;
		this->asmCode = "";
		this->asmName = "";
		this->arrSize = -1;
    }

    SymbolInfo()
    {
        this->createSymbol("","");
		//cout << "new symbol info" << endl;
    }

    SymbolInfo(string name, string type)
    {
        this->createSymbol(name,type);
		//cout << "new symbol info" << endl;
    }
	
	~SymbolInfo()
	{
		delete this->next;
		delete this->parameterList;
		//cout << "delete symbol info" << endl;
	}
};


class ScopeTable
{
    SymbolInfo** table;
	int hashFunc(string key)
	{
		int sum_ascii = 0;
		for(char & ch : key)
		{
			sum_ascii += (int)ch;
		}
		return sum_ascii % this->total_bucket;
	}
    int total_bucket;
    ScopeTable* parentScope;
    string uniqueID;
	SymbolInfo* auxLookUp(int index,string key)   ///search for prev or self if bucket head
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
    int position;

public:
    bool insertSymbol(SymbolInfo* element)
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
			//cout<<success_msg<<endl;
			return true;
		}
		else if(this->table[index]->getName() == element->getName())   ///exists in bucket head
		{
			unsuccess_msg = "<"+ this->table[index]->getName() +" : "+ this->table[index]->getType() +">" + unsuccess_msg;
			//cout<<unsuccess_msg<<endl;
			return false;
		}
		else if(prev->getNext() == nullptr) ///insert at next
		{
			prev->setNext(element);
			prev->getNext()->setNext(nullptr);

			success_msg += to_string(this->position + 1);
			//cout<<success_msg<<endl;
			return true;
		}
		else if(prev->getNext()->getName() == element->getName())   ///exists
		{
			unsuccess_msg = "<"+ prev->getNext()->getName() +" : "+ prev->getNext()->getType() +">" + unsuccess_msg;
			//cout<<unsuccess_msg<<endl;
			return false;
		}
		else
		{
			//cout<<"throw error in insert of scope table"<<endl;
			return false;
		}
	}
    SymbolInfo* lookUp(string name)
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
			//cout<<success_msg<<endl;
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
			//cout<<success_msg<<endl;
			return prev->getNext();
		}
		else
		{
			//cout<<"throw error in lookup of scope table"<<endl;
			return nullptr;
		}
	}
    bool deleteSymbol(string name)
	{
		int index;
		index = this->hashFunc(name);

		string success_msg_1 = "Deleted Entry  "+ to_string(index) +", ";
		string success_msg_2 = " from current ScopeTable";
		string unsuccess_msg = name +" Not found";

		SymbolInfo* prev = this->auxLookUp(index, name);
		if(prev == nullptr) ///bucket empty
		{
			//cout<<unsuccess_msg<<endl;
			return false;
		}
		else if(this->table[index]->getName() == name)   ///exists in bucket head
		{
			this->table[index] = this->table[index]->getNext(); ///can be nullptr
			//cout<<success_msg_1<<this->position<<success_msg_2<<endl;
			return true;
		}
		else if(prev->getNext() == nullptr)   ///not in chain, not found
		{
			//cout<<unsuccess_msg<<endl;
			return false;
		}
		else if(prev->getNext()->getName() == name)    ///exists
		{
			SymbolInfo* temp = prev->getNext()->getNext();  ///can be nullptr
			prev->setNext(temp);
			//cout<<success_msg_1<<this->position+1<<success_msg_2<<endl;
			return true;
		}
		else
		{
			//cout<<"throw error in delete of scope table"<<endl;
			return false;
		}
	}
	void printTable(ofstream& fout)
	{
		SymbolInfo* temp;
		fout<<"ScopeTable# "<<this->uniqueID<<endl;
		for(int i=0; i<this->total_bucket; i++)
		{
			if(this->table[i]){
				temp = this->table[i];
				fout<<i<<" --> ";
			}
			else
			{
				//cout<<endl;
				continue;
			}
			while(true)
			{
				temp->showSymbol(fout);
				temp = temp->getNext();
				if(temp)
					fout<<"  ";
				else
					break;
			}
			fout<<endl;
		}

	}

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
            this->uniqueID = this->parentScope->uniqueID + "_" + to_string(ID);
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

    ScopeTable()
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
    ScopeTable(int total_bucket)
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
    ScopeTable(int total_bucket, int ID, ScopeTable* parentScope)
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
	~ScopeTable()
	{
		///destructor
		delete[] this->table;

	}
};


class SymbolTable
{
    int total_bucket;
    ScopeTable* currentScope;
    SymbolInfo* symbol;
    int currentScopeID;
public:
	void enterScope()
	{
		ScopeTable* temp;
		temp = this->currentScope;
		this->currentScope = new ScopeTable(this->total_bucket,this->currentScopeID+1,temp);
		this->currentScopeID = 0;
		//cout<<"New ScopeTable with id "<<this->currentScope->getUniqueID()<<" created"<<endl;
	}
    void exitScope()
	{
		ScopeTable* temp;
		temp = this->currentScope;
		if(temp == nullptr)
			return;
		this->currentScopeID = (int)(temp->getUniqueID().back()-'0');
		this->currentScope = temp->getParentScope();
		//cout<<"ScopeTable with id "<<temp->getUniqueID()<<" removed"<<endl;
		delete temp;
		//if(currentScope == nullptr)
		//{
			//cout<<"end of all scope"<<endl;
			//exit(1);
		//}
	}
	bool insertSymbol(string name, string type)
	{
		this->symbol = new SymbolInfo(name, type);
		bool returnFlag = this->currentScope->insertSymbol(this->symbol);
		return returnFlag;
	}

	bool insertSymbol(SymbolInfo* symbol)
	{
		this->symbol = symbol;
		bool returnFlag = this->currentScope->insertSymbol(this->symbol);
		return returnFlag;
	}

	bool removeSymbol(string name)
	{
		return this->currentScope->deleteSymbol(name);
	}

	SymbolInfo* lookUpCurrentScope(string name)
	{
		return this->currentScope->lookUp(name);
	}

	SymbolInfo* lookUpSymbol(string name)
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
		//cout<<"Not found"<<endl;
		return found;
	}

	void printCurrent(ofstream& fout)
	{
		this->currentScope->printTable(fout);
	}

	void printAll(ofstream& fout)
	{
		ScopeTable* temp;
		temp = this->currentScope;
		while(temp){
			temp->printTable(fout);
			fout<<endl;
			temp = temp->getParentScope();
		}
	}

    void setTotal_bucket(int total_bucket)
    {
        this->total_bucket = total_bucket;
    }
    int getTotal_bucket()
    {
        return this->total_bucket;
    }
	
	string getCurrentScopeID()
	{
		return this->currentScope->getUniqueID();
	}

    SymbolTable()
	{
		this->total_bucket = 7;
		this->currentScope = nullptr;
		this->currentScopeID = 0;
		this->symbol = nullptr;
		this->enterScope();
	}
	SymbolTable(int total_bucket)
	{
		this->total_bucket = total_bucket;
		this->currentScope = nullptr;
		this->currentScopeID = 0;
		this->symbol = nullptr;
		this->enterScope();
	}
	~SymbolTable()
	{
		///write destructor
		delete this->currentScope;
		delete this->symbol;
	}
};

#endif //OFFLINE_1_SYMTAB_SYMTAB_H
