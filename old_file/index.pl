#!/usr/bin/perl

#!/usr/bin/perl	# shebang line (adresse de l interpreteur)
use strict; # verifie que toutes les variables sont bien declarees avec my
use warnings; # demande l affichage des warnings (erreurs)
use Carp; # recherche les erreurs de syntaxe dans le programme

# declaration des classes
#require "Class.pm"; # 1er methode
use Class 0; # 2eme methode et version

my $dupond = Class -> new ( "Dupond", "Jean", "25", "Simon" );
my $durant = Class -> new ( "Durant", "Claude", "25", "Jacques" );

print
	$dupond -> {nom}," ",
	$dupond -> {prenom}," ",
	$dupond -> {age}," ",
	$dupond -> {frere}[1]," ",
	"\n",
	$durant -> {nom}," ",
	$durant -> {prenom}," ",
	$durant -> {age}," ",
	$durant -> {frere}[1]," ",
	"\n"
;

print $durant -> afficher ();
print $dupond -> parler ( "Bonjour" );

#print "\n",$Class::VERSION,"\n";