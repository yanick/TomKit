use 5.008006;
use ExtUtils::MakeMaker;

use Apache::TestMM qw(test clean);
# prerequisites
my %require =
(
	"Apache::Test"    => "",     # any version will do
	"mod_perl2"       => "",     # any version will do
	"XML::LibXML"     => "1.59", # new callback mechanism
	"XML::LibXSLT"    => "1.59", # new callback mechanism
	"APR::Request"    => "",     # any version will to
);

my @scripts = qw(t/TEST t/tmp);
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache2::TomKit',
    VERSION_FROM      => 'lib/Apache2/TomKit.pm', 
    PREREQ_PM         => \%require,
    clean             => {
    						FILES => "@{ clean_files() }",
                         },
    ($] >= 5.005 ?     
      ( AUTHOR         => 'Tom Schindl <tom.schindl@bestsolution.at>') : ()),
);

sub clean_files {
	return [@scripts];
}
