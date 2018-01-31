#!/usr/bin/perl
use List::Util qw(min max);
use List::Util qw(sum);

#convert the *.lats.post file(vector for each utt) into a matrix for each utt(like the output of a nnet-forward output)
#
open(LAT,"$ARGV[0]") or die "input:lat.1.phone.post,map_root_phones_vs_dep_phones.int num_of_phones/classes output:lats.phone.posts"; #lats.pdf.post: without utt id, starting with "[", and the posts all from lats.1.gz, not from best paths
open(MAP,"$ARGV[1]");# 42 phonemes(pdf-to-phone)
open(OUT,">$ARGV[3]");

$num_of_phonemes=$ARGV[2];# 42 phones/ 12 phone classes

while(<MAP>)
{
 chomp;
 @arraymap=split/\s+/,$_;
 my $root=shift @arraymap;
 foreach my $dep_phone(@arraymap)
 {
  $hashmap{$dep_phone}=$root; #key:pdf-id value:phone-id 
 }
}
close MAP;

#$uttlat=0;
@all_lat=();
while(<LAT>)
{
 chomp;
 s/\]//g;
 @arraylat=split/\[/,$_; #[ is eliminated;
# $uttid=shift @arraylat;# utt-id
 $num=@arraylat;
 @{$array_all_lat[$uttlat]}=@arraylat;
 ++$uttlat;
 #print "utt is $arraylat[0]\n";
 #print "post_on_lats contains $num  frames\n";
}
close LAT;
#print "utt num is $uttlat\n";
$sum=0;

%hashphone=();
@array_phone_post=();
foreach $array_lat(@array_all_lat){ # per utterance
 $uttid=shift @$array_lat;
 print "uttid is $uttid\n";
foreach $k(@$array_lat) # per frame
{
  @arraykey=split/\s+/,$k;
  @arraykey=&splice_array_empty(@arraykey);
  $numkey=@arraykey;
  @array_phone_post=(0)x$num_of_phonemes;
  for (my $j=0;$j<$numkey;$j+=2)
  {
    $phone_id=$hashmap{$arraykey[$j]}; #root or phone_class id
    $phone_post=$arraykey[$j+1];
    if (exists $hashphone{$phone_id})
    {
	    $array_phone_post[$phone_id-1]+=$phone_post;
    }
    else
    {
      $array_phone_post[$phone_id-1]=$phone_post;
      $hashphone{$phone_id}=$phone_post;
    } 

  }
  #@array_phone_post=&smooth_phone_post_array(@array_phone_post);
  unshift @array_phone_post,$uttid;
  $string_phone_post=join(' ', @array_phone_post);
  $string_phone_post=~ s/^\s+|\s+$//g;
  print OUT $string_phone_post."\n";
  #print $string_phone_post."\n";
}
}
close OUT;
print "All done !\n";

sub splice_array_empty()
{
 @array=@_;
 $num=@array;
 for ($i=0;$i<$num;++$i)
 {
  if ($array[$i] eq "")
  {
   splice @array,$i,1;
  }
 }
 return @array;
}

sub smooth_phone_post_array() # write phone_post of each frame to a line in the whole matrix
{
  my @array=@_;
  my $max= max @array;

  my $epsilon=10 ** (-8);

  foreach my $key(@array)
  {
   if ($key eq 0)
   {
     $key=$epsilon;
   }
  }

  my $sum= sum @array;
  # print "sum is $sum\n";

  return @array;
}
