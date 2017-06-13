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
my $result_ud = "";
my $result_morp = "";
@sourcenames = map {$_ } glob 'data/*.txt'; 

empty_output('t1'); #empty output file t1
empty_output('udpipe_temp'); #empty output file 
empty_output('morp_temp'); #empty output file 


for my $fc (@sourcenames)
{
 say "\nid: ", $i, ' file: ', $fc;
 ($result_ud, $result_morp) = use_apis($fc, $i);
 combination_temps($result_ud, $result_morp);
 push @metadata, $fc;
 $i++; #file id 
}

clean_output_udpipe(); #only temp file, fixs blank lines
say 'number of files: ', scalar @metadata; 
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
my $content = '';
my $tokenized ='';


open(my $fh, '<:encoding(UTF-8)', $sourcename)
   or die "Could not open file '$sourcename' $!";
{
	local $/;
	$content = <$fh>;
}
close($fh);


$tokenized = qx ( curl -F 'data=$content' -F 'output=vertical' -F model=czech http://lindat.mff.cuni.cz/services/morphodita/api/tokenize | PYTHONIOENCODING=utf-8 python -c "import sys,json; sys.stdout.write(json.load(sys.stdin)['result'])");

$tokenized =~ s/^\x{feff}//;
$tokenized =~ s/^\n//;


	$mor_result = qx ( curl -F 'data=$tokenized' -F 'input=vertical'  -F 'output=vertical' -F model=czech http://lindat.mff.cuni.cz/services/morphodita/api/tag | PYTHONIOENCODING=utf-8 python -c "import sys,json; sys.stdout.write(json.load(sys.stdin)['result'])");
$result_morp = $mor_result;
	

	$ud_json =  qx( curl -F 'data=$tokenized' -F input=vertical -F model=czech -F tokenizer= -F tagger= -F parser= http://lindat.mff.cuni.cz/services/udpipe/api/process | PYTHONIOENCODING=utf-8 python -c "import sys,json; sys.stdout.write(json.load(sys.stdin)['result'])");

$ud_json =~ s/\#.+\n//g; #remove comments

$ud_json =~ s/\n/\t$id\n/g; #adds id of file, can't catch ^ or $ :( ...

$result_ud = $ud_json;

write_to_temp('udpipe_temp',$result_ud,'udpipe out');
write_to_temp('morp_temp',$result_morp,'morphodita out');

return ($result_ud, $result_morp);
}




#########################
#argv[0] / filename 
#########################
sub empty_output
{
my $filename = $_[0];

open (my $session_file, '>', $filename);
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
##########################
#argv[0] udpipe res
#argv[1] morpohita res
##########################
sub combination_temps
{

open (my $tf, '>>', 't1');


my @result_ud = split /^/, $_[0];
my @result_morp = split /^/, $_[1];
my $i = 0; 
my $e = 0;
my $ll = "";


$e = $i;

#print join("_", @result_ud);

for my $i (0..scalar @result_ud)
{
#say "i: ", $i,",e: ", $e;
 my @ud = split /\t/,$result_ud[$i];
 my @mp = split /\t/,$result_morp[$e];
 my @mp2 = split /\t/, $result_morp[$e+1];
 my @mp3 = split /\t/, $result_morp[$e-1];

if($ud[0] eq '')
{
 print $tf "\n"; #adds blank line to output file when ^$ sentence divider;
}
else
{
 if ($ud[1] eq $mp[0])
 {#say "match";
  #say $ud[1], "\t", $mp[0];
	$result_morp[$e] =~ s/\n/\t$result_ud[$i]/; 
	print $tf $result_morp[$e]; 
 }
 else
 {
  if ( $ud[1] eq $mp2[0])
   {
   #match shift e+1; lookforward
   #say $ud[1], "\t", $mp2[0]; 
	$result_morp[$e+1] =~ s/\n/\t$result_ud[$i]/; 
	print $tf $result_morp[$e+1]; 
   $e++; 
   }
  elsif ( $ud[1] eq $mp3[0])
   {
   #match shift e-1; lookbehind
   #say $ud[1], "\t", $mp3[0];
	$result_morp[$e-1] =~ s/\n/\t$result_ud[$i]/; 
	print  $tf $result_morp[$e-1]; 
   $e--; 
   }
  else
   {
   say "problem with align:", $ud[1], "\t 1:", $mp2[0], "\t2:", $mp3[0];
   };
 };
};
$e++;
};


close $tf;
}

#########################
#[0] - name of output file
#[1] - content
#[3] - msg for log
#########################
sub write_to_temp()
{
my $filename = $_[0];
my $result = $_[1];
my $msg = $_[2];

open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
say $fh $result;
close $fh; 
#say $msg, ' ', $filename, ' - tempfile done';

}



