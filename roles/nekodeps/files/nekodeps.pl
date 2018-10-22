#!/usr/bin/env perl
#
# Script to automatically generate download & install scripts
# for Nekoware packages of your choosing. The script ensures
# that you download both the packages you asked for and all
# their dependencies, and then runs inst on them.
#
# 1. To initialize directories and default config in current
#    location, run
#    nekodeps.pl --config
#
# 2. To install Nekoware wget which is required by the script,
#    (if you don't have it already), run
#    nekodeps.pl --bootstrap
#
# 3. To download new or updated descript.ion file (which
#    contains the list of available packages), run
#    nekodeps.pl --ion
#
# 4. And you're good to go! Run nekodeps.pl -l to see list of
#    available packages, or nekodeps.pl PACKAGE(s) to generate
#    the downloader/installer scripts for your packages.
#
# The generated install scripts will be named "install.sh" by
# default. When you run them, they download the packages you
# requested and their dependencies, and then run 'inst' on them.
#
# (The specific behaviors of everything can be controlled with
# command line switches -- see nekodeps.pl -h -- and by editing
# the config file conf/nekodeps.conf.)
#
# The script also runs on Linux, for package browsing and
# downloading. You just won't be able to run 'inst' of course,
# and the use of 'inst' is automatically switched off if the
# platform is not IRIX.
#
# Enjoy!
#
# Davor Ocelic, docelic@spinlocksolutions.com
# SPINLOCK Solutions, http://www.spinlocksolutions.com/
#
# SPINLOCK Techpubs (code, patches, documentation) --
#   http://techpubs.spinlocksolutions.com/
# Nekoware installer, nekodeps.pl --
#   http://techpubs.spinlocksolutions.com/irix/nekoware-installer/
#

#use warnings;
use strict;

my $DATE= '2016-04-11';
my $VERSION= '.4p0';

use Getopt::Long qw/GetOptions/;
use IO::Socket qw//;

autoflush STDERR;

# Load config, warn if files/directories missing
my $C= do './conf/nekodeps.conf';
my %C= $C ? %$C : ();

my $usage= qq{$0 [options] [PACKAGE...]

Options:
 -l            List available packages and exit
 -b <branch>   Specify branch (default: 'current')
 -o <filename> Specify output script filename (default: 'install.sh')
 --config      Create default nekodeps.pl directories and config files
 --bootstrap   Download and install Nekoware wget for use in download scripts
 --ion         Update descript.ion for a given branch
 -i | --no-i   Insert 'inst' invocation into download script (default: yes)
 -e | --no-e   Use -e (exit on error) in download script (default: yes)
 -s | --no-s   Display spinner when using built-in downloader (default: yes)
 -m <mirror>   Specify mirror to use (default: 'nekochan.net/nekoware')
 -d <command>  Specify downloader to use (default: wget -c --user-agent=Mozilla)
 -f            Force download and skip 'already downloaded' check (default: no)
 -v            Include dependencies in -l output (default: no)
 -h            Help (this message. More comments are within nekodeps.pl)
 --install     Download & install packages immediately, without creating a
                 download script (default: no). This option uses a built-in
                 downloader with no resume capability and is used implicitly
                 with --bootstrap. But you might prefer to use it instead of
                 creating download scripts.
};

unless( GetOptions(
	\%C,
	'inst|i!',
	'downloader|d=s',
	'e!',
	'branch|b=s',
	'mirrors|mirror|m=s@',
	'distdir|dist=s',
	'confdir|conf|c=s',
	'update_ion|update-ion|descript-ion|ion!',
	'bootstrap!',
	'list|l!',
	'help|h!',
	'config!',
	'spinner|s!',
	'force|f!',
	'install',
	'verbose|v!',
)) { die "Error parsing options: $!.\nUsage: $usage"}

if( $C{help}) {
	print qq{Usage: $usage\n};
	exit !$C{help}
}

if( $C{default_mirrors}) {
  @{$C{mirrors}} or $C{mirrors}= $C{default_mirrors};
}

{ my $cfg= "./conf/nekodeps.conf";
if( $C{config}) {
	warn "Creating dist directory ./dist/\n";
	mkdir './dist/', 0755;
	warn "Creating config directory ./conf/\n";
	mkdir './conf/', 0755;

	if( !-e $cfg) {
		warn "Creating default config file $cfg\n";
		open OUT, "> $cfg" or die "Can't wropen '$cfg' ($!); exiting.\n";
		print OUT <DATA>;
		close OUT or die "Can't wrclose '$cfg' ($!); exiting.\n";
	} else {
		warn "Config file $cfg found, not overwriting it. Delete and run again if you need a new one.\n";
	}
	warn "Now, on IRIX, run $0 --bootstrap to install Nekoware wget.\n";
	warn "On GNU/Linux, run $0 --ion to download descript.ion file.\n";
	exit 0
} else {
	if( !-d $C{distdir} or !-d $C{confdir} or !-e $cfg) {
		die "Please run $0 --config to create necessary files and directories.\n";
	}
}}

#use Data::Dumper;
#die Dumper \%C;

# Determine descript.ion file to use (dependent on the Nekoware branch)
my $pkgfile= "$C{confdir}/$C{branch}.ion";

# If wget is not there, bootstrap it.
if( !-x '/usr/nekoware/bin/wget' and !$C{bootstrap} and $C{check}) {
	warn "Nekoware wget not installed yet. Please run with option --bootstrap to install it or --no-check to skip this check.\n";
	exit 1;
}

# If .ion file not there, schedule it for download. (Eases first-time runs.)
if( !-e "$pkgfile" and !$C{update_ion}) {
	warn "No $pkgfile found. Please run with option --ion to download it.\n";
	exit 1;
}

# If user just requested ION file update, do that and exit.
if( $C{update_ion}) {
	warn "Updating $pkgfile (descript.ion) for branch '$C{branch}'\n";
  #system "$C{downloader} -O '$pkgfile' 'http://www.nekochan.net/nekoware/$C{branch}/descript.ion'";
  http_get( $C{mirrors}[0], "/$C{branch}/descript.ion", "$C{confdir}/$C{branch}.ion", 1);
  warn "You're good to go! You can now run $0 PACKAGE(S) or $0 -h\n";
	exit 0
}

# load package list from descript.ion
my( %packages, %dependencies);
open IN, "< $pkgfile" or die "Can't rdopen '$pkgfile' ($!); exiting.\n";
while( $_= <IN>) {

	$_= fix_ion_line( $_);

	chomp;
	my @f= split /\t/;
	my @deps= @f== 5 ? split /,/, $f[4] : ();

	# So now we got:
	# @f= filename, package name, internal version, MD5 sum,
	# @deps= list of dependencies, if any

	# And we save it in our data structure such as:
	# PKG NAME =>   FILENAME               INT.VER            MD5                    DEPS
	# apache => [ neko_apache-1.3.37.tardist, 3, 8951123561e75410e72195a0a06e92b4, [ expat]]
	$packages{$f[1]}= [ $f[0], $f[2], $f[3], [ @deps]];
}
close IN;

if( $C{bootstrap}) {
  push @ARGV, 'wget';
  $C{install}++;
}

# If only package listing required, do that and exit.
if( $C{list}) {
	#print join "\n", sort keys %packages;
  #use Data::Dumper;
  #print Dumper \%packages;
	my $fmt= "%-20s %4s  %s";
	printf STDERR $fmt, qw/PACKAGE PVER FILENAME/;
	printf STDERR "\n";
	for( sort keys %packages) {
		printf $fmt, $_, $packages{$_}[1], $packages{$_}[0];
    if( $C{verbose}) {
      print " (@{$packages{$_}[3]})";
    }
    print "\n";
	}
	exit 0
}

if( !@ARGV) {
	print qq{Usage: $usage\n};
	exit !$C{help}
}

# Now, simply treat all that is left on command line as package names
# that user wants to install.
my @pkgs= @ARGV;
my $pkgi= $#pkgs; # (Index of last specifically requested package)
my @files; # Files to download

for( my $i= 0; $i< @pkgs; $i++) {
	$_= $pkgs[$i];

	# This block pushes all the requested packages and their dependencies
	# to the list of files to download and install.
	if( my $p= $packages{$_}) {

		my $file= $$p[0];
		push @files, $file unless grep /^$file$/, @files;

		my $deps= $$p[3];
		for my $dep( @$deps) {
			push @pkgs, $dep unless grep /^$dep$/, @pkgs;
		}

	}	elsif( $i> $pkgi) {
		#warn "WARN: Package '$_' listed as dependency, but doesn't exist. Skipping it.\n";
		splice @pkgs, $i, 1;
		redo

	}	else {
		# If package as specified does not exist, try producing a regex match
		# out of its nonexistent name and see if there are any close matches
		# available. E.g. 'apac' finds apache2_prefork, etc. If any found,
		# display them to the user as suggestions.
		( my $rm= $_)=~ s/[\W_]/./g;
		my @choices= sort grep /$rm/, keys( %packages);
		warn "Package name '$_' not found.\n";
		if( @choices) {
		local $"= "\n  ";
			warn "Did you mean one of:\n  @choices\n? If so, please correct your input.\n";
		}
		die "Exiting.\n";
	}
}

# At this point we know what the requested packages were, and what
# the dependencies were. As such, if this was ran as part of a
# bootstrap, download these files using an internal downloader and
# install them rather than generating a download script.
# Similarly, do the same if option --install is manually specified.
#
# For effectiveness, this logic is built-in into the below code,
# rather than being present separately.

#warn "Will download; @pkgs\n";

# Finally, produce the resulting shell script that automatically
# downloads (and installs unless --no-inst) selected Nekoware packages.
# (Or download using a built-in installer and run it, if --bootstrap or
# --install are specified.)

my @mirrors= @{$C{mirrors}};

if( !$C{install}) {
  open OUT, "> $C{output}" or die "Can't wropen '$C{output}' ($!); exiting.\n";
  print OUT qq{#!/bin/sh${\($C{e}?' -e':'')}
#
# Auto-generated script for SGI IRIX NEKOWARE package
# download and install with dependencies.
#
# http://techpubs.spinlocksolutions.com/irix/nekoware-installer/
#
# Davor Ocelic, docelic\@spinlocksolutions.com
# http://www.spinlocksolutions.com/
#
# Nekochan, http://www.nekochan.net/
#
# Requested packages:
#  ${\( join "\n#  ", @pkgs[0..$pkgi] )}
#
# Calculated dependencies:
#  ${\( join "\n#  ", @pkgs[($pkgi+ 1)..$#pkgs] )}
#

};
}

my $lc;
my $ret= "# Download requested packages:\n";
for ( my $i= 0; $i<@files; $i++) {
  $_ = $files[$i];

  if ($i== $pkgi+ 1 ) {
    $ret .= "\n# Download dependency packages:\n";
  }

  my ( $loc, %seen );

  my $lc2= 0;
  do {
    $loc = $mirrors[int rand($#mirrors+1)];
  } while ( ( !$loc ) and $lc2++ < 2000);
  if ( $lc2 >= 2000 ) {
    # Just some weird safety
    die "Uncommon error; try fixing your mirrors list. Exiting.\n";
    last
  }

  my $downloader = $C{downloader};
  $ret .= "$downloader -c -O '$C{distdir}/$_' \\\n  '$loc/$C{branch}/$_'\n";
  if( $C{install}) {
    http_get( $loc, "/$C{branch}/$_", "$C{distdir}/$_", $C{force});
  }
}

if( !$C{install}) {
  print OUT $ret;

  if( $C{inst}) {
    print OUT qq{
  # Finally, run inst:
  cd '$C{distdir}' && /usr/sbin/inst \\
  ${\( join " \\\n", map {"  -a -f '$_'"} @files )}
  }
  } else {
    print OUT "\n# Inst line not generated due to --no-inst.\n";
  }

  close OUT;
  chmod 0755, $C{output};
  warn "Created '$C{output}'.
Please run it to install your packages.\n";

} else {
  # We got here either through --bootstrap or someone's manual specification
  # of --install.
  my $cmd= qq{cd '$C{distdir}' && /usr/sbin/inst \\\n${\( join " \\\n", map {"  -a -f '$_'"} @files )}};
  $cmd.= "\n";
  if( $C{inst}&& $C{inst_host}) {
    system $cmd;
  } else {
    print "\n# Not running inst due to --no-inst.\n";
    print $cmd, "\n";
  }
}

###############################################################
# Helpers below

# Descript.ion file from Nekoware contains numerous formatting
# and data field bugs. This function corrects them on the fly.
my %seen;
sub fix_ion_line {
	local $_= shift;
	chomp;

	# Basic polishing
	s/no dependencies//;
	s/ /\t/g;

	# Split into fields and start work
	my @fields = split /\t/;
	if ( $. == 1 ) { goto PUSHFIELDS }

	# Remove any empty fields at the end to not distract us
	# (Not really needed though, split() above take care of that itself.)
	while( not( $fields[-1] and $fields[-1]=~ /\S/)) {
		#warn "INFO: $fields[0]: Removing empty field at the end.\n";
		pop @fields
	}

	# Skip duplicate entries
	!$seen{$fields[0]}++ or do {
		#warn "INFO: $fields[0]: Duplicate entry. First one takes precedence.\n";
		next
	};

	# Remove duplicate MD5 sums
	if( "$fields[-1]" eq "$fields[-2]")
	{
		#warn "INFO: $fields[0]: Duplicate MD5 sum field found. Removing it.\n";
		pop @fields;
	}

	# See if package name is missing, and if yes, add one.
	# NOTE: This will work as long as the row with no package name is
	# not also one in which package name contains "-" as part of the name.
	# (If it does, then the s/// below which removes everything after "-"
	# will produce and insert the incomplete name, e.g. c-ares would be "c".)
	if( $fields[1]=~ /^\d+$/ or length( $fields[1])== 32) {
		#warn "INFO: $fields[0]: Package name missing. Extracting and inserting it.\n";
		my $pfname= $fields[0];
		$pfname=~ s/^neko_//;
		$pfname=~ s/\-.*//;
		splice ( @fields, 1, 0, $pfname);
	}

	# Insert internal version numbers if missing
	unless ( $fields[2] =~ /^\d{1,3}$/ ) { # internal version is missing
		#warn "INFO: $fields[0]: Internal version missing. Inserting it.\n";
		splice ( @fields, 2, 0, 100); # Insert a fixed version of "100"
	}

	# Check for general well-formedness of rows
	unless( @fields>= 4 and @fields<= 5) {
		#warn "INFO: $fields[0]: Malformed row. Skipping it.\n";
		next;
	}

	PUSHFIELDS:
	$fields[$#fields] .= "\n";

	join("\t", @fields);
}

sub http_get {
  my( $host, $file, $out, $force)= @_;

  # Support for using this function to download files from mirrors which
  # include a subdirectory. In such cases, the subdir must become a part
  # of path, not hostname.
  if( $host=~ s#(/.*)##) { $file= $1. $file; }

  print STDERR "Downloading http://$host$file, size: ";
  my $socket = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => 'http(80)',
    Proto => 'tcp',)
  or die("Can't create IO::Socket::INET object ($!); exiting.");
  $socket->autoflush( 1);
  binmode $socket;

  print($socket "GET $file HTTP/1.0\r\nHost: $host\r\nUser-Agent: Mozilla/5.0 (nekodeps.pl)\r\n\r\n");
  my $line;
  my $len= 0;

  while( defined( $line= <$socket>)) {
    if( $len and $line=~ /^\s*$/) { last}
    elsif( $line=~ /^content-length:\s*(\d+)\s*$/i) {
      $len= $1;
      my $len_fmt= sprintf '%.2f', $len/ 1e6;
      print STDERR "$len_fmt MB\n";

      if( !$force and -e "$out" and (stat("$out"))[7]== $len) {
        print STDERR "  ($file already downloaded to $out; skipping.)\n";
        goto NEXT_FILE
      }

      open OUT, "> $out" or die "Can't wropen '$out' ($!); exiting.\n";
      binmode OUT;
    }
  }
  if( !$len) { die "Error downloading $_; exiting.\n"; }

  my $data;
  my $downloaded= 0;
  my $chunk= 0;
  my @spinner= qw( | / - \ | / - \ );
  my $spinner= 0;
  my $len_fmt= '0.00';
  print STDERR 'Downloaded: 0.00 MB |' if $C{spinner};
  while( defined( $data= <$socket>)) {
    my $len= length($data);
    $chunk+= $len;
    $spinner= ($spinner+1) % $#spinner;
    $downloaded+= $len;
    if( $chunk>= 1024* 128) {
      $chunk= 0;
      $len_fmt= sprintf '%.2f', $downloaded/ 1e6;
    }
    print STDERR "\rDownloaded: $len_fmt MB $spinner[$spinner]" if $C{spinner};
    print OUT $data
  }
  $len_fmt= sprintf '%.2f', $downloaded/ 1e6;
  print STDERR "\rDownloaded: $len_fmt MB $spinner[$spinner]\n" if $C{spinner};

  close OUT or warn "Can't wrclose '$out' ($!); ignoring and continuing.\n";

  NEXT_FILE:
  close $socket;
}

__DATA__
#!/usr/bin/perl
# This file is read directly from nekodeps.pl. It needs to be
# found in conf/nekodeps.conf relative to the current working
# directory from which nekodeps.pl is ran, and it needs to be
# a valid Perl file.

# The options here are defaults; all are overridable on the
# command line.

# Ignore these three
my $temp= '/usr/nekoware/bin/wget';
$temp= 'wget' unless -x $temp;
my $uname= `uname -a`;

# Config starts here
%C= (

	# Add automatic inst invocation in generated script?
	inst => 1,

	# (Could theoretically also use 'inst' for downloader, but
	# it is very buggy, and we do need other features of wget
	# not found in inst, so most probably don't change this.)
	downloader => $temp. ' --user-agent="Mozilla/5.0 (nekodeps.pl)"',

	# Use shell -e switch in generated downloader script. (-e
	# will exit the script on any error.)
	e => 1,

	# Default Nekoware branch: current/beta/nekoware-mips3/obsolete
	branch => 'current',

	# Directory for downloading all packages
	distdir => './dist',

	# Directory for saving/loading <branch>.ion files
	confdir => './conf',

	# Default filename to which download script should be output
	output => 'install.sh',

	# Check for presence of Nekoware wget and refuse to work if
	# not there?
	check => ( $uname=~ /IRIX/gis ? 1 : 0),

  # Use verbose mode? (Currently it only affects printing of
  # dependency lists in -l output)
	verbose => 0,

  # Show interactive spinner when using built-in downloader
  # instead of wget? (You might want to disable this if using
  # a serial console)
  spinner => 1,

	# List of HTTP mirrors without "/" or branch name at the end.
	# (But if the directory 'current/' is found in a subdirectory,
	# e.g. under /nekoware, then do specify those parent dir(s).)
  # E.g.: nekoware.dustytech.net, nekochan.net/nekoware
	default_mirrors => [
  'nekochan.net/nekoware',
  #'nekoware.dustytech.net',
	],

	# Most probably do not change these defaults
	mirrors => [],
	update_ion => 0,
	list => 0,
	help => 0,
	config => 0,
	inst_host => ( $uname=~ /IRIX/is ? 1 : 0),
);

# Don't remove nor change the following line:
\%C;
