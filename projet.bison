%{
	#include<iostream>
	#include <map>
	#include <string>

#include <cstring>
	#include <vector>
	using namespace std;
	extern FILE *yyin;
	extern int yylex();
	int yyerror(char *s) { printf("%s\n", s); }

	map<string, double> variables;

	vector<tuple<int, double, string>> instructions;
	int pc = 0;
	double W = 0;
	inline ins(int c, double d, char * e = "") { instructions.push_back(make_tuple(c, d, e)); pc++; };


	typedef struct adr {
		int pc_goto;
		int pc_false;
	} ADRESSE;

	bool parsing = false;

	double depiler(vector<double> &pile);

	void execute();

%}

%union {
	double valeur;
	char name[50];
	ADRESSE adresse;
}

%token <valeur> NUMBER
%token <name> IDENTIFIER
%token <adresse> SI
%token SINON
%token VAR_KEYWORD
%token <adresse> FOR

%type <valeur> expression
%type <name> variable
%type <valeur> condition

%token OUT
%token JNZ
%token JMP
%token MOVF
%token NTSF

%left '+' '-'     /* associativité à gauche */
%left '*' '/'     /* associativité à gauche */

%%
bloc : bloc instruction '\n'
		| bloc instruction
		| /* Epsilon */
		;
instruction : expression { ins(OUT, 0); execute(); /*cout << "Resultat : " << $1 << endl;*/  /* fonction execute to add */ }
				| SI expression '{' {
										parsing = true;
										$1.pc_goto = pc;
										ins(JNZ, 0);
									 }
				  bloc				 {
										$1.pc_false = pc;
										ins(JMP, 0);
										//instructions[$1.pc_goto].second = pc;
										get<1>(instructions[$1.pc_goto]) = pc;
									 }
				  '}' '\n'			 {  }
				  SINON '{'          {  }
				  bloc				 {
										//instructions[$1.pc_false].second = pc;
                                        get<1>(instructions[$1.pc_false]) = pc;
									 }
				  '}'				 { parsing = false; execute(); }
                | FOR '(' variable ';' condition ';' IDENTIFIER '+' '+' ')' '{' {
                                                                                    parsing = true;

                                                                                    ins(MOVF, 0, $3);
                                                                                    ins(NTSF, 0);
                                                                                    ins(JMP, 0);
                                                                                    $1.pc_goto = pc - 1;

                                                                                }
                    bloc                                                        { get<1>(instructions[$1.pc_goto]) = pc + 1; }
                  '}'                                                           { ins(JMP, 0); parsing = false; execute(); }
                | variable                                                      { }
				| /* Ligne vide */
				;
condition : IDENTIFIER '<' expression {
                                        /*if(variables[$1] < $3){
                                            $$ = 1;
                                        }
                                        else {
                                            $$ = 0;
                                        }*/
                                       }
            ;
variable : IDENTIFIER '=' expression {
                                        variables[$1] = $3;
                                        execute();
                                        strcpy($$, $1);
                                        /*cout << $1 << "=" << $3 << endl;*/
                                     }
                | VAR_KEYWORD IDENTIFIER '=' expression {
                                                            variables[$2] = $4;
                                                            execute();

                                                            strcpy($$, $2);
                                                            /*cout << "var " << $2 << "=" << $4 << endl;*/
                                                        }
                ;
expression : expression '+' expression { ins('+', 0); /*$$ = $1 + $3; cout << $1 << "+" << $3 << endl;*/ }
				| expression '-' expression { ins('-', 0); /*$$ = $1 - $3; cout << $1 << "-" << $3 << endl;*/ }
				| expression '*' expression { ins('*', 0); /*$$ = $1 * $3; cout << $1 << "*" << $3 << endl;*/ }
				| expression '/' expression { ins('/', 0); /*$$ = $1 / $3; cout << $1 << "/" << $3 << endl;*/ }
				| '(' expression ')' { $$ = $2; }
				| NUMBER { ins(NUMBER, $1); /*$$ = $1;*/ }
				;

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

double depiler(vector<double> &pile) {
    double t = pile[pile.size()-1];
    //cout << "Dépiler " << t << endl;
    pile.pop_back();
    return t;
}

void execute(){
    vector<double> pile;
    double x, y;
    if(!parsing){
        print_program();
        cout << "===== EXECUTION =====" << endl;
        pc = 0;
        while(pc < instructions.size() ){
            auto ins = instructions[pc];
            //cout << pc << '\t' << nom(ins.first) << "\t" << ins.second << endl;

            switch(get<0>(ins)){
                case '+':
                    x = depiler(pile);
                    y = depiler(pile);
                    pile.push_back(y+x);
                    pc++;
                break;

                case '*':
                    x = depiler(pile);
                    y = depiler(pile);
                    pile.push_back(y*x);
                    pc++;
                break;

                case '-':
                    x = depiler(pile);
                    y = depiler(pile);
                    pile.push_back(y-x);
                    pc++;
                break;

                case '/':
                    x = depiler(pile);
                    y = depiler(pile);
                    pile.push_back(y/x);
                    pc++;
                break;

                case NUMBER:
                    pile.push_back(get<1>(ins));
                    pc++;
                    cout << "Number processed" << endl;
                break;

                case OUT:
                    cout << "Resultat : " << depiler(pile) << endl;
                    pc++;
                break;

                case JNZ:
                    x = depiler(pile);
                    pc = (x ? pc + 1:get<1>(ins));
                break;

                case JMP:
                    pc = get<1>(ins);
                break;

                case MOVF:
                    W = variables[get<2>(ins)];
                    cout << "MOVF processed " << pc << " " << W << endl;
                    pc++;
                break;

                case NTSF:
                    x = depiler(pile);
                    cout << x << endl;
                    cout << " " << pc << endl;
                    cout << W << endl;
                    if(W < x) {cout << "false" << endl;}
                    pc = (W < x ? pc + 2 : pc + 1);
                    cout << " " << pc << endl;
                    variables[get<2>(ins)] = W + 1;
                    cout << variables[get<2>(ins)] << endl;
                    cout << "NTSF processed" << endl;
                    system("pause");
                break;
            }
        }
        cout << "=====================" << endl;
        instructions.clear();
        pc = 0;
    }
}

int main(int argc, char **argv) {

  if ( argc > 1 )
    yyin = fopen( argv[1], "r" );
  else
    yyin = stdin;
  yyparse();
}