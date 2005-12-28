package Apache2::TomKit::Processor::LibXSLTEnhanced;

use base qw( Apache2::TomKit::Processor::LibXSLT );

use XML::LibXML;
use XML::LibXSLT;

use Digest::MD5 qw(md5_hex);
use strict;
use warnings;

use base qw( Apache2::TomKit::Processor::AbstractProcessor );

use Apache2::TomKit::Processor::DefinitionProvider::FileSystemProvider;
use Apache2::TomKit::Util;

sub startUp {
    my $class  = shift;
    my $config = shift;

    foreach my $tagLib ( $config->getTagLibs() ) {
        XML::LibXSLT::Enhanced->loadCustomTagLib( $tagLib );
    }
}

sub shutDown {
    my $class  = shift;
    my $config = shift;

    XML::LibXSLT::Enhanced->unloadAllTagLibs();
}

sub setUp {
    my $this = shift;

    return if( $this->{stylesheet} );

    my $parser   = new XML::LibXML(); 
    my $xslt = XML::LibXSLT::Enhanced->new();

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

    my $stylesheet = $xslt->parse_stylesheet($style_doc, undef, $this->{config}->getXSLTEnhancedDynamicTagLibLoading());

    $this->{stylesheet} = $stylesheet;
}

1;