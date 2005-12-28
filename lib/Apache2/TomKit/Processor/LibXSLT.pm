package Apache2::TomKit::Processor::LibXSLT;

use XML::LibXML;
use XML::LibXSLT;

use Digest::MD5 qw(md5_hex);
use strict;
use warnings;

use base qw( Apache2::TomKit::Processor::AbstractProcessor );

use Apache2::TomKit::Processor::DefinitionProvider::FileSystemProvider;
use Apache2::TomKit::Util;

sub new {
    my $class          = shift;
    my $logger         = shift;
    my $config         = shift;
    my $processordef   = shift;
    my $getMappingType = shift;

    my $this = $class->SUPER::new($logger,$config);

    $this->{processordef}   = new Apache2::TomKit::Processor::DefinitionProvider::FileSystemProvider( $logger, $config, $processordef );
    $this->{stylesheet}     = undef;
    $this->{getMappingType} = $getMappingType;

    return $this;
}

sub init {
}

sub setUp {
    my $this = shift;

    return if( $this->{stylesheet} );

    my $parser   = new XML::LibXML(); 
    my $xslt = XML::LibXSLT->new();

    local($XML::LibXML::match_cb, $XML::LibXML::open_cb,
          $XML::LibXML::read_cb, $XML::LibXML::close_cb);

    my $util = Apache2::TomKit::Util::LibXML->new( $this );

    $XML::LibXML::match_cb = sub { return $util->match_cb(@_); };
    $XML::LibXML::open_cb  = sub { return $util->open_cb(@_); };
    $XML::LibXML::read_cb  = sub { return $util->read_cb(@_); };
    $XML::LibXML::close_cb = sub { return $util->close_cb(@_); };

    my $style_doc;

    if( $this->{processordef}->isFile() ) {
        $style_doc = $parser->parse_file( $this->{processordef}->getInstructions() );
    } else {
        $style_doc = $parser->parse_string( $this->{processordef}->getInstructions() );
    }

    my $stylesheet = $xslt->parse_stylesheet($style_doc);

    $this->{stylesheet} = $stylesheet;
}


sub process {
    my $this = shift;
    my $input = shift;

    $this->{logger}->debug(9,"LibXSLT: Is processing the source with stylesheet: " . $this->{processordef} );

    return $this->{stylesheet}->transform( $input );
}

sub getMTime {
    my $this = shift;
    return $this->{processordef}->getMTime();
}

sub createsXML {
    1;
}

#sub getKey {
#    return $_[0]->{processordef}->getMD5Key();
#}

sub createsDom {
    1;
}

sub getContentType {
    return "text/html";
}

sub getMappingType {
    return $_[0]->{getMappingType}
}

sub getProcessorDefinition {
    return $_[0]->{processordef}->getKey();
}

1;