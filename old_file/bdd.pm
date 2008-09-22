package bdd;
use strict;
use warnings;

# attribut public
our $VERSION = "1.1"; # defini version classe
# attribut prive
my $type_bdd = "mysql";
my $host_bdd = "localhost";
my $post_bdd = "3306";
my $name_bdd = "ekz_mt";
my $log_bdd = "ekz_mt";
my $pwd_bdd = "mttest";

# constructeur
sub new {
	my ( $class, $conn ) = @_; # passe les donnees au constructeur
	my $this;
	if ( $conn == 1 ) {
		$this = DBI -> connect (
			"dbi:".$type_bdd.":".$name_bdd.":".$host_bdd.":".$post_bdd, # type et nom bdd
			$log_bdd, # login
			$pwd_bdd # mot de passe
		);
	} else {
		$this -> disconnect;
	}
	bless ( $this, $class ); # lie reference de la classe
	return $this; # retourne la reference consacrée
}

1; # obligatoire lors de la creation dun module
