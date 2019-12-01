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
	map<string, int> functions;

	vector<tuple<int, double, string>> instructions;
	int pc = 0;
	double W = 0;
	inline ins(int c, double d, char * e = "") { instructions.push_back(make_tuple(c, d, e)); pc++; };


	typedef struct adr {
		int pc_goto;
		int pc_false;
	} ADRESSE;

	bool parsing = false;
	bool debug = false;

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
%token <adresse> WHILE
%token SUPOREQ
%token INFOREQ
%token DOUBLEAND
%token DOUBLEBAR
%token <adresse> FUNCTION


%type <valeur> expression
%type <name> variable
%type <adresse> condition

%token OUT
%token JNZ
%token JMP
%token MOVF
%token INFST
%token SUPST
%token SUPEQ
%token INFEQ
%token INCF
%token DECF
%token NOP
%token MOVWF
%token MOVLW
%token ID
%token AND
%token OR
%token CALL
%token ENDFUNC

%left '+' '-'
%left '*' '/'
%left  ">=" ">" "<" "<=" /* associativité à gauche */
%right "="
%%
bloc : bloc instruction '\n'
		| bloc instruction
		| /* Epsilon */
		;
instruction : expression { ins(OUT, 0); /*execute(); cout << "Resultat : " << $1 << endl;*/  /* fonction execute to add */ }
				| SI condition '{' {
										//parsing = true;
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
				  '}'				 { /*parsing = false; execute();*/ }
                | FOR '(' variable ';' condition ';' IDENTIFIER '+' '+' ')' '{' {
                                                                                    //parsing = true;
                                                                                    $1.pc_goto = pc - 3; //changer -2 si decommente les 2 lignes en dessous
                                                                                    //ins(MOVF, 0, $3);
                                                                                    //ins(INFST, 0);
                                                                                    ins(JNZ, 0);
                                                                                    $1.pc_false = pc - 1;

                                                                                }
                    bloc                                                        { ins(INCF, 0, $3); get<1>(instructions[$1.pc_false]) = pc + 1;  }
                  '}'                                                           { ins(JMP, $1.pc_goto); /*parsing = false; execute();*/ }
                | WHILE '(' condition ')' '{'  {
                                                    $1.pc_goto = pc -3;
                                                    ins(JNZ, 0);
                                                    $1.pc_false = pc -1;
                                                }
                    bloc                        {get<1>(instructions[$1.pc_false])= pc + 1;}
                  '}'                           {ins(JMP, $1.pc_goto);}

                | FUNCTION IDENTIFIER '('')' '{' {
                                                    $1.pc_goto = pc;
                                                    ins(JMP, 0);
                                                    functions[$2] = pc;
                                                 }
                    bloc                         {  }
                '}'                              { ins(ENDFUNC, 0); get<1>(instructions[$1.pc_goto]) = pc; }

                | variable                       { }
                | affectation                    { }
				| /* Ligne vide */
				;
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
            | '(' condition ')' { }
            | condition DOUBLEAND condition { ins(AND, 0); }
            | condition DOUBLEBAR condition { ins(OR, 0); }
            ;

variable : IDENTIFIER '=' expression {
                                        variables[$1] = $3;
                                        //execute();
                                        strcpy($$, $1);
                                        ins(MOVLW, 0);
                                        ins(MOVWF, 0, $1);
                                        /*cout << $1 << "=" << $3 << endl;*/
                                     }
                | VAR_KEYWORD IDENTIFIER '=' expression {
                                                            variables[$2] = $4;
                                                            //execute();

                                                            strcpy($$, $2);
                                                            ins(MOVLW, 0);
                                                            ins(MOVWF, 0, $2);
                                                            /*cout << "var " << $2 << "=" << $4 << endl;*/
                                                        }
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
				| IDENTIFIER { ins(ID, variables[$1])}
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
        case INFST   : return "INFST";
        case SUPST   : return "SUPST";
        case SUPEQ   : return "SUPEQ";
        case INFEQ   : return "INFEQ";
        case INCF    : return "INCF";
        case DECF    : return "DECF";
        case MOVLW    : return "MOVLW";
        case MOVWF    : return "MOVWF";
        case ID    : return "ID";
        case AND   : return "AND";
        case OR    : return "OR";
        case ENDFUNC : return "ENDFUNC";
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
    print_program();
    if(!parsing){

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

                case ID:
                case NUMBER:
                    pile.push_back(get<1>(ins));
                    pc++;
                    if(debug) { cout << "NUM processed " << get<1>(ins) << endl; }
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
                    if(debug) { cout << "JMP processed now pc = " << pc << endl; }
                break;

                case MOVF:
                    W = variables[get<2>(ins)];
                    pc++;
                    if(debug) { cout << "MOVF processed now W = " << W << endl; }
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

                case INCF:
                    x = variables[get<2>(ins)];
                    variables[get<2>(ins)] = x + 1;
                    pc++;
                    if(debug) { cout << "INCF processed " << get<2>(ins) << " now equals " << variables[get<2>(ins)] << endl; }
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

                case MOVWF:
                    variables[get<2>(ins)] = W;
                    pc++;
                    if(debug) { cout << "MOVWF processed " << get<2>(ins) << " = " << variables[get<2>(ins)] << endl; }
                break;
            }
        }
        cout << "=====================" << endl;
        instructions.clear();
        pc = 0;
        cout << "===== VARIABLES =====" << endl;
        for (auto it = variables.begin(); it != variables.end(); ++it){
            cout << it->first << " = " << it->second << endl;
        }
        cout << "=====================" << endl;
    }
}

int main(int argc, char **argv) {

  if ( argc > 1 )
    yyin = fopen( argv[1], "r" );
  else
    yyin = stdin;
  yyparse();
  print_program();
  execute();
}