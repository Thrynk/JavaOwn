#ifndef TP_THL_NUMBER_H
#define TP_THL_NUMBER_H

#include <string>
using namespace std;

class Number {
private:
    double n;
public:
    Number();
    Number(double);
    Number(string);

    double getValue() const;

    void setValue(double);
};


#endif //TP_THL_NUMBER_H
