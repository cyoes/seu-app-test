#!/usr/bin/perl 

# SEbdms.pl
# Module to get directory path, filename, 
# header line from scanned files.
# Write output to file for use by subsequent
# module(s).
#
# Author: CY
#
#  Parameters: $ARGV[0] = optional dirpath to scan
#              Default is /opt/samba/data_comp/
#

use strict;
use warnings;
use DBI;

sub get_carsid;

my $base_dirpath = "/opt/samba/data_comp/";
my $dirpath;
my $fullpath;           # dirpath plus filename 
my @filenames;          # list of files in scan docs directories
my $line;                  
my $text_header;
my $binary_header;
my $output = "scan_docs.txt";             
my @delimarray;
my $delimstring;
my $count1;
my $count2;

# metadata fields to capture 

my $doc_no;
my $image_sys;
my $doc_code;
my $scan_date;
my $purge_date;
my $hold1;
my $security_cd;
my $hold2;
my $loc_of_orig;

my @data;
my $carsid;
my $yr;
my $sess;

# Initialize all counters to zero.

($count1, $count2) = 0;

# If user entered a specific directory to scan,
# use that. Otherwise, read entire tree.

$dirpath = $base_dirpath;
$dirpath = $ARGV[0] if (exists $ARGV[0]);

# Get file names from scanned doc directories

@filenames = `find $dirpath -type f`;

# Separate directory and filename in each line.
# Check each file for header data elements.

foreach $line (@filenames)
{
	if ($line =~ /\/(\d*)\.000/)
	{
		$count1++;
	}	
	# Grab path before we split it out
	$fullpath = $line;   
	
	# There are some recs with header only but no
	# image data. They will fail the line mapping
	# assignment below, so initialize $header_data to
	# avoid error.
	
	my $header_data = "";
	my ($directory, $filename) = $line =~m/(.*\/)(.*)$/;
	$header_data = `grep "||" $fullpath`;
	
	#  Pattern for data shows that common element at end of header
	#  string is 'II*' -- everything after that is binary and
	#  needs to be removed.
	
	($text_header,$binary_header) = split(/II*/,$header_data);
	
	#  And we don't need the data at the beginning of the
	#  string (cookie).
	
	my $table_data = substr($text_header,68,218);
	
	#  The fields we actually need are fixed-width
	#  so use unpack() to get them out.
	
	my $format = 'a6 a4 a8 a10 a10 a33 a8 a26 a5'; 
	
	($doc_no, $image_sys, $doc_code, $scan_date, $purge_date, 
		$hold1, $security_cd, $hold2, $loc_of_orig) = unpack($format, $table_data);
		
		get_carsid($doc_no);
		
		# Concatenate path with characters the import utility expects.
		
		$fullpath = '@@C:' . $fullpath;
		
		# Note: session and year are always null for COMP documents.

		$delimstring = join('|', $carsid, $scan_date, $sess, $yr, "CARS DOC # $doc_no $doc_code", $fullpath);
		
		
		if (defined $delimstring && $delimstring ne ' ')
		{	
			open FILE2, ">>$output" or die "couldn't open file";
			
			print FILE2 $delimstring;
			$count2++;
			
			close(FILE2);
		}		
}

print "Records read: $count1\n";
print "Output recs written: $count2\n";

exit;

sub get_carsid
{
	my $dbh = DBI->connect("dbi:Informix:$ENV{CARSDB}",
		undef, undef, {AutoCommit => 0})
	or die 'Could not connect to database: ' . DBI->errstr();
	
	my $sth = $dbh->prepare("SELECT id,yr,sess FROM im_doc_rec WHERE doc_no = ?")
	or die "Couldn't prepare statement: " . $dbh->errstr();
	
	$sth->execute($doc_no)
	or die "Couldn't execute statement: " . $dbh->errstr();
	
	while (@data = $sth->fetchrow_array()){
		$carsid = $data[0];
		$yr     = $data[1];
		$sess   = $data[2];
	}

$dbh->disconnect;  

return $carsid;
return $yr;
return $sess;

}
