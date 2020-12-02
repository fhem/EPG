#################################################################
# $Id: 66_EPG.pm 21010 2020-02-16 23:10:00Z HomeAuto_User $
#
# Github - FHEM Home Automation System
# https://github.com/fhem/EPG
#
# 2019 | 2020 - HomeAuto_User, elektron-bbs, OdfFhem
#
#################################################################
# Varianten der Informationen:
# *.gz      -> ohne & mit Dateiendung nach unpack
# *.xml     -> ohne unpack
# *.xml.gz  -> mit Dateiendung xml nach unpack
# *.xz      -> ohne Dateiendung nach unpack
#################################################################
# Note´s
# - test option teXXas with this standings
#
# - refresh browser window, any browser no refreh
#   - YES - Mozilla Firefox 72.0.2
#   - NO  - Microsoft Edge 
#################################################################

package main;

use strict;
use warnings;

use HttpUtils;					# https://wiki.fhem.de/wiki/HttpUtils
use Data::Dumper;

use constant {
	EPG_FW_errmsg_time      => 5000, # milliseconds
	EPG_InternalTimer_DELAY => 2,    # seconds
	EPG_Temp_ChSortNumbre   => 999,
	EPG_VERSION             => "20200216_pre_release_expanded",
};

my %EPG_transtable_EN = ( 
		## Days ##
		"day0"                =>  "Sunday",
		"day1"                =>  "Monday",
		"day2"                =>  "Tuesday",
		"day3"                =>  "Wednesday",
		"day4"                =>  "Thursday",
		"day5"                =>  "Friday",
		"day6"                =>  "Saturday",
		## Months ##
		"months1"             =>  "January",
		"months2"             =>  "February",
		"months3"             =>  "March",
		"months4"             =>  "April",
		"months5"             =>  "May",
		"months6"             =>  "June",
		"months7"             =>  "July",
		"months8"             =>  "August",
		"months9"             =>  "September",
		"months10"            =>  "October",
		"months11"            =>  "November",
		"months12"            =>  "December",
		## EPG_Attr ##
		"DownloadFile"        =>  "Please search for new available channels.",
		"Variant_mod"         =>  "Please search for new available channels. The names have changed.",
		## EPG_Get ##
		"get_available_ch"    =>  "available_channels search",
		"get_loadEPG"         =>  "started",
		"get_view_FTUI_data"  =>  "no data exists",
		"Notify_auto_msg"     =>  "automatic process",
		## EPG_FW_Detail ##
		"btn_FavDesc"         =>  "Fav Desc",
		"btn_FavTitle"        =>  "Fav Title",
		"btn_now"             =>  "Now",
		"btn_prime"           =>  "PrimeTime",
		"control_pan_btn"     =>  "list of all available channels",
    "FW_autoload"         =>  "Data is being updated automatically",
    "broadcast"           =>  "Broadcast",
    "channel"             =>  "Channel",
    "control_pan"         =>  "Control panel",
    "date"                =>  "Date",
    "description"         =>  "Description",
    "end"                 =>  "End",
    "epg_info"            =>  "no EPG Data",
    "read_ch"             =>  "readed channels",
    "select_ch"           =>  "selected channels",
    "start"               =>  "Start",
		## EPG_FW_Popup_Channels ##
    "active"              =>  "active",
    "no"                  =>  "no.",
    "tv_fav"              =>  "sort",
    "tv_name"             =>  "TV station name",
		## EPG_FW_set_Attr_Channels ##
    "set_Attr_Ch_eq"      =>  "no channel selected",
		## EPG_ParseHttpResponse ##
		"ParseHttp_Http_URL"  =>  "DownloadURL was not found",
		"ParseHttp_Http_file" =>  "DownloadFile was not found on URL",
		"ParseHttp_Http_ok"   =>  "downloaded",
		"ParseHttp_gz_error"  =>  "ERROR: unpack gz failed,",
		"ParseHttp_state2"    =>  "downloading not finish in the maximum time from HTTP_TimeOut",
		"ParseHttp_state_ok"  =>  "data received",
		"ParseHttp_xz_error"  =>  "ERROR: unpack xz failed,",
    "ParseHttp_state1"    =>  "no information received",
		## EPG_File_check ##
		"File_check_fileage"  =>  "unknown",
		"File_check_DownFile" =>  "file not found",
		## EPG_nonBlock_available_channels ##
		"available_ch_ok"     =>  "ERROR: EPG_file no found at ./FHEM/EPG",
    ## EPG_nonBlock_available_channelsDone ##
		"chDone_state1"       =>  "unknown methode, need development",
		"chDone_msg_OK"       =>  "EPG available with get loadEPG command!",
		"chDone_msg_OK2"      =>  "available_channels loaded, Please select channel on Control panel",
		## EPG_nonBlock_loadEPG_v1Done ##
		"loadEPG_v1Done"      =>  "decode_json failed, use verbose 5 to view more",
		"loadEPG_v1Done_STOP" =>  "automatic download STOP, no current data. Please check your source!",
		## EPG_nonBlock_loadEPG ##
		"loadEPG_msg1"        =>  "all EPG channel information processed",
		"loadEPG_msg2"        =>  "no EPG channel information available",
		"loadEPG_msg3"        =>  "ERROR: loaded Information canceled, file not found",
		## EPG_nonBlock_abortFn ##
		"nonBlock_abortFn"    =>  "timeout nonBlock function"
		);
    
 my %EPG_transtable_DE = ( 
		## Days ##
		"day0"                =>  "Sonntag",
		"day1"                =>  "Montag",
		"day2"                =>  "Dienstag",
		"day3"                =>  "Mittwoch",
		"day4"                =>  "Donnerstag",
		"day5"                =>  "Freitag",
		"day6"                =>  "Sonnabend",
		## Months ##
		"months1"             =>  "Januar",
		"months2"             =>  "Februar",
		"months3"             =>  "März",
		"months4"             =>  "April",
		"months5"             =>  "Mai",
		"months6"             =>  "Juni",
		"months7"             =>  "Juli",
		"months8"             =>  "August",
		"months9"             =>  "September",
		"months10"            =>  "Oktober",
		"months11"            =>  "November",
		"months12"            =>  "Dezember",
		## EPG_Attr ##
		"DownloadFile"        =>  "Bitte suchen Sie nach neuen verfügbaren Kanälen.",
		"Variant_mod"         =>  "Bitte suchen Sie nach neuen verfügbaren Kanälen. Die Namen haben sich geändert.",
		## EPG_Get ##
		"get_available_ch"    =>  "verfügbare Kanäle werden gesucht",
		"get_loadEPG"         =>  "gestartet",
		"get_view_FTUI_data"  =>  "keine Daten vorhanden",
		"Notify_auto_msg"     =>  "automatischer Prozess",
		## EPG_FW_Detail ##
		"btn_FavDesc"         =>  "Fav Beschreibung",
		"btn_FavTitle"        =>  "Fav Titel",
		"btn_now"             =>  "derzeit",
		"btn_prime"           =>  "PrimeTime",
		"control_pan_btn"     =>  "Liste der verfügbaren Kanäle",
    "FW_autoload"         =>  "Daten werden gerade automatisch aktualisiert",
    "broadcast"           =>  "Sendung",
    "channel"             =>  "Sender",
    "control_pan"         =>  "Bedienfeld",
    "date"                =>  "Datum",
    "description"         =>  "Beschreibung",
    "end"                 =>  "Ende",
    "epg_info"            =>  "keine EPG Daten",
    "read_ch"             =>  "eingelesene Kanäle",
    "select_ch"           =>  "ausgewählte Kanäle",
    "start"               =>  "Start",
		## EPG_FW_Popup_Channels ##
    "active"              =>  "aktiv",
    "no"                  =>  "Nr.",
    "tv_fav"              =>  "sort",
    "tv_name"             =>  "TV Sendername",
		## EPG_FW_set_Attr_Channels ##
    "set_Attr_Ch_eq"      =>  "keinen Kanal ausgewählt",
		## EPG_ParseHttpResponse ##
		"ParseHttp_Http_URL"  =>  "DownloadURL wurde nicht gefunden",
		"ParseHttp_Http_file" =>  "DownloadFile wurde in der URL nicht gefunden",
		"ParseHttp_Http_ok"   =>  "heruntergeladen",
		"ParseHttp_gz_error"  =>  "ERROR: unpack gz fehlgeschlagen,",
		"ParseHttp_state2"    =>  "Der Download ist nicht in der maximalen Zeit von HTTP_TimeOut beendet.",
		"ParseHttp_state_ok"  =>  "Daten empfangen",
		"ParseHttp_xz_error"  =>  "ERROR: unpack xz fehlgeschlagen,",
    "ParseHttp_state1"    =>  "keine Informationen erhalten",
		## EPG_File_check ##
		"File_check_fileage"  =>  "unbekannt",
		"File_check_DownFile" =>  "Datei nicht gefunden",
		## EPG_nonBlock_available_channels ##
		"available_ch_ok"     =>  "ERROR: EPG Datei nicht gefunden in ./FHEM/EPG",
    ## EPG_nonBlock_available_channelsDone ##
		"chDone_state1"       =>  "unbekannte Methode, Entwicklung notwendig",
		"chDone_msg_OK"       =>  "EPG mit get loadEPG Befehlen verfügbar",
		"chDone_msg_OK2"      =>  "verfügbare Kanäle geladen! Bitte mit dem Bedienfeld Ihren Kanal auswählen.",
		## EPG_nonBlock_loadEPG_v1Done ##
		"loadEPG_v1Done"      =>  "decode_json fehlgeschlagen, bitte benutze verbose 5 um mehr zu erkennen",
		"loadEPG_v1Done_STOP" =>  "automatischer Download STOP, keine aktuellen Daten. Bitte überprüfen Sie Ihre Quelle!",
		## EPG_nonBlock_loadEPG ##
		"loadEPG_msg1"        =>  "alle EPG Daten verarbeitet",
		"loadEPG_msg2"        =>  "keine EPG Daten verfügbar",
		"loadEPG_msg3"        =>  "ERROR: Information laden abgebrochen, Datei nicht gefunden",
		## EPG_nonBlock_abortFn ##
		"nonBlock_abortFn"    =>  "Zeitüberschreitung nonBlock Funktion"
    );

my $EPG_tt;
my $missingModulEPG = "";
my $osname = $^O;
my $gzError;
my $xzError;

eval "use Encode qw(encode encode_utf8 decode_utf8);1" or $missingModulEPG .= "Encode || libencode-perl, ";
eval "use JSON;1" or $missingModulEPG .= "JSON || libjson-perl, ";
eval "use XML::Simple;1" or $missingModulEPG .= "XML::Simple || libxml-simple-perl, ";

my @tools = ("gzip","xz");

#####################
sub EPG_Initialize($) {
	my ($hash) = @_;

	$hash->{AttrFn}                = "EPG_Attr";
	$hash->{DefFn}                 = "EPG_Define";
	$hash->{GetFn}                 = "EPG_Get";
	$hash->{NotifyFn}              = "EPG_Notify";
	$hash->{SetFn}                 = "EPG_Set";
	$hash->{UndefFn}               = "EPG_Undef";
  $hash->{FW_detailFn}           = "EPG_FW_Detail";
	$hash->{FW_deviceOverview}     = 1;
	$hash->{FW_addDetailToSummary} = 1;  # displays html in fhemweb room-view
	$hash->{AttrList}              =	"Ch_select Ch_sort Ch_Info_to_Reading:yes,no Ch_commands:textField-long ".
                                    "DownloadFile DownloadURL HTTP_TimeOut ".
																		"EPG_auto_download:yes,no EPG_auto_update:yes,no ".
																		"FavTitle FavDesc ".
                                    "Table:on,off Table_view_Subtitle:no,yes disable ".
                                    "Variant:Rytec,TvProfil_XMLTV,WebGrab+Plus,XMLTV.se,teXXas_RSS";
												             #$readingFnAttributes;

	## in any attribute redefinition readjust language ##
	my $lang = uc(AttrVal("global","language","EN"));
	$EPG_tt = $lang eq "DE" ? \%EPG_transtable_DE : \%EPG_transtable_EN;
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

	return "ERROR: you need ".$missingModulEPG."package to use this module" if ($missingModulEPG ne "");
	return "Usage: define <name> $name"  if(@arg != 2);

  ## readjust language ##
	my $lang = uc(AttrVal("global","language","EN"));
	$EPG_tt = $lang eq "DE" ? \%EPG_transtable_DE : \%EPG_transtable_EN;

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

	$hash->{VERSION} = EPG_VERSION;

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

	$hash->{VERSION} = EPG_VERSION if ($hash->{VERSION} && $hash->{VERSION} ne EPG_VERSION);

	return "$name: no set function exists" if ($cmd ne "?");
	return $setList if ( $a[0] eq "?");
	return undef;
}

#####################
sub EPG_Get($$$@) {
	my ( $hash, $name, $cmd, @a ) = @_;
	my $cmd2 = defined $a[0] ? $a[0] : "";
	my $room = AttrVal($name, "room", "");
	my $DownloadFile = AttrVal($name, "DownloadFile", undef);
	my $DownloadURL = AttrVal($name, "DownloadURL", undef);
	my $Variant = AttrVal($name, "Variant", "unknown");
	my $FW_wname = !$FW_wname ? "WEB" : $FW_wname;
	my @Channels_available;
	@Channels_available = \@{$hash->{helper}{Channels_available}} if ($hash->{helper}{Channels_available});

	my $getlist = "loadFile:noArg ";
	$getlist.= "jsonEPG:noArg " if (scalar(@Channels_available) > 0);
	$getlist.= "available_channels:noArg " if (ReadingsVal($name, "HttpResponse", undef) && 
	                                           ReadingsVal($name, "HttpResponse", undef) eq $EPG_tt->{"ParseHttp_Http_ok"} &&
                                             ReadingsVal($name, "EPG_file_name", undef) ne $EPG_tt->{"File_check_DownFile"});
	if ($Variant ne "unknown" && AttrVal($name, "Ch_select", undef) && AttrVal($name, "Ch_select", undef) ne "" && scalar(@Channels_available) > 0 ) {
		$getlist.= "loadEPG_FavDesc:noArg " if (AttrVal($name, "FavDesc", undef));
		$getlist.= "loadEPG_FavTitle:noArg " if (AttrVal($name, "FavTitle", undef));
	}

	## reset old JSON value if modul reload
	delete $hash->{helper}{FTUI_data} if ($cmd eq "?" && scalar(@Channels_available) == 0 && exists $hash->{helper}{FTUI_data});

	if ($cmd ne "?") {
		return "ERROR: Attribute DownloadURL or DownloadFile not right defined - Please check!\n\n<u>example:</u>\n".
		"DownloadURL - http://rytecepg.epgspot.com/epg_data/\n".
		"DownloadFile - rytecAT_Basic.xz\n".
		"\nnote: The two attributes must be entered separately!" if (!$DownloadURL || !$DownloadFile);

		## check directory and create ##
		if (! -d "./FHEM/EPG") {
			my $ok = mkdir("FHEM/EPG");
			my $text = $ok == 1 ? "directory automatic created ($!)" : "directory check - ERROR $ok";
			Log3 $name, 4, "$name: Get - ".$text;
		}
	}

	if ($cmd eq "loadFile") {
		FW_directNotify("FILTER=(room=$room|$name)", "#FHEMWEB:$FW_wname", "FW_errmsg('$name: ".$EPG_tt->{"Notify_auto_msg"}." $cmd' , ".EPG_FW_errmsg_time.")", "");
		EPG_PerformHttpRequest($hash);
		return undef;
	}

	if ($cmd eq "available_channels") {
		Log3 $name, 4, "$name: get $cmd - starting File_check";
		EPG_File_check($hash);
		return "ERROR: no EPG_file found! Please use \"get $name loadFile\" and try again." if (not ReadingsVal($name, "EPG_file_name", undef));

		FW_directNotify("FILTER=(room=$room|$name)", "#FHEMWEB:$FW_wname", "FW_errmsg('$name: ".$EPG_tt->{"Notify_auto_msg"}." $cmd' , ".EPG_FW_errmsg_time.")", "");
		Log3 $name, 4, "$name: get $cmd - starting blocking call";
		delete $hash->{helper}{Channels_available};

		readingsSingleUpdate($hash, "state", $EPG_tt->{"get_available_ch"}, 1);
    $hash->{helper}{RUNNING_PID} = BlockingCall("EPG_nonBlock_available_channels", $name."|".ReadingsVal($name, "EPG_file_name", undef), "EPG_nonBlock_available_channelsDone", 60 , "EPG_nonBlock_abortFn", $hash) unless(exists($hash->{helper}{RUNNING_PID}));
		return undef;
	}

	if ($cmd eq "jsonEPG") {
		## to test (device,cmd & csrfToken must be adapted)
		# jsonEPG   # http://raspberrypi:8083/fhem/?detail=EPG&dev.getEPG=EPG&cmd.getEPG=get&arg.getEPG=jsonEPG&val.getEPG=&fwcsrf=csrf_772140440757415&XHR=1

		Log3 $name, 4, "$name: get $cmd - view data in JSON format";
		if (exists $hash->{helper}{FTUI_data}) {
			return toJSON($hash->{helper}{FTUI_data});
		} else {
			return toJSON({error=>$EPG_tt->{"get_view_FTUI_data"}});
		}
	}

	if ($Variant eq "Rytec" || $Variant eq "TvProfil_XMLTV" || $Variant eq "WebGrab+Plus" || $Variant eq "XMLTV.se") {
		if ( AttrVal($name, "Ch_select", undef) && AttrVal($name, "Ch_select", undef) ne "" && scalar(@Channels_available) > 0 ) {
			$getlist.= "loadEPG_now:noArg ";               # now
			$getlist.= "loadEPG_Prime:noArg ";             # Primetime
			$getlist.= "loadEPG_today:noArg ";             # today all
			$getlist.= "loadEPG_time " ;                   # flex time
		}

		if ($cmd eq "loadEPG_time") {
			my $TimeNowMod = FmtDateTime(time());
			$TimeNowMod =~ s/-|:|\s//g;

			return "ERROR: your time failed (example: get $name $cmd ".substr($TimeNowMod,0, 8)."_".substr($TimeNowMod,8, 4).")" if ($cmd2 eq "");
			return "ERROR: your time is not valid (example: get $name $cmd ".substr($TimeNowMod,0, 8)."_".substr($TimeNowMod,8, 4).")" if ($cmd2 !~ /\d{8}_\d{4}/);
		}

		## loadEPG_Prime | loadEPG_now | loadEPG_time | loadEPG_today ##
		if ($cmd =~ /^loadEPG/ && $cmd !~ /loadEPG_Fav/) {
			FW_directNotify("FILTER=(room=)?$name", "#FHEMWEB:$FW_wname", "FW_errmsg('$name: ".$EPG_tt->{"Notify_auto_msg"}." $cmd' , ".EPG_FW_errmsg_time.")", "");

			delete $hash->{helper}{HTML} if(defined($hash->{helper}{HTML}));
			if ($hash->{helper}{HTML_reload} && $hash->{helper}{HTML_reload} eq "yes") {
				delete $hash->{helper}{HTML_reload} if(defined($hash->{helper}{HTML_reload}));
			} else {
				readingsSingleUpdate($hash, "state", "$cmd ".$EPG_tt->{"get_loadEPG"}, 1);						
			}

			Log3 $name, 4, "$name: get $cmd - starting blocking call";
			$hash->{helper}{RUNNING_PID} = BlockingCall("EPG_nonBlock_loadEPG_v1", $name."|".ReadingsVal($name, "EPG_file_name", undef)."|".$cmd."|".$cmd2, "EPG_nonBlock_loadEPG_v1Done", 60 , "EPG_nonBlock_abortFn", $hash) unless(exists($hash->{helper}{RUNNING_PID}));
			return undef;
		}

		## loadEPG_FavTitle | loadEPG_FavDesc ##
		if ($cmd =~ /^loadEPG_Fav/) {
			readingsSingleUpdate($hash, "state", "$cmd ".$EPG_tt->{"get_loadEPG"}, 1);
			Log3 $name, 4, "$name: get $cmd - looking for $cmd with $Variant";

			delete $hash->{helper}{HTML} if(defined($hash->{helper}{HTML}));
			$hash->{helper}{RUNNING_PID} = BlockingCall("EPG_nonBlock_loadEPG_v1", $name."|".ReadingsVal($name, "EPG_file_name", undef)."|".$cmd."|".$cmd2, "EPG_nonBlock_loadEPG_v1Done", 60 , "EPG_nonBlock_abortFn", $hash) unless(exists($hash->{helper}{RUNNING_PID}));
			return undef;
		}
	}

	if ($Variant eq "teXXas_RSS" ) {
		if (AttrVal($name, "Ch_select", undef) && scalar(@Channels_available) > 0 && AttrVal($name, "Ch_select", undef) ne "") {
			$getlist.= "loadEPG_now:noArg " if ($hash->{helper}{Programm} && $hash->{helper}{Programm} eq "now" && AttrVal($name, "Ch_select", undef) && AttrVal($name, "Ch_select", undef) ne "");
			$getlist.= "loadEPG_Prime:noArg " if ($hash->{helper}{Programm} && $hash->{helper}{Programm} eq "20:15" && AttrVal($name, "Ch_select", undef) && AttrVal($name, "Ch_select", undef) ne "");
		}
 		
		if ($cmd =~ /^loadEPG/ && $cmd !~ /^loadEPG_Fav/) {
			delete $hash->{helper}{HTML} if(defined($hash->{helper}{HTML}));
			readingsSingleUpdate($hash, "state", "$cmd ".$EPG_tt->{"get_loadEPG"}, 1);
			Log3 $name, 4, "$name: get $cmd - starting blocking call";

			$hash->{helper}{RUNNING_PID} = BlockingCall("EPG_nonBlock_loadEPG_v2", $name."|".ReadingsVal($name, "EPG_file_name", undef)."|".$cmd."|".$cmd2, "EPG_nonBlock_loadEPG_v2Done", 60 , "EPG_nonBlock_abortFn", $hash) unless(exists($hash->{helper}{RUNNING_PID}));
			return undef;
		}
	}

	return "Unknown argument $cmd, choose one of $getlist";
}

#####################
sub EPG_Attr() {
	my ($cmd, $name, $attrName, $attrValue) = @_;
	my $hash = $defs{$name};
	my $typ = $hash->{TYPE};
	my $FW_wname = !$FW_wname ? "WEB" : $FW_wname;
	my $Variant = AttrVal($name, "Variant", undef);
	
  ## in any attribute redefinition readjust language ##
	my $lang = uc(AttrVal("global","language","EN"));
	$EPG_tt = $lang eq "DE" ? \%EPG_transtable_DE : \%EPG_transtable_EN;

	if ($cmd eq "set" && $init_done == 1 ) {
		if ($attrName eq "Ch_Info_to_Reading" && $attrValue eq "no") {
			EPG_readingsDeleteChannel($hash);
		}

		if ($attrName eq "DownloadURL") {
			return "Your website entry must end with /\n\nexample: $attrValue/" if ($attrValue !~ /.*\/$/);
			return "Your input must begin with http:// or https://" if ($attrValue !~ /^htt(p|ps):\/\//);
		}

		if ($attrName eq "DownloadFile" && $attrValue ne AttrVal($name, "DownloadFile", undef)) {
			readingsDelete($hash,"EPG_file_last_timestamp") if(ReadingsVal($name, "EPG_file_last_timestamp", undef));
			readingsDelete($hash,"EPG_last_loaded") if(ReadingsVal($name, "EPG_last_loaded", undef));

			delete $attr{$name}{Ch_sort} if ($attr{$name}{Ch_sort});
			delete $attr{$name}{Ch_select} if ($attr{$name}{Ch_select});

			readingsSingleUpdate($hash, "state" , $EPG_tt->{"DownloadFile"}, 1);
		}

		if ($attrName eq "HTTP_TimeOut") {
			return "to small (standard 10)" if ($attrValue < 5);
			return "to long (standard 10)" if ($attrValue > 90);
		}

		if ($attrName eq "FavDesc" || $attrName eq "FavTitle") {
			FW_directNotify("FILTER=room=$FW_room", "#FHEMWEB:$FW_wname", "location.reload('true')", "");
		}

		if ($attrName eq "Ch_commands") {
			return "ERROR: The command must informat { \" \" => \" \" }" if ($attrValue !~ /\s?+{\X+=>\X+}/);
			my $err = perlSyntaxCheck($attrValue, ());   # check PERL Code
			return $err if($err);

			## check syntax and set Ch_command device to list "Probably associated with" ##
			if( $attrValue =~ m/^\{.*\}$/s && $attrValue =~ m/=>/ && $attrValue !~ m/\$/ ) {
				my $av = eval $attrValue;
				if( $@ ) {
					Log3 $name, 3, "$name: Attr - $attrName, ERROR: ". $@;
				} else {
					my $Ch_commands = $av if( ref($av) eq "HASH" );
					my $associatedWith = "";

					foreach my $d (keys %{$Ch_commands}) {
						if ($Ch_commands->{$d} =~ /(get|set)\s(\w+)\s/) {
							if ($2) {
								Log3 $name, 5, "$name: Attr - $attrName, PawList | found: ".$2;
								if (not grep /$2/, $associatedWith) {
									$associatedWith = $associatedWith eq "" ? $2 : $associatedWith.",".$2;
								}
							}
						}
					}
					CommandSetReading(undef, "$name .associatedWith $associatedWith");
				}
			} else {
				return "ERROR: $attrName are wrong format";
			}
		}

		if ($attrName eq "Variant" && $attrValue ne $Variant) {
			delete $attr{$name}{Ch_sort} if ($attrName eq "Ch_select" && $attr{$name}{Ch_sort});
			delete $attr{$name}{Ch_select} if ($attrName eq "Ch_sort" && $attr{$name}{Ch_select});

			EPG_Reset_HELPER($hash);
			readingsSingleUpdate($hash, "state" , $EPG_tt->{"Variant_mod"}, 1);
		}
	}

	if ($cmd eq "del") {
		EPG_readingsDeleteChannel($hash) if ($attrName eq "Ch_Info_to_Reading");
		FW_directNotify("FILTER=room=$FW_room", "#FHEMWEB:$FW_wname", "location.reload('true')", "") if ($attrName eq "FavDesc" || $attrName eq "FavTitle");

		if ($attrName eq "Ch_commands") {
			readingsDelete($hash,".associatedWith") if(ReadingsVal($name, ".associatedWith", undef));
		}

		EPG_Reset_HELPER($hash) if ( $attrName eq "Variant"	);
	}
}

#####################
sub EPG_FW_Detail($@) {
	my ($FW_wname, $name, $room, $pageHash) = @_;
	my $hash = $defs{$name};
	my $Ch_commands = AttrVal($name,"Ch_commands", undef);
	my $Ch_select = AttrVal($name, "Ch_select", undef);
	my $EPG_auto_update = AttrVal($name, "EPG_auto_update", "no");
	my $HTML = $hash->{helper}{HTML};
	my $HTML_cnt = defined $hash->{helper}{HTML_data_counter} ? $hash->{helper}{HTML_data_counter} : 0;
	my $Table = AttrVal($name, "Table", "on");
	my $Table_view_Subtitle = "";
	my $Variant = AttrVal($name, "Variant", undef);
	my $cnt_ch_select = 0;
	my $html_site = "";
	my @Channels_select;
	my @Channels_available;
	@Channels_available = @{$hash->{helper}{Channels_available}} if ($hash->{helper}{Channels_available});

  ## readjust language ##
	my $lang = uc(AttrVal("global","language","EN"));
	$EPG_tt = $lang eq "DE" ? \%EPG_transtable_DE : \%EPG_transtable_EN;

	Log3 $name, 5, "$name: FW_Detail is running (Tableview=$Table, language=$lang)";
	Log3 $name, 5, "$name: FW_Detail - Channels_available: ".scalar(@Channels_available);

	if ($Ch_select) {
		@Channels_select = split(",", $Ch_select);
		$cnt_ch_select = scalar(@Channels_select);
		Log3 $name, 5, "$name: FW_Detail - channel_select: ".$cnt_ch_select;
	}

	if (scalar(@Channels_available) > 0) {
		### Tablet_UI ###
		$html_site.= '<!DOCTYPE html>';
		$html_site.= '<html>';
		$html_site.= '<head></head>';
		$html_site.= '<body>';

		### style via CSS for Checkbox ###
		$html_site.= '<style>

		/* all elements in div with id btn_table */
		#btn_table {
			text-align: center;
			padding: 10px 0px 10px 0px;
		}

		#btn_table input[type="reset"] {
			border-radius: 4px 4px 4px 4px;
			margin: 0px 15px 0px 15px;
			width: 150px;
		}

		/* all elements in table with id EPG_InfoMenue */
		table#EPG_InfoMenue td {
			padding: 0px 5px 0px 5px;
		}

		/* all td,th elements in div table with id FW_Detail */		
		table#FW_Detail td, th {
			padding: 0px 5px 0px 5px;
		}

		/* all th elements in div table with id FW_Detail */		
		table#FW_Detail th {
			text-decoration:underline;
			text-align:left;
		}

		/* all th elements in div with id FW_Popup_Channels */
		#FW_Popup_Channels th {
			text-decoration:underline;
			text-align:left;
		}
		
		/* all elements in div with class oldinfo | transparent */
		.oldinfo {
			opacity: 0.2;
			filter: alpha(opacity=2); /* For IE8 and earlier */
		}

		</style>';

		if ($FW_detail) {
			### Control panel ###
			$html_site .= "<div class='makeTable wide'><span>".$EPG_tt->{"control_pan"}."</span>
										<table class='block wide' id='EPG_InfoMenue' nm='$hash->{NAME}'>
										<tr class='even'>";

			$html_site .= "<td><a href='#button1' id='button1'>".$EPG_tt->{"control_pan_btn"}."</a></td>";
			$html_site .= "<td>".$EPG_tt->{"read_ch"}.": ". scalar(@Channels_available) ."</td>";
			$html_site .= "<td>".$EPG_tt->{"select_ch"}.": ". $cnt_ch_select ."</td>";
			$html_site .= "</tr></table></div>";
		}

		### Javascript ###
		$html_site .= '
			<script>

			$( "#button1" ).click(function(e) {
				e.preventDefault();
				FW_cmd(FW_root+\'?cmd={EPG_FW_Popup_Channels("'.$name.'")}&XHR=1"'.$FW_CSRF.'"\', function(data){EPG_ListWindow(data)});
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
							var Channel = [];
							var Channel_id = [];
							var desired_channel = [];
							$("#EPG_ListWindow input:checkbox:checked").each(function() {
								Channel.push($(this).attr(\'name\'));
								Channel_id.push($(this).attr(\'id\'));
							})

							$("#EPG_ListWindow td input:text").each(function() {
								var n = Channel_id.indexOf($(this).attr(\'id\'));
								if (n != -1) {
									var m = $(this).val();
									if (!m) {
										m = 0;
									}
									/* desired_channel.push($(this).val()); */
									desired_channel.push(m);
								}
							})

							var Channel = encodeURIComponent(Channel); /* need to view + | Javascript must encode + */
							FW_cmd(FW_root+ \'?XHR=1"'.$FW_CSRF.'"&cmd={EPG_FW_set_Attr_Channels("'.$name.'","\'+Channel+\'","\'+desired_channel+\'")}\');

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

			/* checkBox Werte von Checkboxen */
			function Checkbox(id) {
				var checkBox = document.getElementById(id);
				if (checkBox.checked) {
					checkBox.value = 1;
				} else {
					checkBox.value = 0;
				}
			}

			/* FW_detail Buttons */			
			function pushed_button(txt) {
				FW_cmd(FW_root+ \'?XHR=1"'.$FW_CSRF.'"&cmd={EPG_FW_pushed_button("'.$name.'","\'+txt+\'")}\');
			}

		</script>';

		### HTML ###
		if ($Table eq "off") {
			### Tablet_UI ###
			$html_site.= '</body>';
			$html_site.= '</html>';
			return $html_site;
		}

		$html_site .= "<div id=\"table\"><center>- ".$EPG_tt->{"epg_info"}." -</center></div>" if not ($Ch_select && $HTML_cnt != 0);

		if ($Ch_select && $HTML_cnt != 0) {
			my $EPG_cnt = 0;
			my $date;
			my $desc = "";
			my $end = "";
			my $end_timstamp = "";
			my $start = "";
			my $subtitle = "";
			my $title = "";

			$Table_view_Subtitle = "<th>".$EPG_tt->{"description"}."</th>" if (AttrVal($name, "Table_view_Subtitle", "no") eq "yes");

			if ($FW_detail eq "" && $Variant && $Variant ne "teXXas_RSS") {
				$html_site .= "<div id=\"btn_table\">";
				$html_site .= "<INPUT type=\"reset\" onclick=\"pushed_button('now')\" value=\"".$EPG_tt->{"btn_now"}."\"/> <INPUT type=\"reset\" onclick=\"pushed_button('Prime')\" value=\"".$EPG_tt->{"btn_prime"}."\"/>";
				$html_site .= "<INPUT type=\"reset\" onclick=\"pushed_button('FavDesc')\" value=\"".$EPG_tt->{"btn_FavDesc"}."\"/>" if (AttrVal($name, "FavDesc", undef));
				$html_site .= "<INPUT type=\"reset\" onclick=\"pushed_button('FavTitle')\" value=\"".$EPG_tt->{"btn_FavTitle"}."\"/>" if (AttrVal($name, "FavTitle", undef));
				$html_site .= "</div>";			

				### check, old value to must reload ### 
				if ($EPG_auto_update eq "yes") {
					my $TimeNow = FmtDateTime(time());
					my $reload = 0;

					foreach my $ch (sort keys %{$HTML}) {
						for (my $i=0;$i<@{$HTML->{$ch}{EPG}};$i++){
							if ($HTML->{$ch}{EPG}[$i]{end} lt $TimeNow) {
								Log3 $name, 4, "$name: FW_Detail - found old data, $ch with end ".$HTML->{$ch}{EPG}[$i]{end};
								$reload++;
								$HTML = {};
								last;
							}
							last if ($reload != 0);
						}
						last if ($reload != 0);
					}

					if ($reload != 0) {
						$hash->{helper}{HTML_reload} = "yes";
						readingsSingleUpdate($hash, "state" , $EPG_tt->{"FW_autoload"}, 1);
						CommandGet($hash, "$name loadEPG_now");
						return "";
					}
				}
			}

			$html_site .= "<div id=\"table\"><table id=\"FW_Detail\" class=\"block wide\">";

			## HTML view normal ##
			if ($hash->{helper}{last_cmd} !~ /^loadEPG_Fav/) {
				## time now - normal
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$ydat,$isdst) = localtime(fhemTimeGm(0, 0, 0, substr($hash->{helper}{last_loaded},6,2) * 1, ( substr($hash->{helper}{last_loaded},4,2) * 1 - 1 ), ( substr($hash->{helper}{last_loaded},0,4) * 1 - 1900 ) ));
				$date = $EPG_tt->{"day".$wday}.", ".sprintf("%02s",$mday)." ".$EPG_tt->{"months".($mon + 1)}." ".substr($hash->{helper}{last_loaded},0,4);
				$html_site .= "<tr class=\"even\"><th>".$EPG_tt->{"channel"}."</th><th>".$EPG_tt->{"start"}."</th><th>".$EPG_tt->{"end"}."</th><th>".$EPG_tt->{"broadcast"}."<small> (".$date.")</small></th>".$Table_view_Subtitle."</tr>";
			## HTML view for FavoriteShow ##
			} else {
				$html_site .= "<tr class=\"even\"><th>".$EPG_tt->{"channel"}."</th><th>".$EPG_tt->{"date"}."</th><th>".$EPG_tt->{"start"}."</th><th>".$EPG_tt->{"end"}."</th><th>".$EPG_tt->{"broadcast"}."</th>".$Table_view_Subtitle."</tr>";
			}

			my @positioned = sort { $HTML->{$a}{Ch_sort} <=> $HTML->{$b}{Ch_sort} or lc ($HTML->{$a}{Ch_name}) cmp lc ($HTML->{$b}{Ch_name}) } keys %$HTML;

			foreach my $ch (@positioned) {
				## Kanäle ##
				foreach my $value (@{$HTML->{$ch}{EPG}}) {
					## EPG ##
					#Log3 $name, 3, "$name: value             -> $value";
					foreach my $d (keys %{$value}) {
						## einzelne Werte ##
						#Log3 $name, 3, "$name: description       -> $d";
						#Log3 $name, 3, "$name: description value -> $value->{$d}";

						if ($d eq "start") {
							$start = substr($value->{$d},11,2).":".substr($value->{$d},14,2); # $start -> 2020-01-17 11:55:00
							my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime(time_str2num($value->{$d}));
							$date = $EPG_tt->{"day".$wday}.", ".sprintf("%02s",$mday)." ".$EPG_tt->{"months".($mon + 1)}." ".($year + 1900);
						}

						if ($d eq "end") {
							$end = substr($value->{$d},11,2).":".substr($value->{$d},14,2);
							$end_timstamp = time_str2num($value->{$d});
						}
						$title = $value->{$d} if ($d eq "title");
						$desc = $value->{$d} if ($d eq "desc");
						$subtitle = $value->{$d} if ($d eq "subtitle");
					}
					$EPG_cnt++;

					## check HTML information old ? ##
					if ( (($end_timstamp * 1 - time()) < 0) && $EPG_auto_update eq "no") {
						Log3 $name, 4, "$name: FW_Detail - information channel $ch are old | Broadcast already ended $end_timstamp";
						$html_site .= sprintf("<tr class=\"%s oldinfo\">", ($EPG_cnt & 1)?"odd":"even");
					} else {
						$html_site .= sprintf("<tr class=\"%s\">", ($EPG_cnt & 1)?"odd":"even");
					}
					$Table_view_Subtitle = "<td>$subtitle</td>" if (AttrVal($name, "Table_view_Subtitle", "no") eq "yes");

					## onclick Kanal wenn Kommando vorhanden ##
					my $click_ch;
					if (exists $HTML->{$ch}{Ch_command}) {
						Log3 $name, 5, "$name: FW_Detail - Ch_command, onclick for $ch -> ".$HTML->{$ch}{Ch_command};
						$click_ch = "<a href=\"#!\" onclick=\"FW_cmd('/fhem?XHR=1&cmd=$HTML->{$ch}{Ch_command}')\">$ch</a>";
					} else {
						$click_ch = "$ch";
					}

					## Darstellung als Link wenn Sendungsbeschreibung ##
					if ($desc ne "") {
						$desc =~ s/<br>/\n/g;
						$desc =~ s/(.{1,65}|\S{66,})(?:\s[^\S\r\n]*|\Z)/$1<br>/g; 
						$desc =~ s/[\r\'\"]/ /g;
						$desc =~ s/[\n]|\\n/<br>/g;

						$html_site .= "<td>$click_ch</td><td>$start</td><td>$end</td><td><a href=\"#!\" onclick=\"FW_okDialog(\'$desc\')\">$title</a></td>$Table_view_Subtitle</tr>" if ($hash->{helper}{last_cmd} !~ /^loadEPG_Fav/);
						$html_site .= "<td>$click_ch</td><td>".$date."</td><td>$start</td><td>$end</td><td><a href=\"#!\" onclick=\"FW_okDialog(\'$desc\')\">$title</a></td>$Table_view_Subtitle</tr>" if ($hash->{helper}{last_cmd} =~ /^loadEPG_Fav/);
					} else {
						$html_site .= "<td>$click_ch</td><td>$start</td><td>$end</td><td>$title</td>$Table_view_Subtitle</tr>" if ($hash->{helper}{last_cmd} !~ /^loadEPG_Fav/);
						$html_site .= "<td>$click_ch</td><td>".$date."</td><td>$start</td><td>$end</td><td>$title</td>$Table_view_Subtitle</tr>" if ($hash->{helper}{last_cmd} =~ /^loadEPG_Fav/);
					}
				}
			}
			$html_site .= "</table></div>";

			### Tablet_UI ###
			$html_site.= '</body>';
			$html_site.= '</html>';
		}
	} else {
		EPG_readingsDeleteChannel($hash);
	}

	return $html_site;
}

##################### (PopUp to view HTML for available channels)
sub EPG_FW_Popup_Channels {
	my $name = shift;
	my $hash = $defs{$name};
	my $html_site_ch = "";
	my $Ch_select = AttrVal($name, "Ch_select", undef);
	my $Ch_sort = AttrVal($name, "Ch_sort", "");
	my @Ch_sort = split(",",$Ch_sort) if ($Ch_sort ne "");
	my $checked_cnt = -1;
	my @Channels_available = @{$hash->{helper}{Channels_available}};
	my $HTML = $hash->{helper}{HTML};

	Log3 $name, 4, "$name: FW_Popup_Channels is running";

	$html_site_ch.= "<div><table id=\"FW_Popup_Channels\" class=\"block wide\">";
	$html_site_ch.= "<tr class=\"even\"><th>".$EPG_tt->{"no"}."</th><th>".$EPG_tt->{"active"}."</th><th>".$EPG_tt->{"tv_name"}."</th><th>".$EPG_tt->{"tv_fav"}."</th></tr>";

	for (my $i=0; $i<scalar(@Channels_available); $i++) {
		my $checked = "";

		if ($Ch_select && index($Ch_select,$Channels_available[$i]) >= 0) {
			$checked_cnt++;
			$checked = "checked";
			if($HTML->{$Channels_available[$i]}{Ch_sort} && $HTML->{$Channels_available[$i]}{Ch_sort} < EPG_Temp_ChSortNumbre) {
				$Ch_sort = $HTML->{$Channels_available[$i]}{Ch_sort};
			} else {
				$Ch_sort = $Ch_sort[$checked_cnt] if ($Ch_sort[$checked_cnt] && $Ch_sort[$checked_cnt] ne 0);
			}
		}

		$html_site_ch.= sprintf("<tr class=\"%s\">", ($i & 1)?"even":"odd");
		$html_site_ch.= "<td align=\"center\">".($i + 1)."</td><td align=\"center\"><input type=\"checkbox\" id=\"".$i."\" name=\"".$Channels_available[$i]."\" onclick=\"Checkbox(".$i.")\" $checked></td><td>". $Channels_available[$i] ."</td><td> <input type=\"text\" pattern=\"[0-9]+\" id=\"".$i."\" value=\"$Ch_sort\" maxlength=\"3\" size=\"3\"> </td></tr>";
		$Ch_sort = "";
	}

	$html_site_ch.= "</table></div>";
	return $html_site_ch;
}

##################### (SAVE Button on PopUp -> Anpassung Attribute Channels)
sub EPG_FW_set_Attr_Channels {
	my $name = shift;
	my $hash = $defs{$name};
	my $room = AttrVal($name, "room", "");
	my $Ch_select = shift;
	my @Ch_select_array = split(",",$Ch_select);
	my $Ch_sort = shift;
	my @Ch_sort_array = split(",",$Ch_sort);
	my $HTML = $hash->{helper}{HTML};

	Log3 $name, 4, "$name: FW_set_Attr_Channels is running";
	Log3 $name, 5, "$name: FW_set_Attr_Channels Ch_select $Ch_select";
	Log3 $name, 5, "$name: FW_set_Attr_Channels Ch_sort $Ch_sort";

	if ($Ch_select eq "") {
		Log3 $name, 4, "$name: FW_set_Attr_Channels all Channels delete and clean view";
		CommandDeleteAttr($hash,"$name Ch_select");
		CommandDeleteAttr($hash,"$name Ch_sort");
		InternalTimer(gettimeofday()+EPG_InternalTimer_DELAY, "EPG_readingsSingleUpdate_later", "$name,".$EPG_tt->{"set_Attr_Ch_eq"});
		delete $hash->{helper}{HTML} if(defined($hash->{helper}{HTML}));

		FW_directNotify("FILTER=(room=$room|$name)", "#FHEMWEB:$FW_wname", "location.reload('true')", "");
	} else {
		Log3 $name, 4, "$name: FW_set_Attr_Channels set Ch_select to $Ch_select";
		delete $hash->{helper}{HTML} if(defined($hash->{helper}{HTML}));
		CommandAttr($hash,"$name Ch_select $Ch_select");

		if ($Ch_sort !~ /^[0,]+$/) {
			CommandAttr($hash,"$name Ch_sort $Ch_sort");
		} else {
			CommandDeleteAttr($hash,"$name Ch_sort");		
		}

    ## list of all available channels - set Ch_sort from HTML input ##
		foreach my $i (0 .. $#Ch_select_array) {
			if ($Ch_sort_array[$i] != 0) {
				Log3 $name, 4, "$name: FW_set_Attr_Channels new numbre of ".$Ch_select_array[$i]." set to ".$Ch_sort_array[$i];
				$HTML->{$Ch_select_array[$i]}{Ch_sort} = $Ch_sort_array[$i];
				$HTML->{$Ch_select_array[$i]}{Ch_name} = $Ch_select_array[$i];         # need, if channel not PEG Data (sort $HTML)
			} else {
				$HTML->{$Ch_select_array[$i]}{Ch_sort} = EPG_Temp_ChSortNumbre;        # Reset Default
				$HTML->{$Ch_select_array[$i]}{Ch_name} = $Ch_select_array[$i];         # need, if channel not PEG Data (sort $HTML)
			}
		}
		CommandGet($hash, "$name $hash->{helper}{last_cmd}") if ($hash->{helper}{last_cmd});
	}
}

##################### (SAVE Button on PopUp -> Anpassung Attribute Channels)
sub EPG_FW_pushed_button {
	my $name = shift;
	my $command = shift;
	my $hash = $defs{$name};

	Log3 $name, 4, "$name: FW_pushed_button is running";

	foreach my $value (qw(now Prime FavDesc FavTitle)) {
		CommandGet($hash, "$name loadEPG_".$value) if ($command eq $value);
	}
}

#####################
sub EPG_PerformHttpRequest($) {
	my ($hash, $def) = @_;
	my $name = $hash->{NAME};
	my $DownloadURL = AttrVal($name, "DownloadURL", undef);
	my $DownloadFile = AttrVal($name, "DownloadFile", undef);
	my $HTTP_TimeOut = AttrVal($name, "HTTP_TimeOut", 10);

	Log3 $name, 4, "$name: PerformHttpRequest is running";
	my $http_param = { 	url        => $DownloadURL.$DownloadFile,
											timeout    => $HTTP_TimeOut,
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
	my $HTTP_TimeOut = AttrVal($name, "HTTP_TimeOut", 10);
	my $state = $EPG_tt->{"ParseHttp_state1"};
	my $FileAge = undef;
	my $EPG_auto_download = AttrVal($name, "EPG_auto_download", "no");
	my $FW_wname = !$FW_wname ? "WEB" : $FW_wname;

	Log3 $name, 5, "$name: ParseHttpResponse - error: $err";
	Log3 $name, 5, "$name: ParseHttpResponse - http code: ".$http_param->{code};

	if ($err ne "") {                                                          # wenn ein Fehler bei der HTTP Abfrage aufgetreten ist
		$HttpResponse = $err;
		Log3 $name, 3, "$name: ParseHttpResponse - error: $err";
		$state = $EPG_tt->{"ParseHttp_state2"} if (grep /timed out/, $err);
	} elsif ($http_param->{code} ne "200") {                                   # HTTP code
		$HttpResponse = $EPG_tt->{"ParseHttp_Http_file"} if (grep /$DownloadFile\swas\snot\sfound/, $data);
		$HttpResponse = $EPG_tt->{"ParseHttp_Http_URL"} if (grep /URL\swas\snot\sfound/, $data);
		Log3 $name, 3, "$name: ParseHttpResponse - error:\n\n$data";
	} elsif ($http_param->{code} eq "200" && $data ne "") {                    # wenn die Abfrage erfolgreich war ($data enthält die Ergebnisdaten des HTTP Aufrufes)
   	my $filename = "FHEM/EPG/$DownloadFile";
		open(my $file, ">", $filename);                                          # Datei schreiben
			print $file $data;
		close $file;

		Log3 $name, 4, "$name: ParseHttpResponse - returned ".length($data)." bytes Data";

		if ($DownloadFile =~ /.*\.gz$/) {
			Log3 $name, 4, "$name: ParseHttpResponse - unpack methode gz on $osname";
			($gzError, $DownloadFile) = EPG_UnCompress_gz($hash,$DownloadFile);    # Datei Unpack gz
			if ($gzError) {
				Log3 $name, 2, "$name: ParseHttpResponse unpack of $DownloadFile failed! ($gzError)";
				readingsSingleUpdate($hash, "state", $EPG_tt->{"ParseHttp_gz_error"}." $gzError", 1);
				return $gzError
			};
		} elsif ($DownloadFile =~ /.*\.xz$/) {
			Log3 $name, 4, "$name: ParseHttpResponse - unpack methode xz on $osname";
			($xzError, $DownloadFile) = EPG_UnCompress_xz($hash,$DownloadFile);    # Datei Unpack xz
			if ($xzError) {
				Log3 $name, 2, "$name: ParseHttpResponse unpack of $DownloadFile failed! ($xzError)";
				readingsSingleUpdate($hash, "state", $EPG_tt->{"ParseHttp_xz_error"}." $gzError", 1);
				return $xzError;
			}
		}

		EPG_File_check($hash) if ($osname ne "MSWin32");
		FW_directNotify("FILTER=$name", "#FHEMWEB:$FW_wname", "location.reload('true')", "");
		$state = 	$EPG_tt->{"ParseHttp_state_ok"};
		$HttpResponse = $EPG_tt->{"ParseHttp_Http_ok"};
	}

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "HttpResponse", $HttpResponse);                  # HttpResponse Status
	readingsBulkUpdate($hash, "state", $state);
	readingsEndUpdate($hash, 1);

	HttpUtils_Close($http_param);

	# loadEPG_now if cmd automatic_loadFile after "found 0 broadcast information, process automatic download started"
	CommandGet($hash, "$name loadEPG_now") if ($EPG_auto_download eq "yes" && $hash->{helper}{last_cmd} && $hash->{helper}{last_cmd} eq "automatic_loadFile");
}

#####################
sub EPG_UnCompress_gz($$) {
	my ($hash,$file) = @_;
	my $name = $hash->{NAME};
	my $input = "./FHEM/EPG/".$file;
	my $gzipfound = 0;

	if ($^O ne 'MSWin32') {
		## gzip -> gzip ##
		if (-d "/bin") {
			if ( -f "/bin/$tools[0]" && -x _ ) {
				$gzipfound++;
				Log3 $name, 4, "$name: UnCompress_gz - found $tools[0] on /bin";
			}
		}

		if ($gzipfound == 0) {
			Log3 $name, 4, "$name: UnCompress_gz - no found $tools[0]";
			return ("missing $tools[0] package",$input);
		}
	} else {
		return ("please unpack manually [example 7Zip]",$input);
	}

	local $SIG{CHLD} = 'DEFAULT';
	my $ok = qx(gzip -d -f $input 2>&1);   # Datei Unpack gz

	if ($ok ne "" || $? != 0) {
		Log3 $name, 4, "$name: UnCompress_gz - ERROR: $ok $?";
		return ("$ok $?",$input);
	}

	return (undef,$input);
}

#####################
sub EPG_UnCompress_xz($$) {
	my ($hash,$file) = @_;
	my $name = $hash->{NAME};
	my $input = "./FHEM/EPG/".$file;
	my $path_separator = ':';
	my $xzfound = 0;

	if ($^O ne 'MSWin32') {
		## xz -> xz-utils ##
		for my $path ( split /$path_separator/, $ENV{PATH} ) {
			#Log3 $name, 3, "$name: $cmd - \$ENV\{PATH\}: " .$path;
			if ( -f "$path/$tools[1]" && -x _ ) {
				$xzfound++;
				Log3 $name, 4, "$name: UnCompress_xz - found $tools[1] on " .$path;
				last;
			}
		}

		if ($xzfound == 0) {
			Log3 $name, 4, "$name: UnCompress_xz - no found $tools[1]";
			return ("missing $tools[0] (xz-utils) package",$input);
		}
	} else {
		return ("please unpack manually! [example 7Zip]",$input);
	}

	local $SIG{CHLD} = 'DEFAULT';
	my $ok = qx(xz -df $input 2>&1);   # Datei Unpack xz

	if ($ok ne "" || $? != 0) {
		Log3 $name, 4, "$name: UnCompress_xz - ERROR: $ok $?";
		return ("$ok $?",$input);
	}

	return (undef,$input);
}

#####################
sub EPG_Notify($$) {
	my ($hash, $dev_hash) = @_;
	my $name = $hash->{NAME};
	my $typ = $hash->{TYPE};
	return "" if(IsDisabled($name));	               # Return without any further action if the module is disabled
	my $devName = $dev_hash->{NAME};	               # Device that created the events
	my $events = deviceEvents($dev_hash, 1);

	if($devName eq "global" && grep(m/^INITIALIZED|REREADCFG$/, @{$events}) && $typ eq "EPG") {
		Log3 $name, 5, "$name: Notify is running and starting";
		CommandGet($hash, "$name available_channels");
	}
	return undef;
}

#####################
sub EPG_Undef($$) {
	my ($hash, $arg) = @_;
	my $name = $hash->{NAME};

	RemoveInternalTimer($hash);
	BlockingKill($hash->{helper}{RUNNING_PID}) if(defined($hash->{helper}{RUNNING_PID}));

	foreach my $value (qw(Channels_available Ch_commands EPG_file_last_timestamp FTUI_data HTML HTML_data_counter HTML_reload automatic_cnt last_cmd last_loaded programm)) {
		delete $hash->{helper}{$value} if(defined($hash->{helper}{$value}));
	}
	return undef;
}

#####################
sub EPG_File_check {
	my ($hash) = @_;
	my $name = $hash->{NAME};
	my $DownloadFile = AttrVal($name, "DownloadFile", "no file found");
	my $DownloadFile_found = 0;
	my $FileAge = $EPG_tt->{"File_check_fileage"};

	## check files ##
	opendir(DIR,"./FHEM/EPG");																		# not need -> || return "ERROR: directory $path can not open!"
		while( my $directory_value = readdir DIR ){
			if ($directory_value ne "." && $directory_value ne "..") {
				Log3 $name, 5, "$name: File_check - look for file -> $directory_value";
				if (index($DownloadFile,$directory_value) >= 0 ) {
					Log3 $name, 5, "$name: File_check found index $directory_value in $DownloadFile";
					if ($directory_value ne "." && $directory_value ne ".." && $directory_value !~ /\.(gz|xz)/) {
						Log3 $name, 4, "$name: File_check found $directory_value";
						$DownloadFile = $directory_value;
						$DownloadFile_found++;
						last;
					}
				}
			}
		}
	close DIR;

	if ($DownloadFile_found != 0) {
		Log3 $name, 4, "$name: File_check ready to search properties on $DownloadFile";	
		my @stat_DownloadFile = stat("./FHEM/EPG/".$DownloadFile);  # Dateieigenschaften
		$FileAge = FmtDateTime($stat_DownloadFile[9]);              # letzte Änderungszeit

		Log3 $name, 5, "$name: File_check ready - file rights: ".substr((sprintf "%#o", $stat_DownloadFile[2]),1);
		Log3 $name, 5, "$name: File_check ready - file owner-ID numbre: ".$stat_DownloadFile[4];
		Log3 $name, 5, "$name: File_check ready - file group-ID numbre: ".$stat_DownloadFile[5];
		Log3 $name, 5, "$name: File_check ready - file size: ".$stat_DownloadFile[7]." byte";
	} else {
		Log3 $name, 5, "$name: File_check nothing file found";
		$DownloadFile = $EPG_tt->{"File_check_DownFile"};
	}

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "EPG_file_age" , $FileAge);
	readingsBulkUpdate($hash, "EPG_file_name" , $DownloadFile);
	readingsEndUpdate($hash, 0);
}

#####################
sub EPG_nonBlock_available_channels($) {
	my ($string) = @_;
	my ($name, $EPG_file_name) = split("\\|", $string);
  my $hash = $defs{$name};
  my $return;
	my $Variant = "unknown";
	my $Ch_id;
	my $ok = "ok";
	my $additive_info = "";
	my @Channels_available;

  Log3 $name, 4, "$name: nonBlock_available_channels running";
  Log3 $name, 5, "$name: nonBlock_available_channels string=$string";

	if (-e "./FHEM/EPG/$EPG_file_name") {
		open (FileCheck,"<./FHEM/EPG/$EPG_file_name");
			my $line_cnt = 0;
			while (<FileCheck>) {
				my $Ch_name;
				$line_cnt++;
				if ($line_cnt > 0 && $line_cnt <= 3) {
					my $line = $_;
					chomp ($line);
					Log3 $name, 5, "$name: nonBlock_available_channels line: ".$line;
				}
				# <tv generator-info-name="Rytec" generator-info-url="http://forums.openpli.org">
				$Variant = "Rytec" if ($_ =~ /.*generator-info-name="Rytec".*/);
				# <tv source-data-url="http://api.tvprofil.net/" source-info-name="TvProfil API v1.7 - XMLTV" source-info-url="https://tvprofil.com">
				$Variant = "TvProfil_XMLTV" if ($_ =~ /.*source-info-name="TvProfil.*/);
				# <tv generator-info-name="WebGrab+Plus/w MDB &amp; REX Postprocess -- version V2.1.5 -- Jan van Straaten" generator-info-url="http://www.webgrabplus.com">
				$Variant = "WebGrab+Plus" if ($_ =~ /.*generator-info-name="WebGrab\+Plus.*/);
				#XMLTV.se       <tv generator-info-name="Vind 2.52.12" generator-info-url="https://xmltv.se">
				$Variant = "XMLTV.se" if ($_ =~ /.*generator-info-url="https:\/\/xmltv.se.*/);
				#teXXas via RSS  <channel><title>teXXas - 
				$Variant = "teXXas_RSS" if ($_ =~ /.*<channel><title>teXXas -.*<link>http:\/\/www.texxas.de\/tv\/programm.*/);

				if ($Variant eq "Rytec" || $Variant eq "TvProfil_XMLTV" || $Variant eq "WebGrab+Plus" || $Variant eq "XMLTV.se") {
					$Ch_id = $1 if ($_ =~ /<channel id="(.*)">/);        # other
					$Ch_id = $1 if ($_ =~ /\schannel="(.*)"\s?start=/);  # XMLTV.se

					if ($_ =~ /<display-name lang=".*">(.*)<.*/) {
						Log3 $name, 5, "$name: nonBlock_available_channels id: $Ch_id -> display_name: ".$1;
						$Ch_name = $1;
					}

					$Ch_name = $Ch_id if ($Variant eq "XMLTV.se");
					Log3 $name, 4, "$name: nonBlock_available_channels with variant=$Variant and without ch_id. need help!" if (!$Ch_name && $line_cnt == 4);
					Log3 $name, 4, "$name: nonBlock_available_channels with variant=$Variant" if ($Ch_name && $line_cnt == 4);

					## nonBlock_available_channels set helper ##
					if ($Ch_name && (not grep /^$Ch_name$/, @Channels_available)) {
						Log3 $name, 5, "$name: nonBlock_available_channels added $Ch_name with ch_id $Ch_id";
						$hash->{helper}{Programm}{$Ch_id} = $Ch_name;
						push(@Channels_available,$Ch_name);					
					}
				} elsif ($Variant eq "teXXas_RSS") {
					$hash->{helper}{Programm} = "now" if ($_ =~ /<link>http:\/\/www.texxas.de\/tv\/programm\/jetzt\//);
					$hash->{helper}{Programm} = "20:15" if ($_ =~ /<link>http:\/\/www.texxas.de\/tv\/programm\/heute\/2015\//);
					## nonBlock_available_channels set helper ##
					my @RRS = split("<item>", $_);
					my $remove = shift @RRS;
					for (@RRS) {
						push(@Channels_available,$1) if ($_ =~ /<dc:subject>(.*)<\/dc:subject>/);
					}
				}
			}
		close FileCheck;

		if ($Variant eq "Rytec" || $Variant eq "TvProfil_XMLTV" || $Variant eq "WebGrab+Plus" || $Variant eq "XMLTV.se") {
			$additive_info = JSON->new->utf8(0)->encode($hash->{helper}{Programm});
			Log3 $name, 4, "$name: nonBlock_available_channels read additive_info with variant $Variant";
		} elsif ($Variant eq "teXXas_RSS") {
			$additive_info = $hash->{helper}{Programm};	
		}
	} else {
		$ok = $EPG_tt->{"available_ch_ok"};
		Log3 $name, 4, "$name: nonBlock_available_channels file $EPG_file_name not found, need help!";
	}

	my $ch_available = join(";", @Channels_available);
	$return = $name."|".$EPG_file_name."|".$ok."|".$Variant."|".$ch_available."|".$additive_info;

	return $return;
}

#####################
sub EPG_nonBlock_available_channelsDone($) {
	my ($string) = @_;
	my ($name, $EPG_file_name, $ok, $Variant, $ch_available, $additive_info) = split("\\|", $string);
  my $hash = $defs{$name};
	my $ch_table = "";
	my $Ch_select = AttrVal($name, "Ch_select", undef);
	my $EPG_auto_update = AttrVal($name, "EPG_auto_update", "no");
	my @Ch_select_array = split(",",$Ch_select) if ($Ch_select);
	my $FW_wname = !$FW_wname ? "WEB" : $FW_wname;

	return unless(defined($string));
  Log3 $name, 4, "$name: nonBlock_available_channelsDone running";
  Log3 $name, 5, "$name: nonBlock_available_channelsDone string=$string";
	delete($hash->{helper}{RUNNING_PID});

	if ($Variant eq "unknown") {
		readingsSingleUpdate($hash, "state", $EPG_tt->{"chDone_state1"}, 1);
		return "";
	}

	if ($ok ne "ok") {
		readingsSingleUpdate($hash, "state", "$ok", 1);
		return "";
	}

  my @Channels_available = split(';', $ch_available);
	@Channels_available = sort @Channels_available;

	## check channels in attr Ch_select available in file (new available channels) ##
	if ($Ch_select) {
		for(my $i=0;$i<=$#Ch_select_array;$i++) {
			if (not grep /^$Ch_select_array[$i]$/, @Channels_available) {
				my %mod = map { ($_ => 1) }
							grep { $_ !~ m/^$Ch_select_array[$i](:.+)?$/ }
							split(",", $Ch_select);
				$attr{$name}{Ch_select} = join(",", sort keys %mod);
				delete $attr{$name}{Ch_select} if( (!keys %mod && defined($attr{$name}{Ch_select})) || (defined($attr{$name}{Ch_select}) && $attr{$name}{Ch_select} eq "") );
				Log3 $name, 4, "$name: nonBlock_available_channelsDone delete $Ch_select_array[$i] from list Ch_select -> not available";
			}
		}
	}

	if ($Variant eq "Rytec" || $Variant eq "TvProfil_XMLTV" || $Variant eq "WebGrab+Plus" || $Variant eq "XMLTV.se") {
		$additive_info = eval {encode_utf8( $additive_info )};
		$ch_table = decode_json($additive_info);

		foreach my $ch (sort keys %{$ch_table}) {
			Log3 $name, 5, "$name: nonBlock_available_channelsDone channel ".$ch . " -> " . $ch_table->{$ch};
		}	
	}

	$ch_table = $additive_info if ($Variant eq "teXXas_RSS");

	$hash->{helper}{Programm} = $ch_table;
	CommandAttr($hash,"$name Variant $Variant") if ($Variant ne "unknown");
	FW_directNotify("FILTER=$name", "#FHEMWEB:$FW_wname", "location.reload('true')", "");		            # reload Webseite

	if (AttrVal($name, "Ch_select", undef)) {
		if ($EPG_auto_update ne "yes") {
			InternalTimer(gettimeofday()+EPG_InternalTimer_DELAY, "EPG_readingsSingleUpdate_later", "$name,".$EPG_tt->{"chDone_msg_OK"});		
		} else {
			CommandGet($hash, "$name loadEPG_now") if ($Variant ne "teXXas_RSS");
		}
	} else {
		InternalTimer(gettimeofday()+EPG_InternalTimer_DELAY, "EPG_readingsSingleUpdate_later", "$name,".$EPG_tt->{"chDone_msg_OK2"});
	}

	$hash->{helper}{Channels_available} = \@Channels_available;
}

#####################
sub EPG_nonBlock_loadEPG_v1($) {
	my ($string) = @_;
	my ($name, $EPG_file_name, $cmd, $cmd2) = split("\\|", $string);
	my $Ch_select = AttrVal($name, "Ch_select", undef);
	my $Ch_sort = AttrVal($name, "Ch_sort", undef);

	my $FavDesc = AttrVal($name, "FavDesc", undef) if ($cmd eq "loadEPG_FavDesc");
	my @FavDesc_array = split(";",$FavDesc) if ($FavDesc);
	my $FavDesc_found = 0;
	my $FavTitle = AttrVal($name, "FavTitle", undef) if ($cmd eq "loadEPG_FavTitle");
	my @FavTitle_array = split(";",$FavTitle) if ($FavTitle);
	my $FavTitle_found = 0;

  my $hash = $defs{$name};
  my $return;

  Log3 $name, 4, "$name: nonBlock_loadEPG_v1 running, $cmd from file $EPG_file_name";
  Log3 $name, 5, "$name: nonBlock_loadEPG_v1 string=$string";

	my $off_h = 0;
	my @gmt = (gmtime(time+$off_h*60*60));
	my @local = (localtime(time+$off_h*60*60));
	my $TimeLocaL_GMT_Diff = $gmt[2]-$local[2] + ($gmt[5] <=> $local[5] || $gmt[7] <=> $local[7])*24;

	my $EPG_info = "";         # info for user via EPG_readingsSingleUpdate_later
	my $EPG_cnt = 0;           # counter for founded data
	my $array_cnt = -1;        # counter to verification data
	my $EPG_found = 0;          # counter to verification ch
	my $Ch_id = "";            # TV channel channel id
	my $Ch_name = "";          # TV channel display-name
	my $Ch_name_before = "";   # TV channel display-name before
	my $desc = "";             # TV desc text
	my $descend = 0;           # TV desc - ened
	my $descstart = 0;         # TV desc - start
	my $end = "";              # TV time end
	my $hour_diff_read = "";   # hour diff from file
	my $last_loaded = "";      # for Reading EPG_last_loaded
	my $start = "";            # TV time start
	my $subtitle = "";         # TV subtitle
	my $title = "";            # TV title
	my $today_end = "";        # today time end
	my $today_start = "";      # today time start
	my $EPG_file_last_timestamp = "";  # last timestamp on file

	my @Ch_select_array = split(",",$Ch_select) if ($Ch_select);
	my @Ch_sort_array = split(",",$Ch_sort) if ($Ch_sort);

	if ($TimeLocaL_GMT_Diff < 0) {
		$TimeLocaL_GMT_Diff = abs($TimeLocaL_GMT_Diff);
		$TimeLocaL_GMT_Diff = "+".sprintf("%02s", abs($TimeLocaL_GMT_Diff))."00";
	} else {
		$TimeLocaL_GMT_Diff = sprintf("-%02s", $TimeLocaL_GMT_Diff) ."00";
	}

	Log3 $name, 4, "$name: nonBlock_loadEPG_v1 localtime     ".localtime(time+$off_h*60*60);
	Log3 $name, 4, "$name: nonBlock_loadEPG_v1 gmtime        ".gmtime(time+$off_h*60*60);
	Log3 $name, 4, "$name: nonBlock_loadEPG_v1 diff (GMT-LT) " . $TimeLocaL_GMT_Diff;

	my $TimeNow = FmtDateTime(time());
	$TimeNow =~ s/-|:|\s//g;
	$TimeNow.= " $TimeLocaL_GMT_Diff";                       # loadEPG_now   20191016150432 +0200

	if ($cmd =~ /loadEPG_now/) {
		$last_loaded = substr($TimeNow,0,8)."_".substr($TimeNow,8,4);
	}
	
	if ($cmd =~ /loadEPG_Prime/) {
		substr($TimeNow, 8) = "201510 $TimeLocaL_GMT_Diff";    # loadEPG_Prime 20191016201510 +0200	heute
		$last_loaded = substr($TimeNow,0,8)."_2015";
	}
	
	if ($cmd =~ /loadEPG_today/) {                           # Beginn und Ende von heute bestimmen
		$today_start = substr($TimeNow,0,8)."000000 $TimeLocaL_GMT_Diff";
		$today_end = substr($TimeNow,0,8)."235959 $TimeLocaL_GMT_Diff";
		$last_loaded = substr($today_start,0,8)."_";
	}

	if ($cmd =~ /loadEPG/ && $cmd2 =~ /^[0-9]*_[0-9]*$/) {   # loadEPG 20191016_200010 +0200 stündlich ab jetzt
		$TimeNow = $cmd2;
		$TimeNow =~ s/_//g;
		$TimeNow.= "10 $TimeLocaL_GMT_Diff";
		$last_loaded = substr($TimeNow,0,8)."_".substr($TimeNow,8,4);
	}

	if ($cmd =~ /^loadEPG_Fav/) {
		$last_loaded = "_";
	}

	Log3 $name, 4, "$name: nonBlock_loadEPG_v1 | TimeNow          -> $TimeNow";

	if (-e "./FHEM/EPG/$EPG_file_name") {
		open (FileCheck,"<./FHEM/EPG/$EPG_file_name");
			while (<FileCheck>) {
				if ($_ =~ /<programme start="(.*\s+(.*))" stop="(.*)" channel="(.*)"/) {      # find start | end | channel
					my $search = $hash->{helper}{Programm}{$4};
					#Log3 $name, 4, "$name: nonBlock_loadEPG_v1 | data for channel    -> $search";
					($start, $hour_diff_read, $end, $Ch_id, $Ch_name) = ($1, $2, $3, $4, $search);

					if ($TimeLocaL_GMT_Diff ne $hour_diff_read) {
						Log3 $name, 5, "$name: nonBlock_loadEPG_v1 | Time must be recalculated! local=$TimeLocaL_GMT_Diff read=$2";
						my $hour_diff = substr($TimeLocaL_GMT_Diff,0,1).substr($TimeLocaL_GMT_Diff,2,1);
						Log3 $name, 5, "$name: nonBlock_loadEPG_v1 | hour_diff_result $hour_diff";

						my @start_new = split("",$start);
						my @end_new = split("",$end);
						# Log3 $name, 5, "$name: nonBlock_loadEPG_v1 | ".'sec | min | hour | mday | month | year';
						# Log3 $name, 5, "$name: nonBlock_loadEPG_v1 | $start_new[12]$start_new[13]  | $start_new[10]$start_new[11]  |  $start_new[8]$start_new[9]  | $start_new[6]$start_new[7]   | $start_new[4]$start_new[5]    | $start_new[0]$start_new[1]$start_new[2]$start_new[3]";
						# Log3 $name, 5, "$name: nonBlock_loadEPG_v1 | $end_new[12]$end_new[13]  | $end_new[10]$end_new[11]  |  $end_new[8]$end_new[9]  | $end_new[6]$end_new[7]   | $end_new[4]$end_new[5]    | $end_new[0]$end_new[1]$end_new[2]$end_new[3]";
						# Log3 $name, 5, "$name: nonBlock_loadEPG_v1 | UTC start        -> ".fhemTimeLocal(($start_new[12].$start_new[13]), ($start_new[10].$start_new[11]), ($start_new[8].$start_new[9]), ($start_new[6].$start_new[7]), (($start_new[4].$start_new[5])*1-1), (($start_new[0].$start_new[1].$start_new[2].$start_new[3])*1-1900));
						# Log3 $name, 5, "$name: nonBlock_loadEPG_v1 | UTC end          -> ".fhemTimeLocal(($end_new[12].$end_new[13]), ($end_new[10].$end_new[11]), ($end_new[8].$end_new[9]), ($end_new[6].$end_new[7]), (($end_new[4].$end_new[5])*1-1), (($end_new[0].$end_new[1].$end_new[2].$end_new[3])*1-1900));
						# Log3 $name, 5, "$name: nonBlock_loadEPG_v1 | start            -> $start";             # 20191023211500 +0000
						# Log3 $name, 5, "$name: nonBlock_loadEPG_v1 | end              -> $end";               # 20191023223000 +0000

						if (index($hour_diff,"-")) {
							$start = fhemTimeLocal(($start_new[12].$start_new[13]), ($start_new[10].$start_new[11]), ($start_new[8].$start_new[9]), ($start_new[6].$start_new[7]), (($start_new[4].$start_new[5])*1-1), (($start_new[0].$start_new[1].$start_new[2].$start_new[3])*1-1900)) + (60*60*abs(substr($TimeLocaL_GMT_Diff,2,1)));
							$end = fhemTimeLocal(($end_new[12].$end_new[13]), ($end_new[10].$end_new[11]), ($end_new[8].$end_new[9]), ($end_new[6].$end_new[7]), (($end_new[4].$end_new[5])*1-1), (($end_new[0].$end_new[1].$start_new[2].$start_new[3])*1-1900)) + (60*60*abs(substr($TimeLocaL_GMT_Diff,2,1)));
						} else {
							$start = fhemTimeLocal(($start_new[12].$start_new[13]), ($start_new[10].$start_new[11]), ($start_new[8].$start_new[9]), ($start_new[6].$start_new[7]), (($start_new[4].$start_new[5])*1-1), (($start_new[0].$start_new[1].$start_new[2].$start_new[3])*1-1900)) - (60*60*abs(substr($TimeLocaL_GMT_Diff,2,1)));
							$end = fhemTimeLocal(($end_new[12].$end_new[13]), ($end_new[10].$end_new[11]), ($end_new[8].$end_new[9]), ($end_new[6].$end_new[7]), (($end_new[4].$end_new[5])*1-1), (($end_new[0].$end_new[1].$start_new[2].$start_new[3])*1-1900)) - (60*60*abs(substr($TimeLocaL_GMT_Diff,2,1)));
						}

						$start = FmtDateTime($start);
						$end = FmtDateTime($end);
						$start =~ s/-|:|\s//g;
						$end =~ s/-|:|\s//g;
						$start.= " $TimeLocaL_GMT_Diff";
						$end.= " $TimeLocaL_GMT_Diff";

						# Log3 $name, 4, "$name: nonBlock_loadEPG_v1 | start new        -> $start";
						# Log3 $name, 4, "$name: nonBlock_loadEPG_v1 | end new          -> $end";
					}

					## save last timestamp from EPG_file ##
					$EPG_file_last_timestamp = $end ne "" && $EPG_file_last_timestamp lt $end ? $end : $EPG_file_last_timestamp;

					if ($cmd !~ /loadEPG_Fav/ && grep /$search($|,)/, $Ch_select) {             # find in attributes channel
						if ($cmd !~ /loadEPG_today/) {
							$EPG_found++ if ($TimeNow gt $start && $TimeNow lt $end);               # Zeitpunktsuche, normal
						} else {
              # Zeitpunktsuche, kompletter Tag
							if (($start eq $today_start || $start gt $today_start) && ($end eq $today_end || $end lt $today_end) || ($start lt $today_end && ($end gt $today_end || $end eq $today_end))) {
								# Log3 $name, 3, "$name: nonBlock_loadEPG_v1 | start            -> $start";
								# Log3 $name, 3, "$name: nonBlock_loadEPG_v1 | today_start      -> $today_start";
								# Log3 $name, 3, "$name: nonBlock_loadEPG_v1 | end              -> $end";
								# Log3 $name, 3, "$name: nonBlock_loadEPG_v1 | today_end        -> $today_end";
								$EPG_found++;
							}
						}
					}
				}

				### title subtitle desc if EPG_found ###
				if ($cmd !~ /loadEPG_Fav/ && $EPG_found != 0) {
					$title = $2 if ($_ =~ /<title lang="(.*)">(.*)<\/title>/);                # title
					$subtitle = $2 if ($_ =~ /<sub-title lang="(.*)">(.*)<\/sub-title>/);     # subtitle
					
					if ($_ =~ /<desc lang="(.*)">(.*)<\/desc>/ && $descstart == 0) {          # desc - one line
						$desc = $2;
						$descstart = 1;
						$descend = 1;
					}

				### title subtitle desc if always ###
				} else {
					$title = $2 if ($_ =~ /<title lang="(.*)">(.*)<\/title>/);                # title
					$subtitle = $2 if ($_ =~ /<sub-title lang="(.*)">(.*)<\/sub-title>/);     # subtitle

					if ($_ =~ /<desc lang="(.*)">(.*)<\/desc>/ && $descstart == 0) {          # desc - one line
						$desc = $2;
						$descstart = 1;
						$descend = 1;
					}
				}

				if ($_ =~ /<desc lang="(.*)">(.*)/ && $descstart == 0 && $descend == 0) {          # desc - multiline line
					$desc = $2;
					$descstart = 1;
				}

				if ($descstart == 1 && $descend == 0 && $_ !~ /<desc lang/ && $_ !~ /<\/desc>/) {  # desc - multiline line
					chomp ($_);
					$desc.= " ".$_;
				}

				if ($descstart == 1 && $descend == 0 && $_ =~ /(.*)<\/desc>/) {                     # desc - multiline line end
					$desc.= " ".$1;
					$descend = 1;
				};

				### FavTitle FavDesc over all Programms ###
				if ($_ =~ /<\/programme>/ && $cmd =~ /loadEPG_Fav/) {
					## looking for FavTitle ##
					if (scalar(@FavTitle_array) > 0 && ($start gt $TimeNow)) {
						for (my $i=0;$i<@FavTitle_array;$i++) {
							if (grep /^\Q$FavTitle_array[$i]\E/, $title) {
								$EPG_found++;
								$FavTitle_found++;
							}
						}
					}

					## looking for FavDesc ##					
					if (scalar(@FavDesc_array) > 0 && ($start gt $TimeNow)) {
						for (my $i=0;$i<@FavDesc_array;$i++) {
							if (grep /\Q$FavDesc_array[$i]/, $desc) {
								$EPG_found++;
								$FavDesc_found++;
							}
						}
					}
				}
				### END ###

				## FOUND - End of program entry ##
				if ($_ =~ /<\/programme>/ && $EPG_found != 0) {          # find end channel
					$array_cnt = -1 if ($Ch_name_before ne $Ch_name);      # Reset bei Kanalwechsel
					$array_cnt++;
					Log3 $name, 4, "#################################################";
					Log3 $name, 4, "$name: nonBlock_loadEPG_v1 | ch_name          -> $Ch_name";
					Log3 $name, 4, "$name: nonBlock_loadEPG_v1 | ch_before        -> $Ch_name_before";
					Log3 $name, 4, "$name: nonBlock_loadEPG_v1 | EPG information  -> $array_cnt (value of array)";
					Log3 $name, 4, "$name: nonBlock_loadEPG_v1 | FavDesc          -> $FavDesc_found";
					Log3 $name, 4, "$name: nonBlock_loadEPG_v1 | FavTitle         -> $FavTitle_found";
					Log3 $name, 5, "$name: nonBlock_loadEPG_v1 | start (intern)   -> $start";
					Log3 $name, 5, "$name: nonBlock_loadEPG_v1 | end (indern)     -> $end";

					## time format better for JSON and format once intern
					($start) = EPG_Time_toISO_v1($start);
					($end) = EPG_Time_toISO_v1($end);
					Log3 $name, 4, "$name: nonBlock_loadEPG_v1 | start            -> $start";
					Log3 $name, 4, "$name: nonBlock_loadEPG_v1 | end              -> $end";

					Log3 $name, 4, "$name: nonBlock_loadEPG_v1 | title            -> $title";
					Log3 $name, 5, "$name: nonBlock_loadEPG_v1 | subtitle         -> $subtitle";
					Log3 $name, 5, "$name: nonBlock_loadEPG_v1 | desc             -> $desc.\n";

					$hash->{helper}{HTML}{$Ch_name}{Ch_name} = $Ch_name;
					$hash->{helper}{HTML}{$Ch_name}{Ch_id} = $Ch_id;

					if ($Ch_select && $Ch_sort && (grep /$Ch_name/, $Ch_select)) {
						foreach my $i (0 .. $#Ch_select_array) {
							if ($Ch_select_array[$i] eq $Ch_name) {
								my $value_new = EPG_Temp_ChSortNumbre;
								$value_new = $Ch_sort_array[$i] if ($Ch_sort_array[$i] != 0);
								$hash->{helper}{HTML}{$Ch_select_array[$i]}{Ch_sort} = $value_new;
								Log3 $name, 4, "$name: nonBlock_loadEPG_v1 old numbre of ".$Ch_select_array[$i]." set to ".$value_new;
							}
						}
					} else {
						$hash->{helper}{HTML}{$Ch_name}{Ch_sort} = EPG_Temp_ChSortNumbre;
					}

					my $mod_cnt;
					($title, $subtitle, $desc, $mod_cnt) = EPG_SyntaxCheck_for_JSON_v1($hash, $title, $subtitle, $desc);

					$hash->{helper}{HTML}{$Ch_name}{EPG}[$array_cnt]{start} = $start;
					$hash->{helper}{HTML}{$Ch_name}{EPG}[$array_cnt]{end} = $end;
					$hash->{helper}{HTML}{$Ch_name}{EPG}[$array_cnt]{title} = $title;
					$hash->{helper}{HTML}{$Ch_name}{EPG}[$array_cnt]{subtitle} = $subtitle;
					$hash->{helper}{HTML}{$Ch_name}{EPG}[$array_cnt]{desc} = $desc;

					### if modify JSON ###
					Log3 $name, 5, "$name: nonBlock_loadEPG_v1 Dumper: ".Dumper\$hash->{helper}{HTML}{$Ch_name}{EPG}[$array_cnt] if ($mod_cnt != 0);

					$EPG_cnt++;
					$EPG_found = 0;
					$Ch_name_before = $Ch_name;
				}

				## NOTHING FOUND - End of program entry - AND RESET values ##
				if ($_ =~ /<\/programme>/) {
					$Ch_name = "";
					$desc = "";
					$descend = 0;
					$descstart = 0;
					$hour_diff_read = "";
					$subtitle = "";
					$title = "";
				}
			}
		close FileCheck;

		$EPG_info = $EPG_tt->{"loadEPG_msg1"} if ($array_cnt != -1);
		$EPG_info = $EPG_tt->{"loadEPG_msg2"} if ($array_cnt == -1);
	} else {
		$EPG_info = $EPG_tt->{"loadEPG_msg3"};
		Log3 $name, 3, "$name: nonBlock_loadEPG_v1 | error, file $EPG_file_name no found at ./opt/fhem/FHEM/EPG";
	}

	my $json_HTML;
	$json_HTML = JSON->new->utf8(0)->encode($hash->{helper}{HTML}) if ($array_cnt != -1);
	$json_HTML = "" if ($array_cnt == -1);
	Log3 $name, 5, "$name: nonBlock_loadEPG_v1 value JSON for delivery: $json_HTML";

	$return = $name."|".$EPG_file_name."|".$EPG_info."|".$cmd."|".$cmd2."|".$json_HTML."|".$last_loaded."|".$EPG_cnt."|".$EPG_file_last_timestamp;
	return $return;
}

#####################
sub EPG_nonBlock_loadEPG_v1Done($) {
	my ($string) = @_;
	my ($name, $EPG_file_name, $EPG_info, $cmd, $cmd2, $json_HTML, $last_loaded, $EPG_cnt, $EPG_file_last_timestamp) = split("\\|", $string);
  my $hash = $defs{$name};
	my $Ch_commands = AttrVal($name,"Ch_commands", undef);
	my $Ch_Info_to_Reading = AttrVal($name, "Ch_Info_to_Reading", "no");
	my $EPG_auto_download = AttrVal($name, "EPG_auto_download", "no");
	my $Ch_select = AttrVal($name, "Ch_select", undef);
	my @Ch_select_array = split(",",$Ch_select) if ($Ch_select);
	my $room = AttrVal($name, "room", "");
	my $FW_wname = !$FW_wname ? "WEB" : $FW_wname;

  Log3 $name, 4, "$name: nonBlock_loadEPG_v1Done running, $cmd from file $EPG_file_name";
  Log3 $name, 5, "$name: nonBlock_loadEPG_v1Done string=$string";

	delete($hash->{helper}{RUNNING_PID});
	$hash->{helper}{HTML_data_counter} = $EPG_cnt;

	if ($EPG_cnt == 0 && $EPG_auto_download eq "yes") {
		$hash->{helper}{automatic_cnt}++;
		## safety loop and STOP ##
		if ($hash->{helper}{automatic_cnt} >= 2) {
			$hash->{helper}{last_cmd} = "STOP";
			Log3 $name, 2, "$name: nonBlock_loadEPG_v1Done automatic download STOP, no current data!";
			readingsSingleUpdate($hash, "state", $EPG_tt->{"loadEPG_v1Done_STOP"},1);
			return undef;
		}

		Log3 $name, 3, "$name: nonBlock_loadEPG_v1Done found 0 broadcast information, process automatic download started";
		$hash->{helper}{last_cmd} = "automatic_loadFile";
		CommandGet($hash, "$name loadFile");
		return undef;
	}

	delete $hash->{helper}{automatic_cnt} if ($hash->{helper}{automatic_cnt});

	Log3 $name, 4, "$name: nonBlock_loadEPG_v1Done found $EPG_cnt broadcast information";
	$json_HTML = eval {encode_utf8( $json_HTML )};
	my $HTML = eval { decode_json( $json_HTML ) } if ($json_HTML ne "");

	if ($@) {
		Log3 $name, 3, "$name: nonBlock_loadEPG_v1Done, Please report it to the developer with the following line!";
		Log3 $name, 3, "$name: nonBlock_loadEPG_v1Done decode_json failed: ".$@;

		readingsBeginUpdate($hash);
		readingsBulkUpdate($hash, "state", "#### ERROR JSON ####");
		readingsBulkUpdate($hash, "state", $@);
		readingsBulkUpdate($hash, "state", "$json_HTML");
		readingsBulkUpdate($hash, "state", $EPG_tt->{"loadEPG_v1Done"});
		readingsEndUpdate($hash, 1);

		return "ERROR";
	}
	
	if ($Ch_Info_to_Reading eq "yes") {
		## delete old Readings ##
		foreach my $reading (keys %{$hash->{READINGS}}) {
			if ($reading =~ /^x_.*/ && (not grep /^$reading$/, @Ch_select_array)) {
				Log3 $name, 5, "$name: nonBlock_loadEPG_v1Done delete reading $reading";
				readingsDelete($hash,$reading);
			}
		}

		if ($cmd =~ /loadEPG_now/ || $cmd =~ /loadEPG_Prime/ || $cmd =~ /loadEPG_today/) {
			## create Readings ##
			readingsBeginUpdate($hash);

			foreach my $ch (sort keys %{$HTML}) {
				## Kanäle ##
				Log3 $name, 4, "#################################################";
				Log3 $name, 4, "$name: nonBlock_loadEPG_v1Done ch          -> $ch";
				# start end title
				for (my $i=0;$i<@{$HTML->{$ch}{EPG}};$i++){
					Log3 $name, 4, "$name: nonBlock_loadEPG_v1Done array value -> ".$i;
					Log3 $name, 4, "$name: nonBlock_loadEPG_v1Done start       -> ".$HTML->{$ch}{EPG}[$i]{start};
					Log3 $name, 4, "$name: nonBlock_loadEPG_v1Done end         -> ".$HTML->{$ch}{EPG}[$i]{end};
					Log3 $name, 4, "$name: nonBlock_loadEPG_v1Done title       -> ".$HTML->{$ch}{EPG}[$i]{title};

					my $time = substr($HTML->{$ch}{EPG}[$i]{start},11,2).":".substr($HTML->{$ch}{EPG}[$i]{start},14,2)."-".substr($HTML->{$ch}{EPG}[$i]{end},11,2).":".substr($HTML->{$ch}{EPG}[$i]{end},14,2);
					#Log3 $name, 4, "$name: nonBlock_loadEPG_v1Done time fromto -> ".$time;
					readingsBulkUpdate($hash, "x_".$ch."_".$time, $HTML->{$ch}{EPG}[$i]{title});
				}
			}
			readingsEndUpdate($hash, 1);
		}
	}

	## Ch_commands check and set to helper ##
	if ($Ch_commands) {
		my $av = eval $Ch_commands;
		if( $@ ) {
			Log3 $name, 3, "$name: nonBlock_loadEPG_v1Done - Ch_Command, ERROR: ". $@;
			delete $hash->{helper}{Ch_commands} if(defined($hash->{helper}{Ch_commands}));
		} else {
			$Ch_commands = $av if( ref($av) eq "HASH" );
			$hash->{helper}{Ch_commands} = $Ch_commands;
		}
	}

	## JSON data ##
	my @mychannels = ();
	foreach my $ch (keys %{$HTML}) {
		## check Ch_Command for channel
		if ($hash->{helper}{Ch_commands} && grep { $_ eq "$ch" } %{$hash->{helper}{Ch_commands}}) {
			foreach my $d (keys %{$hash->{helper}{Ch_commands}}) {
				if (exists $HTML->{$ch} && $d eq $ch) {
					$HTML->{$d}{Ch_command} = $hash->{helper}{Ch_commands}{$d};
					Log3 $name, 4, "$name: nonBlock_loadEPG_v1Done, Ch_Command found, $d => " . $hash->{helper}{Ch_commands}{$d};
				}
			}
		}
		push (@mychannels, $HTML->{$ch});
	}

	$hash->{helper}{FTUI_data} = \@mychannels;
	$hash->{helper}{HTML} = $HTML;
	$hash->{helper}{last_cmd} = $cmd;
	$hash->{helper}{last_loaded} = $last_loaded;
	
	if ($EPG_file_last_timestamp ne "") {
		## change to FHEM format
		($EPG_file_last_timestamp) = EPG_Time_toISO_v1($EPG_file_last_timestamp);
		$hash->{helper}{EPG_file_last_timestamp} = $EPG_file_last_timestamp;
	}

	FW_directNotify("FILTER=(room=$room|$name)", "#FHEMWEB:$FW_wname", "location.reload('true')", "");		# reload Webseite

	my $text = $cmd2 ne "" ? $cmd."_".$last_loaded : $cmd."_".$last_loaded;
	InternalTimer(gettimeofday()+EPG_InternalTimer_DELAY, "EPG_readingsSingleUpdate_later", "$name,$EPG_info,$text");
}

#####################
sub EPG_nonBlock_loadEPG_v2($) {
	my ($string) = @_;
	my ($name, $EPG_file_name, $cmd, $cmd2) = split("\\|", $string);
	my $Ch_select = AttrVal($name, "Ch_select", undef);
	my $Ch_sort = AttrVal($name, "Ch_sort", undef);
  my $hash = $defs{$name};
  my $return;

  Log3 $name, 4, "$name: nonBlock_loadEPG_v2 running, $cmd from file $EPG_file_name";
  Log3 $name, 5, "$name: nonBlock_loadEPG_v2 string=$string";

	my @Ch_select_array = split(",",$Ch_select) if ($Ch_select);
	my @Ch_sort_array = split(",",$Ch_sort) if ($Ch_sort);

	my $EPG_info = "";	
	my $array_cnt = -1;         # counter to verification data

	if (-e "./FHEM/EPG/$EPG_file_name") {
		open (FileCheck,"<./FHEM/EPG/$EPG_file_name");
			my $string = "";
			while (<FileCheck>) {
				$string .= $_;
			}
		close FileCheck;
		#Log3 $name, 4, "$name: nonBlock_loadEPG_v2 $string";
		my @RRS = split("<item>", $string);
		my $remove = shift @RRS;

		for (@RRS) {
			my $EPG_found = 0;
			my $Ch_name;
			my $desc = "";
			my $end;
			my $start;

			if($_ =~ /<dc:subject>(.*)<\/dc:subject>/) {
				Log3 $name, 5, "$name: nonBlock_loadEPG_v2 look for    -> ".$1." selection in $Ch_select" if ($Ch_select);
				my $search = $1;
				if (index($search,"+") >= 0) {
					substr($search,index($search,"+"),1,'\+');
				}

				if ( ($Ch_select) && (grep /$search($|,)/, $Ch_select) ) {
					#Log3 $name, 3, "$name: $cmd $_";
					Log3 $name, 4, "$name: nonBlock_loadEPG_v2             -> $1 found";
					$Ch_name = $1;
					$EPG_found++;
					$array_cnt++;
				} else {
					Log3 $name, 5, "$name: nonBlock_loadEPG_v2             -> not $1 found";
				}
			}

			if($_ =~ /:\s(.*)<\/title>/ && $EPG_found != 0) {
				Log3 $name, 4, "$name: nonBlock_loadEPG_v2 channel     -> ".$Ch_name;
				Log3 $name, 4, "$name: nonBlock_loadEPG_v2 title       -> ".$1 ;

				$hash->{helper}{HTML}{$Ch_name}{EPG}[0]{title} = $1;

				### need check
				if ($Ch_select && $Ch_sort && (grep /$Ch_name/, $Ch_select)) {
					foreach my $i (0 .. $#Ch_select_array) {
						if ($Ch_select_array[$i] eq $Ch_name) {
							my $value_new = EPG_Temp_ChSortNumbre;
							$value_new = $Ch_sort_array[$i] if ($Ch_sort_array[$i] != 0);
							$hash->{helper}{HTML}{$Ch_select_array[$i]}{Ch_sort} = $value_new;
							Log3 $name, 4, "$name: nonBlock_loadEPG_v2 ch numbre   -> set to ".$value_new;
						}
					}
				} else {
					$hash->{helper}{HTML}{$Ch_name}{Ch_sort} = EPG_Temp_ChSortNumbre;
				}
				### need check attribut
				$hash->{helper}{HTML}{$Ch_name}{Ch_name} = $Ch_name;
			}

			if($_ =~ /<!\[CDATA\[(.*)?((.*)?\d{2}\.\d{2}\.\d{4}\s(\d{2}:\d{2})\s+-\s+(\d{2}:\d{2}))(<br>)?((.*)((\n.*)?)+)]]/ && $EPG_found != 0) {
				Log3 $name, 4, "$name: nonBlock_loadEPG_v2 time        -> ".$2;    	 # 17.01.2020 20:15 - 21:15

				($start,$end) = EPG_StartEnd_toISO_v2($2,$2);
				Log3 $name, 4, "$name: nonBlock_loadEPG_v2 start       -> ".$4;			 # 20:15
				Log3 $name, 4, "$name: nonBlock_loadEPG_v2 start mod   -> ".$start;  # 2020-01-17 20:15:00
				Log3 $name, 4, "$name: nonBlock_loadEPG_v2 end         -> ".$5;
				Log3 $name, 4, "$name: nonBlock_loadEPG_v2 end mod     -> ".$end;

				$desc = $7;
				$desc = encode_utf8($desc);
				Log3 $name, 4, "$name: nonBlock_loadEPG_v2 description -> ".$desc;
				Log3 $name, 4, "#################################################";

				#my $mod_cnt;
				#($title, $desc, $mod_cnt) = EPG_SyntaxCheck_for_JSON_v2($hash, $title, $desc);

				$hash->{helper}{HTML}{$Ch_name}{EPG}[0]{start} = $start;
				$hash->{helper}{HTML}{$Ch_name}{EPG}[0]{end} = $end;
				$hash->{helper}{HTML}{$Ch_name}{EPG}[0]{desc} = $desc;
			}
		}
		$EPG_info = $EPG_tt->{"loadEPG_msg1"} if ($array_cnt != -1);
		$EPG_info = $EPG_tt->{"loadEPG_msg2"} if ($array_cnt == -1);
	} else {
		$EPG_info = $EPG_tt->{"loadEPG_msg3"};
		Log3 $name, 3, "$name: nonBlock_loadEPG_v2 | error, file $EPG_file_name no found at ./opt/fhem/FHEM/EPG";
	}

	my $json_HTML = JSON->new->utf8(0)->encode($hash->{helper}{HTML});

	$return = $name."|".$EPG_file_name."|".$EPG_info."|".$cmd."|".$json_HTML;
	return $return;
}

#####################
sub EPG_nonBlock_loadEPG_v2Done($) {
	my ($string) = @_;
	my ($name, $EPG_file_name, $EPG_info, $cmd, $json_HTML) = split("\\|", $string);
  my $hash = $defs{$name};
	my $Ch_Info_to_Reading = AttrVal($name, "Ch_Info_to_Reading", "no");
	my $Ch_select = AttrVal($name, "Ch_select", undef);
	my @Ch_select_array = split(",",$Ch_select) if ($Ch_select);
	my $room = AttrVal($name, "room", "");
	my $FW_wname = !$FW_wname ? "WEB" : $FW_wname;

	Log3 $name, 4, "$name: nonBlock_loadEPG_v2Done running, $cmd from file $EPG_file_name";
  Log3 $name, 5, "$name: nonBlock_loadEPG_v2Done string=$string";
	delete($hash->{helper}{RUNNING_PID});

	$json_HTML = eval {encode_utf8( $json_HTML )};
	my $HTML = decode_json($json_HTML);

	if ($Ch_Info_to_Reading eq "yes") {
		## delete old Readings ##
		foreach my $reading (keys %{$hash->{READINGS}}) {
			if ($reading =~ /^x_.*/ && (not grep /^$reading$/, @Ch_select_array)) {
				Log3 $name, 5, "$name: nonBlock_loadEPG_v2Done delete reading $reading";
				readingsDelete($hash,$reading);
			}
		}

		if ($cmd =~ /loadEPG_(Prime|now)/) {
			## create Readings ##
			readingsBeginUpdate($hash);

			foreach my $ch (sort keys %{$HTML}) {
				## Kanäle ##
				Log3 $name, 4, "#################################################";
				Log3 $name, 4, "$name: nonBlock_loadEPG_v2Done ch          -> $ch";
				# start end title
				for (my $i=0;$i<@{$HTML->{$ch}{EPG}};$i++){
					# Log3 $name, 4, "$name: nonBlock_loadEPG_v2Done start       -> ".$HTML->{$ch}{EPG}[$i]{start};
					# Log3 $name, 4, "$name: nonBlock_loadEPG_v2Done end         -> ".$HTML->{$ch}{EPG}[$i]{end};
					Log3 $name, 4, "$name: nonBlock_loadEPG_v2Done title       -> ".$HTML->{$ch}{EPG}[$i]{title};

					readingsBulkUpdate($hash, "x_".$ch, $HTML->{$ch}{EPG}[$i]{title});
				}
			}
			readingsEndUpdate($hash, 1);
		}
	}

	$hash->{helper}{last_cmd} = $cmd;
	$hash->{helper}{HTML} = $HTML;

	FW_directNotify("FILTER=(room=$room|$name)", "#FHEMWEB:$FW_wname", "location.reload('true')", "");		# reload Webseite
	InternalTimer(gettimeofday()+EPG_InternalTimer_DELAY, "EPG_readingsSingleUpdate_later", "$name,$EPG_info,$cmd");
}

#####################
sub EPG_nonBlock_abortFn($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};
	delete($hash->{helper}{RUNNING_PID});

  Log3 $name, 4, "$name: nonBlock_abortFn running";
	readingsSingleUpdate($hash, "state", $EPG_tt->{"nonBlock_abortFn"},1);
}

##################### (name,one reading,or more readings with "," cut)
sub EPG_readingsSingleUpdate_later {
	my ($param) = @_;
	my @parameter = split(",", $param);
	my $hash = $defs{$parameter[0]};

  Log3 $parameter[0], 4, "$parameter[0]: readingsSingleUpdate_later running";

	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "state", $parameter[1]) if ($parameter[1]);
	readingsBulkUpdate($hash, "EPG_file_last_timestamp", $hash->{helper}{EPG_file_last_timestamp}) if ($hash->{helper}{EPG_file_last_timestamp});
	readingsBulkUpdate($hash, "EPG_last_loaded", $parameter[2]) if ($parameter[2]);
	readingsEndUpdate($hash, 1);
}

#####################
sub EPG_readingsDeleteChannel($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};

	foreach my $reading (keys %{$hash->{READINGS}}) {
		if ($reading =~ /^x_.*/) {
			Log3 $name, 5, "$name: readingsDeleteChannel delete $reading";
			readingsDelete($hash,$reading);		
		}
	}
}

#####################
sub EPG_Reset_HELPER($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};
	Log3 $name, 5, "$name: Reset_HELPER is running";

	foreach my $value (qw(Channels_available EPG_file_last_timestamp HTML HTML_data_counter Programm last_cmd)) {
		delete $hash->{helper}{$value} if(defined($hash->{helper}{$value}));
	}
}

#####################
sub EPG_SyntaxCheck_for_JSON_v1($$$$) {
	my ($hash, $title, $subtitle, $desc) = @_;
	my $name = $hash->{NAME};
	my @values;
	my $error_cnt = 0;
	my $mod_cnt = 0;
	
	## http://jsoneditoronline.org/ ##
	Log3 $name, 5, "$name: SyntaxCheck_for_JSON_v1 is running";

	$subtitle = "-" if ($subtitle eq "");
	$desc = "-" if ($desc eq "");

	## arrray need always uses the same number
	push (@values,$title);
	push (@values,$subtitle);
	push (@values,$desc);

	for(my $i=0;$i<=$#values;$i++) {
		if ($values[$i]) {
			if ($values[$i] =~ /\s\\\s/) {
				$error_cnt++;
				if ($error_cnt != 0) {
					Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 found wrong syntax ".'-> \\ <-';
					Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 orginal: ".$values[$i];
				}
				$values[$i] =~ s/\s\\\s/ /g;
				$mod_cnt++;
				Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 modded: ".$values[$i];
			}
			
			if ($values[$i] =~ /\\\s/) {
				$error_cnt++;
				if ($error_cnt != 0) {
					Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 found wrong syntax ".'->\ <-';
					Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 orginal: ".$values[$i];
				}
				$values[$i] =~ s/\\\s/\\\\ /g;
				$mod_cnt++;
				Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 modded: ".$values[$i];
			}
			
			if ($values[$i] =~ /\\"/) {
				$error_cnt++;
				if ($error_cnt != 0) {
					Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 found wrong syntax ".'->\\"<-';
					Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 orginal: ".$values[$i];
				}
				$values[$i] =~ s/\\"//g;
				$mod_cnt++;
				Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 modded: ".$values[$i];
			}
			
			if ($values[$i] =~ /\|/) {
				$error_cnt++;
				if ($error_cnt != 0) {
					Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 found wrong syntax ".'->|<-';
					Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 orginal: ".$values[$i];
				}
				$values[$i] =~ s/\|/,/g;
				$mod_cnt++;
				Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 modded: ".$values[$i];
			}
			
			if ($values[$i] =~ /'/) { ## need for Java !!!
				$error_cnt++;
				if ($error_cnt != 0) {
					Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 found wrong syntax ".'->\'<-';
					Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 orginal: ".$values[$i];
				}
				$values[$i] =~ s/'//g;
				$mod_cnt++;
				Log3 $name, 4, "$name: SyntaxCheck_for_JSON_v1 modded: ".$values[$i];
			}
		}

		$title = $values[$i] if($i == 0 && $error_cnt != 0);
		$subtitle = $values[$i] if($i == 1 && $error_cnt != 0);
		$desc = $values[$i] if($i == 2 && $error_cnt != 0);
		$error_cnt = 0;
	}

	$subtitle = "" if ($subtitle eq "-");
	$desc = "" if ($desc eq "-");

	return ($title, $subtitle, $desc, $mod_cnt);
}

#####################
sub EPG_SyntaxCheck_for_JSON_v2($$$) {
	my ($hash, $title, $desc) = @_;
	my $name = $hash->{NAME};
	my @values;
	my $error_cnt = 0;
	my $mod_cnt = 0;

	## http://jsoneditoronline.org/ ##
	Log3 $name, 5, "$name: SyntaxCheck_for_JSON_v2 is running";

	push (@values,$title);
	push (@values,$desc) if $desc;

	for(my $i=0;$i<=$#values;$i++) {
		if ($values[$i]) {
			if ($values[$i] =~ /\s\\\s/) {
				$error_cnt++;
				if ($error_cnt != 0) {
					Log3 $name, 3, "$name: SyntaxCheck_for_JSON_v2 found wrong syntax ".'-> \ <-';
					Log3 $name, 3, "$name: SyntaxCheck_for_JSON_v2 orginal: ".$values[$i];
				}
				$values[$i] =~ s/\s\\\s/ /g;
				$mod_cnt++;
				Log3 $name, 3, "$name: SyntaxCheck_for_JSON_v2 modded: ".$values[$i];
			}
			if ($values[$i] =~ /\\"/) {
				$error_cnt++;
				if ($error_cnt != 0) {
					Log3 $name, 3, "$name: SyntaxCheck_for_JSON_v2 found wrong syntax ".'->\\"<-';
					Log3 $name, 3, "$name: SyntaxCheck_for_JSON_v2 orginal: ".$values[$i];
				}
				$values[$i] =~ s/\\"//g;
				$mod_cnt++;
				Log3 $name, 3, "$name: SyntaxCheck_for_JSON_v2 modded: ".$values[$i];
			}
		}

		$title = $values[$i] if($i == 0 && $error_cnt != 0);
		$desc = $values[$i] if($i == 2 && $error_cnt != 0);
		$error_cnt = 0;
	}

	return ($title, $desc, $mod_cnt);
}

##################### ( valid Format´s for Date.parse() )
# 20200116101500 +0100 to 2020-01-16T10:15:00
# 20200116101500 +0100 to 2020-01-16 10:15:00
sub EPG_Time_toISO_v1($) {
	my($time) = @_;

	$time = substr($time,0,4)."-".substr($time,4,2)."-".substr($time,6,2)." ".substr($time,8,2).":".substr($time,10,2).":".substr($time,12,2);	
	return ($time);
}

##################### ( valid Format´s for Date.parse() )
# 17.01.2020 20:15 - 21:15 to 2020-01-17T20:15:00
# 17.01.2020 20:15 - 21:15 to 2020-01-17 20:15:00
sub EPG_StartEnd_toISO_v2($$) {
	my($start, $end) = @_;

	$start = substr($start,6,4)."-".substr($start,3,2)."-".substr($start,0,2)." ".substr($start,11,2).":".substr($start,14,2).":00";
	$end = substr($end,6,4)."-".substr($end,3,2)."-".substr($end,0,2)." ".substr($end,19,2).":".substr($end,22,2).":00";
	return ($start, $end);
}

#####################

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
<u>The module has dependencies:</u><br>
<ul>
<li>Encode (encode encode_utf8 decode_utf8)</li>
<li>JSON (encode decode_json)</li>
<li>XML::Simple</li>
<li>gzip</li>
<li>xz (xz-utils)</li>
</ul><br>
<i>Depending on the source and host country, the information can be slightly differentiated.<br> Each variant has its own read-in routine. When new sources become known, the module can be extended at any time.</i>
<br><br>
You have to choose a source and only then can the data of the TV Guide be displayed.<br>
The specifications for the attribute Variant | DownloadFile and DownloadURL are mandatory.
<br><br>
<ul>
	<u>Currently the following file extensions are supported</u><br>
	<li>.gz</li>
	<li>.xml</li>
	<li>.xml.gz</li>
	<li>.xz</li>
	<br>
	<u>Currently the following services are supported:</u>
	<li>Rytec (Rytec EPG Downloader)<br><br>
			well-known sources:<br>
			<ul>
				<li>http://91.121.106.172/~rytecepg/epg_data/rytecDE_Basic.xz <small>&nbsp;&nbsp;(x)</small></li>
				<li>http://91.121.106.172/~rytecepg/epg_data/rytecDE_Common.xz <small>&nbsp;&nbsp;(x)</small></li>
				<li>http://91.121.106.172/~rytecepg/epg_data/rytecDE_SportMovies.xz <small>&nbsp;&nbsp;(x)</small></li>
				<li>http://epg.energyiptv.com/epg/epg.xml.gz <small>&nbsp;&nbsp;(&#10003; slowly due to dataset)</small></li>
				<li>http://www.vuplus-community.net/rytec/rytecDE_Basic.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li>http://www.vuplus-community.net/rytec/rytecDE_Common.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li>http://www.vuplus-community.net/rytec/rytecDE_SportMovies.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li>http://www.xmltvepg.nl/rytecDE_Basic.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li>http://www.xmltvepg.nl/rytecDE_Common.xz <small>&nbsp;&nbsp;(&#10003;)</small></li>
				<li><a href="http://rytecepg.epgspot.com/epg_data/" target=”_blank”>http://rytecepg.epgspot.com/epg_data/</a> <small>&nbsp;&nbsp;(&#10003; - Auswahl nach L&auml;ndern)</small></li>
				<li><a href="https://rytec.ricx.nl/epg_data/" target=”_blank”>https://rytec.ricx.nl/epg_data/</a> <small>&nbsp;&nbsp;(&#10003; - Auswahl nach L&auml;ndern)</small></li>
			</ul><br>
	</li>
	<li> IPTV_XML (<a href="https://iptv.community/threads/epg.5423" target="_blank">IPTV.community</a>) </li>
	<li> teXXas.de - RSS (<a href="http://www.texxas.de/rss/" target="_blank">TV-Programm RSS Feed</a>) </li>
	<li> xmltv.se (<a href="https://xmltv.se" target="_blank">Provides XMLTV schedules for Europe</a>) </li>
	
</ul>
<br><br>

<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; EPG</code></ul>
<br><br>

<b>Get</b><br>
	<ul>
		<a name="available_channels"></a>
		<li>available_channels: retrieves all available channels</li><a name=""></a>
		<a name="jsonEPG"></a>
		<li>jsonEPG: outputs the loaded information in JSON format</li><a name=""></a>
		<a name="loadEPG_now"></a>
		<li>loadEPG_now: let the EPG data of the selected channels at the present time</li><a name=""></a>
		<a name="loadEPG_FavDesc"></a>
		<li>loadEPG_FavDesc: Loads the EPG data of the defined title of the attribute <code>FavDesc</code></li><a name=""></a>
		<a name="loadEPG_FavTitle"></a>
		<li>loadEPG_FavTitle: Loads the EPG data of the defined title of the attribute <code>FavTitle</code></li><a name=""></a>
		<a name="loadEPG_Prime"></a>
		<li>loadEPG_Prime: let the EPG data of the selected channels be at PrimeTime 20:15</li><a name=""></a>
		<a name="loadEPG_time"></a>
		<li>loadEPG_time: let the EPG data of the selected channels be at input time (example: <code> get EPG loadEPG_time 20200210_1745</code>)</li><a name=""></a>
		<a name="loadEPG_today"></a>
		<li>loadEPG_today: let the EPG data of the selected channels be from the current day</li><a name=""></a>
		<a name="loadFile"></a>
		<li>loadFile: load the file with the information</li><a name=""></a>
	</ul>
<br><br>

<b>Attribute</b><br>
	<ul><li><a href="#disable">disable</a></li></ul><br>
	<ul><li><a name="Ch_commands">Ch_commands</a><br>
	This allows commands to be assigned to the transmitters, which are executed when the transmitter is clicked.<br>
	The transmitter is shown as a link in the table. Important, take over the channel name correctly!<br><br>
	<u>Example code to assign a FHEM command to 2 transmitters:</u><br>
	<code>{<br>
	"Das Erste" => "set Fernsehr_LG channel 1",<br>
	"ZDF" => "set Lampe off"<br>
	}</code><br></a></ul><br>
	<ul><li><a name="Ch_select">Ch_select</a><br>
	This attribute will be filled automatically after entering the control panel "<code>list of all available channels</code>" and defined the desired channels.<br>
	<i>Normally you do not have to edit this attribute manually.</i></li><a name=" "></a></ul><br>
	<ul><li><a name="Ch_sort">Ch_sort</a><br>
	This attribute will be filled automatically after entering the control panel "<code>list of all available channels</code>" and defined the desired new channelnumbre.<br>
	<i>Normally you do not have to edit this attribute manually. Once you clear this attribute, there is no manual sort!</i></li><a name=" "></a></ul><br>
	<ul><li><a name="Ch_Info_to_Reading">Ch_Info_to_Reading</a><br>
	You can write the data in readings (yes | no = default)</a></ul><br>
	<ul><li><a name="DownloadFile">DownloadFile</a><br>
	File name of the desired file containing the information.</li><a name=" "></a></ul><br>
	<ul><li><a name="DownloadURL">DownloadURL</a><br>
	Website URL where the desired file is stored.</li><a name=" "></a></ul><br>
	<ul><li><a name="EPG_auto_download">EPG_auto_download</a><br>
	This enables the automatic download of the EPG file to be activated.<br>As soon as absolutely no EPG information is available, a new download is initiated. (yes | no = default)</a></ul><br>
	<ul><li><a name="EPG_auto_update">EPG_auto_update</a><br>
	This enables the automatic update of the view data in the front end. The setting is effective for a FHEM restart, where the data is loaded immediately or when you click on the room view.
	The attribute has no influence on the detailed view. (yes | no = default)</a></ul><br>
	<ul><li><a name="FavDesc">FavDesc</a><br>
	Names of programs which are searched for separately. (values ​​must be separated by a semicolon)</a></ul><br>
	<ul><li><a name="FavTitle">FavTitle</a><br>
	Names of programs which are searched for separately. (values ​​must be separated by a semicolon)</a></ul><br>
	<ul><li><a name="HTTP_TimeOut">HTTP_TimeOut</a><br>
	Maximum time in seconds for the download. (default 10 | maximum 90)</li><a name=" "></a></ul><br>
	<ul><li><a name="Table">Table</a><br>
	Displays the EPG data in a predefined table. (on = default | off) </li><a name=" "></a></ul><br>
	<ul><li><a name="Table_view_Subtitle">Table_view_Subtitle</a><br>
	Displays additional information of the shipment as far as available.</li><a name=" "></a></ul><br>
	<ul><li><a name="Variant">Variant</a><br>
	Processing variant according to which method the information is processed or read.</li><a name=" "></a></ul>

=end html


=begin html_DE

<a name="EPG"></a>
<h3>EPG Modul</h3>
<ul>
Das EPG Modul holt die TV - Sendungsinformationen aus verschiedenen Quellen.<br>
Es handelt sich hiermit um einen Modul welches die Daten f&uuml;r einen elektronischen Programmf&uuml;hrer abruft und sofort darstellt. (Bsp: Alternative f&uuml;r HTTPMOD + Readingsgroup & weitere)<br><br>
<u>Das Modul besitzt Abh&auml;ngigkeiten:</u><br>
<ul>
<li>Encode (encode encode_utf8 decode_utf8)</li>
<li>JSON (encode decode_json)</li>
<li>XML::Simple</li>
<li>gzip</li>
<li>xz (xz-utils)</li>
</ul><br>

<i>Je nach Quelle und Aufnahmeland k&ouml;nnen die Informationen bei Ihnen geringf&uuml;gig abweichen.<br> Jede Variante besitzt ihre eigene Einleseroutine. Beim bekanntwerden neuer Quellen kann das Modul jederzeit erweitert werden.</i>
<br><br>
Sie m&uuml;ssen sich f&uuml;r eine Quelle entscheiden und erst danach k&ouml;nnen Daten des TV-Guides dargestellt werden.<br>
Die Angaben f&uuml;r die Attribut Variante | DownloadFile und DownloadURL sind zwingend notwendig.
<br><br>
<ul>
	<u>Derzeit werden folgende Dateiendungen unterst&uuml;tzt:</u><br>
	<li>.gz</li>
	<li>.xml</li>
	<li>.xml.gz</li>
	<li>.xz</li>
	<br>

	<u>Derzeit werden folgende Dienste unterst&uuml;tzt:</u>
	<li>Rytec (Rytec EPG Downloader)<br><br>
			bekannte Quellen:<br>
			<ul>
				<li>http://91.121.106.172/~rytecepg/epg_data/rytecDE_Basic.xz <small>&nbsp;&nbsp;(x)</small></li>
				<li>http://91.121.106.172/~rytecepg/epg_data/rytecDE_Common.xz <small>&nbsp;&nbsp;(x)</small></li>
				<li>http://91.121.106.172/~rytecepg/epg_data/rytecDE_SportMovies.xz <small>&nbsp;&nbsp;(x)</small></li>
				<li>http://epg.energyiptv.com/epg/epg.xml.gz <small>&nbsp;&nbsp;(&#10003; langsam aufgrund Datenmenge)</small></li>
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
	<li> IPTV_XML (<a href="https://iptv.community/threads/epg.5423" target="_blank">IPTV.community</a>) </li>
	<li> teXXas (<a href="http://www.texxas.de/rss/" target="_blank">teXXas.de - TV-Programm RSS Feed</a>) </li>
	<li> xmltv.se (<a href="https://xmltv.se" target="_blank">Provides XMLTV schedules for Europe</a>) </li>
	
</ul>
<br><br>

<b>Define</b><br>
	<ul><code>define &lt;NAME&gt; EPG</code></ul>
<br><br>

<b>Get</b><br>
	<ul>
		<a name="available_channels"></a>
		<li>available_channels: ruft alle verf&uuml;gbaren Kan&auml;le ab</li><a name=""></a>
		<a name="jsonEPG"></a>
		<li>jsonEPG: gibt die geladen Informationen im JSON Format zurück</li><a name=""></a>
		<a name="loadEPG_now"></a>
		<li>loadEPG_now: l&auml;dt die EPG-Daten der ausgew&auml;hlten Kan&auml;le vom jetzigen Zeitpunkt</li><a name=""></a>
		<a name="loadEPG_FavDesc"></a>
		<li>loadEPG_FavDesc: l&auml;dt die EPG-Daten der definierten Beschreibung des Attributes <code>FavDesc</code></li><a name=""></a>
		<a name="loadEPG_FavTitle"></a>
		<li>loadEPG_FavTitle: l&auml;dt die EPG-Daten der definierten Titel des Attributes <code>FavTitle</code></li><a name=""></a>
		<a name="loadEPG_Prime"></a>
		<li>loadEPG_Prime: l&auml;dt die EPG-Daten der ausgew&auml;hlten Kan&auml;le von der PrimeTime 20:15Uhr</li><a name=""></a>
		<a name="loadEPG_time"></a>
		<li>loadEPG_time: l&auml;dt die EPG-Daten der ausgew&auml;hlten Kan&auml;le zum angegebenen Zeitpunkt (Bsp: <code> get EPG loadEPG_time 20200210_1745</code>)</li><a name=""></a>
		<a name="loadEPG_today"></a>
		<li>loadEPG_today: l&auml;dt die EPG-Daten der ausgew&auml;hlten Kan&auml;le vom aktuellen Tag</li><a name=""></a>
		<a name="loadFile"></a>
		<li>loadFile: l&auml;dt die Datei mit den Informationen herunter</li><a name=""></a>
	</ul>
<br><br>

<b>Attribute</b><br>
	<ul><li><a href="#disable">disable</a></li></ul><br>
	<ul><li><a name="Ch_commands">Ch_commands</a><br>
	Hiermit kann den Sendern Kommandos zuweisen, welche ausgef&uuml;hrt werden beim Klick auf den Sender.<br>
	Die Darstellung des Senders erfolgt als Link in der Tabelle. Wichtig, Sendernamen richtig &uuml;bernehmen!<br><br>
	<u>Beispielcode um 2 Sendern einen FHEM Befehl zuzuweisen:</u><br>
	<code>{<br>
	"Das Erste" => "set Fernsehr_LG channel 1",<br>
	"ZDF" => "set Lampe off"<br>
	}</code><br></a></ul><br>
	<ul><li><a name="Ch_select">Ch_select</a><br>
	Dieses Attribut wird automatisch gef&uuml;llt nachdem man im Control panel mit "<code>list of all available channels</code>" die gew&uuml;nschten Kan&auml;le definierte.<br>
	<i>Im Normalfall muss man dieses Attribut nicht manuel bearbeiten.</i></li><a name=" "></a></ul><br>
	<ul><li><a name="Ch_sort">Ch_sort</a><br>
	Dieses Attribut wird automatisch gef&uuml;llt nachdem man im Control panel mit "<code>list of all available channels</code>" die gew&uuml;nschte neue Kanalnummer definierte.<br>
	<i>Im Normalfall muss man dieses Attribut nicht manuel bearbeiten. Sobald man dieses Attribut l&ouml;scht, ist keine manuelle Sortierung vorhanden!</i></li><a name=" "></a></ul><br>
	<ul><li><a name="Ch_Info_to_Reading">Ch_Info_to_Reading</a><br>
	Hiermit kann man die Daten in Readings schreiben lassen (yes | no = default)</a></ul><br>
	<ul><li><a name="DownloadFile">DownloadFile</a><br>
	Dateiname von der gew&uuml;nschten Datei welche die Informationen enth&auml;lt.</li><a name=" "></a></ul><br>
	<ul><li><a name="DownloadURL">DownloadURL</a><br>
	Webseiten URL wo die gew&uuml;nschten Datei hinterlegt ist.</li><a name=" "></a></ul><br>
	<ul><li><a name="EPG_auto_download">EPG_auto_download</a><br>
	Hiermit kann der automatische Download der EPG Datei aktiviert werden.<br>Sobald absolut keine EPG Informationen zur Verfügung stehen, wird ein neuer Download angestoßen. (yes | no = default)</a></ul><br>
	<ul><li><a name="EPG_auto_update">EPG_auto_update</a><br>
	Hiermit kann die automatische Aktualisierung der Ansichtsdaten im FrontEnd aktiviert werden. Die Einstellung wirkt bei einem FHEM Restart, wo sofort die Daten geladen werden oder
	bei einem Klick auf die Raumansicht. Auf die Detailansicht hat das Attribut keinen Einfluss. (yes | no = default)</a></ul><br>
	<ul><li><a name="FavDesc">FavDesc</a><br>
	Namen von Beschreibungen einer Sendung welche gezielt gesucht werden k&ouml;nnen. (mehrere Werte m&uuml;ssen durch ein Semikolon getrennt werden)</a></ul><br>
	<ul><li><a name="FavTitle">FavTitle</a><br>
	Namen vom Titel einer Sendung welche gezielt gesucht werden k&ouml;nnen. (mehrere Werte m&uuml;ssen durch ein Semikolon getrennt werden)</a></ul><br>
	<ul><li><a name="HTTP_TimeOut">HTTP_TimeOut</a><br>
	Maximale Zeit in Sekunden für den Download. (Standard 10 | maximal 90)</li><a name=" "></a></ul><br>
	<ul><li><a name="Table">Table</a><br>
	Zeigt die EPG-Daten in einer vordefinierten Tabelle an. (on = default | off) </li><a name=" "></a></ul><br>
	<ul><li><a name="Table_view_Subtitle">Table_view_Subtitle</a><br>
	Zeigt Zusatzinformation der Sendung an soweit verf&uuml;gbar.</li><a name=" "></a></ul><br>
	<ul><li><a name="Variant">Variant</a><br>
	Verarbeitungsvariante, nach welchem Verfahren die Informationen verarbeitet oder gelesen werden.</li><a name=" "></a></ul>

=end html_DE

# Ende der Commandref
=cut