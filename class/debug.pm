package debug;

use strict;
use warnings;

#our @ISA = ( "DBI" );

our $VERSION = "0.1";

sub	new
{
    my ( $class ) = @_; # passe les donnees au constructeur
    my $this = {};

    bless($this, $class);
    return ($this);
}

sub	afficher
{
    my ($this, $ligne, $lib) = @_;

    print "\n \# Ligne ".$ligne.($lib ? " -> ".$lib : "")."\n\n";
}

1;
