%{
	#include<iostream>
	#include <map>
	#include <string>
    #include <cstring>
    #include <sstream>
    #include <fstream>
	#include <vector>
    #include <stack>
	using namespace std;

    #include "utils/Variable.h"

	extern FILE *yyin;
	extern int yylex();
	int yyerror(char *s) { printf("%s\n", s); }

	map<string, Variable> variables;
	map<string, Variable> temp_attributes;
	map<string, int> functions;
	map<string, vector<string>> func_vars;
	vector<string> temp_vars;
	vector<Variable> temp_values;

	vector<tuple<int, Variable, string>> instructions;
	int pc = 0;

	Variable W = 0;
	inline ins(int c, Variable d, const char * e = "") { instructions.push_back(make_tuple(c, d, e)); pc++; };
	int nbCond = 1;

	typedef struct adr {
		int pc_goto;
		int pc_false;
	} ADRESSE;

	bool parsing = false;
	bool debug = false;

	Variable depiler(vector<Variable> &pile);

	void execute();

%}

%union {
	double valeur;
	char name[50];
	ADRESSE adresse;
	char chaine[200];
}

%token <valeur> NUMBER
%token <name> IDENTIFIER
%token <adresse> SI
%token SINON
%token VAR_KEYWORD
%token <adresse> FOR
%token <chaine> STRING
%token <adresse> WHILE
%token SUPOREQ
%token INFOREQ
%token DOUBLEAND
%token DOUBLEBAR
%token DOUBLEEQUAL
%token DIFFERENTFROM
%token <adresse> FUNCTION
%token AFFICHER

%type <valeur> expression
%type <name> variable
%type <valeur> condition
%type <chaine> stringExpression
%type <adresse> si

%token OUT
%token JNZ
%token JMP
%token MOVF
%token INFST
%token SUPST
%token SUPEQ
%token INFEQ
%token DBLEQ
%token DFFROM
%token INCF
%token DECF
%token NOP
%token MOVWF
%token MOVLW
%token OBJECT
%token IDOFOBJECT
%token ID
%token AND
%token OR
%token CALL
%token ENDFUNC


%left '+' '-'
%left '*' '/'

%%
bloc : bloc instruction
		| /* Epsilon */
		;

instruction : AFFICHER '(' expression ')' { ins(OUT, 0); }
                | AFFICHER '(' stringExpression ')' { ins(OUT, 0) }
                | si
				| siSinon
                | FOR '(' variable ';' condition ';' IDENTIFIER '+' '+' ')' '{' {
                                                                                    $1.pc_goto = pc - 3;
                                                                                    ins(JNZ, 0);
                                                                                    $1.pc_false = pc - 1;

                                                                                }
                    bloc                                                        { ins(INCF, 0, $3); get<1>(instructions[$1.pc_false]) = pc + 1;  }
                '}'                                                             { ins(JMP, $1.pc_goto); }
                | WHILE '(' condition ')' '{'                                   {
                                                                                    $1.pc_goto = pc - 3 * nbCond - nbCond + 1;
                                                                                    nbCond = 1;
                                                                                    ins(JNZ, 0);
                                                                                    $1.pc_false = pc -1;
                                                                                }
                    bloc                                                        {get<1>(instructions[$1.pc_false])= pc + 1;}
                '}'                                                             {ins(JMP, $1.pc_goto);}

                | FUNCTION IDENTIFIER '(' parametresFunction ')' '{' {
                                                                        $1.pc_goto = pc;
                                                                        ins(JMP, 0);
                                                                        functions[$2] = pc;
                                                                        func_vars[$2] = temp_vars;
                                                                        temp_vars.clear();
                                                                     }
                    bloc                                             {  }
                '}'                                                  { ins(ENDFUNC, 0); get<1>(instructions[$1.pc_goto]) = pc; }
                | IDENTIFIER '(' parametresDonnes ')'                {
                                                                        ins(CALL, 0, $1);
                                                                        for(int i = 0; i < func_vars[$1].size(); i++){
                                                                            variables[func_vars[$1][i]] = temp_values[i];
                                                                        }
                                                                        temp_values.clear();
                                                                     }
                | variable                                           { }
                | affectation                                        { }
                | stringExpression { ins(OUT, 0); }
				;

si : SI condition '{' {
                            $1.pc_goto = pc;
                            ins(JNZ, 0);
                            nbCond = 1;
                        }
        bloc            {
                            $1.pc_false = pc;
                            get<1>(instructions[$1.pc_goto]) = pc;
                        }
    '}'                 { $$ = $1;}
    ;

siSinon : si SINON '{'  { ins(JMP, 0); }
            bloc        {
                            get<1>(instructions[$1.pc_false]) = pc;
                        }
        '}'
    ;

parametresFunction : parametresFunction ',' parametreFunction {  }
             | parametreFunction {}
             | /* Epsilon */
             ;

parametreFunction : IDENTIFIER { temp_vars.push_back($1); }

parametresDonnes : parametresDonnes ',' parametreDonne {  }
                    | parametreDonne {}
                    | /* Epsilon */
                    ;

parametreDonne : expression { temp_values.push_back($1); }

condition : IDENTIFIER SUPOREQ expression {
                                            ins(MOVF, 0, $1);
                                            ins(SUPEQ, 0);
                                        }
            | IDENTIFIER INFOREQ expression {
                                            ins(MOVF, 0, $1);
                                            ins(INFEQ, 0);
                                        }
            |IDENTIFIER '<' expression {
                                            ins(MOVF, 0, $1);
                                            ins(INFST, 0);
                                       }
            | IDENTIFIER '>' expression  {
                                            ins(MOVF, 0, $1);
                                            ins(SUPST, 0);
                                       }
            | IDENTIFIER DOUBLEEQUAL expression {
                                                    ins(MOVF, 0, $1);
                                                    ins(DBLEQ, 0);
                                                }
            | IDENTIFIER DIFFERENTFROM expression {
                                                    ins(MOVF, 0, $1);
                                                    ins(DFFROM, 0);
                                                  }
            | '(' condition ')' { }
            | condition DOUBLEAND condition { ins(AND, 0); nbCond++; }
            | condition DOUBLEBAR condition { ins(OR, 0); nbCond++; }
            ;

variable : IDENTIFIER '=' expression {
                                        Variable var($3);
                                        variables[$1] = var;
                                        strcpy($$, $1);
                                        ins(MOVLW, 0);
                                        ins(MOVWF, 0, $1);
                                     }
                | VAR_KEYWORD IDENTIFIER '=' expression {
                                                            Variable var($4);
                                                            variables[$2] = var;
                                                            strcpy($$, $2);
                                                            ins(MOVLW, 0);
                                                            ins(MOVWF, 0, $2);
                                                        }
                | IDENTIFIER '=' stringExpression {
                                                    Variable var($3);
                                                    variables[$1] = var;
                                                    strcpy($$, $1);
                                                    ins(MOVLW, 0);
                                                    ins(MOVWF, 0, $1);
                                                    }
                | VAR_KEYWORD IDENTIFIER '=' stringExpression {
                                                            Variable var($4);
                                                            variables[$2] = var;
                                                            strcpy($$, $2);
                                                            ins(MOVLW, 0);
                                                            ins(MOVWF, 0, $2);
                                                         }
                | IDENTIFIER '=' '{'                    {  }
                    attributes                          {
                                                            Variable var(temp_attributes);
                                                            variables[$1] = var;
                                                            temp_attributes.clear();
                                                            ins(OBJECT, var);
                                                            ins(MOVLW, 0);
                                                            ins(MOVWF, 0, $1);
                                                        }
                  '}'                                   {  }
                ;

affectation : IDENTIFIER '+' '+' {
                                    ins(INCF, 0, $1);
                                 }
             | IDENTIFIER '-' '-' {
                                    ins(DECF, 0, $1);
                                  }
                ;
expression : expression '+' expression { ins('+', 0); /*$$ = $1 + $3; cout << $1 << "+" << $3 << endl;*/ }
				| expression '-' expression { ins('-', 0); /*$$ = $1 - $3; cout << $1 << "-" << $3 << endl;*/ }
				| expression '*' expression { ins('*', 0); /*$$ = $1 * $3; cout << $1 << "*" << $3 << endl;*/ }
				| expression '/' expression { ins('/', 0); /*$$ = $1 / $3; cout << $1 << "/" << $3 << endl;*/ }
				| '(' expression ')' { }
				| NUMBER { ins(NUMBER, $1); /*$$ = $1;*/ }
				| IDENTIFIER { ins(ID, 0, $1); }
				| IDENTIFIER '.' IDENTIFIER {
                                                string name = string($1) + "." + string($3);
                                                const char * nameChar = name.c_str();
                                                ins (IDOFOBJECT, 0, nameChar)
                                            }
				;

stringExpression : STRING { ins(STRING, $1); }
                    ;

attributes : attributes ',' attribute {  }
             | attribute {  }
             ;

attribute : IDENTIFIER ':' expression { temp_attributes[$1] = $3; }
            | IDENTIFIER ':' stringExpression { temp_attributes[$1] = $3; }
            | IDENTIFIER ':' IDENTIFIER { temp_attributes[$1] = variables[$3]; }

%%

// Pour imprimer le code généré de manière plus lisible
string nom(int instruction){
    switch (instruction){
        case '+'     : return "ADD";
        case '*'     : return "MUL";
        case '-'     : return "MIN";
        case '/'     : return "DIV";
        case NUMBER  : return "NUM";
        case OUT     : return "OUT";
        case JNZ     : return "JNZ";
        case JMP     : return "JMP";
        case MOVF    : return "MOVF";
        case INFST   : return "INFST";
        case SUPST   : return "SUPST";
        case SUPEQ   : return "SUPEQ";
        case INFEQ   : return "INFEQ";
        case DBLEQ   : return "DBLEQ";
        case DFFROM  : return "DFFROM";
        case INCF    : return "INCF";
        case DECF    : return "DECF";
        case MOVLW    : return "MOVLW";
        case MOVWF    : return "MOVWF";
        case STRING  : return "STRING";
        case ID    : return "ID";
        case AND   : return "AND";
        case OR    : return "OR";
        case ENDFUNC : return "ENDFUNC";
        case CALL  : return "CALL";
        default  : return to_string (instruction);
    }
}

void print_program(){
    cout << "==== CODE GENERE ====" << endl;
    int i = 0;
    for (auto ins : instructions )
        cout << i++ << '\t' << nom(get<0>(ins)) << "\t" << get<1>(ins) << "\t" << get<2>(ins) << endl;
    cout << "=====================" << endl;
    cout << "===== VARIABLES =====" << endl;
    for (auto it = variables.begin(); it != variables.end(); ++it){
        cout << it->first << " = " << it->second << endl;
    }
    cout << "=====================" << endl;
}

Variable depiler(vector<Variable> &pile) {
    Variable t = pile[pile.size()-1];
    pile.pop_back();
    return t;
}

void execute(){
    vector<Variable> pile;
    Variable x, y;
    stack<int> pile_stack_pointer;
    print_program();
    cout << "===== EXECUTION =====" << endl;
    pc = 0;
    while(pc < instructions.size() ) {
        auto ins = instructions[pc];
        stringstream ss;
        char str[256];

        switch (get<0>(ins)) {
            case '+':
                x = depiler(pile);
                y = depiler(pile);
                pile.push_back(y + x);
                pc++;
            break;

            case '*':
                x = depiler(pile);
                y = depiler(pile);
                pile.push_back(y * x);
                pc++;
                break;

            case '-':
                x = depiler(pile);
                y = depiler(pile);
                pile.push_back(y - x);
                pc++;
                break;

            case '/':
                x = depiler(pile);
                y = depiler(pile);
                pile.push_back(y / x);
                pc++;
                break;

            case ID:
                pile.push_back(variables[get<2>(ins)]);
                pc++;
                if(debug) { cout << "ID processed " << variables[get<2>(ins)] << endl; }
            break;

            case NUMBER:
                pile.push_back(get<1>(ins));
                pc++;
                if(debug) { cout << "NUM processed " << get<1>(ins) << endl; }
            break;

            case STRING:
                pile.push_back(get<1>(ins));
                pc++;
                if (debug) { cout << "STRING processed " << get<1>(ins) << endl; }
            break;

            case OBJECT:
                pile.push_back(get<1>(ins));
                pc++;
                if (debug) { cout << "OBJECT processed " << get<1>(ins) << endl; }
            break;

            case IDOFOBJECT:
                //cout << get<2>(ins).substr(0, get<2>(ins).find('.')) << " " << get<2>(ins).substr(get<2>(ins).find('.') + 1) << endl;
                //cout << variables[get<2>(ins).substr(0, get<2>(ins).find('.'))].get(get<2>(ins).substr(get<2>(ins).find('.') + 1)) << endl;
                pile.push_back(variables[get<2>(ins).substr(0, get<2>(ins).find('.'))].get(get<2>(ins).substr(get<2>(ins).find('.') + 1)));
                pc++;
            break;

            case OUT:
                cout << depiler(pile) << endl;
                pc++;
                break;

            case JNZ:
                x = depiler(pile);
                pc = (x ? pc + 1 : get<1>(ins).toNumber());
                if(debug){ cout << "JNZ processed now pc = " << pc << " because " << x << endl; }
            break;

            case JMP:
                pc = get<1>(ins).toNumber();
                if (debug) { cout << "JMP processed now pc = " << pc << endl; }
            break;

            case INFST:
                x = depiler(pile);
                //pc = (W < x ? pc + 2 : pc + 1);
                //if(W < x){ pile.push_back(x); }
                pile.push_back(W < x);
                pc++;
                if(debug) { cout << "INFST processed pushed " << (W < x) << " because " << W << " was < to " << x << " is " << (W < x ? "true" : "false") << endl; }
            break;

            case SUPST:
                x = depiler(pile);
                //pc = (W > x ? pc + 2 : pc + 1);
                //if(W > x){ pile.push_back(x); }
                pile.push_back(W > x);
                pc++;
                if(debug) { cout << "SUPST processed pushed " << (W > x) << " because " << W << " was > to " << x << " is " << (W > x ? "true" : "false") << endl; }
            break;

            case SUPEQ:
                x = depiler(pile);
                //pc = (W >= x ? pc + 2 : pc + 1);
                //if(W >= x){ pile.push_back(x); }
                pile.push_back(W >= x);
                pc++;
                if(debug) { cout << "SUPEQ processed pushed " << (W >= x) << " because " << W << " was >= to " << x << " is " << (W >= x ? "true" : "false") << endl; }
            break;

            case INFEQ:
                x = depiler(pile);
                //pc = (W <= x ? pc + 2 : pc + 1);
                //if(W <= x){ pile.push_back(x); }
                pile.push_back(W <= x);
                pc++;
                if(debug) { cout << "INFEQ processed pushed " << (W <= x) << " because " << W << " was <= to " << x << " is " << (W <= x ? "true" : "false") << endl; }
            break;

            case DBLEQ:
                x = depiler(pile);
                pile.push_back(W==x);
                pc++;
                if(debug) { cout << "DBLEQ processed pushed " << (W == x) << " because " << W << " was == to " << x << " is " << (W == x ? "true" : "false") << endl; }
            break;

            case DFFROM:
                x = depiler(pile);
                pile.push_back(W!=x);
                pc++;
                if(debug) { cout << "DFFROM processed pushed " << (W != x) << " because " << W << " was != to " << x << " is " << (W != x ? "true" : "false") << endl; }
            break;

            case AND:
                x = depiler(pile);
                y = depiler(pile);
                pile.push_back(y && x);
                pc++;
                if(debug){ cout << "AND processed pushed " << (y && x) << " because pile contained " << y << " and " << x << endl;  }
            break;

            case OR:
                x = depiler(pile);
                y = depiler(pile);
                pile.push_back(y || x);
                pc++;
                if(debug){ cout << "OR processed pushed " << (y || x) << " because pile contained " << y << " and " << x << endl;  }
            break;

            case MOVF:
                W = variables[get<2>(ins)];
                pc++;
                if (debug) { cout << "MOVF processed now W = " << W << endl; }
            break;

            case DECF:
                x = variables[get<2>(ins)];
                variables[get<2>(ins)] = x - 1;
                pc++;
                if(debug) { cout << "DECF processed " << get<2>(ins) << " now equals " << variables[get<2>(ins)] << endl; }
             break;

            case MOVLW:
                x = depiler(pile);
                W = x;
                pc++;
                if(debug) { cout << "MOVLW processed W = " << W << endl; }
            break;

            case INCF:
                x = variables[get<2>(ins)];
                variables[get<2>(ins)] = x.toNumber() + 1;
                pc++;
                if (debug) {
                    cout << "INCF processed " << get<2>(ins) << " now equals " << variables[get<2>(ins)] << endl;
                }
                break;

            case MOVWF:
                variables[get<2>(ins)] = W;
                pc++;
                if (debug) { cout << "MOVWF processed " << get<2>(ins) << " = " << variables[get<2>(ins)] << endl; }
                break;

            case CALL:
                pile_stack_pointer.push(pc+1);
                pc = functions[get<2>(ins)];
            break;

            case ENDFUNC:
                pc = pile_stack_pointer.top();
                pile_stack_pointer.pop();
            break;
        }
    }
    cout << "=====================" << endl;
    cout << "===== VARIABLES =====" << endl;
    for (auto it = variables.begin(); it != variables.end(); ++it){
        cout << it->first << " = " << it->second << endl;
    }
    cout << "=====================" << endl;
}

int main(int argc, char **argv) {

  if ( argc > 1 )
    yyin = fopen( argv[1], "r" );
  else
    yyin = stdin;
  yyparse();
  //print_program();
  execute();
}