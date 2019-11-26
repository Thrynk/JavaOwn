#include "String.h"

String::String(){
    this->s = "";
}

String::String(string s){
    this->s = s;
}

string String::getValue() const {
    return this->s;
}

void String::setValue(string s) {
    this->s = s;
}
