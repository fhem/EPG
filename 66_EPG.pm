#################################################################
# $Id: 66_EPG.pm 15699 2019-10-26 21:17:50Z HomeAuto_User $
#
# Github - FHEM Home Automation System
# https://github.com/fhem/EPG
#
# 2019 - HomeAuto_User & elektron-bbs
#
#################################################################
# Varianten der Informationen:
# *.gz      -> ohne & mit Dateiendung nach unpack
# *.xml     -> ohne unpack
# *.xml.gz  -> mit Dateiendung xml nach unpack
# *.xz      -> ohne Dateiendung nach unpack
#################################################################

package main;

use strict;
use warnings;
use HttpUtils;					# https://wiki.fhem.de/wiki/HttpUtils
use Data::Dumper;

my $missingModulEPG = "";
eval "use XML::Simple;1" or $missingModulEPG .= "XML::Simple (cpanm XML::Simple)";

my @channel_available;
my %progamm;
my %HTML;

#####################
sub EPG_Initialize($) {
	my ($hash) = @_;

	$hash->{DefFn}                 = "EPG_Define";
	$hash->{SetFn}                 = "EPG_Set";
	$hash->{GetFn}                 = "EPG_Get";
	$hash->{AttrFn}                = "EPG_Attr";
	$hash->{NotifyFn}              = "EPG_Notify";
  $hash->{FW_detailFn}           = "EPG_FW_Detail";
	$hash->{FW_deviceOverview}     = 1;
	$hash->{FW_addDetailToSummary} = 1;                # displays html in fhemweb room-view
	$hash->{AttrList}              =	"disable DownloadURL DownloadFile Variant:Rytec,TvProfil_XMLTV,WebGrab+Plus,XMLTV.se Channels";
												             #$readingFnAttributes;
}

#####################
sub EPG_Define($$) {
	my ($hash, $def) = @_;
	my @arg = split("[ \t][ \t]*", $def);
	my $name = $arg[0];									## Definitionsname
	my $typ = $hash->{TYPE};						## Modulname
	my $filelogName = "FileLog_$name";
	my ($autocreateFilelog, $autocreateHash, $autocreateName, $autocreateDeviceRoom, $autocreateWeblinkRoom) = ('%L' . $name . '-%Y-%m.log', undef, 'autocreate', $typ, $typ);
	my ($cmd, $ret);

	return "Usage: define <name> $name"  if(@arg != 2);
	
	if ($init_done) {
		if (!defined(AttrVal($autocreateName, "disable", undef)) && !exists($defs{$filelogName})) {
			### create FileLog ###
			$autocreateFilelog = AttrVal($autocreateName, "filelog", undef) if (defined AttrVal($autocreateName, "filelog", undef));
			$autocreateFilelog =~ s/%NAME/$name/g;
			$cmd = "$filelogName FileLog $autocreateFilelog $name";
			Log3 $filelogName, 2, "$name: define $cmd";
			$ret = CommandDefine(undef, $cmd);
			if($ret) {
				Log3 $filelogName, 2, "$name: ERROR: $ret";
			} else {
				### Attributes ###
				CommandAttr($hash,"$filelogName room $autocreateDeviceRoom");
				CommandAttr($hash,"$filelogName logtype text");
				CommandAttr($hash,"$name room $autocreateDeviceRoom");
			}
		}

		### Attributes ###
		CommandAttr($hash,"$name room $typ") if (!defined AttrVal($name, "room", undef));				# set room, if only undef --> new def
	}
	
	### default value´s ###
	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "state" , "Defined");
	readingsEndUpdate($hash, 0);
	return undef;
}

#####################
sub EPG_Set($$$@) {
	my ( $hash, $name, @a ) = @_;
	my $setList = "";
	my $cmd = $a[0];

	return "no set value specified" if(int(@a) < 1);

	if ($cmd ne "?") {
		return "development";
	}

	return $setList if ( $a[0] eq "?");
	return "Unknown argument $cmd, choose one of $setList" if (not grep /$cmd/, $setList);
	return undef;
}

#####################
sub EPG_Get($$$@) {
	my ( $hash, $name, $cmd, @a ) = @_;
	my $cmd2 = $a[0];
	my $getlist = "loadFile:noArg ";
	my $Channels = AttrVal($name, "Channels", undef);
	my $DownloadURL = AttrVal($name, "DownloadURL", undef);
	my $DownloadFile = AttrVal($name, "DownloadFile", undef);
	my $EPG_file_name = InternalVal($name, "EPG_file_name", undef);
	my $Variant = AttrVal($name, "Variant", undef);
	my $TimeNow = FmtDateTime(time());
	
	if ($Variant) {
		$getlist.= "available_channels:noArg " if (InternalVal($name, "EPG_file_age", undef) && InternalVal($name, "EPG_file_age", undef) ne "unknown or no file found");
	}

	if (AttrVal($name, "Channels", undef) && scalar(@channel_available) > 0 && AttrVal($name, "Channels", undef) ne "" && AttrVal($name, "Variant", undef)) {
		$getlist.= "loadEPG_now:noArg ";               # now
		$getlist.= "loadEPG_Prime:noArg ";             # Primetime
		$getlist.= "loadEPG_today:noArg ";             # today all

		my $TimeNowMod = $TimeNow;
		$TimeNowMod =~ s/-|:|\s//g;

		# every hour list #
		my $loadEPG_list = "";
		for my $d (substr($TimeNowMod,8, 2) +1 .. 23) {
			$loadEPG_list.= substr($TimeNowMod,0, 8)."_".sprintf("%02s",$d)."00,";
		}

		if ($loadEPG_list =~ /,$/) {
			$loadEPG_list = substr($loadEPG_list,0, -1);
			$getlist.= "loadEPG:".$loadEPG_list." " ;
		}
	}

	my $ch_id;
	my $obj;
	my $state;
	my $xml;

	if ($cmd ne "?") {
		return "ERROR: no Attribute DownloadURL or DownloadFile defined - Please check!" if (!$DownloadURL || !$DownloadFile);
		return "ERROR: you need ".$missingModulEPG."package to use this command!" if ($missingModulEPG ne "");
		return "ERROR: You need the directory ./FHEM/EPG to download!" if (! -d "FHEM/EPG");
	}

	if ($cmd eq "loadFile") {
		EPG_PerformHttpRequest($hash);
		Log3 $name, 4, "$name: Get | $cmd successful";
		return undef;
	}

	if ($cmd eq "available_channels") {
		Log3 $name, 4, "$name: Get | $cmd read file $EPG_file_name";
		return "ERROR: no EPG_file_name" if !($EPG_file_name);

		@channel_available = ();
		%progamm = ();

		if (-e "/opt/fhem/FHEM/EPG/$EPG_file_name") {
			open (FileCheck,"</opt/fhem/FHEM/EPG/$EPG_file_name");
				while (<FileCheck>) {
					# <tv generator-info-name="Rytec" generator-info-url="http://forums.openpli.org">
					$hash->{EPG_file_format} = "Rytec" if ($_ =~ /.*generator-info-name="Rytec".*/);
					# <tv source-data-url="http://api.tvprofil.net/" source-info-name="TvProfil API v1.7 - XMLTV" source-info-url="https://tvprofil.com">
					$hash->{EPG_file_format} = "TvProfil_XMLTV" if ($_ =~ /.*source-info-name="TvProfil.*/);
					# <tv generator-info-name="WebGrab+Plus/w MDB &amp; REX Postprocess -- version V2.1.5 -- Jan van Straaten" generator-info-url="http://www.webgrabplus.com">
					$hash->{EPG_file_format} = "WebGrab+Plus" if ($_ =~ /.*generator-info-name="WebGrab+Plus.*/);
					#XMLTV.se       <tv generator-info-name="Vind 2.52.12" generator-info-url="https://xmltv.se">
					$hash->{EPG_file_format} = "XMLTV.se" if ($_ =~ /.*generator-info-url="https:\/\/xmltv.se.*/);

					$ch_id = $1 if ($_ =~ /<channel id="(.*)">/);
					if ($_ =~ /<display-name lang=".*">(.*)<.*/) {
						Log3 $name, 5, "$name: Get | $cmd id: $ch_id -> display_name: ".$1;
						$progamm{$ch_id}{name} = $1;
						push(@channel_available,$1);
					}
				}
			close FileCheck;

			@channel_available = sort @channel_available;
			$state = "available channels loaded";
			CommandAttr($hash,"$name Variant $hash->{EPG_file_format}") if ($hash->{EPG_file_format});		# setzt Variante von EPG_File
			FW_directNotify("FILTER=$name", "#FHEMWEB:WEB", "location.reload('true')", "");		            # reload Webseite
			readingsSingleUpdate($hash, "state", $state, 1);
		} else {
			$state = "ERROR: $Variant Canceled";
			Log3 $name, 3, "$name: $cmd | error, file $EPG_file_name no found at ./opt/fhem/FHEM/EPG";
			return "ERROR: no file found!";
		}
		return undef;
	}

	if ($cmd =~ /^loadEPG/) {
		%HTML = ();                # reset hash for HTML
		my $start = "";            # TV time start
		my $end = "";              # TV time end
		my $ch_found = 0;          # counter to verification ch
		my $data_found = 0;        # counter to verification data
		my $ch_name = "";          # TV channel name
		my $title = "";            # TV title
		my $subtitle = "";         # TV subtitle
		my $desc = "";             # TV desc
		my $today_start = "";      # today time start
		my $today_end = "";        # today time end
		my $hour_diff_read = "";   # hour diff from file

		Log3 $name, 4, "$name: $cmd from file $EPG_file_name";
		#Log3 $name, 3, "$name: Get | $TimeNow";

		my $off_h = 0;
		my @local = (localtime(time+$off_h*60*60));
		my @gmt = (gmtime(time+$off_h*60*60));
		my $TimeLocaL_GMT_Diff = $gmt[2]-$local[2] + ($gmt[5] <=> $local[5] || $gmt[7] <=> $local[7])*24;
		if ($TimeLocaL_GMT_Diff < 0) {
			$TimeLocaL_GMT_Diff = abs($TimeLocaL_GMT_Diff);
			$TimeLocaL_GMT_Diff = "+".sprintf("%02s", abs($TimeLocaL_GMT_Diff))."00";
		} else {
			$TimeLocaL_GMT_Diff = sprintf("-%02s", $TimeLocaL_GMT_Diff) ."00";
		}

		Log3 $name, 4, "$name: $cmd localtime     ".localtime(time+$off_h*60*60);
		Log3 $name, 4, "$name: $cmd gmtime        ".gmtime(time+$off_h*60*60);
		Log3 $name, 4, "$name: $cmd diff (GMT-LT) " . $TimeLocaL_GMT_Diff;

		$TimeNow =~ s/-|:|\s//g;
		$TimeNow.= " $TimeLocaL_GMT_Diff";       # loadEPG_now   20191016150432 +0200

		if ($cmd eq "loadEPG_Prime") {
			if (substr($TimeNow,8, 2) > 20) {                      # loadEPG_Prime 20191016201510 +0200	morgen wenn Prime derzeit läuft
				my @time = split(/-\s:/,FmtDateTime(time()));
				$TimeNow = FmtDateTime(time() - ($time[5] + $time[4] * 60 + $time[3] * 3600) + 86400);
				$TimeNow =~ s/-|:|\s//g;
				$TimeNow.= " +0200";
				substr($TimeNow, 8) = "201510 $TimeLocaL_GMT_Diff";
			} else {                                               # loadEPG_Prime 20191016201510 +0200	heute
				substr($TimeNow, 8) = "201510 $TimeLocaL_GMT_Diff";
			}
		}
			
		if ($cmd eq "loadEPG_today") {                           # Beginn und Ende von heute bestimmen
			$today_start = substr($TimeNow,0,8)."000000 $TimeLocaL_GMT_Diff";
			$today_end = substr($TimeNow,0,8)."235959 $TimeLocaL_GMT_Diff";
		}

		if ($cmd eq "loadEPG" && $cmd2 =~ /^[0-9]*_[0-9]*$/) {   # loadEPG 20191016_200010 +0200 stündlich ab jetzt
			$cmd2 =~ s/_//g;
			$cmd2.= "10 $TimeLocaL_GMT_Diff";
			$TimeNow = $cmd2;
		}
		
		Log3 $name, 4, "$name: $cmd | TimeNow          -> $TimeNow";

		if (-e "/opt/fhem/FHEM/EPG/$EPG_file_name") {
			open (FileCheck,"</opt/fhem/FHEM/EPG/$EPG_file_name");
				while (<FileCheck>) {
					if ($_ =~ /<programme start="(.*\s+(.*))" stop="(.*)" channel="(.*)"/) {   ## find start | end | channel
						my $search = $progamm{$4}->{name};
						if (grep /$search($|,)/, $Channels) {                                    ## find in attributes channel
							($start, $hour_diff_read, $end, $ch_name) = ($1, $2, $3, $progamm{$4}->{name});
							if ($TimeLocaL_GMT_Diff ne $hour_diff_read) {
								#Log3 $name, 4, "$name: $cmd | Time must be recalculated! local=$TimeLocaL_GMT_Diff read=$2";
								my $hour_diff = substr($TimeLocaL_GMT_Diff,0,1).substr($TimeLocaL_GMT_Diff,2,1);
								#Log3 $name, 4, "$name: $cmd | hour_diff_result $hour_diff";

								my @start_new = split("",$start);
								my @end_new = split("",$end);
								#Log3 $name, 4, "$name: $cmd | ".'sec | min | hour | mday | month | year';
								#Log3 $name, 4, "$name: $cmd | $start_new[12]$start_new[13]  | $start_new[10]$start_new[11]  |  $start_new[8]$start_new[9]  | $start_new[6]$start_new[7]   | $start_new[4]$start_new[5]    | $start_new[0]$start_new[1]$start_new[2]$start_new[3]";
								#Log3 $name, 4, "$name: $cmd | $end_new[12]$end_new[13]  | $end_new[10]$end_new[11]  |  $end_new[8]$end_new[9]  | $end_new[6]$end_new[7]   | $end_new[4]$end_new[5]    | $end_new[0]$end_new[1]$end_new[2]$end_new[3]";
								#Log3 $name, 4, "$name: $cmd | UTC start        -> ".fhemTimeLocal(($start_new[12].$start_new[13]), ($start_new[10].$start_new[11]), ($start_new[8].$start_new[9]), ($start_new[6].$start_new[7]), (($start_new[4].$start_new[5])*1-1), (($start_new[0].$start_new[1].$start_new[2].$start_new[3])*1-1900));
								#Log3 $name, 4, "$name: $cmd | UTC end          -> ".fhemTimeLocal(($end_new[12].$end_new[13]), ($end_new[10].$end_new[11]), ($end_new[8].$end_new[9]), ($end_new[6].$end_new[7]), (($end_new[4].$end_new[5])*1-1), (($end_new[0].$end_new[1].$end_new[2].$end_new[3])*1-1900));
								#Log3 $name, 4, "$name: $cmd | start            -> $start";             # 20191023211500 +0000
								#Log3 $name, 4, "$name: $cmd | end              -> $end";               # 20191023223000 +0000

								if (index($hour_diff,"-")) {
									$start = fhemTimeLocal(($start_new[12].$start_new[13]), ($start_new[10].$start_new[11]), ($start_new[8].$start_new[9]), ($start_new[6].$start_new[7]), (($start_new[4].$start_new[5])*1-1), (($start_new[0].$start_new[1].$start_new[2].$start_new[3])*1-1900)) + (60*60*abs(substr($TimeLocaL_GMT_Diff,2,1)));
									$end = fhemTimeLocal(($end_new[12].$end_new[13]), ($end_new[10].$end_new[11]), ($end_new[8].$end_new[9]), ($end_new[6].$end_new[7]), (($end_new[4].$end_new[5])*1-1), (($end_new[0].$end_new[1].$start_new[2].$start_new[3])*1-1900)) + (60*60*abs(substr($TimeLocaL_GMT_Diff,2,1)));
								} else {
									$start = fhemTimeLocal(($start_new[12].$start_new[13]), ($start_new[10].$start_new[11]), ($start_new[8].$start_new[9]), ($start_new[6].$start_new[7]), (($start_new[4].$start_new[5])*1-1), (($start_new[0].$start_new[1].$start_new[2].$start_new[3])*1-1900)) - (60*60*abs(substr($TimeLocaL_GMT_Diff,2,1)));
									$end = fhemTimeLocal(($end_new[12].$end_new[13]), ($end_new[10].$end_new[11]), ($end_new[8].$end_new[9]), ($end_new[6].$end_new[7]), (($end_new[4].$end_new[5])*1-1), (($end_new[0].$end_new[1].$start_new[2].$start_new[3])*1-1900)) - (60*60*abs(substr($TimeLocaL_GMT_Diff,2,1)));
								}

								#Log3 $name, 4, "$name: $cmd | UTC start new    -> $start";
								#Log3 $name, 4, "$name: $cmd | UTC end new      -> $end";

								$start = FmtDateTime($start);
								$end = FmtDateTime($end);
								$start =~ s/-|:|\s//g;
								$end =~ s/-|:|\s//g;
								$start.= " $TimeLocaL_GMT_Diff";
								$end.= " $TimeLocaL_GMT_Diff";

								#Log3 $name, 4, "$name: $cmd | start new        -> $start";
								#Log3 $name, 4, "$name: $cmd | end new          -> $end";
							}

							if ($cmd ne "loadEPG_today") {
								$ch_found++ if ($TimeNow gt $start && $TimeNow lt $end);             ## Zeitpunktsuche, normal
							} else {
								$ch_found++ if ($today_end gt $start && $today_start lt $end);       ## Zeitpunktsuche, kompletter Tag
							}
						}
					}
					$title = $2 if ($_ =~ /<title lang="(.*)">(.*)<\/title>/ && $ch_found != 0);             ## find title
					$subtitle = $2 if ($_ =~ /<sub-title lang="(.*)">(.*)<\/sub-title>/ && $ch_found != 0);  ## find subtitle
					$desc = $2 if ($_ =~ /<desc lang="(.*)">(.*)<\/desc>/ && $ch_found != 0);                ## find desc

					if ($_ =~ /<\/programme>/ && $ch_found != 0) {   ## find end channel
						$data_found++;
						Log3 $name, 4, "$name: $cmd | ch_name          -> $ch_name";        # ZDF

						$HTML{$ch_name}{$data_found}{ch_name} = $ch_name;
						$HTML{$ch_name}{$data_found}{start} = $start;
						$HTML{$ch_name}{$data_found}{end} = $end;
						$HTML{$ch_name}{$data_found}{hour_diff} = $hour_diff_read;
						Log3 $name, 4, "$name: $cmd | title            -> $title";
						$HTML{$ch_name}{$data_found}{title} = $title;
						Log3 $name, 4, "$name: $cmd | subtitle         -> $subtitle";
						$HTML{$ch_name}{$data_found}{subtitle} = $subtitle;
						Log3 $name, 4, "$name: $cmd | desc             -> $desc.\n";
						$HTML{$ch_name}{$data_found}{desc} = $desc;

						$ch_found = 0;
						$ch_name = "";
						$desc = "";
						$hour_diff_read = "";
						$subtitle = "";
						$title = "";
					}
				}
			close FileCheck;

			$hash->{EPG_data} = "all channel information loaded" if ($data_found != 0);
			$hash->{EPG_data} = "no channel information available!" if ($data_found == 0);
		} else {
			readingsSingleUpdate($hash, "state", "ERROR: loaded Information Canceled. file not found!", 1);
			Log3 $name, 3, "$name: $cmd | error, file $EPG_file_name no found at ./opt/fhem/FHEM/EPG";
			return "ERROR: no file found!";
		}
			
		#Log3 $name, 3, "$name: ".Dumper\%HTML;
		FW_directNotify("FILTER=(room=)?$name", "#FHEMWEB:WEB", "location.reload('true')", "") if (scalar keys %HTML  != 0);
		return undef;
	}
	return "Unknown argument $cmd, choose one of $getlist";
}

#####################
sub EPG_Attr() {
	my ($cmd, $name, $attrName, $attrValue) = @_;
	my $hash = $defs{$name};
	my $typ = $hash->{TYPE};

	if ($cmd eq "set") {
		if ($attrName eq "disable") {
			if ($attrValue == 1) {
			}
			
			if ($attrValue == 0) {
			}
		}

		if ($attrName eq "DownloadURL") {
			return "Your website entry must end with /\n\nexample: $attrValue/" if ($attrValue !~ /.*\/$/);
			return "Your input must begin with http:// or https://" if ($attrValue !~ /^htt(p|ps):\/\//);
		}
	}
}

#####################
sub EPG_FW_Detail($@) {
	my ($FW_wname, $name, $room, $pageHash) = @_;
	my $hash = $defs{$name};
	my $Channels = AttrVal($name, "Channels", undef);
	my $cnt = 0;
	my $ret = "";
	
	Log3 $name, 5, "$name: FW_Detail is running";

	if ($Channels) {
		my @Channels_value = split(",", $Channels);
		$cnt = scalar(@Channels_value);
	}

	if (scalar(@channel_available) > 0) {
		if ($FW_detail) {
			### Control panel ###
			$ret .= "<div class='makeTable wide'><span>Control panel</span>
							<table class='block wide' id='EPG_InfoMenue' nm='$hash->{NAME}' class='block wide'>
							<tr class='even'>";

			$ret .= "<td><a href='#button1' id='button1'>list of all available channels</a></td>";
			$ret .= "<td> readed channels:". scalar(@channel_available) ."</td>";
			$ret .= "<td> selected channels: ". $cnt ."</td>";
			$ret .= "</tr></table></div>";
		}

		### Javascript ###
		$ret .= '
			<script>

			$( "#button1" ).click(function(e) {
				e.preventDefault();
				FW_cmd(FW_root+\'?cmd={EPG_FW_Channels("'.$name.'")}&XHR=1"'.$FW_CSRF.'"\', function(data){EPG_ListWindow(data)});
			});

			function EPG_ListWindow(txt) {
				var div = $("<div id=\"EPG_ListWindow\">");
				$(div).html(txt);
				$("body").append(div);
				var oldPos = $("body").scrollTop();

				$(div).dialog({
					dialogClass:"no-close", modal:true, width:"auto", closeOnEscape:true, 
					maxHeight:$(window).height()*0.95,
					title: "'.$name.' Channel Overview",
					buttons: [
						{text:"select all", click:function(){
							$("#EPG_ListWindow table td input:checkbox").prop(\'checked\', true);
						}},
						{text:"deselect all", click:function(){
							$("#EPG_ListWindow table td input:checkbox").prop(\'checked\', false);
						}},
						{text:"save", click:function(){
							var allVals = [];
							$("#EPG_ListWindow input:checkbox:checked").each(function() {
							allVals.push($(this).attr(\'name\'));
							})
							FW_cmd(FW_root+ \'?XHR=1"'.$FW_CSRF.'"&cmd={EPG_FW_Attr_Channels("'.$name.'","\'+allVals+\'")}\');

							$(this).dialog("close");
							$(div).remove();
							location.reload();
						}},
						{text:"close", click:function(){
							$(this).dialog("close");
							$(div).remove();
						}}]
				});
			}

			/* checkBox Werte von Checkboxen Wochentage */
			function Checkbox(id) {
				var checkBox = document.getElementById(id);
				if (checkBox.checked) {
					checkBox.value = 1;
				} else {
					checkBox.value = 0;
				}
			}

		</script>';

		### HTML ###
		
		$ret .= "<div id=\"table\"><center>- no EPG Data -</center></div>" if (scalar keys %HTML  == 0);
		if (scalar keys %HTML != 0) {
			my $ch_name = "";
			my $start = "";
			my $end = "";
			my $title = "";
			my $subtitle = "";
			my $desc = "";
			my $cnt_infos = 0;

			$ret .= "<div id=\"table\"><table class=\"block wide\">";
			$ret .= "<tr class=\"even\" style=\"text-decoration:underline; text-align:left;\"><th>Sender</th><th>Start</th><th>Ende</th><th>Sendung</th></tr>";
	
			foreach my $ch (sort keys %HTML) {
				foreach my $value (sort {$a <=> $b} keys %{$HTML{$ch}}) {
					foreach my $d (keys %{$HTML{$ch}{$value}}) {
						$ch_name = $HTML{$ch}{$value}{$d} if ($d eq "ch_name");
						$start = substr($HTML{$ch}{$value}{$d},8,2).":".substr($HTML{$ch}{$value}{$d},10,2) if ($d eq "start");
						$end = substr($HTML{$ch}{$value}{$d},8,2).":".substr($HTML{$ch}{$value}{$d},10,2) if ($d eq "end");
						$title = $HTML{$ch}{$value}{$d} if ($d eq "title");
						$desc = $HTML{$ch}{$value}{$d} if ($d eq "desc");					
					}
					$cnt_infos++;
					## Darstellung als Link wenn Sendungsbeschreibung ##
					$ret .= sprintf("<tr class=\"%s\">", ($cnt_infos & 1)?"odd":"even");
					if ($desc ne "") {
						#Log3 $name, 3, "$name: $desc";
						$desc =~ s/"/&quot;/g if (grep /"/, $desc);  # "
						$desc =~ s/'/\\'/g if (grep /'/, $desc);     # '
						$ret .= "<td>$ch_name</td><td>$start</td><td>$end</td><td><a href=\"#!\" onclick=\"FW_okDialog(\'$desc\')\">$title</a></td></tr>";
					} else {
						$ret .= "<td>$ch_name</td><td>$start</td><td>$end</td><td>$title</td></tr>";
					}
					
				}
			}			

			$ret .= "</table></div>";
		}
	}

	return $ret;
}

##################### (Aufbau HTML Tabelle available channels)
sub EPG_FW_Channels {
	my $name = shift;
	my $ret = "";
	my $Channels = AttrVal($name, "Channels", undef);
	my $checked = "";
	my $style_background = "";

	Log3 $name, 4, "$name: FW_Channels is running";

	$ret.= "<table>";
	$ret.= "<tr style=\"text-decoration-line: underline;\"><td>no.</td><td>active</td><td>TV station name</td></tr>";

	for (my $i=0; $i<scalar(@channel_available); $i++) {
		$style_background = "background-color:#F0F0D8;" if ($i % 2 == 0);
		$style_background = "" if ($i % 2 != 0);
		$checked = "checked" if ($Channels && index($Channels,$channel_available[$i]) >= 0);
		$ret.= "<tr style=\"$style_background\"><td align=\"center\">".($i + 1)."</td><td align=\"center\"><input type=\"checkbox\" id=\"".$i."\" name=\"".$channel_available[$i]."\" onclick=\"Checkbox(".$i.")\" $checked></td><td>". $channel_available[$i] ."</td></tr>";
		$checked = "";
	}
	
	$ret.= "</table>";

	return $ret;
}

##################### (Anpassung Attribute Channels)
sub EPG_FW_Attr_Channels {
	my $name = shift;
	my $hash = $defs{$name};
	my $Channels = shift;

	Log3 $name, 4, "$name: FW_Attr_Channels is running";
	CommandAttr($hash,"$name Channels $Channels") if ($Channels ne "");

	if ($Channels eq "") {
		%progamm = ();
		CommandDeleteAttr($hash,"$name Channels");
		readingsSingleUpdate($hash, "state", "no channels selected", 1);
	}
}

#####################
sub EPG_PerformHttpRequest($) {
	my ($hash, $def) = @_;
	my $name = $hash->{NAME};
	my $DownloadURL = AttrVal($name, "DownloadURL", undef);
	my $DownloadFile = AttrVal($name, "DownloadFile", undef);

	Log3 $name, 4, "$name: EPG_PerformHttpRequest is running";
	my $http_param = { 	url        => $DownloadURL.$DownloadFile,
											timeout    => 10,
											hash       => $hash,                                     # Muss gesetzt werden, damit die Callback funktion wieder $hash hat
											method     => "GET",                                     # Lesen von Inhalten
											callback   => \&EPG_ParseHttpResponse                    # Diese Funktion soll das Ergebnis dieser HTTP Anfrage bearbeiten
							};
	HttpUtils_NonblockingGet($http_param);                                       # Starten der HTTP Abfrage
}

#####################
sub EPG_ParseHttpResponse($$$) {
	my ($http_param, $err, $data) = @_;
	my $hash = $http_param->{hash};
	my $name = $hash->{NAME};
	my $DownloadFile = AttrVal($name, "DownloadFile", undef);
	my $HttpResponse = "";
	my $state = "no information received";
	my $FileAge = undef;

	Log3 $name, 5, "$name: ParseHttpResponse - error: $err";
	Log3 $name, 5, "$name: ParseHttpResponse - http code: ".$http_param->{code};

	if ($err ne "") {                                                          # wenn ein Fehler bei der HTTP Abfrage aufgetreten ist
		$HttpResponse = $err;
		Log3 $name, 3, "$name: ParseHttpResponse - error: $err";
	} elsif ($http_param->{code} ne "200") {                                   # HTTP code
		$HttpResponse = "DownloadFile $DownloadFile was not found on URL" if (grep /$DownloadFile\swas\snot\sfound/, $data);
		$HttpResponse = "DownloadURL was not found" if (grep /URL\swas\snot\sfound/, $data);
		Log3 $name, 3, "$name: ParseHttpResponse - error:\n\n$data";
	} elsif ($http_param->{code} eq "200" && $data ne "") {                    # wenn die Abfrage erfolgreich war ($data enthält die Ergebnisdaten des HTTP Aufrufes)
   	my $filename = "FHEM/EPG/$DownloadFile";
		open(my $file, ">", $filename);                                          # Datei schreiben
			print $file $data;
		close $file;

		local $SIG{CHLD} = 'DEFAULT';
		if ($DownloadFile =~ /.*\.gz$/) {
			qx(gzip -d -f /opt/fhem/FHEM/EPG/$DownloadFile 2>&1);                  # Datei Unpack gz
		} elsif ($DownloadFile =~ /.*\.xz$/) {
			qx(xz -df /opt/fhem/FHEM/EPG/$DownloadFile 2>&1);                      # Datei Unpack xz
		}

		if ($? != 0 && $DownloadFile =~ /\.(gz|xz)/) {
			@channel_available = ();
			%progamm = ();
			$state = "ERROR: unpack $DownloadFile";
		} else { 
			EPG_File_check($hash);
			$state = "information received";
		}

		$HttpResponse = "downloaded";
	}

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "HttpResponse", $HttpResponse);                  # HttpResponse Status
	readingsBulkUpdate($hash, "state", $state);
	readingsEndUpdate($hash, 1);

	HttpUtils_Close($http_param);
}

#####################
sub EPG_Notify($$) {
	my ($hash, $dev_hash) = @_;
	my $name = $hash->{NAME};
	my $typ = $hash->{TYPE};
	return "" if(IsDisabled($name));	                                        # Return without any further action if the module is disabled
	my $devName = $dev_hash->{NAME};	                                        # Device that created the events
	my $events = deviceEvents($dev_hash, 1);
	my $DownloadFile = AttrVal($name, "DownloadFile", undef);

	if($devName eq "global" && grep(m/^INITIALIZED|REREADCFG$/, @{$events}) && $typ eq "EPG") {
		Log3 $name, 5, "$name: Notify is running and starting";
		EPG_File_check($hash) if ($DownloadFile);
	}

	return undef;
}

#####################
sub EPG_File_check {
	my ($hash) = @_;
	my $name = $hash->{NAME};
	my $DownloadFile = AttrVal($name, "DownloadFile", "no file found");
	my $DownloadFile_found = 0;
	my $FileAge = "unknown";

	Log3 $name, 5, "$name: File_check is running";

	## check files ##
	opendir(DIR,"/opt/fhem/FHEM/EPG");																		# not need -> || return "ERROR: directory $path can not open!"
		while( my $directory_value = readdir DIR ){
			if (index($DownloadFile,$directory_value) >= 0 && $directory_value ne "." && $directory_value ne ".." && $directory_value !~ /\.(gz|xz)/) {
				$DownloadFile = $directory_value;
				$DownloadFile_found++;
			}
		}
	close DIR;

	if ($DownloadFile_found != 0) {
		my @stat_DownloadFile = stat("/opt/fhem/FHEM/EPG/".$DownloadFile);  # Dateieigenschaften
		$FileAge = FmtDateTime($stat_DownloadFile[9]);                      # letzte Änderungszeit
		CommandGet($hash,"$name available_channels");
	} else {
		$DownloadFile = "file not found";
	}

	$hash->{EPG_file_age} = $FileAge;
	$hash->{EPG_file_name} = $DownloadFile;
	FW_directNotify("FILTER=$name", "#FHEMWEB:WEB", "location.reload('true')", "");
}

# Eval-Rückgabewert für erfolgreiches
# Laden des Moduls
1;


# Beginn der Commandref

=pod
=item [helper]
=item summary TV-EPG Guide
=item summary_DE TV-EPG Guide

=begin html

<a name="EPG"></a>
<h3>EPG Modul</h3>
<ul>
The EPG module fetches the TV broadcast information from various sources.<br>
This is a module which retrieves the data for an electronic program guide and displays it immediately. (example: alternative for HTTPMOD + Readingsgroup & other)<br><br>
<i>Depending on the source and host country, the information can be slightly differentiated.<br> Each variant has its own read-in routine. When new sources become known, the module can be extended at any time.</i>
<br><br>
You have to choose a source and only then can the data of the TV Guide be displayed.<br>
The specifications for the attribute Variant | DownloadFile and DownloadURL are mandatory.
<br><br>
<ul><u>Currently the following services are supported:</u>
	<li>Rytec (Rytec EPG Downloader)<br><br>
			well-known sources:<br>
			<ul>
				<li>http://91.121.106.172/~rytecepg/epg_data/rytecDE_Basic.xz <small>&nbsp;&nbsp;(x)</small></li>
				<li>http://91.121.106.172/~rytecepg/epg_data/rytecDE_Common.xz <small>&nbsp;&nbsp;(x)</small></li>
				<li>http://91.121.106.172/~rytecepg/epg_data/rytecDE_SportMovies.xz <small>&nbsp;&nbsp;(x)</small></li>
				<li>http://www.vuplus-community.net/rytec/rytecDE_Basic.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li>http://www.vuplus-community.net/rytec/rytecDE_Common.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li>http://www.vuplus-community.net/rytec/rytecDE_SportMovies.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li>http://www.xmltvepg.nl/rytecDE_Basic.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li>http://www.xmltvepg.nl/rytecDE_Common.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li><a href="http://rytecepg.epgspot.com/epg_data/" target=”_blank”>http://rytecepg.epgspot.com/epg_data/</a> <small>&nbsp;&nbsp;(&#10003; - Auswahl nach L&auml;ndern)</small></li>
				<li><a href="https://rytec.ricx.nl/epg_data/" target=”_blank”>https://rytec.ricx.nl/epg_data/</a> <small>&nbsp;&nbsp;(&#10003; - Auswahl nach L&auml;ndern)</small></li>
			</ul><br>
	</li>
	<li> IPTV_XML (<a href="https://iptv.community/threads/epg.5423">IPTV.community</a>) </li>
	<li> xmltv.se (<a href="https://xmltv.se">Provides XMLTV schedules for Europe</a>) </li>
	
</ul>
<br><br>

<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; EPG</code></ul>
<br><br>

<b>Get</b><br>
	<ul>
		<a name="available_channels"></a>
		<li>available_channels: retrieves all available channels</li><a name=""></a>
		<a name="loadEPG_now"></a>
		<li>loadEPG_now: let the EPG data of the selected channels at the present time</li><a name=""></a>
		<a name="loadEPG_Prime"></a>
		<li>loadEPG_Prime: let the EPG data of the selected channels be at PrimeTime 20:15</li><a name=""></a>
		<a name="loadEPG_today"></a>
		<li>loadEPG_today: let the EPG data of the selected channels be from the current day</li><a name=""></a>
	</ul>
<br><br>

<b>Attribute</b><br>
	<ul><li><a href="#disable">disable</a></li></ul><br>
	<ul><li><a name="Channels">Channels</a><br>
	This attribute will be filled automatically after entering the control panel "<code>list of all available channels</code>" and defined the desired channels.<br>
	<i>Normally you do not have to edit this attribute manually.</i></li><a name=" "></a></ul><br>
	<ul><li><a name="DownloadFile">DownloadFile</a><br>
	File name of the desired file containing the information.</li><a name=" "></a></ul><br>
	<ul><li><a name="DownloadURL">DownloadURL</a><br>
	Website URL where the desired file is stored.</li><a name=" "></a></ul><br>
	<ul><li><a name="Variant">Variant</a><br>
	Processing variant according to which method the information is processed or read.</li><a name=" "></a></ul>
=end html


=begin html_DE

<a name="EPG"></a>
<h3>EPG Modul</h3>
<ul>
Das EPG Modul holt die TV - Sendungsinformationen aus verschiedenen Quellen.<br>
Es handelt sich hiermit um einen Modul welches die Daten f&uuml;r einen elektronischen Programmf&uuml;hrer abruft und sofort darstellt. (Bsp: Alternative f&uuml;r HTTPMOD + Readingsgroup & weitere)<br><br>
<i>Je nach Quelle und Aufnahmeland k&ouml;nnen die Informationen bei Ihnen geringf&uuml;gig abweichen.<br> Jede Variante besitzt ihre eigene Einleseroutine. Beim bekanntwerden neuer Quellen kann das Modul jederzeit erweitert werden.</i>
<br><br>
Sie m&uuml;ssen sich f&uuml;r eine Quelle entscheiden und erst danach k&ouml;nnen Daten des TV-Guides dargestellt werden.<br>
Die Angaben f&uuml;r die Attribut Variante | DownloadFile und DownloadURL sind zwingend notwendig.
<br><br>
<ul><u>Derzeit werden folgende Dienste unterst&uuml;tzt:</u>
	<li>Rytec (Rytec EPG Downloader)<br><br>
			bekannte Quellen:<br>
			<ul>
				<li>http://91.121.106.172/~rytecepg/epg_data/rytecDE_Basic.xz <small>&nbsp;&nbsp;(x)</small></li>
				<li>http://91.121.106.172/~rytecepg/epg_data/rytecDE_Common.xz <small>&nbsp;&nbsp;(x)</small></li>
				<li>http://91.121.106.172/~rytecepg/epg_data/rytecDE_SportMovies.xz <small>&nbsp;&nbsp;(x)</small></li>
				<li>http://www.vuplus-community.net/rytec/rytecDE_Basic.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li>http://www.vuplus-community.net/rytec/rytecDE_Common.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li>http://www.vuplus-community.net/rytec/rytecDE_SportMovies.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li>http://www.xmltvepg.nl/rytecDE_Basic.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li>http://www.xmltvepg.nl/rytecDE_Common.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li>http://www.xmltvepg.nl/rytecDE_SportMovies.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li><a href="http://rytecepg.epgspot.com/epg_data/" target=”_blank”>http://rytecepg.epgspot.com/epg_data/</a> <small>&nbsp;&nbsp;(&#10003; - Auswahl nach L&auml;ndern)</small></li>
				<li><a href="https://rytec.ricx.nl/epg_data/" target=”_blank”>https://rytec.ricx.nl/epg_data/</a> <small>&nbsp;&nbsp;(&#10003; - Auswahl nach L&auml;ndern)</small></li>
			</ul><br>
	</li>
	<li> IPTV_XML (<a href="https://iptv.community/threads/epg.5423">IPTV.community</a>) </li>
	<li> xmltv.se (<a href="https://xmltv.se">Provides XMLTV schedules for Europe</a>) </li>
	
</ul>
<br><br>

<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; EPG</code></ul>
<br><br>

<b>Get</b><br>
	<ul>
		<a name="available_channels"></a>
		<li>available_channels: ruft alle verf&uuml;gbaren Kan&auml;le ab</li><a name=""></a>
		<a name="loadEPG_now"></a>
		<li>loadEPG_now: l&auml;d die EPG-Daten der ausgew&auml;hlten Kan&auml;le vom jetzigen Zeitpunkt</li><a name=""></a>
		<a name="loadEPG_Prime"></a>
		<li>loadEPG_Prime: l&auml;d die EPG-Daten der ausgew&auml;hlten Kan&auml;le von der PrimeTime 20:15Uhr</li><a name=""></a>
		<a name="loadEPG_today"></a>
		<li>loadEPG_today: l&auml;d die EPG-Daten der ausgew&auml;hlten Kan&auml;le vom aktuellen Tag</li><a name=""></a>
	</ul>
<br><br>

<b>Attribute</b><br>
	<ul><li><a href="#disable">disable</a></li></ul><br>
	<ul><li><a name="Channels">Channels</a><br>
	Dieses Attribut wird automatisch gef&uuml;llt nachdem man im Control panel mit "<code>list of all available channels</code>" die gew&uuml;nschten Kan&auml;le definierte.<br>
	<i>Im Normalfall muss man dieses Attribut nicht manuel bearbeiten.</i></li><a name=" "></a></ul><br>
	<ul><li><a name="DownloadFile">DownloadFile</a><br>
	Dateiname von der gew&uuml;nschten Datei welche die Informationen enth&auml;lt.</li><a name=" "></a></ul><br>
	<ul><li><a name="DownloadURL">DownloadURL</a><br>
	Webseiten URL wo die gew&uuml;nschten Datei hinterlegt ist.</li><a name=" "></a></ul><br>
	<ul><li><a name="Variant">Variant</a><br>
	Verarbeitungsvariante, nach welchem Verfahren die Informationen verarbeitet oder gelesen werden.</li><a name=" "></a></ul>

=end html_DE

# Ende der Commandref
=cut