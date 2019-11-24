#include "Number.h"

Number::Number(){
    this->n = 0;
}

Number::Number(double n) {
    this->n = n;
}

Number::Number(string s) {}

double Number::getValue() const {
    return this->n;
}

void Number::setValue(double n){
    this->n = n;
}