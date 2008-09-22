############### [ PROC ] ################

#!/usr/bin/perl	# shebang line (adresse de l interpreteur)
use strict; # verifie que toutes les variables sont bien declarees avec my
use warnings; # demande l affichage des warnings (erreurs)
use Carp; # recherche les erreurs de syntaxe dans le programme
use Switch; # utilisation de l instruction SWITCH
use DBI; # module dbi pour traitement SQL

# declaration des variables utiles
my $db;
my $debug;
my $timeout = 60;
my $nb_req = 0;

my $chem_init = "/etc/init.d/";

# champs table action, type, service, user
my $act_id;
my $act_usr_id;
my $act_type_id;
my $act_serv_id;
my $usr_login;
my $act_detail;
my $act_date_add;
my $act_etat;
my $act_ip;

# coordonnees bdd
my $type_db = "mysql";
my $host_db = "localhost";
my $port_db = "3306";
my $name_db = "ilock";
my $log_db = "root";
my $pwd_db = "tde2005";

# id server
my $srv_id = 1;


sub connexion_bdd() {
	if ( $_[0] eq "conn" ) {
		&debug( "connexion a la bdd", __LINE__ );
		$db = DBI -> connect(
			"dbi:".$type_db.":dbname=".$name_db.";host=".$host_db.";port=".$port_db,
			$log_db,
			$pwd_db
		);
	} elsif ( $_[0] eq "deconn" ) {
		&debug( "deconnexion de la bdd", __LINE__ );
		$db -> disconnect;
	}
}

sub debug() { # affiche debuger
	if ( $debug ) {
		print "
",( $_[1] ? "\# Ligne ".$_[1] : "" )," ",( $_[0] ? " -> ".$_[0] : "" ),"
		";
	}
}

sub get_dom() {
	&debug( "Chargement info web d un utilisateur", __LINE__ );
	
	my ( $dom_1, $dom_2, $dom_3 ) = $db -> selectrow_array ( "
		SELECT
			dom_1.dom_lib dom_1,
			dom_2.dom_lib dom_2,
			dom_3.dom_lib dom_3
		FROM
			ilk_domain dom_1,
			ilk_domain dom_2,
			ilk_domain dom_3,
			ilk_web
		WHERE
			dom_1.dom_old_id = dom_2.dom_id
			AND dom_2.dom_old_id = dom_3.dom_id
			AND web_dom_id = dom_1.dom_id
			AND web_id = '".$_[0]."'
		;
	" );
	
	return
		( $dom_1 ? $dom_1 ).
		( $dom_2 ? ".".$dom_2 ).
		( $dom_3 ? ".".$dom_3 )
	;
}

sub get_web() {
	&debug( "Chargement info web d un utilisateur", __LINE__ );
	
	my @get_web = $db -> selectrow_array ( "
		SELECT
			usr_login,
			web_login,
			web_mdp,
			dom_lib,
			site_prefix
		FROM
			ilk_web,
			ilk_user,
			ilk_domain,
			ilk_site
		WHERE
			web_usr_id = usr_id
			AND web_dom_id = dom_id
			AND dom_site_id = site_id
			AND web_id = '".$_[0]."'
		;
	" );
	
	return @get_web;
}

sub get_bdd() {
	&debug( "Chargement info bdd d un utilisateur", __LINE__ );
	
	my @get_bdd = $db -> selectrow_array ( "
		SELECT
			usr_login,
			bdd_login,
			bdd_mdp,
			site_prefix
		FROM
			ilk_bdd,
			ilk_user,
			ilk_web,
			ilk_domain,
			ilk_site
		WHERE
			bdd_usr_id = usr_id
			AND bdd_web_id = web_id
			AND web_dom_id = dom_id
			AND dom_site_id = site_id
			AND bdd_id = '".$_[0]."'
		;
	" );
	
	return @get_bdd;
}

sub action() {
	&debug( "ACTION : debut", __LINE__ );
	
	# declaration
	my $service = $_[0];
	my $action = $_[1];
	my $usr_id = $_[2];
	my $id = $_[3];
	
	switch ( $service ) {
		case 1 { # BDD
			switch ( $action ) {
				case [1, 2] { # activer / desactiver BDD
					my $value = ( $action == 1 ? "Y" : "N" );
					$db -> do( "
						UPDATE
							db
						SET
							Select_priv = '".$value."',
							Insert_priv = '".$value."',
							Update_priv = '".$value."',
							Delete_priv = '".$value."',
							Create_priv = '".$value."',
							Drop_priv = '".$value."'
						WHERE
							Db = '".$prefix."_".$login."_".$login_w."'
							AND User = '".$prefix."_".$login."_".$login_w."'
						LIMIT 1
						;
					" );
				}
				case 3 { # creer BDD
					# creation de user
					$db -> do( "
						CREATE USER
							\"".$prefix."_".$login."_".$login_w."\"@\"localhost\"
						IDENTIFIED BY
							\"".$prefix."_".$login."_".$login_w."\";
					" );
					
					# privilege de user
					$db -> do( "
						GRANT USAGE
						ON * . *
						TO \"".$prefix."_".$login."_".$login_w."\"@\"localhost\"
						IDENTIFIED BY
							\"".$prefix."_".$login."_".$login_w."\"
						WITH
							MAX_QUERIES_PER_HOUR 0
							MAX_CONNECTIONS_PER_HOUR 0
							MAX_UPDATES_PER_HOUR 0
							MAX_USER_CONNECTIONS 0
						;
					" );
					
					# creation de la bdd
					$db -> do( "
						CREATE DATABASE ".$prefix."_".$login."_".$login_w.";
					" );
					
					# privilege de user sur la bdd
					$db -> do( "
						GRANT
							SELECT,
							INSERT,
							UPDATE,
							DELETE,
							CREATE,
							DROP,
							INDEX,
							ALTER
						ON \"".$prefix."_".$login."_".$login_w."\" . *
						TO \"".$prefix."_".$login."_".$login_w."\"@\"localhost\"
						;
					" );
				}
				case 4 { # supprimer BDD
					$db -> do( "
						DROP USER \"".$prefix."_".$login."_".$login_w."\"@\"localhost\";
					" );
					
					$db -> do( "
						DROP DATABASE ".$prefix."_".$login."_".$login_w.";
					" );
					
					$db -> do( "
						FLUSH PRIVILEGES;
					" );
				}
				case 5 { # recharger BDD
					system $chem_init."mysql reload";
				}
				else {
					&debug( "ACTION[BDD] : aucune action", __LINE__ );
				}
			}
		}
		case 2 { # WEB
			# declaration
			my ( $login, $login_w, $mdp, $dom, $prefix ) = get_web( $id );
			my $domain = get_dom( $id );
			my $chem_vhosts = "/home/".$prefix."_vhosts/";
			my $chem_apache = $chem_vhosts."apache/";
			my $chem_root = $chem_vhosts.$login."/".$login_w."/";
			my $chem_tmp = $chem_root."_tmp/";
			my $file = $chem_apache."_template_";
			my $file_cont;
			
			switch ( $action ) {
				case [1, 2] { # activer / desactiver WEB
					my $value = ( $action == 1 ? "770" : "000" );
					system "chmod -R ".$value." ".$chem_root."/";
				}
				case 3 { # creer WEB
					system "mkdir -p ".$chem_root."www/";
					system "mkdir -p ".$chem_root."_log/";
					system "chown -R 33:33 ".$chem_root;
					system "chmod -R 770 ".$chem_root;
					
					open( FILE, $file ) or die "ACTION[WEB] : erreur !\n"; # ouverture du fichier
					&debug( __LINE__, "ACTION[WEB] : lecture du fichier template : ".$file );
					while ( <FILE> ) {
						$file_cont .= $_;
					}
					close( FILE );
					
					$file_cont =~ s/{ROOT}/$chem_root/img;
					$file_cont =~ s/{TMP}/$chem_tmp/img;
					$file_cont =~ s/{DOMAIN}/$domain/img;
				}
				case 4 { # supprimer WEB
					system "rm -rf ".$chem_root;
					system "rm -rf ".$chem_apache.$domain.".conf";
				}
				case 5 { # recharger WEB
					system $chem_init."apache2 reload";
				}
				else {
					&debug( "ACTION[WEB] : aucune action", __LINE__ );
				}
			}
		}
		case 3 { # FTP
			switch ( $action ) {
				case 1 { # activer FTP
				
				}
				case 2 { # desactiver FTP
				
				}
				case 3 { # creer FTP
				
				}
				case 4 { # supprimer FTP
				
				}
				case 5 { # recharger FTP
				
				}
				else {
					&debug( "ACTION[FTP] : aucune action", __LINE__ );
				}
			}
		}
		case 4 { # DNS
			switch ( $action ) {
				case 1 { # activer DNS
					
				}
				case 2 { # desactiver DNS
					
				}
				case 3 { # creer DNS
					
				}
				case 4 { # supprimer DNS
					
				}
				case 5 { # recharger DNS
					
				}
				else {
					&debug( "ACTION[DNS] : aucune action", __LINE__ );
				}
			}
		}
		case 5 { # STREAM
			switch ( $action ) {
				case 1 { # activer STREAM
					
				}
				case 2 { # desactiver STREAM
					
				}
				case 3 { # creer STREAM
					
				}
				case 4 { # supprimer STREAM
					
				}
				case 5 { # recharger STREAM
					
				}
				else {
					&debug( "ACTION[STREAM] : aucune action", __LINE__ );
				}
			}
		}
		case 6 { # GAME
			switch ( $action ) {
				case 1 { # activer GAME
					
				}
				case 2 { # desactiver GAME
					
				}
				case 3 { # creer GAME
					
				}
				case 4 { # supprimer GAME
					
				}
				case 5 { # recharger GAME
					
				}
				else {
					&debug( "ACTION[GAME] : aucune action", __LINE__ );
				}
			}
		}
		case 7 { # IRC
			switch ( $action ) {
				case 1 { # activer IRC
					
				}
				case 2 { # desactiver IRC
					
				}
				case 3 { # creer IRC
					
				}
				case 4 { # supprimer IRC
					
				}
				case 5 { # recharger IRC
					
				}
				else {
					&debug( "ACTION[IRC] : aucune action", __LINE__ );
				}
			}
		}
		case 8 { # BACKUP
			switch ( $action ) {
				case 1 { # activer BACKUP
					
				}
				case 2 { # desactiver BACKUP
					
				}
				case 3 { # creer BACKUP
					
				}
				case 4 { # supprimer BACKUP
					
				}
				case 5 { # recharger BACKUP
					
				}
				else {
					&debug( "ACTION[BACKUP] : aucune action", __LINE__ );
				}
			}
		}
		else {
			&debug( "ACTION : aucune action", __LINE__ );
		}
	}
	
	&debug( "ACTION : fin", __LINE__ );
}

sub afficher_type() {
	&debug( "Liste des types d actions" );

	my $req = $db -> prepare( "
		SELECT
			type_id,
			type_lib
		FROM
			ilk_action_type
		;
	" );
	$req -> execute();

	while ( my ( $id, $lib ) = $req -> fetchrow_array ) {
		&debug( "-> ".$id." : ".$lib );
	}
	$req -> finish();
}

sub afficher_service() {
	&debug( "Liste des services" );

	my $req = $db -> prepare( "
		SELECT
			serv_id,
			serv_lib
		FROM
			ilk_service
		;
	" );
	$req -> execute();

	while ( my ( $id, $lib ) = $req -> fetchrow_array ) {
		&debug( "-> ".$id." : ".$lib );
	}
	$req -> finish();
}

sub main() { # fonction main
	# time
	my ( $sec, $min, $hour, $day_month, $month, $year, $day_week, $day_calendaire, $heure_ete ) = localtime();
	$month += 1;
	$year += 1900;

	&debug( "DATE -> ".$day_month."/".$month."/".$year." ".$hour."h".$min, __LINE__ );

	my $req = $db -> prepare( "
		SELECT
			act_usr_id,
			act_type_id,
			act_serv_id,
			act_other_id
		FROM
			ilk_action,
			ilk_user,
			ilk_action_type,
			ilk_service
		WHERE
			act_usr_id = usr_id
			AND act_type_id = type_id
			AND act_serv_id = serv_id
			AND type_srv_id = '".$srv_id."'
			AND act_etat = 'Y'
			AND ( act_period_min LIKE '%|".$min."|%' OR act_period_min = '' )
			AND ( act_period_hour LIKE '%|".$hour."|%' OR act_period_hour = '' )
			AND ( act_period_day LIKE '%|".$day_month."|%' OR act_period_day = '' )
			AND ( act_period_month LIKE '%|".$month."|%' OR act_period_month = '' )
			AND ( act_period_year LIKE '%|".$year."|%' OR act_period_year = '' )
			AND ( act_period_week_day LIKE '%|".$day_week."|%' OR act_period_week_day = '' )
			AND ( act_period_week LIKE '%|week|%' OR act_period_week = '' )
		;
	" );
	$req -> execute();

	&debug( "MAIN : liste de toutes les actions a executer", __LINE__ );
	while ( my ( $act_usr_id, $act_type_id, $act_serv_id, $act_other_id ) = $req -> fetchrow_array ) {
		&action( $act_serv_id, $act_type_id, $act_usr_id, $act_other_id );
	}
	$req -> finish();
	
	&debug( " --------------------- fin boucle :: ".$nb_req." --------------------- ", __LINE__ );
	$nb_req ++;
}

##### MAIN #####

$debug = ( $ARGV[0] || 0 ); # mode debug

&connexion_bdd( "conn" );

&debug( "LANCEMENT DE PROC" );
&debug( "Server : ".$srv_id );
&debug( "Timeout : ".$timeout." secondes" );

&afficher_type();
&afficher_service();

while ( 1 ) { # boucle infinie
	&debug( " -------------------- debut boucle :: ".$nb_req." -------------------- ", __LINE__ );
	&main(); # fonction main
	sleep( $timeout ); # pause de x secondes
}

&connexion_bdd( "deconn" );
