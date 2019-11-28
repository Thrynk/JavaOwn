#ifndef TP_THL_VARIABLE_H
#define TP_THL_VARIABLE_H

#include <iostream>
#include <string>
#include "PrimitiveTypes/Number.h"
#include "PrimitiveTypes/String.h"

using namespace std;

class Variable {
private:
    Number n;
    String s;
    string type;
public:
    Variable();
    Variable(int);
    Variable(double);
    Variable(char *);
    Variable(char *, bool);

    double toNumber();

    friend ostream& operator<<(ostream&, const Variable&);
    friend Variable operator+(Variable& a, Variable& b);
    friend Variable operator-(Variable& a, Variable& b);
    friend Variable operator*(Variable& a, Variable& b);
    friend Variable operator/(Variable& a, Variable& b);
    friend bool operator<(Variable& a, Variable& b);
    operator bool();
};


#endif //TP_THL_VARIABLE_H
