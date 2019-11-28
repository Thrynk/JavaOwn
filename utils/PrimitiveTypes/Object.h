#ifndef TP_THL_OBJECT_H
#define TP_THL_OBJECT_H

#include <string>
#include <map>
using namespace std;

#include "../Variable.h"

class Object {
private:
    map<string, Variable> attributes;
public:
    Object(string);
};


#endif //TP_THL_OBJECT_H
