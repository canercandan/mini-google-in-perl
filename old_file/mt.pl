  ############### [ MT ] ################
 ############### [ MT ] ################
############### [ MT ] ################

#!/usr/bin/perl	# shebang line (adresse de l interpreteur)
use strict; # verifie que toutes les variables sont bien declarees avec my
use warnings; # demande l affichage des warnings (erreurs)
use Carp; # recherche les erreurs de syntaxe dans le programme
use DBI; # module dbi pour traitement SQL

# declaration des classes
#require "class.pm"; # 1er methode
#use class::debug; # 2eme methode et version

# declaration des variables utiles
my $db;
#my $db = bdd -> new(); # connexion bdd
#my $debug = debug -> new();
my $debug;
my $ext_file;
my $ext_dom;
my $prot;
my @host_field;
my $cache_id;
my $cache_dir;
#my $max_host;
#my $max_refer;
#my $max_email;
#my $max_wordlist;
#my $max_wordmatch;
#my $max_cache;
my $nb_essai = 0;
my $nb_req = 1;
my @ARGV = @ARGV;

sub connexion_bdd() { # connexion mysql
	my $type_db = "mysql";
	my $host_db = "localhost";
	my $port_db = "3306";
	my $name_db = "ekz_mt";
	my $log_db = "ekz_mt";
	my $pwd_db = "mttest";

	if ( $_[0] eq "conn" ) {
		&debug( __LINE__, "connexion a la bdd" );
		$db = DBI -> connect (
			"dbi:".$type_db.":dbname=".$name_db.";host=".$host_db.";port=".$port_db,
			$log_db,
			$pwd_db
		);
	} elsif ( $_[0] eq "deconn" ) {
		&debug( __LINE__, "deconnexion de la bdd" );
		$db -> disconnect;
	}
}

=put
sub connexion_bdd() { # connexion postgres
	my $type_db = "Pg";
	my $host_db = "91.121.15.22";
	my $port_db = "5432";
	my $name_db = "mt";
	my $log_db = "postgres";
	my $pwd_db = "espad99";

	if ( $_[0] eq "conn" ) {
		&debug( __LINE__, "connexion a la bdd" );
		$db = DBI -> connect (
			"dbi:".$type_db.":dbname=".$name_db.";host=".$host_db.";port=".$port_db,
			$log_db,
			$pwd_db
		);
	} elsif ( $_[0] eq "deconn" ) {
		&debug( __LINE__, "deconnexion de la bdd" );
		$db -> disconnect;
	}
}
=cut

sub debug() { # affiche debuger
	if ( $debug ) {
		print "\n \# Ligne ".$_[0].( $_[1] ? " -> ".$_[1] : "" )."\n\n";
	}
}

sub type_field() { # arg pour type_ext
	my @type_field = $db -> selectrow_array ( "
		SELECT
			type_id,
			type_lib,
			type_cache
		FROM
			mt_type
		WHERE
			type_ext LIKE '%".$_[0]."|%'
		;
	" );
	return @type_field;
}

sub host_id() { # arg pour host_url, host_lib, host_level, host_old_id
	my $host_id = $db -> selectrow_array ( "
		SELECT
			host_id
		FROM
			mt_host
		WHERE
			host_url = '".$_[0]."'
		;
	" );
	if ( !$host_id ) {
		&debug( __LINE__, "host_id() : ajout de l host" );
		#$max_host ++;
		$db -> do ( "
			INSERT INTO
				mt_host
			VALUES (
				NULL,
				'".$_[0]."',
				'".$_[1]."',
				'".( $_[2] || 0 )."',
				'".( $_[3] || 0 )."'
			);
		" );
		#return $max_host;
	} else {
		&debug( __LINE__, "host_id() : host existant" );
		return $host_id;
	}
}

sub host_field() { # arg pour host_id
	@host_field = $db -> selectrow_array ( "
		SELECT
			host_id,
			host_url,
			host_lib,
			host_level
		FROM
			mt_host
		WHERE
			host_id = '".$_[0]."'
		;
	" );
	return @host_field;
}

sub insert_url() { # ajout manuel d url
	foreach (@ARGV) { # liste les arguments et ajoute les @ a la bdd
		&debug( __LINE__, "insert_url() : arguments trouves" );
		if ( $_ =~ m/($prot):\/\/(?:www\.)?([-a-zA-Z0-9\.]*?\.*?[-a-zA-Z0-9]*?\.(?:[a-zA-Z]{2}?$ext_dom))(\/[-a-zA-Z0-9+\/%=~_\|!:,.;]*?[-a-zA-Z0-9+\/\%=~_\|]*?\.($ext_file.___))/im ) {
			&debug( __LINE__, "insert_url() : url correct, ajout d url" );
			my $host_refer = &host_id ( $2, 0, 0, 0 );
			my $chemin_refer = $3;
			my $verif_refer = $db -> selectrow_array ( "
				SELECT
					refer_id
				FROM
					mt_refer
				WHERE
					refer_url = '".$chemin_refer."'
					AND refer_host_id = '".$host_refer."'
				;
			" );
			if ( !$verif_refer ) {
				&debug( __LINE__, "insert_url() : refer_id innexistant, ajout du refer_id" );
				#$max_refer ++;
				my @type_refer = &type_field ( $4 );
				$db -> do ( "
					INSERT INTO
						mt_refer
					VALUES (
						NULL,
						'".$host_refer."',
						'".$type_refer[0]."',
						'".$chemin_refer."',
						'',
						'',
						".time()."
					);
				" );
			} else {
				&debug( __LINE__, "insert_url() : refer_id existant" );
			}
  		}
	}
}

sub insert_refer() { # insertion url
	if ( $_[0] && $_[1] && $_[2] ) {
		&debug( __LINE__, "insert_refer () : recupere donnee preparation" );
		my $host_refer = &host_id ( $_[0], 0, $host_field[3]+1, $host_field[0] );
		my $chemin_refer = $_[2];
		my $verif_refer = $db -> selectrow_array ( "
			SELECT
				refer_id
			FROM
				mt_refer
			WHERE
				refer_url = '".$chemin_refer."'
				AND refer_host_id = '".$host_refer."'
			;
		" );
		if ( !$verif_refer ) {
			&debug( __LINE__, "insert_refer() : refer_id innexistant, ajout du refer_id" );
			#$max_refer ++;
			my @type_refer = &type_field($_[1]);
			my $lib_refer = ($_[3] || 0);
			$db -> do ( "
				INSERT INTO
					mt_refer
				VALUES (
					NULL,
					'".$host_refer."',
					'".$type_refer[0]."',
					'".$chemin_refer."',
					\"".$lib_refer."\",
					'',
					".time()."
				);
			" );
		} else {
			&debug( __LINE__, "insert_refer() : refer_id existant" );
		}
	}
}

sub insert_email() { # insertion email
	if ( $_[0] && $_[1] && $_[2] ) {
		&debug( __LINE__, "insert_email() : recupere donnee preparation" );
		my $host_email = &host_id ( $_[0], 0, $host_field[3]+1, $host_field[0] );
		my $lib_email = $_[2];
		my $verif_email = $db -> selectrow_array ( "
			SELECT
				email_id
			FROM
				mt_email
			WHERE
				email_lib = '".$lib_email."'
				AND email_host_id = '".$host_email."'
			;
		" );
		if ( !$verif_email ) {
			&debug( __LINE__, "insert_email() : email_id innexistant, ajout du email_id" );
			#$max_email ++;
			my $refer_email = $_[1];
			$db -> do ( "
				INSERT INTO
					mt_email
				VALUES (
					NULL,
					'".$host_email."',
					'".$refer_email."',
					'".$lib_email."',
					".time()."
				);
			" );
		} else {
			&debug( __LINE__, "insert_email() : email_id existant" );
		}
	}
}

sub insert_keywords() {
	if( $_[0] && $_[1] ) {
		&debug( __LINE__, "insert_keywords() : recupere donnee preparation" );
		my $refer_id = $_[1];
		my @keywords = split ( "\\b[\\s]?(?:,|\\s)[\\s]*?\\b", lc ( $_[0] ) ); # vire espaces et vigules et met les mots dans @keywords
		my $num = 0;
		&debug( __LINE__, "insert_keywords() : liste tous les keywords" );
		while ( $keywords[$num] ) {
			my @verif_wordlist = $db -> selectrow_array ( "
				SELECT
					wordlist_id,
					(wordlist_nb)+1
				FROM
					mt_wordlist
				WHERE
					wordlist_text = \"".$keywords[$num]."\"
				;
			" );
			if ( $verif_wordlist[0] ) {
				&debug( __LINE__, "insert_keywords() : keyword existant, maj" );
				$db -> do ( "
					UPDATE
						mt_wordlist
					SET
						wordlist_nb = '".$verif_wordlist[1]."'
					WHERE
						wordlist_text = \"".$keywords[$num]."\"
					;
				" );
			} else {
				&debug( __LINE__, "insert_keywords() : keyword innexistant, ajout" );
				#$max_wordlist ++;
				$db -> do ( "
					INSERT INTO
						mt_wordlist
					VALUES (
						NULL,
						\"".$keywords[$num]."\",
						'1',
						'Y'
					);
				" );
			}
			my $verif_wordmatch = $db -> selectrow_array ( "
				SELECT
					wordmatch_id
				FROM
					mt_wordmatch
				WHERE
					wordmatch_wordlist_id = '".$verif_wordlist[0]."'
					AND wordmatch_refer_id = '".$refer_id."'
				;
			" );
			if ( !$verif_wordmatch ) {
				&debug( __LINE__, "insert_keywords() : keyword non mappe, ajout" );
				#$max_wordmatch ++;
				$db -> do ( "
					INSERT INTO
						mt_wordmatch
					VALUES (
						NULL,
						'".$verif_wordlist[0]."',
						'".$refer_id."'
					);
				" );
			}
			$num ++;
		}
	}
}

sub insert_others() {
	if ( $_[0] && $_[1] && $_[2] ) {
		my $refer_id = $_[1];
		my $verif_others = $db -> selectrow_array ( "
			SELECT
				refer_id
			FROM
				mt_refer
			WHERE
				refer_id = '".$refer_id."'
			;
		" );
		if ( $verif_others ) {
			my $refer_others = $_[0];
			&debug( __LINE__, "insert_others() : keyword existant, maj" );
			$db -> do ( "
				UPDATE
					mt_refer
				SET
					".( $_[2] eq "descrip" ? "refer_descrip" : ( $_[2] eq "title" ? "refer_lib" : "" ) )." = \"".$refer_others."\"
				WHERE
					refer_id = '".$refer_id."'
				;
			" );
		}
	}
}

sub insert_cache() { # ajout id cache dans la table
	if ( $_[0] && $_[1] && $_[2] ) {
		my $req_cache_id = $db -> selectrow_array ( "
			SELECT 
				cache_id
			FROM
				mt_cache
			WHERE
				cache_file = '".$_[0]."'
				AND cache_host_id = '".$_[1]."'
				AND cache_refer_id = '".$_[2]."'
			;
		" );
		if ( !$req_cache_id ) {
			&debug( __LINE__, "insert_cache() : id cache innexistant, ajout de id cache dans la table" );
			#$max_cache ++;
			$db -> do ( "
				INSERT INTO
					mt_cache
				VALUES (
					NULL,
					'".$_[1]."',
					'".$_[2]."',
					'".$_[0]."',
					".time()."
				);
			" );
		} else {
			&debug( __LINE__, "insert_cache() : id cache existant" );
		}
	}
}

sub gen_id() { # genere id
	my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
	return join ( "", @chars [ map { rand @chars } ( 1 .. 32 ) ] );
}

sub ext_file() { # liste extensions valides
	my $req_type = $db -> prepare ( "
		SELECT
			type_id,
			type_lib,
			type_ext
		FROM
			mt_type
		;
	" );
	$req_type -> execute();
	my $ext;
	&debug( __LINE__, "ext_file() : creation de la liste des extensions valides" );
	while ( my ( $type_id, $type_lib, $type_ext ) = $req_type -> fetchrow_array ){
		&debug( __LINE__, $type_lib." |".$type_ext );
		$ext .= $type_ext;
	}
	$req_type -> finish();
	return $ext;
}

sub converti_date() {
	my ( $secondes, $minutes, $heures, $jour_mois, $mois, $an, $jour_semaine, $jour_calendaire, $heure_ete ) = localtime( $_[0] );
	my $CTIME_String = localtime( $_[0] );
	$mois += 1;
	$an += 1900;
	$jour_calendaire += 1;
	$mois = ($mois < 10 ? "0".$mois : $mois);
	$jour_mois = ($jour_mois < 10 ? "0".$jour_mois : $jour_mois);
	$heures = ($heures < 10 ? "0".$heures : $heures);
	$minutes = ($minutes < 10 ? "0".$minutes : $minutes);
	$secondes = ($secondes < 10 ? "0".$secondes : $secondes);

	my @noms_de_jours = (
		"Dimanche",
		"Lundi",
		"Mardi",
		"Mercredi",
		"Jeudi",
		"Vendredi",
		"Samedi"
	);

	my @noms_de_mois = (
		"",
		"Janvier",
		"F&eacute;vrier",
		"Mars",
		"Avril",
		"Mai",
		"Juin",
		"Juillet",
		"Ao&ucirc;t",
		"Septembre",
		"Octobre",
		"Novembre",
		"D&eacute;cembre"
	);

	if ( $_[1] eq "cache" ) {
		&debug( __LINE__, "converti_date() : creation dossier cache + affiche date" );
		mkdir( $cache_dir, 0777 );
		mkdir( $cache_dir."/".$an."/", 0777 );
		mkdir( $cache_dir."/".$an."/".$mois."/", 0777 );
		mkdir( $cache_dir."/".$an."/".$mois."/".$jour_mois."/", 0777 );
		return $cache_dir."/".$an."/".$mois."/".$jour_mois;
	} else {
		&debug( __LINE__, "converti_date() : affiche date" );
		return $an."-".$mois."-".$jour_mois;
	}
}

=put
sub id_max() { # initialise id max
	# declaration
	my $req_max;

	$req_max = $db -> selectrow_array( "
		SELECT
			MAX(host_id)
		FROM
			mt_host
		;
	" );
	$max_host = ($req_max || 0);

	$req_max = $db -> selectrow_array( "
		SELECT
			MAX(refer_id)
		FROM
			mt_refer
		;
	" );
	$max_refer = ($req_max || 0);

	$req_max = $db -> selectrow_array( "
		SELECT
			MAX(email_id)
		FROM
			mt_email
		;
	" );
	$max_email = ($req_max || 0);

	$req_max = $db -> selectrow_array( "
		SELECT
			MAX(wordlist_id)
		FROM
			mt_wordlist
		;
	" );
	$max_wordlist = ($req_max || 0);

	$req_max = $db -> selectrow_array( "
		SELECT
			MAX(wordmatch_id)
		FROM
			mt_wordmatch
		;
	" );
	$max_wordmatch = ($req_max || 0);

	$req_max = $db -> selectrow_array( "
		SELECT
			MAX(cache_id)
		FROM
			mt_cache
		;
	" );
	$max_cache = ($req_max || 0);
}
=cut

sub mt_refer() { # contenu de la fonction mere
	&debug( __LINE__, "mt_refer() : fonction mere" );

	# declaration
	$ext_dom = "|com|org|net|biz|info|name|aero|biz|info|jobs|museum|name";
	$prot = "https?|ftp|mms";
	$cache_dir = "cache";
	my @url_min_field;
	my $file;

	if ( $nb_essai < 1 ) {
		#&id_max (); # initialise id max
		&insert_url (); # appel fonction ajout manuel d url
	}

	my $req_min_field = $db -> prepare( "
		SELECT
			refer_id,
			refer_host_id,
			refer_type_id,
			refer_url
		FROM
			mt_refer
		WHERE
			refer_id NOT IN (
				SELECT
					cache_refer_id
				FROM
					mt_cache
			)
			AND refer_type_id IN (
				SELECT
					type_id
				FROM
					mt_type
				WHERE
					type_cache = 'Y'
			)
		ORDER BY refer_id ASC
		;
	" );
	$req_min_field -> execute();

	&debug( __LINE__, "mt_refer() : refer_id recherche avec valeur min et sans indexation" );
	while ( @url_min_field = $req_min_field -> fetchrow_array ) {
		# declaration
		$cache_id = &gen_id();
		&insert_cache( $cache_id, $url_min_field[1], $url_min_field[0] );
		my $num = 1;

		&debug( __LINE__, "mt_refer() : refer_id non indexe innexistant" );
		$file = &converti_date( time (), "cache" )."/".$cache_id;
		@host_field = &host_field( $url_min_field[1] );
		my $host_www = $host_field[1];
		#$host_www =~ s/^([-a-zA-Z0-9]*?\.[a-zA-Z]{2}?$ext_dom)$/www\.$1/ig;
		system "wget --timeout=1 -N -t 1 -O ".$file." http://".$host_www."/".$url_min_field[3]; # telecharge source de $file

		open( FILE, $file ) or die "mt_refer() : erreur !\n"; # ouverture du fichier en cache
		&debug( __LINE__, "mt_refer() : lecture du fichier en cache : ".$file );
		while ( <FILE> ) {
			while($_ =~ m/($prot):\/\/(?:www\.)?([-a-zA-Z0-9\.]*?\.*?[-a-zA-Z0-9]*?\.(?:[a-zA-Z]{2}?$ext_dom))(\/[-a-zA-Z0-9+\/%=~_\|.]*?[-a-zA-Z0-9+\/\%=~_\|]*?\.($ext_file.___))|<a[\s]+[^>]*?href[\s]*?=[\s\"\'](?!(?:$prot):\/\/)(\/?[-a-zA-Z0-9+\/%=~_\|.]*?[-a-zA-Z0-9+\/\%=~_\|]*?\.($ext_file.___)).*?[\s\"\']+.*?>(.*?)<\/a>|<img[\s]+[^>]*?src[\s]*?=[\s\"\'](?!(?:$prot):\/\/)(\/?[-a-zA-Z0-9+\/%=~_\|.]*?[-a-zA-Z0-9+\/\%=~_\|]*?\.($ext_file.___))[\s\"\']+.*?>|\b([A-Z0-9._%-]*?)(?:@|\[a\]|_at_)([A-Z0-9-]*?)(?:\.|\[\.\]|_dot_|_point_)([A-Z]{2}?$ext_dom)\b|<meta[\s]+[^>]*?name[\s]*?=[\s\"\'](keywords|description)[\s\"\'][\s]*?content[\s]*?=[\"\'](.*?)[\"\']+.*?>.*?|<title>(.*?)<\/title>/img){

# expression rationnelle
# (http):\/\/(?:www\.)?([-a-zA-Z0-9\.]*?\.*?[-a-zA-Z0-9]*?\.(?:[a-zA-Z]{2}?|com|org|net))(\/[-a-zA-Z0-9+\/%=~_\|.]*?[-a-zA-Z0-9+\/\%=~_\|]*?\.(html?))|
# <a[\s]+[^>]*?href[\s]*?=[\s\"\'](?!(?:http):\/\/)(\/?[-a-zA-Z0-9+\/%=~_\|.]*?[-a-zA-Z0-9+\/\%=~_\|]*?\.(html?)).*?[\s\"\']+.*?>(.*?)<\/a>|
# <img[\s]+[^>]*?src[\s]*?=[\s\"\'](?!(?:http):\/\/)(\/?[-a-zA-Z0-9+\/%=~_\|.]*?[-a-zA-Z0-9+\/\%=~_\|]*?\.(html?))[\s\"\']+.*?>|
# \b([A-Z0-9._%-]*?)(?:@|\[a\]|_at_)([A-Z0-9-]*?)(?:\.|\[\.\]|_dot_|_point_)([A-Z]{2}?|com|org|net)\b|
# <meta[\s]+[^>]*?name[\s]*?=[\s\"\'](keywords|description)[\s\"\'][\s]*?content[\s]*?=[\"\'](.*?)[\"\']+.*?>.*?|
# <title>(.*?)<\/title>

				&debug( __LINE__, "mt_refer() : elements valides trouves dans le cache" );
				if ( $1 ) {
					&insert_refer( $2, $4, $3 );
					&debug( __LINE__,
						"mt_refer () : \n".
						"Format http://[URL]/[CHEMIN].[EXT]\n".
						"Protocole : ".$1."\n".
						"URL : ".$2."\n".
						"Chemin : ".$3."\n".
						"Extension : ".$4."\n"
					);
				} elsif ( $5 ) {
					my $titre = $7;
					$titre =~ s/(<[^>]+>)//img;
					#$titre =~ s/(?:<[^>]*>)?//img;
					&insert_refer( $host_field[1], $6, $5, ( $titre || 0 ) );
					&debug( __LINE__,
						"mt_refer() : \n".
						"Format : <a href='[CHEMIN].[EXT]'>[LIB]</a>\n".
						"Chemin : ".$5."\n".
						"Extension : ".$6."\n".
						"Libelle : ".$titre."\n"
					);
				} elsif ( $8 ) {
					&insert_refer( $host_field[1], $9, $8 );
					&debug( __LINE__,
						"mt_refer() : \n".
						"Format : <img src='[CHEMIN].[EXT]'>\n".
						"Chemin : ".$8."\n".
						"Extension : ".$9."\n"
					);
				} elsif ( $10 ) {
					my $url = $11.".".$12;
					&insert_email ( $url, $url_min_field[0], $10 );
					&debug( __LINE__,
						"mt_refer () : \n".
						"Format : [LIB]@[URL]\n".
						"Libelle : ".$10."\n".
						"URL : ".$url."\n"
					);
				} elsif ( $13 eq "keywords" ) {
					&insert_keywords ( $14, $url_min_field[0] );
					&debug( __LINE__,
						"mt_refer () : \n".
						"Format : <META NAME='[KEYWORDS]'>\n".
						"Keywords : ".$14."\n"
					);
				} elsif ( $13 eq "description" ) {
					&insert_others ( $14, $url_min_field[0], "descrip" );
					&debug( __LINE__,
						"mt_refer () : \n".
						"Format : <META NAME='[DESCRIPTION]'>\n".
						"Description : ".$14."\n"
					);
				} elsif ( $15 ) {
					&insert_others ( $15, $url_min_field[0], "title" );
					&debug( __LINE__,
						"mt_refer () : \n".
						"Format : <TITLE>[TITLE]</TITLE>\n".
						"Title : ".$15."\n"
					);
				}
				&debug( __LINE__, "num -> ",$num,"\n\n" );
				$num ++;
			}
		}
		close ( FILE );
		$nb_essai = 0;
	}
	$req_min_field -> finish();

#	if( !$url_min_field[0] ) {
#		&debug( __LINE__, "mt_refer () : pas de refer_id avec valeur min et sans indexation" );
#		$nb_essai ++;
#	}
}


##### MAIN #####

$debug = ( $ARGV[0] || 0 ); # mode debug

&connexion_bdd( "conn" );
#$db -> connect(); # connexion bdd

$ext_file = &ext_file();

while ( $nb_essai <= 2 ) { # boucle termine si inactif
	&debug( __LINE__, " -------------------- debut boucle :: ".$nb_req." -------------------- " );
	&mt_refer(); # execute la fonction mere
	&debug( __LINE__, " --------------------- fin boucle :: ".$nb_req." --------------------- " );
	$nb_req ++;
	sleep( 1 ); # pause de x secondes
}

&connexion_bdd( "deconn" );
#$db -> disconnect(); # deconnexion bdd

