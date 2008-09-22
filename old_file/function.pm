package BDD;

sub connexion_bdd () {
	if ( $_[0] eq "conn" ) {
		&debug ( __LINE__, "connexion a la bdd" );
		$db = DBI -> connect (
			"dbi:mysql:ekz_mt:localhost:3306", # type et nom bdd
			"ekz_mt", # login
			"mttest" # mot de passe
		);
	} elsif ( $_[0] eq "deconn" ) {
		&debug ( __LINE__, "deconnexion de la bdd" );
		$db -> disconnect;
	}
}

