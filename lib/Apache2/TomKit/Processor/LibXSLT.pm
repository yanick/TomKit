## -----------------------------------------------------------------
## Copyright (c) 2005-2006 BestSolution.at EDV Systemhaus GmbH
## All Rights Reserved.
##
## BestSolution.at GmbH MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT THE
## SUITABILITY OF THE SOFTWARE, EITHER EXPRESS OR IMPLIED, INCLUDING
## BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.
## BestSolution.at GmbH SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY
## LICENSEE AS A RESULT OF USING, MODIFYING OR DISTRIBUTING THIS
## SOFTWARE OR ITS DERIVATIVES.
## ----------------------------------------------------------------
##
## This library is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself, either Perl version 5.8.6 or,
## at your option, any later version of Perl 5 you may have available.
##

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

    my $util = Apache2::TomKit::Util::LibXML->new( $this, $this->{logger}, $this->{config} );
    

    $this->{logger}->debug(10,"Start parsing XSL-Stylesheet");

    my $style_doc;

    $style_doc = $parser->parse_string( $this->{processordef}->getContent() );
    
    my $stylesheet = $xslt->parse_stylesheet($style_doc);
    
    my $input_callbacks = XML::LibXML::InputCallback->new();
    $input_callbacks->register_callbacks([ sub { return $util->match_cb(@_); }, sub { return $util->open_cb(@_); }, sub { return $util->read_cb(@_); }, sub { return $util->close_cb(@_); } ]);
    $stylesheet->input_callbacks( $input_callbacks );

    $this->{logger}->debug(10,"End parsing XSL-Stylesheet");

    $this->{stylesheet} = $stylesheet;
}


sub process {
    my $this = shift;
    my $input = shift;

    $this->{logger}->debug(9,"LibXSLT: Is processing the source with stylesheet: " . $this->{processordef} );
    $this->{logger}->debug(9,"INPUT: " . $input->toString() );

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
