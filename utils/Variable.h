#ifndef TP_THL_VARIABLE_H
#define TP_THL_VARIABLE_H

#include <iostream>
#include <string>
#include <map>
#include "PrimitiveTypes/Number.h"
#include "PrimitiveTypes/String.h"
#include "PrimitiveTypes/Object.h"

using namespace std;

class Object;

class Variable {
private:
    Number n;
    String s;
    string type;
    Object * o;
public:
    Variable();
    Variable(int);
    Variable(double);
    Variable(char *);
    Variable(map<string, Variable>&);

    double toNumber();
    string toString();
    Variable get(string);

    friend ostream& operator<<(ostream&, const Variable&);
    friend Variable operator+(Variable& a, Variable& b);
    friend Variable operator-(Variable& a, Variable& b);
    friend Variable operator*(Variable& a, Variable& b);
    friend Variable operator/(Variable& a, Variable& b);
    friend bool operator<(Variable& a, Variable& b);
    friend bool operator>(Variable& a, Variable& b);
    friend bool operator<=(Variable& a, Variable& b);
    friend bool operator>=(Variable& a, Variable& b);
    friend bool operator!=(Variable& a, Variable& b);
    friend bool operator==(Variable& a, Variable& b);
    friend bool operator||(Variable& a, Variable& b);
    friend bool operator&&(Variable& a, Variable& b);
    operator bool();
};


#endif //TP_THL_VARIABLE_H
