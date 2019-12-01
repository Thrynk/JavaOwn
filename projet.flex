%option noyywrap
%{
	#include <iostream>
	#include <string>

	typedef struct adr {
		int pc_goto;
		int pc_false;
	} ADRESSE;

	#include "projet.bison.hpp"
	using namespace std;
%}

%%
[0-9]+(\.[0-9]*)?([Ee][0-9]+)? { yylval.valeur = atof(yytext); return NUMBER; }

si|SI|Si { return SI; }
sinon|SINON|Sinon { return SINON; }

pour|POUR|Pour { return FOR; }

tantque|TANTQUE|Tantque { return WHILE; }

fonction|FONCTION|Fonction { return FUNCTION; }

>= { return SUPOREQ; }
\<= { return INFOREQ; }
&& { return DOUBLEAND; }
\|\| { return DOUBLEBAR; }

var { return VAR_KEYWORD; }

[A-Za-z_][0-9A-Za-z_]*  { strcpy(yylval.name,yytext); return IDENTIFIER; }

\r\n  							{  return '\n'; }
\r								{  return '\n'; }
\n								{  return '\n'; }

[ \t]							{ }

.								{  return yytext[0]; }
%%