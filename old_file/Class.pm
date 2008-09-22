package Class;
use strict;
use warnings;

# attribut public
our $VERSION = "0.1"; # defini la version de la classe
# attribut prive
my $nb = 0;

# constructeur
sub new {
	my ( $class, $nom, $prenom, $age, @frere ) = @_;# on passe les donnees au constructeur
	my $this = {
		"nom" => $nom,
		"prenom" => $prenom,
		"age" => $age,
		"frere" => ["Simon", "Jacques"]
	};
	bless ( $this, $class ); # lie la reference a la classe
	return $this; # on retourne la reference consacrée
}

# methode
sub parler { # methode dinstance
	my ( $this, $parole ) = @_;
	return $this -> {nom}," a dit : \"",$parole,"\"\n";
}
sub afficher { # methode de classe
	my $class = @_;
	return "La classe $class comporte $nb membres\n";
}

1; # obligatoire lors de la creation dun module
