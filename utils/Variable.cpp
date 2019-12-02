#include "Variable.h"

Variable::Variable() {
    this->type = "undefined";
}

Variable::Variable(double n) {
    this->type = "Number";
    this->n.setValue(n);
}

Variable::Variable(int n) {
    this->type = "Number";
    this->n.setValue(n);
}

Variable::Variable(char * s){
    this->type = "String";
    string str(s);
    this->s.setValue(str);
}

Variable::Variable(map<string, Variable>& attributes){
    this->type = "Object";
    this->o = new Object();
    this->o->setValue(attributes);
}

double Variable::toNumber() {
    return n.getValue();
}

ostream& operator<<(ostream& flux, const Variable& var){
    if(var.type.compare("Number") == 0){
        flux << var.n.getValue();
    }
    else if(var.type.compare("String") == 0){
        flux << var.s.getValue();
    }
    else if(var.type.compare("Object") == 0){
        flux << var.o->toJSON();
    }

    return flux;
}

Variable operator+(Variable& a, Variable& b){
    if(a.type.compare("Number") == 0 && b.type.compare("Number") == 0){
        Variable var(a.n.getValue() + b.n.getValue());
        return var;
    }
    else if(a.type.compare("String") == 0 && b.type.compare("String") == 0){}
}

string Variable::toString(){
    if(this->type.compare("Number") == 0){
        return to_string(this->n.getValue());
    }
    else if(this->type.compare("String") == 0){
        return this->s.getValue();
    }
}

Variable operator-(Variable& a, Variable& b){
    if(a.type.compare("Number") == 0 && b.type.compare("Number") == 0){
        Variable var(a.n.getValue() - b.n.getValue());
        return var;
    }
}

Variable operator*(Variable& a, Variable& b){
    if(a.type.compare("Number") == 0 && b.type.compare("Number") == 0){
        Variable var(a.n.getValue() * b.n.getValue());
        return var;
    }
}

Variable operator/(Variable& a, Variable& b){
    if(a.type.compare("Number") == 0 && b.type.compare("Number") == 0){
        Variable var(a.n.getValue() / b.n.getValue());
        return var;
    }
}

bool operator<(Variable& a, Variable& b){
    if(a.type.compare("Number") == 0 && b.type.compare("Number") == 0){
        return a.n.getValue() < b.n.getValue();
    }
}

Variable::operator bool(){
    return n.getValue() == 0;
}

