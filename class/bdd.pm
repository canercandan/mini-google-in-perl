package bdd;

use strict;
use warnings;

#use DBI;
#our @ISA = ( "DBI" );

our $VERSION = "1.1";

sub	connexion_bdd()
{
    my $type_bdd = "mysql";
    my $host_bdd = "localhost";
    my $post_bdd = "3306";
    my $name_bdd = "ekz_mt";
    my $log_bdd = "ekz_mt";
    my $pwd_bdd = "mttest";

    if ($_[0] eq "conn")
    {
	&debug(__LINE__, "connexion a la bdd");
	$db = DBI->connect
	    ("dbi:".$type_bdd.":".$name_bdd.":".$host_bdd.":".$post_bdd,
	     $log_bdd, $pwd_bdd);
    }
    elsif ($_[0] eq "deconn")
    {
	&debug(__LINE__, "deconnexion de la bdd");
	$db->disconnect;
    }
}

1;
