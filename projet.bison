%{
	#include<iostream>
	#include <map>
	#include <string>
    #include <cstring>
	#include <vector>
	using namespace std;

    #include "utils/Variable.h"

	extern FILE *yyin;
	extern int yylex();
	int yyerror(char *s) { printf("%s\n", s); }

	map<string, Variable> variables;
	map<string, Variable> temp_attributes;

	vector<tuple<int, Variable, string>> instructions;
	int pc = 0;
	Variable W = 0;
	inline ins(int c, Variable d, char * e = "") { instructions.push_back(make_tuple(c, d, e)); pc++; };


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

%type <valeur> expression
%type <name> variable
%type <valeur> condition
%type <chaine> stringExpression

%token OUT
%token JNZ
%token JMP
%token MOVF
%token NTSF
%token INCF
%token NOP
%token MOVWF
%token MOVLW
%token OBJECT

%left '+' '-'     /* associativité à gauche */
%left '*' '/'     /* associativité à gauche */

%%
bloc : bloc instruction '\n'
		| bloc instruction
		| /* Epsilon */
		;
instruction : expression { ins(OUT, 0); }
				| SI expression '{' {
										$1.pc_goto = pc;
										ins(JNZ, 0);
									 }
				  bloc				 {
										$1.pc_false = pc;
										ins(JMP, 0);
										get<1>(instructions[$1.pc_goto]) = pc;
									 }
				  '}' '\n'			 {  }
				  SINON '{'          {  }
				  bloc				 {

                                        get<1>(instructions[$1.pc_false]) = pc;
									 }
				  '}'				 {  }
                | FOR '(' variable ';' condition ';' IDENTIFIER '+' '+' ')' '{' {
                                                                                    //parsing = true;
                                                                                    $1.pc_goto = pc;
                                                                                    ins(MOVF, 0, $3);
                                                                                    ins(NTSF, 0);
                                                                                    ins(JMP, 0);
                                                                                    $1.pc_false = pc - 1;

                                                                                }
                    bloc                                                        { ins(INCF, 0, $3); get<1>(instructions[$1.pc_false]) = pc + 1;  }
                  '}'                                                           { ins(JMP, $1.pc_goto); }
                | variable                                                      { }
                | stringExpression { ins(OUT, 0); }
				| /* Ligne vide */
				;
condition : IDENTIFIER '<' expression { }
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
expression : expression '+' expression { ins('+', 0); }
				| expression '-' expression { ins('-', 0); }
				| expression '*' expression { ins('*', 0); }
				| expression '/' expression { ins('/', 0); }
				| '(' expression ')' { $$ = $2; }
				| NUMBER { ins(NUMBER, $1); }
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
        case NTSF    : return "NTSF";
        case INCF    : return "INCF";
        case MOVLW    : return "MOVLW";
        case MOVWF    : return "MOVWF";
        case STRING  : return "STRING";
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
    cout << "===== EXECUTION =====" << endl;
    pc = 0;
    while(pc < instructions.size() ) {
        auto ins = instructions[pc];

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

            case NUMBER:
                pile.push_back(get<1>(ins));
                pc++;
                if (debug) { cout << "NUM processed " << get<1>(ins) << endl; }
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

            case OUT:
                cout << "Resultat : " << depiler(pile) << endl;
                pc++;
                break;

            case JNZ:
                x = depiler(pile);
                pc = (x ? pc + 1 : get<1>(ins).toNumber());
                break;

            case JMP:
                pc = get<1>(ins).toNumber();
                if (debug) { cout << "JMP processed now pc = " << pc << endl; }
                break;

            case MOVF:
                W = variables[get<2>(ins)];
                pc++;
                if (debug) { cout << "MOVF processed now W = " << W << endl; }
                break;

            case NTSF:
                x = depiler(pile);
                pc = (W < x ? pc + 2 : pc + 1);
                if (W < x) { pile.push_back(x); }
                if (debug) {
                    cout << "NTSF processed now pc = " << pc << " because " << W << " was < to " << x
                         << (W < x ? " true" : " false") << endl;
                }
                break;

            case INCF:
                x = variables[get<2>(ins)];
                variables[get<2>(ins)] = x.toNumber() + 1;
                pc++;
                if (debug) {
                    cout << "INCF processed " << get<2>(ins) << " now equals " << variables[get<2>(ins)] << endl;
                }
                break;

            case MOVLW:
                x = depiler(pile);
                W = x;
                pc++;
                if (debug) { cout << "MOVLW processed W = " << W << endl; }
                break;

            case MOVWF:
                variables[get<2>(ins)] = W;
                pc++;
                if (debug) { cout << "MOVWF processed " << get<2>(ins) << " = " << variables[get<2>(ins)] << endl; }
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