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

Variable::Variable(char * s, bool isObject){
    this->type = "Object";
    string str(s);
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

    return flux;
}

Variable operator+(Variable& a, Variable& b){
    if(a.type.compare("Number") == 0 && b.type.compare("Number") == 0){
        Variable var(a.n.getValue() + b.n.getValue());
        return var;
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

