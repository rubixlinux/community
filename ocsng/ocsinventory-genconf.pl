#!/usr/bin/perl 

###############################################################################
##OCS inventory Version 1.0 RC1
##Copyleft Pascal DANEK 2005
##Web : http://ocsinventory.sourceforge.net
##
##This code is open source and may be copied and modified as long as the source
##code is always made freely available.
##Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################
use constant VERSION => '1.0-RC1';
#################################################
#Installation script for OcsInventory Linux Agent
#################################################
use XML::Simple;
use Compress::Zlib;
use Compress::Zlib;
use LWP::UserAgent;
use Net::IP qw(:PROC);
################
#THE SUBROUTINES
################

sub _deco{	
	system "clear";
	print <<HERE;
##################################################
#INSTALLATION SCRIPT FOR OCSINVENTORY LINUX AGENT#
##################################################



HERE
}

sub _method{
	#Local or export http?
	#If local, user will have to run the agent himself, and tranfer the compressed inventory on the ocs web server
	$err = 0;
	&_deco;
	while(!($err)){
		print "Wich method will you use to generate the inventory (http/Local): ";
		chomp($export=<STDIN>);
		($export=~/^http$|^local$/i)?$err=1:print "\nChoose a valid method (http ou local)\n";
	}
	#Server name
	#'Local' if not connected to the network
	if($export=~/http/i){
		print "\nServer name : ";
		chomp($ServerName=<STDIN>);
	}else{
		$ServerName='local';
	
	}
}	


#Creation of Device ID
sub _id{
	#Generation de l'identifiant
	chomp($Device=`hostname`);
	($YEAR, $MONTH , $DAY, $HOUR, $MIN, $SEC)=(localtime (time))[5,4,3,2,1,0];
	$DeviceID=sprintf "%s-%02d-%02d-%02d-%02d-%02d-%02d",  $Device, ($YEAR+1900), ($MONTH+1), $DAY, $HOUR, $MIN, $SEC;
}
	

#Request for auto-update
sub _update{
	&_deco;
	$fin=1;
	while($fin){
		print "Will you activate the auto-update ? (y/n) : ";
		chomp($AuthUpdate=<STDIN>);
		if($AuthUpdate=~/^y$|^n$/i){
			$fin=0;
			$AuthUpdate=~/^y$/?($AuthUpdate=1):($AuthUpdate=0);
		}
	}
}

sub _tag{
	#It's possible to put a file into the installation directory to be more explicit with the user concerning the tag nature.
	#Just put a text file with the keyword of the tag (exemple : service, unitid....)
	&_deco;
	if(-f "label"){
		open LABEL , "label";
		chomp($label=<LABEL>);
		close LABEL;
	}
	
	printf("Type the %s or return : ", $label?$label:'tag');
	chomp($tag=<STDIN>);
}


#Menu
sub _menu{	
	$choix=1;
	while($choix){
		&_deco;
		#Show the existing parameters
		print "\nCurrent parameters :\n\n";
		print "\t--- Account infos ---\n" if (keys %account);
		for(keys %account){
			print "\t\t".$_." = ".$account{$_}."\n";
		}
		print "\n\n";
		print                      "\t(1)Generating method      = $export\n";
		if($export=~/http/){print  "\t(1)Server name            = $ServerName\n";}	
		printf(                    "\t(2)Auto-update            = %s\n", $AuthUpdate?'on':'off');
		printf(    "\n\t(3)%s = $tag\n",$label?$label:'tag');
		
		print "\n\nType the number of the field you want to modify (or type '0') : ";
		chomp($choix=<STDIN>);
		if($choix==1){&_method}
		if($choix==2){&_update}
		if($choix==3){&_tag}
		if(($choix!=1)&&($choix!=2)&&($choix!=0)){
			print "Don't understand your choice\n"
		}
	}
}


#####
#MAIN
#####

####################
#Looking for context
####################

#Permissions checking
(-w "/etc") && (-w "/etc/cron.daily")?1:die "You don't have enough permissions to run this program. Are you really root ?\n";

&_deco;

&_id;
&_method;
&_update;
&_tag;
		
#############
#INSTALLATION
#############

$fin=1;
while($fin){	
	&_deco;
	#Print the inputs
	print "Your inputs :\n\n";
	print                     "\tGenerating method   = $export\n";
	if($export=~/http/){print "\tServer name         = $ServerName\n";}
	printf(                   "\tAuto-update         = %s\n", $AuthUpdate?'on':'off');
	printf("\n\t%s = $tag\n",$label?$label:'tag');
	print  "\nDo you confirm ?  (y/[n]) : ";
	
	chomp ($choix=<STDIN>);
	if($choix=~/^y/i){$fin=0;}
	else{$fin=1; &_menu}
}

##########
#Writings
##########

#writing of ocs.conf
$xmlconf{'DEVICEID'} = [ $DeviceID ];
$xmlconf{'OCSFSERVER'} = [ $ServerName ];
$xmlconf{'DMIVERSION'} = [ "1" ];
$xmlconf{'IPDISCOVER_VERSION'} = [ "1" ];
$xmlconf{'UPDATE'} = [ "1" ] if $AuthUpdate;
$xml = XML::Simple::XMLout( \%xmlconf, RootName => 'CONF' );
open CONF, ">/etc/ocsinventory-client/ocsinv.conf";
print CONF $xml;
close CONF;

open ADM, ">/etc/ocsinventory-client/ocsinv.adm" or warn "Cannot create account info file\n";
$xmladm{'ACCOUNTINFO'}[0]{'KEYNAME'} = [ "TAG" ];
$xmladm{'ACCOUNTINFO'}[0]{'KEYVALUE'} = [ $tag ];
$xml=XML::Simple::XMLout( \%xmladm , RootName=> "ADM");
print ADM $xml;
close ADM;
