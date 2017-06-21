use strict; # don't allow dangerous things
use warnings; # when something goes wrong, let me know
use utf8; # allow UTF-8 in the source code
#use open qw(:utf8 :std); #set inputs and outputs to UTF-8
use Encode;
use open qw( :encoding(UTF-8) :std);
use v5.16; # modern features and better Unicode support
use JSON::PP;



#########################
#finds problematic sentences
#in: temp_file from UDPIPE, conllu
#out: @sentences, contains d-d parts
#########################

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
 if ($row =~ /^\d+-\d+/)
	#if row starts with d-d\t
  {
   #say $row;
   $flagin = 1;
  }
 elsif($row =~ /^$/)
  {
   #if blank row, separation of sentences and sentence contains d-d token;
   if ($flagin == 1)
    {
    $sentences[$i] = $buffer;
    $i++;
    }
   $buffer = "";
   $flagin = 0;
  }
}

#say join("\n", @sentences);
#say $i;


#################
#in:  @sentences / one problematic sentence, multi lines per id
#out: @new_tokens - one token per array(id), with joined section of d-d, d, d+1
#joining: id/new, token from X-N[1], lemma from N[3], pos X[4], features X[6], next empty columns;   
#out: temp file with original tokens, $i of sentence
#################
$i = 0;

foreach my $sentence_problem (@sentences)
{
#my @tokens = split ("\n", $sentences[0]); 

my @tokens = split ("\n", $sentence_problem); 
my @new_tokens = ();
my $token_id = 1;
my $new_id = 1;
my $tokens_row = "";


while ($token_id<=(scalar @tokens))
{
 $tokens_row = $tokens[$token_id-1];
# say $tokens_row;
 my @r1 = split ("\t", $tokens_row);
 
 if($tokens_row =~ /^\d+-\d+/)
 {
	#can't do lookahead with regex, only part =~ /\n\d+-\d.*?\d+\t[\.\?\!].*?\n/sg from d-d to the end line the last sentence \d\t\.\t;
  my @r2 = split ("\t", $tokens[$token_id]);
  my @r3 = split ("\t", $tokens[$token_id+1]);

  $new_tokens[$new_id] = $new_id."\t".$r1[1]."\t".'_^('.$r2[1].'-'.$r2[3].', '.$r3[1].'-'.$r3[2].'-'.$r3[3].')'."\t".$r3[3]."\t".$r3[4]."\t".$r3[5]."\t_\t_\t_\t_";
#  say $tokens_row;
#  say $tokens[$token_id];
#  say $tokens[$token_id+1];
  my $removed_part = $tokens_row."\n".$tokens[$token_id]."\n".$tokens[$token_id+1];
  write_to_temp(('edited/'.($i+1).'_token_divided'), $removed_part, 'removed tokens saved to file: '.('edited/'.($i+1).'_token_divided'));
  $i++;
# say 'new: ', $new_tokens[$new_id];
  $token_id = $token_id + 2;	
}
 else
{
  #say 'old: ', $tokens_row;
  $r1[0] = $new_id;
  $r1[6] = "_";
  pop @r1;
  $new_tokens[$new_id] = join("\t", @r1);
  
 #say 'new: ', $new_tokens[$new_id];
 }

$new_id++;
$token_id++;
}

#say scalar @tokens;
#say $new_id;

say 'sentence:', $i,', tokens: ' , scalar @new_tokens;



#################
#in: @new_tokens, duplicates and clean for parsitko api for rearanging of the dependency tree;
#out: 
#################
#write_to_temp('for_parsito', join("\n", @new_tokens),'ddd');

splice @new_tokens, 0,1;
#say $new_tokens[0];
my $conllu = join("\n", @new_tokens);

my $new_tree = qx ( curl -F 'data=$conllu' -F model=czech http://lindat.mff.cuni.cz/services/parsito/api/parse | PYTHONIOENCODING=utf-8 python -c "import sys,json; sys.stdout.write(json.load(sys.stdin)['result'])");


#say "after:\n" , $new_tree;
write_to_temp(('edited/'.$i.'_parsito_edited_tokens'), $new_tree ,('created file: '.('edited/'.$i.'_parsito_edited_tokens')));

} #end foreach sentence











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
say $msg, ' -  done';
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
#argv[0] / array metadata 
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





