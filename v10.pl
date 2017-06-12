use strict; # don't allow dangerous things
use warnings; # when something goes wrong, let me know
use utf8; # allow UTF-8 in the source code
#use open qw(:utf8 :std); #set inputs and outputs to UTF-8
use Encode;
use open qw( :encoding(UTF-8) :std);
use v5.16; # modern features and better Unicode support
use JSON::PP;

my @sourcenames = (); 
my @metadata = ();
my $i=0;
my $comb = "";

@sourcenames = map {$_ } glob 'data/*.txt'; 
#say join(" ", @sourcename2);

#empty output file t1

	empty_output();

	for my $fc (@sourcenames)
	{
	#use_apis($fc, $i);
	clean_output_udpipe();
	$comb = qx ( paste morp_temp udpipe_temp >> t1 );
	push @metadata, $fc;
	$i++;
	say $comb, "added.";
	}

#	say scalar @metadata; 
metadata_add(\@metadata);


#########################
#argv[0] / filename.txt
#argv[1] / id
#
########################

sub use_apis 
{
my $id = $_[1];
my $sourcename = $_[0];
my $ud_json = "";
my $result_ud = "";
my $result_morp = "";
my $filename;
my $mor_result = '';

open(my $fh, '<:encoding(UTF-8)', $sourcename)
   or die "Could not open file '$sourcename' $!";
	    
    while (my $row = <$fh>)
    {
      chomp $row;
     	#print "$row\n";
	$row =~ s/^\x{feff}//;
	#if($row =~ /^\x{feff}/){say 'fffffffffffff';};

		
	$ud_json =  qx( curl -F 'data=$row' -F model=czech -F tokenizer= -F tagger= -F parser= http://lindat.mff.cuni.cz/services/udpipe/api/process | PYTHONIOENCODING=utf-8 python -c "import sys,json; sys.stdout.write(json.load(sys.stdin)['result'])");
	
	$mor_result = qx ( curl -F 'data=$row' -F 'output=vertical' -F model=czech http://lindat.mff.cuni.cz/services/morphodita/api/tag | PYTHONIOENCODING=utf-8 python -c "import sys,json; sys.stdout.write(json.load(sys.stdin)['result'])");


	$result_ud .= $ud_json;
	$result_morp .= $mor_result;
	}

	$result_ud =~ s/\#.+\n//g; #remove comments
	#append to the end of line column with id
	$result_ud =~ s/\n/\t$id\n/g;

	#my @matches = $result_ud =~ s/\n/\t$id\n/g;
	#my @matches = $result_ud =~ s/(?!^)\n/\t$id\n/g;
#	say scalar @matches;


$filename = 'udpipe_temp';
open($fh, '>:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";
say $fh $result_ud;
close $fh; 
say $sourcename, ' UDPIPE done';
	
$filename = 'morp_temp';
open($fh, '>', $filename) or die "Could not open file '$filename' $!";
say $fh $result_morp;
close $fh; 
say $sourcename, ' MORP done';


}

#########################
#
#########################
sub empty_output
{
open (my $session_file, '>', 't1');
truncate $session_file, 0;
close $session_file;
}

#########################
#
##########################
sub clean_output_udpipe
{
my $result_ud ="";

open (my $fh, '<', 'udpipe_temp')
or die "Could not open file $!";

while(my $row = <$fh>)
{
	$row =~ s/^\t\d+$//;
	$result_ud .= $row;
}

open ($fh, '>', 'udpipe_temp')
or die "Could not open file $!";
say $fh $result_ud;
close $fh;

}
##########################
#argv[0] / array eetadata 
##########################
sub metadata_add
{
my @metadata = @{$_[0]};
my $i=0;

#	say scalar @metadata;

open (my $fh, '>', 'metadata')
or die "Could not open file $!";

foreach my $meta(@metadata)
{
say $fh $i."\t".$meta; 
$i++;
}
close $fh;


}
