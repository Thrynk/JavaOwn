%option noyywrap
%{
	#include <iostream>
	#include <string>
    using namespace std;

	typedef struct adr {
		int pc_goto;
		int pc_false;
	} ADRESSE;

	#include "projet.bison.hpp"

%}

%%
[0-9]+(\.[0-9]*)?([Ee][0-9]+)? { yylval.valeur = atof(yytext); return NUMBER; }

\"[a-z0-9A-Z]*\" { strcpy(yylval.chaine, yytext); return STRING; }

si|SI|Si { return SI; }
sinon|SINON|Sinon { return SINON; }

pour|POUR|Pour { return FOR; }

tantque|TANTQUE|Tantque { return WHILE; }

fonction|FONCTION|Fonction { return FUNCTION; }

>= { return SUPOREQ; }
\<= { return INFOREQ; }
&& { return DOUBLEAND; }
\|\| { return DOUBLEBAR; }
"==" { return DOUBLEEQUAL; }
"!=" { return DIFFERENTFROM; }

var { return VAR_KEYWORD; }

[A-Za-z_][0-9A-Za-z_]*  { strcpy(yylval.name,yytext); return IDENTIFIER; }



[ \t\r\n]+							{ }

.								{  return yytext[0]; }
%%