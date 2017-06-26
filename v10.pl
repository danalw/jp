use strict; # don't allow dangerous things
use warnings; # when something goes wrong, let me know
use utf8; # allow UTF-8 in the source code
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
my $waitforit = "";

#init
empty_output('t1'); 
empty_output('udpipe_temp');  
empty_output('morp_temp');  
empty_output('udpipe_temp2');

#for each .txt file in data/
for my $fc (@sourcenames)
{
 say "\nid: ", $i, ' file: ', $fc;
#($result_ud, $result_morp) = use_apis($fc, $i);
 use_apis($fc, $i);
 push @metadata, $fc;
 $i++; #file id 
}

clean_output_udpipe(); #affects only udpipe_temp, fixs blank lines starting with number;
say 'init and temps done.';
$waitforit= <>;

retrees();
say 'retrees done, edited files noted, and udpipe_temp2 created.';
$waitforit= <>;

combination_temps();

say 'number of files: ', scalar @metadata; 
metadata_add(\@metadata);



########################
##finds problematic sentences that contains divided tokens;
##in: temp_file from udpipe_temp 
##out: @sentences, contains d-d parts
##########################
sub retrees
{


open(my $fht, '<:encoding(UTF-8)', 'udpipe_temp')
   or die "Could not open file udpipe_temp  $!";

 my $selection = "";
 my @sentences = ();
 my $buffer = "";
 my $flagin = 0;
 my $i = 0;
 my $new_tree ="";
 my %old_new;

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
 close $fht;


#################
#in:  @sentences / one problematic sentence, multi lines per id
#out: @new_tokens - one token per array(id), with joined section of d-d, d, d+1
#joining: id/new, token from X-N[1], lemma from N[3], pos X[4], features X[6], next empty columns;   
#out: temp file with original tokens, $i of sentence
#################
 $i = 0;

 foreach my $sentence_problem (@sentences)
 {
my @tokens = split ("\n", $sentence_problem); 
my @new_tokens = ();
my $token_id = 1;
my $new_id = 1;
my $tokens_row = "";

  while ($token_id<=(scalar @tokens))
  {
   $tokens_row = $tokens[$token_id-1];
   my @r1 = split ("\t", $tokens_row);
    if($tokens_row =~ /^\d+-\d+/)
    {
    #can't do lookahead with regex, only part =~ /\n\d+-\d.*?\d+\t[\.\?\!].*?\n/sg from d-d to the end line the last sentence \d\t\.\t;
      my @r2 = split ("\t", $tokens[$token_id]);
      my @r3 = split ("\t", $tokens[$token_id+1]);
      $new_tokens[$new_id] = $new_id."\t".$r1[1]."\t".'_^('.$r2[1].'-'.$r2[3].', '.$r3[1].'-'.$r3[2].'-'.$r3[3].')'."\t".$r3[3]."\t".$r3[4]."\t".$r3[5]."\t_\t_\t_\t_";
      my $removed_part = $tokens_row."\n".$tokens[$token_id]."\n".$tokens[$token_id+1];
      write_to_temp(('edited/'.($i+1).'_token_divided'), $removed_part, 'removed tokens saved to file: '.('edited/'.($i+1).'_token_divided'));
      $i++; #counts sentences
      $token_id = $token_id + 2;	
    }
    else
    {
      $r1[0] = $new_id;
      $r1[6] = "_";
      pop @r1;
      $new_tokens[$new_id] = join("\t", @r1);
    }
   $new_id++;
   $token_id++;
  }

 say 'sentence:', $i,', tokens: ' , scalar @new_tokens;



#################
#in: for each @new_tokens
#out: $new_tree, for each sentence file in /edited with parsito new tree 
#################

 splice @new_tokens, 0,1; #removes blank line on the beginning
 my $conllu = join("\n", @new_tokens);

 $new_tree = qx ( curl -F 'data=$conllu' -F model=czech http://lindat.mff.cuni.cz/services/parsito/api/parse | PYTHONIOENCODING=utf-8 python -c "import sys,json; sys.stdout.write(json.load(sys.stdin)['result'])");

 $old_new{$sentences[($i-1)]} = $new_tree;
 write_to_temp(('edited/'.$i.'_parsito_edited_tokens'), $new_tree ,('created file: '.('edited/'.$i.'_parsito_edited_tokens')));

} #end foreach sentence


#########################
#blending of origin udpipe_temp + edited tokens with tree
#in: original selected @sentences, $new_tree edited sentences, udpipe_temp file
#out: udpipe_temp_edited
#########################
my $content;

open(my $fhc, '<:encoding(UTF-8)', 'udpipe_temp')
   or die "Could not open file udpipe_temp  $!";
 {  
  local $/;
  $content = <$fhc>;
 }
close($fhc);

 while((my $key, my $value) = each %old_new)
  {
   $content =~ s/\Q$key\E/$value/g;
  }
  append_to_temp('udpipe_temp2', $content,"\n\nfor check: vim -d udpipe_temp udpipe_temp2");


} #end sub retrees;



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

 append_to_temp('udpipe_temp',$result_ud,'udpipe out');
 append_to_temp('morp_temp',$result_morp,'morphodita out');

# return ($result_ud, $result_morp);
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
#Solves different blank lines after interpuction from morphodita
#in: udpipe_temp2 = udpipe with deleted divided tokens, with new tree
#out: file t1, merged udpipe_temp2 and morp_temp
##########################
sub combination_temps
{
my @result_ud = ();
my @result_morp = ();

open(my $fhu, '<:encoding(UTF-8)', 'udpipe_temp2')
   or die "Could not open file udpipe_temp2 $!";
 while (<$fhu>)
  {push (@result_ud, $_);
  }
 close($fhu);

open(my $fhm, '<:encoding(UTF-8)', 'morp_temp')
   or die "Could not open file morp_temp $!";
 while (<$fhm>)
  {push (@result_morp, $_);
  }
close($fhm);


#correction of blank lines/shifts from  morhpodita;
my $id_m = 0;
 for my $id_u (0..scalar @result_ud)
  {
   if ((($result_ud[$id_u]=~ /^$/)==1) && (($result_morp[$id_u]=~ /^$/)==0))
   {
    splice( @result_morp, $id_u, 0, "\n");
    next;
   };
   $id_m++;
  };


open (my $tf, '>>', 't1');
my $merged = "";
 for my $id_u (0..scalar @result_ud)
  {
   $result_morp[$id_u] =~ s/\n/$result_ud[$id_u]/;
   print $tf $result_morp[$id_u];
  }

} #end of sub


#########################
#[0] - name of output file
#[1] - content
#[3] - msg for log
#########################

sub append_to_temp
{
my $filename = $_[0];
my $result = $_[1];
my $msg = $_[2];

open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
 say $fh $result;
 close $fh; 
 say $msg, ': ', $filename, "\n";
}


#######################
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
 say $msg;
}

