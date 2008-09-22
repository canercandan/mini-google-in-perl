#!/usr/bin/perl
use strict; # verifie que toutes les variables sont bien declarees avec my
use warnings; # demande l affichage des warnings (erreurs)
use Carp; # recherche les erreurs de syntaxe dans le programme
use DBI; # module dbi pour traitement SQL

my $num = 0;
my $key = "MSN, MSN France, messenger, messagerie instantan�e, mon MSN, recherche, moteur de recherche, recherche web, recherche actualit�s, recherche images, email, mail, email gratuit, mail gratuit, communautes, blogs, spaces, shopping, voyages, automobile, cin�ma";
my @chaine = split ( "\\b[\\s]?(?:,|\\s)[\\s]*?\\b", lc ( $key ) );

while ( $chaine[$num] ) {
	print $chaine[$num]."\n";
	$num ++;
}

