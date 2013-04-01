#!/usr/bin/perl
# 
#  Based on doc_display.cgi from /opt/carsi/modules/common/cgi
#
#  Parameters: 
#  ARGV[0] = directory path to read
#  ARGV[1] = tmp directory path to write
#
use strict;
use warnings;

my $directory = '/opt/samba/data_comp/vol00019/20/553620';
my $dirpath = "";
my $temppathname = '/home/carsids/cyoes/test/tmp';
my $tempname;
my $outfilename;
my $line = "";
my $filename = "";
my @filenames;
my $count1;
my $magcookie;
my $majverno;
my $minverno;
my $numpage;
my $numcomp;
my $vbdirpos;
my $perldirpos;
my $len;
my $imfilenames;
my $imagefilename;
my $vbstartpos;
my $perlstartpos;
my $filelen;
my ($i,$j,$k);
my $blocksize;
my $numblocks;
my $partial_block_length;
my $partialbuff;
my $tiffbuff;


$directory = $ARGV[0] if (exists $ARGV[0]);
$temppathname = $ARGV[1] if (exists $ARGV[1]);

# Initialize all counters to zero.

$count1 = 0;

#  First find all image documents (suffix .000), which have the TIFF
#  images embedded in them.

 @filenames = `find $directory -type f`;
 
 foreach $line (@filenames)
{
	$count1++;
       ($dirpath, $filename) = $line =~m/(.*\/)(.*)$/;
	&extract_files($filename);
}

print "Nbr files read: $count1\n";

exit;

sub extract_files
{   
	#  Note!.  Opening two copies of document file so that can walk down the
	#  document file's internal directory at the same time that are walking down
	#  the image locations.  
	
	open(DOCFILE, '<', $dirpath  . $filename) || die "Can't open doc1  $filename: $!\n";
	open(DOCFILE2, '<', $dirpath  . $filename) || die "Can't open doc2 $filename: $!\n";
		
	$len = read(DOCFILE,$magcookie,8);
	$len = read(DOCFILE,$majverno,3);
	$len = read(DOCFILE,$minverno,3);
	$len = read(DOCFILE,$numpage,4);
	$len = read(DOCFILE,$numcomp,4);
	$len = read(DOCFILE,$vbdirpos,10);
	
	$perldirpos = $vbdirpos -1;
		
	#    Seek to the beginning of the Document file's internal directory.
		
	seek(DOCFILE,$perldirpos,0);
	$imfilenames = "";       
	
	for ($i=0;$i<$numpage;$i++)
	{
		#   For each entry in the directory of the document, get the information
		#   for the corresponding image file.  This includes the filename to use,
		#   the start position in this document file, and the file length.
		
		$len = read(DOCFILE,$imagefilename,12);
		$len = read(DOCFILE,$vbstartpos,10);
		$perlstartpos = $vbstartpos - 1;
		$len = read(DOCFILE,$filelen,10);

		extract_image_file();   
       
	}
} 
#end - sub extract_files

sub extract_image_file
{       
	# This subroutine will use the implicit parameters $imagefilename, $startpos,
	# and $filelen to extract the selected image file from the document file.	

	my $quotient = $filelen/512;	
	$numblocks = int($filelen/512);
	$partial_block_length = $filelen%512;    	
	
	if($filename =~ s/.000//)
	{
		$tempname = $filename.".TIF";
	}
	
	$outfilename = $temppathname . "/" .$tempname;
	
	open (IMAGEFILE,">$outfilename") || die "Cannot open $outfilename: $!\n";
	
	seek(DOCFILE2,$perlstartpos,0);
	
	$k = 0;
	$blocksize = 512;
	for ($j=0;$j<$numblocks;$j++)
	{ 
		# First read and write all of the complete blocks
		
		$len = read(DOCFILE2, $tiffbuff, 512);
		print(IMAGEFILE $tiffbuff);
		$k = $j;
	}
	
	# Next read and write the partial block (if there is one)
	
	if ($partial_block_length > 0)
	{
		$len = read(DOCFILE2, $partialbuff, $partial_block_length);
		print(IMAGEFILE $partialbuff);
	}
	# Finished with this file so close it.
	close(IMAGEFILE);
} 
#end - sub extract_image_file

