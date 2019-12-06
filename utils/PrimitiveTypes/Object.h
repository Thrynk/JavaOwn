#ifndef TP_THL_OBJECT_H
#define TP_THL_OBJECT_H

#include <string>
#include <map>
using namespace std;

#include "../Variable.h"

class Variable;

class Object {
private:
    map<string, Variable> attributes;
public:
    Object();
    Object(map<string, Variable>&);
    void setValue(map<string, Variable>&);
    string toJSON();
};


#endif //TP_THL_OBJECT_H
