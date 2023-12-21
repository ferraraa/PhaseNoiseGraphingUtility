#!/hfs/d1/roq100/perl524i/bin/perl -w
#
#  printenv -- demo CGI program which prints its environment
#              and describes the perl installation.
#
#

use strict;
use lib '/hfs/d1/roq200/apache/cgi-bin/anferrar/';
# use lib '/users/anferrar/perl5/lib/perl5/';
use Config qw(myconfig config_sh config_vars);
use CGI;
use CGI::HTML::Functions;
use Data::Dumper;
use Cwd;
use filesystem;
use CGI::Easy::SendFile;

#use phasenoiseoptions;
use webpage;
use rscriptgen;
use File::Temp;
use File::Basename;
use CGI::HTML::Functions;

#use Text::FillIn;

$|++;
## Create CGI Component
my $cgi = new CGI;

my $phasenoisedataloc = getcwd . '/phasenoisedatadir/';
my $formpath          = '/cgi-bin/anferrar/phasenoisegraphutility.pl';
my $htmldir           = '/users/anferrar/public_html/';
## Prepare Drop Down Menu Variables and Parameters
my $WebJustStarted        = 0;
my $comparisonoptionname  = 'CaseSelect';
my $phasenoiseoptionname  = 'SubCaseSelect';
my $dutoptionname         = "DUTSelect";
my $inputfreqoptionname   = "InputFreqSelect";
my $inputpoweroptionname  = "InputPowerSelect";
my $outputfreqoptionname  = "OutputFreqSelect";
my $outputpoweroptionname = "OutputPowerSelect";
my $smoothingoptionname   = 'Smoothing';
my $resetoptionname       = "Reset";
my $reffreqoptionname     = "ReferenceFreqSelect";
my $refoptionname         = "ReferenceSelect";
my $randsdutoptionname    = "RandSDUTSelect";
my $randsfreqoptionname   = "RandSFreqSelect";
my $keysdutoptionname     = "KeysDUTSelect";
my $keysfreqoptionname    = "KeysFreqSelect";


my $xmindefault  = 1;
my $xmaxdefault  = 160e6;
my $ymindefault  = -190;
my $ymaxdefault  = 0;
my $titledefault = 'Phase Noise';

#######################################################################################
##################### Comparison Options
#######################################################################################
my @beginningcomparisonoptions = ( "---Select an Option---", 'DDS Residual Phase Noise Comparison', 'Frequency Divider Residual Phase Noise Comparison', 'Amplifier Residual Phase Noise Comparison', 'Reference Phase Noise Comparison', 'Competitive Analysis', 'Source' );
#######################################################################################
##################### Drop Down Menu Options
#######################################################################################
my @phasenoiseoptions_div = (
							  "---Select an Option---",
							  "One Frequency Divider at One Input Frequency, Different Output Frequencies",
							  "One Frequency Divider at One Output Frequency, Different Input Frequencies",
							  "Multiple Frequency Dividers at One Output Frequency, Multiple Input Frequencies"
);
my @phasenoiseoptions_dds = (
							  "---Select an Option---",
							  "One DDS at One Clock Rate, Different Output Frequencies",
							  "One DDS at One Output Frequency, Different Clock Rates",
							  "Multiple DDSs at One Clock Rate, One Output Frequency",
							  'Different Reference Absolutes with a DUT Residual',
							  'Different DUT Residuals with a Scaled Reference Absolute'
);
my @phasenoiseoptions_amp = ( "---Select an Option---", "One Amplifier at One Input Frequency and Multiple Input Powers", "Multiple Amplifiers at One Input Frequency and Multiple Input Powers" );
#my @phasenoiseoptions_src = ( '---Select an Option---', 'MCS1.5 Absolute and Residual Phase Noise Measurements', 'MCS1.5 vs DDS Residual', 'MCS1.5 vs R&S SMA100B' );
my @phasenoiseoptions_ref  = ( '---Select an Option---', 'One Reference Absolute Phase Noise', 'Multiple References, Absolute Phase Noise', 'Different Reference Absolutes with a DUT Residual', 'Different DUT Residuals with a Scaled Reference Absolute' );
my @phasenoiseoptions_comp = ( '---Select an Option---', 'R&S vs Keysight','R&S vs DDS Residual' );
my @phasenoiseoptions_src = ( '---Select an Option---', 'Keysight');
#######################################################################################
##################### Start the HTML WebPage
#######################################################################################
print "Content-type: text/html\n\n";
print $cgi ->start_html( 'Phase Noise Graph Builder' );
print $cgi->a( { href => ( 'http://www.srs.is.keysight.com/~anferrar' ) }, "Return Home" );
print "<H2>Andy\'s Phase Noise Graphing Utility</H2>\n";
## Check to see what options have been selected

my @resetoption = $cgi->param( $resetoptionname );
my @resetboxch  = $cgi->param( 'Check This If You Want to Reset the Form, Good When Funky Stuff Happens' );

if ( @resetoption && @resetboxch ) {
	$WebJustStarted = 1;
	$cgi->delete_all();

}

my @graphoption = $cgi->param( $comparisonoptionname );
if ( not @graphoption ) {
	$WebJustStarted = 1;

}

my @dutoption       = $cgi->param( $dutoptionname );
my @inFoption       = $cgi->param( $inputfreqoptionname );
my @inPoption       = $cgi->param( $inputpoweroptionname );
my @outFoption      = $cgi->param( $outputfreqoptionname );
my @outPoption      = $cgi->param( $outputpoweroptionname );
my @refFoption      = $cgi->param( $reffreqoptionname );
my @refoption       = $cgi->param( $refoptionname );
my @randsdutoption  = $cgi->param( $randsdutoptionname );
my @randsfreqoption = $cgi->param( $randsfreqoptionname );
my @keysdutoption   = $cgi->param( $keysdutoptionname );
my @keysfreqoption  = $cgi->param( $keysfreqoptionname );


#print Dumper($cgi);

## Make Reset Button
print $cgi ->start_form( -method => 'post',
						 -action => $formpath );
print $cgi ->div(
				  $cgi->submit(
								-name   => $resetoptionname,
								-id     => $resetoptionname,
								-values => 'Submit'
				  ),
				  $cgi->checkbox(
								  -name    => 'Check This If You Want to Reset the Form, Good When Funky Stuff Happens',
								  -id      => 'resetbox',
								  -value   => 'resetboxchecked',
								  -default => 'unchecked'
				  )
);
$cgi->end_form;

#############################################################################################
############################# Web Page Just Started or Was Reset
#############################################################################################
if ( $WebJustStarted ) {    # If no drop down was selected, the web page just started

# Create the Form, Upon execution it will call this webpage again and again but with new data added
	print $cgi ->start_form( -method => 'post',
							 -action => $formpath );

	## Display the Main Menu with Default Selection
	webpage::makeDropDownMenu( $cgi, $comparisonoptionname, '<br>Phase Noise Graphing Options: <br>', \@beginningcomparisonoptions );
	$cgi->end_form;
##############################################################################################
######################## # A Comparison Category Was Selected
##############################################################################################
} else {
	## Create the Form, Upon execution it will call this webpage again and again but with new data added
	print $cgi ->start_form( -method => 'post',
							 -action => $formpath );
	## Display the Main Menu with Default Selection
	webpage::makeDropDownMenu( $cgi, $comparisonoptionname, '<br>Phase Noise Graphing Options: <br>', \@beginningcomparisonoptions );

	## Display the Drop Down Menu With Sub Categories
	if ( $cgi->param( 'CaseSelect' ) eq 'DDS Residual Phase Noise Comparison' ) {
		webpage::makeDropDownMenu( $cgi, $phasenoiseoptionname, '<br>Sub-Category Graphing Options: <br>', \@phasenoiseoptions_dds );
	} elsif ( $cgi->param( 'CaseSelect' ) eq 'Frequency Divider Residual Phase Noise Comparison' ) {
		webpage::makeDropDownMenu( $cgi, $phasenoiseoptionname, '<br>Sub-Category Graphing Options: <br>', \@phasenoiseoptions_div );
	} elsif ( $cgi->param( 'CaseSelect' ) eq 'Amplifier Residual Phase Noise Comparison' ) {
		webpage::makeDropDownMenu( $cgi, $phasenoiseoptionname, '<br>Sub-Category Graphing Options: <br>', \@phasenoiseoptions_amp );
	} elsif ( $cgi->param( 'CaseSelect' ) eq 'Reference Phase Noise Comparison' ) {
		webpage::makeDropDownMenu( $cgi, $phasenoiseoptionname, '<br>Sub-Category Graphing Options: <br>', \@phasenoiseoptions_ref );
	} elsif ( $cgi->param( 'CaseSelect' ) eq 'Competitive Analysis' ) {
		webpage::makeDropDownMenu( $cgi, $phasenoiseoptionname, '<br>Sub-Category Graphing Options: <br>', \@phasenoiseoptions_comp );
	} elsif ( $cgi->param( 'CaseSelect' ) eq 'Source' ) {
		webpage::makeDropDownMenu( $cgi, $phasenoiseoptionname, '<br>Sub-Category Graphing Options: <br>', \@phasenoiseoptions_src );
	}

	##############################################################################################
	######################## SubCategories
	##############################################################################################
	my $DataFileDownload;
	if ( $cgi->param( 'SubCaseSelect' ) eq "One DDS at One Clock Rate, Different Output Frequencies" ) {
		$DataFileDownload = OneDDSOneInF_ManyOutF();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq "One DDS at One Output Frequency, Different Clock Rates" ) {    ## Create Radios of all Available Clocks
		$DataFileDownload = OneDDSOneOutF_ManyInF();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq "Multiple DDSs at One Clock Rate, One Output Frequency" ) {
		$DataFileDownload = ManyDDS_OneInF_OneOutF();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq "One Amplifier at One Input Frequency and Multiple Input Powers" ) {
		$DataFileDownload = OneAmpOneInF_ManyInP();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq "Multiple Amplifiers at One Input Frequency and Multiple Input Powers" ) {
		$DataFileDownload = ManyAmp_OneInF_ManyInP();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq "One Frequency Divider at One Input Frequency, Different Output Frequencies" ) {
		$DataFileDownload = OneDivOneInF_ManyOutF();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq "One Frequency Divider at One Output Frequency, Different Input Frequencies" ) {
		$DataFileDownload = OneDivOneOutF_ManyInF();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq "Multiple Frequency Dividers at One Output Frequency, Multiple Input Frequencies" ) {
		$DataFileDownload = ManyDiv_OneOutF_ManyInF();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq 'One Reference Absolute Phase Noise' ) {
		$DataFileDownload = OneReference();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq 'Multiple References, Absolute Phase Noise' ) {
		$DataFileDownload = ManyReferences();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq 'Different Reference Absolutes with a DUT Residual' ) {
		$DataFileDownload = DiffReferenceWithDDS();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq 'Different DUT Residuals with a Scaled Reference Absolute' ) {
		$DataFileDownload = ReferenceWithDiffDDS();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq 'R&S vs Keysight' ) {
		$DataFileDownload = RandSvsKeys_Source();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq 'R&S vs DDS Residual' ) {
		$DataFileDownload = RandSvsDDS();
	} elsif ( $cgi->param( 'SubCaseSelect' ) eq 'Keysight' ) {
		$DataFileDownload = SourceAbs();
	}

	if ( $DataFileDownload ) {
		webpage::DownloadFiles( $cgi, $DataFileDownload, $htmldir );
	}

}

#print Dumper($cgi);

print $cgi->end_form;

print $cgi->end_html();

sub OneDDSOneInF_ManyOutF {
	## Search For all Available Data in the DDS Path
	$phasenoisedataloc = $phasenoisedataloc . '/FrequencyConverters/DDS/';
	my @AllData = filesystem::hashEveryDDSTextFile( $phasenoisedataloc );
	my @MeasType;
	$MeasType[ 0 ] = 'ResidualPhaseNoise';
	my ( $ResidualData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
	my @UniqueDDSs = filesystem::searchHashArrayForUnique( $ResidualData, 'DUT' );
	@UniqueDDSs = sort @UniqueDDSs;

	## Display Radio Button With all Available DUTs
	webpage::makeButtons( $cgi, 'radio', $dutoptionname, '<br>Choose a DDS: <br>', \@UniqueDDSs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @dutoption ) {
		## Get and Display Available Clock/ Input Frequencies
		my ( $DUTOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $ResidualData, 'DUT', \@dutoption );
		my @UniqueInputFreqs = filesystem::searchHashArrayForUnique( $DUTOnlyHash, 'InputFreq' );
		@UniqueInputFreqs = sort @UniqueInputFreqs;
		webpage::makeButtons( $cgi, 'radio', $inputfreqoptionname, '<br>Choose a Clock Frequency: <br>', \@UniqueInputFreqs, 0, 1 );

		##############################################################################################
		######################## Multiple DDSs at One Clock Rate, One Output Frequency
		##############################################################################################
		if ( @inFoption ) {
			my ( $DUTAndInFHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $DUTOnlyHash, 'InputFreq', \@inFoption );
			my @UniqueOutputFreqs = filesystem::searchHashArrayForUnique( $DUTAndInFHash, 'OutputFreq' );
			@UniqueOutputFreqs = sort @UniqueOutputFreqs;
			webpage::makeButtons( $cgi, 'checkbox', $outputfreqoptionname, '<br>Choose Multiple Output Frequencies: <br>', \@UniqueOutputFreqs, 1, 1 );

			if ( @outFoption ) {
				##############################################################################################
				######################## Make the R Script!
				##############################################################################################

				## Given Chose Parameters, Get the Data Files
				my ( $TempHashes, $DataFiles ) = filesystem::searchHashArrayGivenParam( $DUTAndInFHash, 'OutputFreq', \@outFoption );
				webpage::makeGraphInputs( $cgi, $smoothingoptionname );
				my ( $RScriptID, $GraphID ) =
					rscriptgen::makeRGraphScriptBruteForce( $DataFiles, $htmldir, \@outFoption,
															$cgi->param( 'xmin' ),
															$cgi->param( 'xmax' ),
															$cgi->param( 'ymin' ),
															$cgi->param( 'ymax' ),
															$cgi->param( 'ydiv' ),
															$cgi->param( 'graphtitle' ),
															$cgi->param( 'Smooth' ) );
				system( 'chmod 777 ' . $RScriptID->filename );
				system( '/usr/bin/Rscript ' . $RScriptID->filename );
				my $TempGraph = basename( $GraphID );
				print $cgi ->img(
								  {
									-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
								  }
				);
				return $DataFiles;

			}
		}
	}


}

sub OneDDSOneOutF_ManyInF {
	## Search For all Available Data in the DDS Path
	$phasenoisedataloc = $phasenoisedataloc . '/FrequencyConverters/DDS/';
	my @AllData = filesystem::hashEveryDDSTextFile( $phasenoisedataloc );
	my @MeasType;
	$MeasType[ 0 ] = 'ResidualPhaseNoise';
	my ( $ResidualData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
	my @UniqueDDSs = filesystem::searchHashArrayForUnique( $ResidualData, 'DUT' );
	@UniqueDDSs = sort @UniqueDDSs;

	## Display Radio Button With all Available DUTs
	webpage::makeButtons( $cgi, 'radio', $dutoptionname, '<br>Choose a DDS: <br>', \@UniqueDDSs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @dutoption ) {
		## Get and Display Available Clock/ Input Frequencies
		my ( $DUTOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $ResidualData, 'DUT', \@dutoption );
		my @UniqueOutputFreqs = filesystem::searchHashArrayForUnique( $DUTOnlyHash, 'OutputFreq' );
		@UniqueOutputFreqs = sort @UniqueOutputFreqs;
		webpage::makeButtons( $cgi, 'radio', $outputfreqoptionname, '<br>Choose an Output Frequency: <br>', \@UniqueOutputFreqs, 0, 1 );

		##############################################################################################
		######################## Multiple DDSs at One Clock Rate, One Output Frequency
		##############################################################################################
		if ( @outFoption ) {
			my ( $DUTAndOutFHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $DUTOnlyHash, 'OutputFreq', \@outFoption );
			my @UniqueInputFreqs = filesystem::searchHashArrayForUnique( $DUTAndOutFHash, 'InputFreq' );
			@UniqueInputFreqs = sort @UniqueInputFreqs;
			webpage::makeButtons( $cgi, 'checkbox', $inputfreqoptionname, '<br>Choose Multiple Clock Frequencies: <br>', \@UniqueInputFreqs, 1, 1 );

			if ( @inFoption ) {
				##############################################################################################
				######################## Make the R Script!
				##############################################################################################

				## Given Chose Parameters, Get the Data Files
				my ( $TempHashes, $DataFiles ) = filesystem::searchHashArrayGivenParam( $DUTAndOutFHash, 'InputFreq', \@inFoption );
				webpage::makeGraphInputs( $cgi, $smoothingoptionname );
				my ( $RScriptID, $GraphID ) =
					rscriptgen::makeRGraphScriptBruteForce( $DataFiles, $htmldir, \@inFoption,
															$cgi->param( 'xmin' ),
															$cgi->param( 'xmax' ),
															$cgi->param( 'ymin' ),
															$cgi->param( 'ymax' ),
															$cgi->param( 'ydiv' ),
															$cgi->param( 'graphtitle' ),
															$cgi->param( 'Smooth' ) );
				system( 'chmod 777 ' . $RScriptID->filename );
				system( '/usr/bin/Rscript ' . $RScriptID->filename );
				my $TempGraph = basename( $GraphID );
				print $cgi ->img(
								  {
									-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
								  }
				);
				return $DataFiles;
			}
		}
	}


}

sub ManyDDS_OneInF_OneOutF {
	## Search For all Available Data in the DDS Path
	$phasenoisedataloc = $phasenoisedataloc . '/FrequencyConverters/DDS/';
	my @AllData = filesystem::hashEveryDDSTextFile( $phasenoisedataloc );
	my @MeasType;
	$MeasType[ 0 ] = 'ResidualPhaseNoise';
	my ( $ResidualData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
	my @UniqueInputFreqs = filesystem::searchHashArrayForUnique( $ResidualData, 'InputFreq' );
	@UniqueInputFreqs = sort @UniqueInputFreqs;

	## Display Radio Button With all Available DUTs
	webpage::makeButtons( $cgi, 'radio', $inputfreqoptionname, '<br>Choose a Clock Frequency: <br>', \@UniqueInputFreqs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @inFoption ) {
		## Get and Display Available Clock/ Input Frequencies
		my ( $InFOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $ResidualData, 'InputFreq', \@inFoption );
		my @UniqueOutputFreqs = filesystem::searchHashArrayForUnique( $InFOnlyHash, 'OutputFreq' );
		@UniqueOutputFreqs = sort @UniqueOutputFreqs;
		webpage::makeButtons( $cgi, 'radio', $outputfreqoptionname, '<br>Choose an Output Frequency <br>', \@UniqueOutputFreqs, 0, 1 );

		##############################################################################################
		######################## Multiple DDSs at One Clock Rate, One Output Frequency
		##############################################################################################
		if ( @inFoption ) {
			my ( $InFAndOutFHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $InFOnlyHash, 'OutputFreq', \@outFoption );
			my @UniqueDUTs = filesystem::searchHashArrayForUnique( $InFAndOutFHash, 'DUT' );
			@UniqueDUTs = sort @UniqueDUTs;
			webpage::makeButtons( $cgi, 'checkbox', $dutoptionname, '<br>Choose Multiple DDSs <br>', \@UniqueDUTs, 1, 1 );

			if ( @dutoption ) {
				##############################################################################################
				######################## Make the R Script!
				##############################################################################################

				## Given Chose Parameters, Get the Data Files
				my ( $TempHashes, $DataFiles ) = filesystem::searchHashArrayGivenParam( $InFAndOutFHash, 'DUT', \@dutoption );
				webpage::makeGraphInputs( $cgi, $smoothingoptionname );
				my ( $RScriptID, $GraphID ) =
					rscriptgen::makeRGraphScriptBruteForce( $DataFiles, $htmldir, \@dutoption,
															$cgi->param( 'xmin' ),
															$cgi->param( 'xmax' ),
															$cgi->param( 'ymin' ),
															$cgi->param( 'ymax' ),
															$cgi->param( 'ydiv' ),
															$cgi->param( 'graphtitle' ),
															$cgi->param( 'Smooth' ) );
				system( 'chmod 777 ' . $RScriptID->filename );
				system( '/usr/bin/Rscript ' . $RScriptID->filename );
				my $TempGraph = basename( $GraphID );
				print $cgi ->img(
								  {
									-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
								  }
				);
				return $DataFiles;
			}


		}
	}

}

sub OneDivOneInF_ManyOutF {
	## Search For all Available Data in the DDS Path
	$phasenoisedataloc = $phasenoisedataloc . '/FrequencyConverters/Dividers/';
	my @AllData = filesystem::hashEveryDivTextFile( $phasenoisedataloc );
	my @MeasType;
	$MeasType[ 0 ] = 'ResidualPhaseNoise';
	my ( $ResidualData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
	my @UniqueDUTs = filesystem::searchHashArrayForUnique( $ResidualData, 'DUT' );
	@UniqueDUTs = sort @UniqueDUTs;

	## Display Radio Button With all Available DUTs
	webpage::makeButtons( $cgi, 'radio', $dutoptionname, '<br>Choose a DDS: <br>', \@UniqueDUTs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @dutoption ) {
		## Get and Display Available Clock/ Input Frequencies
		my ( $DUTOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $ResidualData, 'DUT', \@dutoption );
		my @UniqueInputFreqs = filesystem::searchHashArrayForUnique( $DUTOnlyHash, 'InputFreq' );
		@UniqueInputFreqs = sort @UniqueInputFreqs;
		webpage::makeButtons( $cgi, 'radio', $inputfreqoptionname, '<br>Choose a Clock Frequency: <br>', \@UniqueInputFreqs, 0, 1 );

		##############################################################################################
		######################## Multiple DDSs at One Clock Rate, One Output Frequency
		##############################################################################################
		if ( @inFoption ) {
			my ( $DUTAndInFHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $DUTOnlyHash, 'InputFreq', \@inFoption );
			my @UniqueOutputFreqs = filesystem::makeLegendArray_OutputFreqInputPowerPairs( $DUTAndInFHash );
			@UniqueOutputFreqs = sort @UniqueOutputFreqs;
			webpage::makeButtons( $cgi, 'checkbox', $outputfreqoptionname, '<br>Choose Multiple Output Frequencies: <br>', \@UniqueOutputFreqs, 1, 1 );

			if ( @outFoption ) {
				##############################################################################################
				######################## Make the R Script!
				##############################################################################################
				my ( @FOutArray, @PInArray );
				for ( my $PCount = 0 ; $PCount < scalar( @outFoption ) ; $PCount++ ) {
					my @ParsedString = split( /, /, $outFoption[ $PCount ] );
					push( @FOutArray, $ParsedString[ 0 ] );
					push( @PInArray,  $ParsedString[ 1 ] );
				}
				## Given Chose Parameters, Get the Data Files
				my ( $TempHashes, $DataFiles ) = filesystem::searchHashArrayGiven2Params( $DUTAndInFHash, 'OutputFreq', \@FOutArray, 'InputPower', \@PInArray );
				webpage::makeGraphInputs( $cgi, $smoothingoptionname );
				my ( $RScriptID, $GraphID ) =
					rscriptgen::makeRGraphScriptBruteForce( $DataFiles, $htmldir, \@PInArray,
															$cgi->param( 'xmin' ),
															$cgi->param( 'xmax' ),
															$cgi->param( 'ymin' ),
															$cgi->param( 'ymax' ),
															$cgi->param( 'ydiv' ),
															$cgi->param( 'graphtitle' ),
															$cgi->param( 'Smooth' ) );
				system( 'chmod 777 ' . $RScriptID->filename );
				system( '/usr/bin/Rscript ' . $RScriptID->filename );
				my $TempGraph = basename( $GraphID );
				print $cgi ->img(
								  {
									-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
								  }
				);
				return $DataFiles;

			}
		}
	}

}

sub OneDivOneOutF_ManyInF {
	## Search For all Available Data in the DDS Path
	$phasenoisedataloc = $phasenoisedataloc . '/FrequencyConverters/Dividers/';
	my @AllData = filesystem::hashEveryDivTextFile( $phasenoisedataloc );
	my @MeasType;
	$MeasType[ 0 ] = 'ResidualPhaseNoise';
	my ( $ResidualData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
	my @UniqueDUTs = filesystem::searchHashArrayForUnique( $ResidualData, 'DUT' );
	@UniqueDUTs = sort @UniqueDUTs;

	## Display Radio Button With all Available DUTs
	webpage::makeButtons( $cgi, 'radio', $dutoptionname, '<br>Choose a DDS: <br>', \@UniqueDUTs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @dutoption ) {
		## Get and Display Available Clock/ Input Frequencies
		my ( $DUTOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $ResidualData, 'DUT', \@dutoption );
		my @UniqueOutputFreqs = filesystem::searchHashArrayForUnique( $DUTOnlyHash, 'OutputFreq' );
		@UniqueOutputFreqs = sort @UniqueOutputFreqs;
		webpage::makeButtons( $cgi, 'radio', $outputfreqoptionname, '<br>Choose an Output Frequency: <br>', \@UniqueOutputFreqs, 0, 1 );

		##############################################################################################
		######################## Multiple DDSs at One Clock Rate, One Output Frequency
		##############################################################################################
		if ( @outFoption ) {
			my ( $DUTAndOutFHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $DUTOnlyHash, 'OutputFreq', \@outFoption );
			my @UniqueInputFreqs = filesystem::makeLegendArray_InputFreqInputPowerPairs( $DUTAndOutFHash );
			@UniqueInputFreqs = sort @UniqueInputFreqs;
			webpage::makeButtons( $cgi, 'checkbox', $inputfreqoptionname, '<br>Choose Multiple Input Frequencies: <br>', \@UniqueInputFreqs, 1, 1 );

			if ( @inFoption ) {
				##############################################################################################
				######################## Make the R Script!
				##############################################################################################
				my ( @FInArray, @PInArray );
				for ( my $PCount = 0 ; $PCount < scalar( @inFoption ) ; $PCount++ ) {
					my @ParsedString = split( /, /, $inFoption[ $PCount ] );
					push( @FInArray, $ParsedString[ 0 ] );
					push( @PInArray, $ParsedString[ 1 ] );
				}
				## Given Chose Parameters, Get the Data Files
				my ( $TempHashes, $DataFiles ) = filesystem::searchHashArrayGiven2Params( $DUTAndOutFHash, 'InputFreq', \@FInArray, 'InputPower', \@PInArray );
				webpage::makeGraphInputs( $cgi, $smoothingoptionname );
				my ( $RScriptID, $GraphID ) =
					rscriptgen::makeRGraphScriptBruteForce( $DataFiles, $htmldir, \@PInArray,
															$cgi->param( 'xmin' ),
															$cgi->param( 'xmax' ),
															$cgi->param( 'ymin' ),
															$cgi->param( 'ymax' ),
															$cgi->param( 'ydiv' ),
															$cgi->param( 'graphtitle' ),
															$cgi->param( 'Smooth' ) );
				system( 'chmod 777 ' . $RScriptID->filename );
				system( '/usr/bin/Rscript ' . $RScriptID->filename );
				my $TempGraph = basename( $GraphID );
				print $cgi ->img(
								  {
									-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
								  }
				);
				return $DataFiles;

			}
		}
	}

}

sub ManyDiv_OneOutF_ManyInF {
	## Search For all Available Data in the DDS Path
	$phasenoisedataloc = $phasenoisedataloc . '/FrequencyConverters/Dividers/';
	my @AllData = filesystem::hashEveryDivTextFile( $phasenoisedataloc );
	my @MeasType;
	$MeasType[ 0 ] = 'ResidualPhaseNoise';
	my ( $ResidualData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
	my @UniqueOutputFreqs = filesystem::searchHashArrayForUnique( $ResidualData, 'OutputFreq' );
	@UniqueOutputFreqs = sort @UniqueOutputFreqs;

	## Display Radio Button With all Available DUTs
	webpage::makeButtons( $cgi, 'radio', $outputfreqoptionname, '<br>Choose an Output Frequency: <br>', \@UniqueOutputFreqs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @outFoption ) {
		## Get and Display Available Clock/ Input Frequencies
		my ( $OutFOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $ResidualData, 'OutputFreq', \@outFoption );
		my @UniqueDUTs = filesystem::searchHashArrayForUnique( $OutFOnlyHash, 'DUT' );
		@UniqueDUTs = sort @UniqueDUTs;
		webpage::makeButtons( $cgi, 'checkbox', $dutoptionname, '<br>Choose Multiple DUTs: <br>', \@UniqueDUTs, 0, 1 );

		##############################################################################################
		######################## Multiple DDSs at One Clock Rate, One Output Frequency
		##############################################################################################
		if ( @dutoption ) {
			my ( $DUTAndOutFHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $OutFOnlyHash, 'DUT', \@dutoption );
			my @UniqueInputFreqs = filesystem::makeLegendArray_DUTInputFreqInputPowerPairs( $DUTAndOutFHash );
			@UniqueInputFreqs = sort @UniqueInputFreqs;
			webpage::makeButtons( $cgi, 'checkbox', $inputfreqoptionname, '<br>Choose Multiple Input Frequencies: <br>', \@UniqueInputFreqs, 1, 1 );

			if ( @inFoption ) {
				##############################################################################################
				######################## Make the R Script!
				##############################################################################################
				my ( @DUT, @FInArray, @PInArray, @Legend );
				for ( my $PCount = 0 ; $PCount < scalar( @inFoption ) ; $PCount++ ) {
					my @ParsedString = split( /, /, $inFoption[ $PCount ] );
					push( @DUT,      $ParsedString[ 0 ] );
					push( @FInArray, $ParsedString[ 1 ] );
					push( @PInArray, $ParsedString[ 2 ] );
					push( @Legend,   $ParsedString[ 0 ] . ': ' . $ParsedString[ 1 ] . ', ' . $ParsedString[ 2 ] );
				}
				## Given Chose Parameters, Get the Data Files
				my ( $TempHashes, $DataFiles ) = filesystem::searchHashArrayGiven3Params( $DUTAndOutFHash, 'InputFreq', \@FInArray, 'InputPower', \@PInArray, 'DUT', \@DUT );
				webpage::makeGraphInputs( $cgi, $smoothingoptionname );
				my ( $RScriptID, $GraphID ) =
					rscriptgen::makeRGraphScriptBruteForce( $DataFiles, $htmldir, \@Legend,
															$cgi->param( 'xmin' ),
															$cgi->param( 'xmax' ),
															$cgi->param( 'ymin' ),
															$cgi->param( 'ymax' ),
															$cgi->param( 'ydiv' ),
															$cgi->param( 'graphtitle' ),
															$cgi->param( 'Smooth' ) );
				system( 'chmod 777 ' . $RScriptID->filename );
				system( '/usr/bin/Rscript ' . $RScriptID->filename );
				my $TempGraph = basename( $GraphID );
				print $cgi ->img(
								  {
									-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
								  }
				);
				return $DataFiles;

			}
		}
	}

}

sub OneAmpOneInF_ManyInP {
	## Search For all Available Data in the Amplifier Path
	$phasenoisedataloc = $phasenoisedataloc . '/Amplifiers/';
	my @AllData = filesystem::hashEveryAmpTextFile( $phasenoisedataloc );
	my @MeasType;
	$MeasType[ 0 ] = 'ResidualPhaseNoise';
	my ( $ResidualData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
	my @UniqueDUTs = filesystem::searchHashArrayForUnique( $ResidualData, 'DUT' );
	@UniqueDUTs = sort @UniqueDUTs;

	## Display Radio Button With all Available DUTs
	webpage::makeButtons( $cgi, 'radio', $dutoptionname, '<br>Choose an Amplifier: <br>', \@UniqueDUTs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @dutoption ) {
		## Get and Display Available Clock/ Input Frequencies
		my ( $DUTOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $ResidualData, 'DUT', \@dutoption );
		my @UniqueInputFreqs = filesystem::searchHashArrayForUnique( $DUTOnlyHash, 'InputFreq' );
		@UniqueInputFreqs = sort @UniqueInputFreqs;
		webpage::makeButtons( $cgi, 'radio', $inputfreqoptionname, '<br>Choose an Input Frequency <br>', \@UniqueInputFreqs, 0, 1 );

		##############################################################################################
		######################## Multiple DDSs at One Clock Rate, One Output Frequency
		##############################################################################################
		if ( @inFoption ) {
			my ( $DUTandInFHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $DUTOnlyHash, 'InputFreq', \@inFoption );
			my @UniqueInputPowers = filesystem::searchHashArrayForUnique( $DUTandInFHash, 'InputPower' );
			@UniqueInputPowers = sort @UniqueInputPowers;
			webpage::makeButtons( $cgi, 'checkbox', $inputpoweroptionname, '<br>Choose Multiple Input Powers <br>', \@UniqueInputPowers, 1, 1 );

			if ( @inPoption ) {
				##############################################################################################
				######################## Make the R Script!
				##############################################################################################

				## Given Chose Parameters, Get the Data Files
				my ( $TempHashes, $DataFiles ) = filesystem::searchHashArrayGivenParam( $DUTandInFHash, 'InputPower', \@inPoption );
				my @Legend = filesystem::makeLegendArray_InputOutputPowerPairs( $TempHashes );
				webpage::makeGraphInputs( $cgi, $smoothingoptionname );
				my ( $RScriptID, $GraphID ) =
					rscriptgen::makeRGraphScriptBruteForce( $DataFiles, $htmldir, \@Legend,
															$cgi->param( 'xmin' ),
															$cgi->param( 'xmax' ),
															$cgi->param( 'ymin' ),
															$cgi->param( 'ymax' ),
															$cgi->param( 'ydiv' ),
															$cgi->param( 'graphtitle' ),
															$cgi->param( 'Smooth' ) );

				system( 'chmod 777 ' . $RScriptID->filename );
				system( '/usr/bin/Rscript ' . $RScriptID->filename );
				my $TempGraph = basename( $GraphID );
				print $cgi ->img(
								  {
									-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
								  }
				);
				return $DataFiles;

			}
		}
	}

}

sub ManyAmp_OneInF_ManyInP {
	## Search For all Available Data in the Amplifier Path
	$phasenoisedataloc = $phasenoisedataloc . '/Amplifiers/';
	my @AllData = filesystem::hashEveryAmpTextFile( $phasenoisedataloc );
	my @MeasType;
	$MeasType[ 0 ] = 'ResidualPhaseNoise';
	my ( $ResidualData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
	my @UniqueInputFreq = filesystem::searchHashArrayForUnique( $ResidualData, 'InputFreq' );
	@UniqueInputFreq = sort @UniqueInputFreq;

	## Display Radio Button With all Available DUTs
	webpage::makeButtons( $cgi, 'radio', $inputfreqoptionname, '<br>Choose an Input Frequency: <br>', \@UniqueInputFreq, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @inFoption ) {
		## Get and Display Available Clock/ Input Frequencies
		my ( $InputFOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $ResidualData, 'InputFreq', \@inFoption );
		my @UniqueDUTs = filesystem::searchHashArrayForUnique( $InputFOnlyHash, 'DUT' );
		@UniqueDUTs = sort @UniqueDUTs;
		webpage::makeButtons( $cgi, 'checkbox', $dutoptionname, '<br>Choose Multiple Amplifiers <br>', \@UniqueDUTs, 0, 1 );

		##############################################################################################
		######################## Multiple DDSs at One Clock Rate, One Output Frequency
		##############################################################################################
		if ( @dutoption ) {
			my ( $DUTandInFHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $InputFOnlyHash, 'DUT', \@dutoption );
			my @InputPowers = filesystem::makeLegendArray_InputPowerDUTPairs( $DUTandInFHash );
			webpage::makeButtons( $cgi, 'checkbox', $inputpoweroptionname, '<br>Choose Multiple Input Powers <br>', \@InputPowers, 1 );

			if ( @inPoption ) {
				##############################################################################################
				######################## Make the R Script!
				##############################################################################################
				my ( @PInArray, @DUTArray );
				for ( my $PCount = 0 ; $PCount < scalar( @inPoption ) ; $PCount++ ) {
					my @ParsedString = split( /, /, $inPoption[ $PCount ] );
					push( @PInArray, $ParsedString[ 0 ] );
					push( @DUTArray, $ParsedString[ 1 ] );
				}

				## Given Chose Parameters, Get the Data Files
				my ( $TempHashes, $DataFiles ) = filesystem::searchHashArrayGiven2Params( $DUTandInFHash, 'InputPower', \@PInArray, 'DUT', \@DUTArray );
				my @Legend = filesystem::makeLegendArray_DUTInputOutputPowerPairs( $TempHashes );
				webpage::makeGraphInputs( $cgi, $smoothingoptionname );
				my ( $RScriptID, $GraphID ) =
					rscriptgen::makeRGraphScriptBruteForce( $DataFiles, $htmldir, \@Legend,
															$cgi->param( 'xmin' ),
															$cgi->param( 'xmax' ),
															$cgi->param( 'ymin' ),
															$cgi->param( 'ymax' ),
															$cgi->param( 'ydiv' ),
															$cgi->param( 'graphtitle' ),
															$cgi->param( 'Smooth' ) );
				system( 'chmod 777 ' . $RScriptID->filename );
				system( '/usr/bin/Rscript ' . $RScriptID->filename );
				my $TempGraph = basename( $GraphID );
				print $cgi ->img(
								  {
									-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
								  }
				);
				return $DataFiles;

			}
		}
	}

}

sub OneReference {
	## Search For all Available Data in the Reference Path
	$phasenoisedataloc = $phasenoisedataloc . '/FrequencyReferences/';
	my @AllData = filesystem::hashEveryRefTextFile( $phasenoisedataloc );
	my @MeasType;
	$MeasType[ 0 ] = 'AbsolutePhaseNoise';
	my ( $ResidualData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
	my @UniqueRefs = filesystem::searchHashArrayForUnique( $ResidualData, 'DUT' );
	@UniqueRefs = sort @UniqueRefs;

	## Display Radio Button With all Available References
	webpage::makeButtons( $cgi, 'radio', $dutoptionname, '<br>Choose a Reference: <br>', \@UniqueRefs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @dutoption ) {
		## Get and Display Available Clock/ Input Frequencies
		my ( $DUTOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $ResidualData, 'DUT', \@dutoption );
		my @UniqueFreqs = filesystem::searchHashArrayForUnique( $DUTOnlyHash, 'Freq' );
		@UniqueFreqs = sort { substr( $a, 0, -3 ) <=> substr( $b, 0, -3 ) } @UniqueFreqs;
		webpage::makeButtons( $cgi, 'checkbox', $inputfreqoptionname, '<br>Choose a Frequency: <br>', \@UniqueFreqs, 0, 1 );

		if ( @inFoption ) {
			##############################################################################################
			######################## Make the R Script!
			##############################################################################################

			## Given Chose Parameters, Get the Data Files
			my ( $TempHashes, $DataFiles ) = filesystem::searchHashArrayGivenParam( $DUTOnlyHash, 'Freq', \@inFoption );
			webpage::makeGraphInputs( $cgi, $smoothingoptionname );
			my ( $RScriptID, $GraphID ) =
				rscriptgen::makeRGraphScriptBruteForce( $DataFiles, $htmldir, \@inFoption, $cgi->param( 'xmin' ), $cgi->param( 'xmax' ), $cgi->param( 'ymin' ), $cgi->param( 'ymax' ), $cgi->param( 'ydiv' ), $cgi->param( 'graphtitle' ),
														$cgi->param( 'Smooth' ) );
			system( 'chmod 777 ' . $RScriptID->filename );
			system( '/usr/bin/Rscript ' . $RScriptID->filename );
			my $TempGraph = basename( $GraphID );
			print $cgi ->img(
							  {
								-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
							  }
			);
			return $DataFiles;

		}

	}


}

sub ManyReferences {
	## Search For all Available Data in the Reference Path
	$phasenoisedataloc = $phasenoisedataloc . '/FrequencyReferences/';
	my @AllData = filesystem::hashEveryRefTextFile( $phasenoisedataloc );
	my @MeasType;
	$MeasType[ 0 ] = 'AbsolutePhaseNoise';
	my ( $ResidualData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
	my @UniqueFreqs = filesystem::searchHashArrayForUnique( $ResidualData, 'Freq' );
	@UniqueFreqs = sort { substr( $a, 0, -3 ) <=> substr( $b, 0, -3 ) } @UniqueFreqs;

	## Display Radio Button With all Available References
	webpage::makeButtons( $cgi, 'radio', $inputfreqoptionname, '<br>Choose a Frequency: <br>', \@UniqueFreqs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @inFoption ) {
		## Get and Display Available Clock/ Input Frequencies
		my ( $FreqOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $ResidualData, 'Freq', \@inFoption );
		my @UniqueDUTs = filesystem::searchHashArrayForUnique( $FreqOnlyHash, 'DUT' );
		@UniqueDUTs = sort @UniqueDUTs;
		webpage::makeButtons( $cgi, 'checkbox', $dutoptionname, '<br>Choose a DUT: <br>', \@UniqueDUTs, 0, 1 );

		if ( @dutoption ) {
			##############################################################################################
			######################## Make the R Script!
			##############################################################################################

			## Given Chose Parameters, Get the Data Files
			my ( $TempHashes, $DataFiles ) = filesystem::searchHashArrayGivenParam( $FreqOnlyHash, 'DUT', \@dutoption );
			webpage::makeGraphInputs( $cgi, $smoothingoptionname );
			my ( $RScriptID, $GraphID ) =
				rscriptgen::makeRGraphScriptBruteForce( $DataFiles, $htmldir, \@dutoption, $cgi->param( 'xmin' ), $cgi->param( 'xmax' ), $cgi->param( 'ymin' ), $cgi->param( 'ymax' ), $cgi->param( 'ydiv' ), $cgi->param( 'graphtitle' ),
														$cgi->param( 'Smooth' ) );
			system( 'chmod 777 ' . $RScriptID->filename );
			system( '/usr/bin/Rscript ' . $RScriptID->filename );
			my $TempGraph = basename( $GraphID );
			print $cgi ->img(
							  {
								-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
							  }
			);
			return $DataFiles;

		}

	}


}

sub DiffReferenceWithDDS {
	## Search For all Available Data in the DDS Path
	my $phasenoisedataloc_dds = $phasenoisedataloc . '/FrequencyConverters/DDS/';
	my $phasenoisedataloc_ref = $phasenoisedataloc . '/FrequencyReferences/';
	my @AllData               = filesystem::hashEveryDDSTextFile( $phasenoisedataloc_dds );
	my @MeasType;
	$MeasType[ 0 ] = 'ResidualPhaseNoise';
	my ( $ResidualData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
	my @UniqueDUTs = filesystem::searchHashArrayForUnique( $ResidualData, 'DUT' );
	@UniqueDUTs = sort @UniqueDUTs;

	## Display Radio Button With all Available DUTs
	webpage::makeButtons( $cgi, 'radio', $dutoptionname, '<br>Choose a DDS: <br>', \@UniqueDUTs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @dutoption ) {
		## Get and Display Available Clock/ Input Frequencies
		my ( $DUTOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $ResidualData, 'DUT', \@dutoption );
		my @UniqueInputFreqs = filesystem::searchHashArrayForUnique( $DUTOnlyHash, 'InputFreq' );
		@UniqueInputFreqs = sort @UniqueInputFreqs;
		webpage::makeButtons( $cgi, 'radio', $inputfreqoptionname, '<br>Choose a Clock Frequency: <br>', \@UniqueInputFreqs, 0, 1 );

		##############################################################################################
		######################## Multiple DDSs at One Clock Rate, One Output Frequency
		##############################################################################################
		if ( @inFoption ) {
			my ( $DUTAndInFHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $DUTOnlyHash, 'InputFreq', \@inFoption );
			my @UniqueOutputFreqs = filesystem::searchHashArrayForUnique( $DUTAndInFHash, 'OutputFreq' );
			@UniqueOutputFreqs = sort @UniqueOutputFreqs;
			webpage::makeButtons( $cgi, 'radio', $outputfreqoptionname, '<br>Choose An Output Frequency: <br>', \@UniqueOutputFreqs, 1, 1 );

			if ( @outFoption ) {

				my @AllData_Ref = filesystem::hashEveryRefTextFile( $phasenoisedataloc_ref );
				my @MeasType_Ref;
				$MeasType_Ref[ 0 ] = 'AbsolutePhaseNoise';
				my ( $RefData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData_Ref, 'MeasType', \@MeasType_Ref );
				my @UniqueRefs = filesystem::searchHashArrayForUnique( $RefData, 'DUT' );
				@UniqueRefs = sort @UniqueRefs;
				## Display CheckBox Button With all Available References
				webpage::makeButtons( $cgi, 'checkbox', $refoptionname, '<br>Choose a Reference: <br>', \@UniqueRefs, 0, 1 );

				if ( @refoption ) {
					## Get and Display Available Clock/ Input Frequencies
					my ( $RefOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $RefData, 'DUT', \@refoption );
					my @UniqueRefFreqs = filesystem::makeLegendArray_RefFreqRefPairs( $RefOnlyHash );
					@UniqueRefFreqs = sort @UniqueRefFreqs;
					webpage::makeButtons( $cgi, 'checkbox', $reffreqoptionname, '<br>Choose a Reference Frequency (This will be 20*log10(N) Scaled to the DDS Frequency: <br>', \@UniqueRefFreqs, 0, 1 );

					if ( @refFoption ) {
						##############################################################################################
						######################## Make the R Script!
						##############################################################################################
						my ( @FArray, @DUTArray );
						for ( my $PCount = 0 ; $PCount < scalar( @refFoption ) ; $PCount++ ) {
							my @ParsedString = split( /, /, $refFoption[ $PCount ] );
							push( @FArray,   $ParsedString[ 0 ] );
							push( @DUTArray, $ParsedString[ 1 ] );
						}
						## Given Chose Parameters, Get the Data Files
						my ( $TempHashes1, $DataFiles ) = filesystem::searchHashArrayGivenParam( $DUTAndInFHash, 'OutputFreq', \@outFoption );
						my @DUTFreqs = filesystem::searchHashArrayForUnique( $TempHashes1, 'OutputFreq' );
						my @DUT      = filesystem::searchHashArrayForUnique( $TempHashes1, 'DUT' );
						my ( $TempHashes2, $DataFiles2 ) = filesystem::searchHashArrayGiven2Params( $RefOnlyHash, 'Freq', \@FArray, 'DUT', \@DUTArray );
						my @RefFreqs = filesystem::makeLegendArray_RefFreqRefPairs( $TempHashes2 );
						push( @DUT,            @RefFreqs );
						push( @{ $DataFiles }, @{ $DataFiles2 } );
						webpage::makeGraphInputs( $cgi, $smoothingoptionname );
						my ( $RScriptID, $GraphID ) =
							rscriptgen::makeRGraphScriptBruteForce_DDSandRef(
																			  $DataFiles,
																			  $htmldir,
																			  \@DUT,
																			  \@DUTFreqs,
																			  \@RefFreqs,
																			  $cgi->param( 'xmin' ),
																			  $cgi->param( 'xmax' ),
																			  $cgi->param( 'ymin' ),
																			  $cgi->param( 'ymax' ),
																			  $cgi->param( 'ydiv' ),
																			  $cgi->param( 'graphtitle' ),
																			  $cgi->param( 'Smooth' )
							);
						system( 'chmod 777 ' . $RScriptID->filename );
						system( '/usr/bin/Rscript ' . $RScriptID->filename );
						my $TempGraph = basename( $GraphID );
						print $cgi ->img(
										  {
											-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
										  }
						);
						return $DataFiles;

					}
				}
			}
		}
	}

}

sub ReferenceWithDiffDDS {
	## Search For all Available Data in the DDS Path
	my $phasenoisedataloc_dds = $phasenoisedataloc . '/FrequencyConverters/DDS/';
	my $phasenoisedataloc_ref = $phasenoisedataloc . '/FrequencyReferences/';
	my @AllData               = filesystem::hashEveryRefTextFile( $phasenoisedataloc_ref );
	my @MeasType;
	$MeasType[ 0 ] = 'AbsolutePhaseNoise';
	my ( $AbsoluteData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
	my @UniqueRefs = filesystem::searchHashArrayForUnique( $AbsoluteData, 'DUT' );
	@UniqueRefs = sort @UniqueRefs;

	## Display Radio Button With all Available References
	webpage::makeButtons( $cgi, 'radio', $refoptionname, '<br>Choose a Reference: <br>', \@UniqueRefs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @refoption ) {
		## Get and Display Available Reference Frequencies
		my ( $RefOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $AbsoluteData, 'DUT', \@refoption );
		my @UniqueRefFreqs = filesystem::searchHashArrayForUnique( $RefOnlyHash, 'Freq' );
		@UniqueRefFreqs = sort @UniqueRefFreqs;
		webpage::makeButtons( $cgi, 'radio', $reffreqoptionname, '<br>Choose a Reference Frequency: <br>', \@UniqueRefFreqs, 0, 1 );

		##############################################################################################
		######################## Multiple DDSs at One Clock Rate, One Output Frequency
		##############################################################################################
		if ( @refFoption ) {
			my ( $RefAndFHash, $RefDataFiles ) = filesystem::searchHashArrayGivenParam( $RefOnlyHash, 'Freq', \@refFoption );

			## Search For all Available Data in the DDS Path
			$phasenoisedataloc = $phasenoisedataloc . '/FrequencyConverters/DDS/';
			my @AllData = filesystem::hashEveryDDSTextFile( $phasenoisedataloc );
			my @MeasType;
			$MeasType[ 0 ] = 'ResidualPhaseNoise';
			my ( $ResidualData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
			my @UniqueInputFreqs = filesystem::searchHashArrayForUnique( $ResidualData, 'InputFreq' );
			@UniqueInputFreqs = sort @UniqueInputFreqs;

			## Display Radio Button With all Available DUTs
			webpage::makeButtons( $cgi, 'radio', $inputfreqoptionname, '<br>Choose a DDS Clock Frequency: <br>', \@UniqueInputFreqs, 0, 1 );
			##############################################################################################
			######################## A Clock Was Chosen
			##############################################################################################
			if ( @inFoption ) {
				## Get and Display Available Clock/ Input Frequencies
				my ( $InFOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $ResidualData, 'InputFreq', \@inFoption );
				my @UniqueOutputFreqs = filesystem::searchHashArrayForUnique( $InFOnlyHash, 'OutputFreq' );
				@UniqueOutputFreqs = sort @UniqueOutputFreqs;
				webpage::makeButtons( $cgi, 'radio', $outputfreqoptionname, '<br>Choose an Output Frequency <br>', \@UniqueOutputFreqs, 0, 1 );

				##############################################################################################
				######################## Multiple DDSs at One Clock Rate, One Output Frequency
				##############################################################################################
				if ( @outFoption ) {
					my ( $InFAndOutFHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $InFOnlyHash, 'OutputFreq', \@outFoption );
					my @UniqueDUTs = filesystem::searchHashArrayForUnique( $InFAndOutFHash, 'DUT' );
					@UniqueDUTs = sort @UniqueDUTs;
					webpage::makeButtons( $cgi, 'checkbox', $dutoptionname, '<br>Choose Multiple DDSs <br>', \@UniqueDUTs, 1, 1 );

					if ( @dutoption ) {
						##############################################################################################
						######################## Make the R Script!
						##############################################################################################

						## Given Chose Parameters, Get the Data Files
						my ( $TempHashes, $DataFiles ) = filesystem::searchHashArrayGivenParam( $InFAndOutFHash, 'DUT', \@dutoption );
						my @DUTFreqs = filesystem::searchHashArrayForUnique( $TempHashes,  'OutputFreq' );
						my @RefFreqs = filesystem::searchHashArrayForUnique( $RefAndFHash, 'Freq' );
						my @DUT      = filesystem::searchHashArrayForUnique( $RefAndFHash, 'DUT' );
						my @Legend   = $DUT[ 0 ] . ', ' . $RefFreqs[ 0 ];

						for ( my $i = 0 ; $i < scalar @dutoption ; $i++ ) {
							push( @Legend, $dutoption[ $i ] . ', ' . $DUTFreqs[ 0 ] );
						}
						webpage::makeGraphInputs( $cgi, $smoothingoptionname );
						push( @{ $RefDataFiles }, @{ $DataFiles } );
						my ( $RScriptID, $GraphID ) =
							rscriptgen::makeRGraphScriptBruteForce_ManyDDSandRef( $RefDataFiles, $htmldir, \@Legend, \@DUTFreqs, \@RefFreqs,
																				  $cgi->param( 'xmin' ),
																				  $cgi->param( 'xmax' ),
																				  $cgi->param( 'ymin' ),
																				  $cgi->param( 'ymax' ),
																				  $cgi->param( 'ydiv' ),
																				  $cgi->param( 'graphtitle' ),
																				  $cgi->param( 'Smooth' ) );
						system( 'chmod 777 ' . $RScriptID->filename );

						system( '/usr/bin/Rscript ' . $RScriptID->filename );
						my $TempGraph = basename( $GraphID );
						print $cgi ->img(
										  {
											-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
										  }
						);
						return $DataFiles;
					}


				}
			}
		}
	}
}


sub RandSvsKeys_Source {
	## Search For all Available Data in the Keysight and Rohde Paths
	my $phasenoisedataloc_keys  = $phasenoisedataloc . '/Keysight/';
	my $phasenoisedataloc_rands = $phasenoisedataloc . '/RoadyAndShorts/';
	my @AllRandSData            = filesystem::hashEverySrcTextFile( $phasenoisedataloc_rands );
	my @AllKeysData             = filesystem::hashEverySrcTextFile( $phasenoisedataloc_keys );
	my @MeasType;
	$MeasType[ 0 ] = 'AbsolutePhaseNoise';
	my ( $AbsoluteRandSData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllRandSData, 'MeasType', \@MeasType );
	my ( $AbsoluteKeysData,  $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllKeysData,  'MeasType', \@MeasType );
	my @UniqueRandSDUTs = filesystem::searchHashArrayForUnique( $AbsoluteRandSData, 'DUT' );
	@UniqueRandSDUTs = sort @UniqueRandSDUTs;

	## Display Radio Button With all Available Rohde DUTs
	webpage::makeButtons( $cgi, 'radio', $randsdutoptionname, '<br>Choose an R&S Source: <br>', \@UniqueRandSDUTs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @randsdutoption ) {
		## Get and Display Available Rohde DUT Frequencies
		my ( $RandSDUT, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $AbsoluteRandSData, 'DUT', \@randsdutoption );
		my @UniqueRandSFreqs = filesystem::searchHashArrayForUnique( $RandSDUT, 'Freq' );
		@UniqueRandSFreqs = sort @UniqueRandSFreqs;

		webpage::makeButtons( $cgi, 'checkbox', $randsfreqoptionname, '<br>Choose an Output Frequency For the R&S Source: <br>', \@UniqueRandSFreqs, 0, 1 );

		if ( @randsfreqoption ) {
			## Get and Display Available Keysight DUTs
			my @UniqueKeysDUTs = filesystem::searchHashArrayForUnique( $AbsoluteKeysData, 'DUT' );
			@UniqueKeysDUTs = sort @UniqueKeysDUTs;

			webpage::makeButtons( $cgi, 'checkbox', $keysdutoptionname, '<br>Choose a Keysight Source: <br>', \@UniqueKeysDUTs, 0, 1 );

			if ( @keysdutoption ) {
				my ( $KeysDUT, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $AbsoluteKeysData, 'DUT', \@keysdutoption );
				## Get and Display Available Keysight Freqs
				my @UniqueKeysFreqs = filesystem::makeLegendArray_DUTFreqPowerPairs( $KeysDUT );
				@UniqueKeysFreqs = sort @UniqueKeysFreqs;

				webpage::makeButtons( $cgi, 'checkbox', $keysfreqoptionname, '<br>Choose a Keysight Source and Output Frequency: <br>', \@UniqueKeysFreqs, 0, 1 );
				##############################################################################################
				######################## Multiple DDSs at One Clock Rate, One Output Frequency
				##############################################################################################
				if ( @keysfreqoption ) {

					#Get RandS Datafiles
					my ( $TempHash, $RandSDataFiles ) = filesystem::searchHashArrayGivenParam( $RandSDUT, 'Freq', \@randsfreqoption );

					#Get Keys Data Files
					my ( @KeysDUTArray, @KeysFreqArray, @KeysPowerArray );
					for ( my $PCount = 0 ; $PCount < scalar( @keysfreqoption ) ; $PCount++ ) {
						my @ParsedString = split( /, /, $keysfreqoption[ $PCount ] );
						push( @KeysDUTArray,   $ParsedString[ 0 ] );
						push( @KeysFreqArray,  $ParsedString[ 1 ] );
						push( @KeysPowerArray, $ParsedString[ 2 ] );
					}
					my ( $TempHash, $KeysDataFiles ) = filesystem::searchHashArrayGiven3Params( $KeysDUT, 'DUT', \@KeysDUTArray, 'Freq', \@KeysFreqArray, 'Power', \@KeysPowerArray );
					my @Legend;
						for (my $i = 0; $i < scalar(@randsfreqoption); $i++){
							$Legend[$i] = $randsdutoption[0] . ', ' . $randsfreqoption[$i];
						}
					push( @Legend,              @keysfreqoption );
					push( @{ $RandSDataFiles }, @{ $KeysDataFiles } );
					##############################################################################################
					######################## Make the R Script!
					##############################################################################################
					webpage::makeGraphInputs( $cgi, $smoothingoptionname );
					my ( $RScriptID, $GraphID ) =
						rscriptgen::makeRGraphScriptBruteForce( $RandSDataFiles, $htmldir, \@Legend,
																$cgi->param( 'xmin' ),
																$cgi->param( 'xmax' ),
																$cgi->param( 'ymin' ),
																$cgi->param( 'ymax' ),
																$cgi->param( 'ydiv' ),
																$cgi->param( 'graphtitle' ),
																$cgi->param( 'Smooth' ) );
					system( 'chmod 777 ' . $RScriptID->filename );

					system( '/usr/bin/Rscript ' . $RScriptID->filename );
					my $TempGraph = basename( $GraphID );
					print $cgi ->img(
									  {
										-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
									  }
					);
					return $RandSDataFiles;
				}


			}
		}
	}
}

sub RandSvsDDS {
	## Search For all Available Data in the Keysight and Rohde Paths
	my $phasenoisedataloc_rands = $phasenoisedataloc . '/RoadyAndShorts/';
	my @AllRandSData            = filesystem::hashEverySrcTextFile( $phasenoisedataloc_rands );
	my @MeasType;
	$MeasType[ 0 ] = 'AbsolutePhaseNoise';
	my ( $AbsoluteRandSData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllRandSData, 'MeasType', \@MeasType );
	my @UniqueRandSDUTs = filesystem::searchHashArrayForUnique( $AbsoluteRandSData, 'DUT' );
	@UniqueRandSDUTs = sort @UniqueRandSDUTs;

	## Display Radio Button With all Available Rohde DUTs
	webpage::makeButtons( $cgi, 'radio', $randsdutoptionname, '<br>Choose an R&S Source: <br>', \@UniqueRandSDUTs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @randsdutoption ) {
		## Get and Display Available Rohde DUT Frequencies
		my ( $RandSDUT, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $AbsoluteRandSData, 'DUT', \@randsdutoption );
		my @UniqueRandSFreqs = filesystem::searchHashArrayForUnique( $RandSDUT, 'Freq' );
		@UniqueRandSFreqs = sort @UniqueRandSFreqs;

		webpage::makeButtons( $cgi, 'checkbox', $randsfreqoptionname, '<br>Choose an Output Frequency For the R&S Source: <br>', \@UniqueRandSFreqs, 0, 1 );

		if ( @randsfreqoption ) {
			my ( $TempHash, $RandSDataFiles ) = filesystem::searchHashArrayGivenParam( $RandSDUT, 'Freq', \@randsfreqoption );

			## Search For all Available Data in the DDS Path
			$phasenoisedataloc = $phasenoisedataloc . '/FrequencyConverters/DDS/';
			my @AllData = filesystem::hashEveryDDSTextFile( $phasenoisedataloc );
			my @MeasType;
			$MeasType[ 0 ] = 'ResidualPhaseNoise';
			my ( $ResidualData, $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllData, 'MeasType', \@MeasType );
			my @UniqueInputFreqs = filesystem::searchHashArrayForUnique( $ResidualData, 'InputFreq' );
			@UniqueInputFreqs = sort @UniqueInputFreqs;

			## Display Radio Button With all Available DUTs
			webpage::makeButtons( $cgi, 'radio', $inputfreqoptionname, '<br>Choose a DDS Clock Frequency: <br>', \@UniqueInputFreqs, 0, 1 );
			##############################################################################################
			######################## A Clock Was Chosen
			##############################################################################################
			if ( @inFoption ) {
				## Get and Display Available Clock/ Input Frequencies
				my ( $InFOnlyHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $ResidualData, 'InputFreq', \@inFoption );
				my @UniqueOutputFreqs = filesystem::searchHashArrayForUnique( $InFOnlyHash, 'OutputFreq' );
				@UniqueOutputFreqs = sort @UniqueOutputFreqs;
				webpage::makeButtons( $cgi, 'radio', $outputfreqoptionname, '<br>Choose a DDS Output Frequency: <br>', \@UniqueOutputFreqs, 0, 1 );

				##############################################################################################
				######################## Multiple DDSs at One Clock Rate, One Output Frequency
				##############################################################################################
				if ( @outFoption ) {
					my ( $InFAndOutFHash, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $InFOnlyHash, 'OutputFreq', \@outFoption );
					my @UniqueDUTs = filesystem::searchHashArrayForUnique( $InFAndOutFHash, 'DUT' );
					@UniqueDUTs = sort @UniqueDUTs;
					webpage::makeButtons( $cgi, 'checkbox', $dutoptionname, '<br>Choose Multiple DDS Residuals: <br>', \@UniqueDUTs, 1, 1 );

					if ( @dutoption ) {
						##############################################################################################
						######################## Make the R Script!
						##############################################################################################

						## Given Chose Parameters, Get the Data Files
						my ( $TempHashes, $DataFiles ) = filesystem::searchHashArrayGivenParam( $InFAndOutFHash, 'DUT', \@dutoption );
						my @Legend;
						for (my $i = 0; $i < scalar(@randsfreqoption); $i++){
							$Legend[$i] = $randsdutoption[0] . ', ' . $randsfreqoption[$i];
						}

						for ( my $i = 0 ; $i < scalar @dutoption ; $i++ ) {
							push( @Legend, $dutoption[ $i ] . ', ' . $outFoption[ 0 ] );
						}
						webpage::makeGraphInputs( $cgi, $smoothingoptionname );
						push( @{ $RandSDataFiles }, @{ $DataFiles } );
						my ( $RScriptID, $GraphID ) =
							rscriptgen::makeRGraphScriptBruteForce( $RandSDataFiles, $htmldir, \@Legend,
																				  $cgi->param( 'xmin' ),
																				  $cgi->param( 'xmax' ),
																				  $cgi->param( 'ymin' ),
																				  $cgi->param( 'ymax' ),
																				  $cgi->param( 'ydiv' ),
																				  $cgi->param( 'graphtitle' ),
																				  $cgi->param( 'Smooth' ) );
						system( 'chmod 777 ' . $RScriptID->filename );

						system( '/usr/bin/Rscript ' . $RScriptID->filename );
						my $TempGraph = basename( $GraphID );
						print $cgi ->img(
										  {
											-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
										  }
						);
						return $DataFiles;
					}


				}
			}

		}
	}
}

sub SourceAbs {
	## Search For all Available Data in the Keysight and Rohde Paths
	my $phasenoisedataloc_keys  = $phasenoisedataloc . '/Keysight/';
	my @AllKeysData             = filesystem::hashEverySrcTextFile( $phasenoisedataloc_keys );
	my @MeasType;
	$MeasType[ 0 ] = 'AbsolutePhaseNoise';
	my ( $AbsoluteKeysData,  $TempFiles ) = filesystem::searchHashArrayGivenParam( \@AllKeysData,  'MeasType', \@MeasType );
	my @UniqueKeysDUTs = filesystem::searchHashArrayForUnique( $AbsoluteKeysData, 'DUT' );
	@UniqueKeysDUTs = sort @UniqueKeysDUTs;

	## Display Radio Button With all Available Rohde DUTs
	webpage::makeButtons( $cgi, 'radio', $keysdutoptionname, '<br>Choose a Keysight Source: <br>', \@UniqueKeysDUTs, 0, 1 );
	##############################################################################################
	######################## A Clock Was Chosen
	##############################################################################################
	if ( @keysdutoption ) {
		## Get and Display Available Rohde DUT Frequencies
		my ( $KeysDUT, $TempDataFiles ) = filesystem::searchHashArrayGivenParam( $AbsoluteKeysData, 'DUT', \@keysdutoption );
		my @UniqueKeysFreqs = filesystem::searchHashArrayForUnique( $KeysDUT, 'Freq' );
		@UniqueKeysFreqs = sort @UniqueKeysFreqs;

		webpage::makeButtons( $cgi, 'checkbox', $keysfreqoptionname, '<br>Choose an Output Frequency For the Keysight Source: <br>', \@UniqueKeysFreqs, 0, 1 );

		if ( @keysfreqoption ) {
		
					#Get Keys Data Files
					my ( @KeysDUTArray, @KeysFreqArray, @KeysPowerArray );
					for ( my $PCount = 0 ; $PCount < scalar( @keysfreqoption ) ; $PCount++ ) {
						my @ParsedString = split( /, /, $keysfreqoption[ $PCount ] );
						push( @KeysDUTArray,   $ParsedString[ 0 ] );
						push( @KeysFreqArray,  $ParsedString[ 1 ] );
						push( @KeysPowerArray, $ParsedString[ 2 ] );
					}
					my ( $TempHash, $KeysDataFiles ) = filesystem::searchHashArrayGivenParam( $KeysDUT, 'Freq', \@keysfreqoption );
					##############################################################################################
					######################## Make the R Script!
					##############################################################################################
					webpage::makeGraphInputs( $cgi, $smoothingoptionname );
					my ( $RScriptID, $GraphID ) =
						rscriptgen::makeRGraphScriptBruteForce( $KeysDataFiles, $htmldir, \@keysfreqoption,
																$cgi->param( 'xmin' ),
																$cgi->param( 'xmax' ),
																$cgi->param( 'ymin' ),
																$cgi->param( 'ymax' ),
																$cgi->param( 'ydiv' ),
																$cgi->param( 'graphtitle' ),
																$cgi->param( 'Smooth' ) );
					system( 'chmod 777 ' . $RScriptID->filename );

					system( '/usr/bin/Rscript ' . $RScriptID->filename );
					my $TempGraph = basename( $GraphID );
					print $cgi ->img(
									  {
										-src => ( 'http://www.srs.is.keysight.com/~anferrar/tmp/' . $TempGraph )
									  }
					);
					return $KeysDataFiles;
				}


			}
		}
	


2
