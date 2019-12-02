#include "Object.h"
#include "../Variable.h"

Object::Object() {}

Object::Object(map<string, Variable>& attributes){
    for(auto pair : attributes){
        this->attributes[pair.first] = pair.second;
    }
}

void Object::setValue(map<string, Variable>& attributes){
    for(auto pair : attributes){
        this->attributes[pair.first] = pair.second;
    }
}

string Object::toJSON(){
    string json = "{ ";
    for(auto e : this->attributes){
        json = json + e.first + " : " + e.second.toString() + ", ";
    }
    json = json + "}";
    return json;
}