use strict; # don't allow dangerous things
use warnings; # when something goes wrong, let me know
use utf8; # allow UTF-8 in the source code
use open qw(:utf8 :std); #set inputs and outputs to UTF-8
use v5.16; # modern features and better Unicode support
use JSON::PP;
use Encode;



	my $text = "sněhulák"; 	
	my $ud_json = "";
	my $result_ud = "";
	my $result_morp = "";
	my $filename = $ARGV[0];
	my $mor_result = "";

   open(my $fh, '<:encoding(UTF-8)', $filename)
   or die "Could not open file '$filename' $!";
	    
    while (my $row = <$fh>)
    {
      chomp $row;
      print "$row\n";
	say "\n\n";	
		
	$ud_json =  qx( curl -F 'data=$row' -F model=czech -F tokenizer= -F tagger= -F parser= http://lindat.mff.cuni.cz/services/udpipe/api/process | PYTHONIOENCODING=utf-8 python -c "import sys,json; sys.stdout.write(json.load(sys.stdin)['result'])");
	
	$mor_result = qx ( curl -F 'data=$row' -F 'output=vertical' -F model=czech http://lindat.mff.cuni.cz/services/morphodita/api/tag | PYTHONIOENCODING=utf-8 python -c "import sys,json; sys.stdout.write(json.load(sys.stdin)['result'])");


	$result_ud .= $ud_json;
	$result_morp .= $mor_result;
	}

	$result_ud =~ s/\#.+\n//g;
	$result_ud =~ s/^\x{FEFF}//g;

	say $result_ud;
	say "\n\n";
	say $result_morp;

my $filename = 'udpipe_temp';
open(my $fh, '>:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";
say $fh $result_ud;
close $fh; 
say 'done';
	
my $filename = 'morp_temp';
open(my $fh, '>:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";
say $fh $result_morp;
close $fh; 
say 'done';
