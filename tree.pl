use strict; # don't allow dangerous things
use warnings; # when something goes wrong, let me know
use utf8; # allow UTF-8 in the source code
#use open qw(:utf8 :std); #set inputs and outputs to UTF-8
use Encode;
use open qw( :encoding(UTF-8) :std);
use v5.16; # modern features and better Unicode support
use JSON::PP;

#########################
#[0] - name of output file
#[1] - content
#[3] - msg for log
#########################
sub write_to_temp
{
my $filename = $_[0];
my $result = $_[1];
my $msg = $_[2];

open(my $fh, '>', $filename)
	or die "Could not open file $!";
print $fh $result;
close $fh; 
say $msg, ' - tempfile done';
}

#########################
#########################
#my $result_ud = "";
#my $content = "";

#empty_output('t1'); #empty output file t1
# ($result_ud, $result_morp) = use_apis($fc, $i);
#write_to_temp('filter', 'test' , 'udpipe out');


#open(my $fh, '<:encoding(UTF-8)', 'udpipe_temp')
#   or die "Could not open file udpipe_temp  $!";
#{
#	local $/;
#	$content = <$fh>;
#}
#close($fh);


	#say ($content =~ /^\d-\d(.*\n){3}/gm);

	#$filter = ($content =~ /\d-\d.*\./sg);
	#say ($content =~ /\d-\d.*?\d+\t\..*?\n/sg);

#say ($content =~ /\n\d+-\d.*?\d+\t[\.\?\!].*?\n/sg);

	#write_to_temp('filter', $filter , 'test');

#my @filter = ();

#(@filter) = $content =~ m/\n\d+-\d.*?\d+\t[\.\?\!].*?\n/sg;

open(my $fht, '<:encoding(UTF-8)', 'udpipe_temp')
   or die "Could not open file udpipe_temp  $!";


my $selection = "";
my @sentences = ();
my $buffer = "";
my $flagin = 0;
my $i = 0;

while (my $row = <$fht>) 
{
$buffer .= $row;
	#pridej do bufferu
 if ($row =~ /^\d+-\d+/)
	#if radek obsahuje na zacatku cislo s pomlckou
	# schovej buffer do vyberu a flag jsem v na true
  {
   #say $row;
   $flagin = 1;
   
  }
 elsif($row =~ /^$/)
	#if radek obsahuje nic
	# if flag jsem v true
	#  schovej buffer do vyberu
  {
   #say 'end of sentence';
   if ($flagin == 1)
    {
    #$selection .= $buffer;
    $sentences[$i] = $buffer;
    $i++;
    }
#  smaz buffer
   $buffer = "";
   $flagin = 0;
  #$selection = "";
  }

}
#say join("\n", @sentences);
say $i;


#################
# @sentences / one problematic sentence, multi lines per id
#vezmi vetu

my @tokens = split ("\n", $sentences[0]); 
my @new_tokens = ();
my $token_id = 1;
my $new_id = 1;
my $tokens_row = "";
$i = 0;

#foreach my $tokens_row (@tokens)
#foreach ($token_id..(scalar @tokens))
while ($token_id<=(scalar @tokens))
{
 $tokens_row = $tokens[$token_id-1];
# say $tokens_row;
 my @r1 = split ("\t", $tokens_row);
 
 if($tokens_row =~ /^\d+-\d+/)
 {
  my @r2 = split ("\t", $tokens[$token_id]);
  my @r3 = split ("\t", $tokens[$token_id+1]);

  $new_tokens[$new_id] = $new_id."\t".$r1[1]."\t".'_^('.$r2[1].'-'.$r2[3].', '.$r3[1].'-'.$r3[2].'-'.$r3[3].')'."\t".$r3[3]."\t".$r3[4]."\t".$r3[5]."\t_\t_\t_\t_\n";
#  say $tokens_row;
#  say $tokens[$token_id];
#  say $tokens[$token_id+1];
  say 'new: ', $new_tokens[$new_id];
  $token_id = $token_id + 2;	
}
 else
{
  #say 'old: ', $tokens_row;
  $r1[0] = $new_id;
  $r1[6] = "_";
  pop @r1;
  $new_tokens[$new_id] = join("\t", @r1);
  
  say 'new: ', $new_tokens[$new_id];
 }

$new_id++;
$token_id++;
}

say scalar @tokens;
say $new_id;









#say scalar @filter ;
	#say join("\n\n", @filter);
	

	#say $filter[0];
#say ($content =~ /(\n1\t){1}(.+?)\n{2}/sg);
#say ($content =~ /\n\n\d.*?\n/sg);


#say ($content =~ /\n\n\d.*?\n5\-6/sg);

	#if ($content =~ /$filter[0]/)
#{
#say 'true';
#say ($content =~ /\n\n1\t.*$filter[0]/s);
#};


#$tokenized = qx ( curl -F 'data=$content' -F 'output=vertical' -F model=czech http://lindat.mff.cuni.cz/services/morphodita/api/tokenize | PYTHONIOENCODING=utf-8 python -c "import sys,json; sys.stdout.write(json.load(sys.stdin)['result'])");
#$tokenized =~ s/^\x{feff}//;
#$tokenized =~ s/^\n//;
#	$mor_result = qx ( curl -F 'data=$tokenized' -F 'input=vertical'  -F 'output=vertical' -F model=czech http://lindat.mff.cuni.cz/services/morphodita/api/tag | PYTHONIOENCODING=utf-8 python -c "import sys,json; sys.stdout.write(json.load(sys.stdin)['result'])");
#$result_morp = $mor_result;
#	$ud_json =  qx( curl -F 'data=$tokenized' -F input=vertical -F model=czech -F tokenizer= -F tagger= -F parser= http://lindat.mff.cuni.cz/services/udpipe/api/process | PYTHONIOENCODING=utf-8 python -c "import sys,json; sys.stdout.write(json.load(sys.stdin)['result'])");
#$ud_json =~ s/\#.+\n//g; #remove comments
#$ud_json =~ s/\n/\t$id\n/g; #adds id of file, can't catch ^ or $ :( ...
#$result_ud = $ud_json;

#write_to_temp('morp_temp',$result_morp,'morphodita out');
#return ($result_ud, $result_morp);
#}


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





