#ifndef TP_THL_STRING_H
#define TP_THL_STRING_H

#include <string>
using namespace std;

class String {
private:
    string s;
public:
    String();
    String(string s);

    string getValue() const;
    void setValue(string);
};


#endif //TP_THL_STRING_H
