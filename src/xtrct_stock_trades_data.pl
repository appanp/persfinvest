#!/usr/bin/perl -w
#
# Script to extract data from the AxisDirect contract notes for trade.
# Takes the folder of PDF files as input argument
# Assumed that sensitive secrets are stored in env variables & run command:
# source ./secrets.sh
$num_args = $#ARGV + 1;
if ($num_args != 1) {
    print "\nUsage: xtrct_stock_trades_data.pl <PDF files folder>\n";
    exit;
}
print 
my $dir = $ARGV[0];
opendir my $dh, $dir or die "Could not open '$dir' for reading '$!'\ n";
open(my $f_output, '>:encoding(UTF-8)', 'stock_trans.csv');
# Output the field names as 1st row
print $f_output "Date,Order No.,Order Time,Trade No.,Trade Time,Company,Type,Quantity,Gross Rate per Unit,Brokerage per Unit, Net Rate per Unit, Net Total\n";
# Make temp directory if not present
if (!-d './temp') {
	mkdir './temp' or die "Error creating './temp' directory";
}
my @files = grep {$_ ne '.' and $_ ne '..' } readdir $dh;
foreach my $file (@files) {
	# First convert from PDF to text file
	#say "I/P file: $file";
	my $ftype = substr($file,-4);
	if ($ftype eq '.pdf') {
		my $inRows = 0, 
			 @currflds = (),
			 $opfile = substr($file,0,length($file)-4).".txt",
			 $upwd = $ENV{'contract_pwd'};
		system("pdftotext -nopgbrk -layout -upw $upwd ./$dir/$file ./temp/$opfile");
		open(my $fh, '<:encoding(UTF-8)', "./temp/$opfile")
  			or die "Could not open file '$opfile' $!";
		$file =~ m/(\d{2}-[a-zA-Z]{3}-\d{4})/;
		my $tdate = $1;
 		while (my $line = <$fh>) {
  		chomp $line;
			if ($line =~ /^$/) {
				next;
			}
			if ($line =~ m/NSE-Cash Normal/) {
				$inRows = 1;
				print "$file: Entering table rows\n";
			} 
			elsif ($inRows) {
			  #print $line."\n";
				$line =~ s/^\s*//g;
				if ($line =~ m/\s+(B|S)\s+/) {
				  if ($#currflds != -1) {
						print $f_output $tdate.','.join(',',@currflds)."\n";
						@currflds = ();
					}
					$line =~ s/\s+(B|S)\s+/,$1,/;
					#print $line."\n";
					# Split fields before & after company name
					# They do not have spaces
					$line =~ /^(.*)\s+(\d+:\d+:\d+)\s+([^,]+),(B|S),(.*)$/;
					my $p1 = $1, $date = $2, $co = $3, $ttype = $4, $p2 = $5;
					$p1 =~ s/\s+$//g;
					@currflds = split(/\s+/,$p1,3);
					$currflds[3] = $date;
					$currflds[4] = $co;
					$currflds[5] = $ttype;
					#print STDOUT join(',',@currflds);
					push(@currflds, split(/\s+/,$p2));
				} elsif ($line =~ m/BSE EQUITY\s+NSE EQUITY/i) {
					print $f_output $tdate.','.join(',',@currflds)."\n";
					$inRows = 0;
					print "$file: Leaving table rows\n";
					last;
				} elsif ($line !~ /Sub\s+Total|Page\s+\d+\s+of/) {
					$line =~ s/^\s+|\s+$//g;
					$currflds[4] = $currflds[4].' '.$line;
				} 
			}
		}
		close $file;
	}
}
closedir $dh;
