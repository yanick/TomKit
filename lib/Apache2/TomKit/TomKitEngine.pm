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

package Apache2::TomKit::TomKitEngine;

use strict;
use warnings;

use Apache2::Filter ();
use Apache2::RequestRec ();
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use APR::Table ();

use XML::LibXML;
use XML::SAX::ParserFactory;

use constant BUFF_LEN => 1024;


sub handler {
    my $f    = shift;

    if( ! defined $f->ctx() ) {
        my $inputXML = "";
        $f->r->headers_out->unset("Content-Length");
        $f->ctx($inputXML);
    }

    while( $f->read(my $buffer, BUFF_LEN) ) {
        $f->ctx( $f->ctx() . $buffer );
    }

    if( $f->seen_eos ) {
    	eval {
    		runEngine($f);
    	};
    	
    	if( $@ ) {
    		$f->r->pnotes( "AxKitConfig" )->{apr}->log_error($@);
		$f->r->status( Apache2::Const::SERVER_ERROR );
    	}
    }

    return Apache2::Const::OK;
}

sub runEngine {
    my $f = shift;
    my $r = $f->r;

    my $config  = $r->pnotes( "AxKitConfig" );
    my $logging = $r->pnotes( "AxKitLogging" );

    my $processor;
    my $chain = $r->pnotes("AxProcessorChain");

    if( $config->getNoCache() == 1 ) {
        &Apache2::TomKit::Util::setUpProcessor($chain,$logging,$config);
    }

    my @processorChain = @{ $chain->{chain} };

    my $cacheEntry = $r->pnotes( "AxCacheEntry" );
    my $cache      = $r->pnotes( "AxCache"      );

    if( scalar @processorChain == 0 ) {
        $logging->debug(8,"There hasn't been a processor chain set up for us. We need to do it now!");
        my $handler = new Apache2::TomKit::TomKitEngine::SAXFilter($chain,$logging,$config);
        my $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
        $parser->parse_string($f->ctx());
        @processorChain = @{ $chain->{chain} };
    }

    ## THIS IS USED WHEN WE HAVE A CUSTOM PROVIDER AND WANT WE WANT TO AVOID THE
    ## TRANSFORMATION ;-)
    if( ! defined $cacheEntry && defined $cache && defined $r->notes()->{AxMTime} ) {
        $logging->debug(8,"Although this is a custom content provider we could try to avoid the transformation.");
        my $mtime = $r->notes()->{AxMTime};
        $logging->debug(8,"The MTime: " . $mtime );
        $cacheEntry = $cache->deliverFromCacheImpl( $mtime, $chain );
        @processorChain = @{ $chain->{chain} };
    }

    if( defined $cacheEntry && $cacheEntry->{isCached} ) {
        $logging->debug(8,"We can deliver the cached content:" . $cacheEntry->{isCached});
        $r->content_type($cacheEntry->{processorChain}->{chain}->[-1]->getContentType());
        $f->print( $cacheEntry->{content} );
    } else {
        my $parser = new XML::LibXML();

        local($XML::LibXML::match_cb, $XML::LibXML::open_cb,
              $XML::LibXML::read_cb, $XML::LibXML::close_cb
             );

        if( defined $cacheEntry ) {
            my $util = Apache2::TomKit::Util::LibXML->new( $cacheEntry, $logging, $config );

            $XML::LibXML::match_cb = sub { return $util->match_cb(@_); };
            $XML::LibXML::open_cb  = sub { return $util->open_cb(@_); };
            $XML::LibXML::read_cb  = sub { return $util->read_cb(@_); };
            $XML::LibXML::close_cb = sub { return $util->close_cb(@_); };
        }

        my $dom    = $parser->parse_string( $f->ctx() );

        foreach( @processorChain ) {
            $_->setUp();
            $dom = $_->process($dom);

            if( $_->createsXML() && ! $_->createsDom() ) {
                $dom = $parser->parse_string();
            }

            $processor = $_;
        }

        if( defined $processor ) {
            $f->r->content_type( $processor->getContentType() );
        }

        if( $config->getNoCache() == 1 || ! defined $cacheEntry ) {
            $f->print( $dom->toString() );
        } else {
            my $content = $dom->toString();
            $cacheEntry->restore($content);
            $f->print( $content );
        }
    }
    
    $logging->debug(9, "======= Request is finished =======");
}

package Apache2::TomKit::TomKitEngine::SAXFilter;

use base qw(XML::SAX::Base);

sub new {
    my $class = shift;
    my $this = $class->SUPER::new();

    $this->{chain}  = shift;
    $this->{logger} = shift;
    $this->{config} = shift;

    return $this;
}

sub processing_instruction {
    my $this = shift;
    my $data = shift;

    $this->{logger}->debug( 10, "We found an processing instruction: " . (join ",", keys %{ $data } ) );
    $this->{logger}->debug( 10, "Target: " . $data->{Target} );
    $this->{logger}->debug( 10, "Data: " . $data->{Data} );

    $data->{Data} = " " . $data->{Data};
    $data->{Data} =~ /\s+href\s*=\s*"([^"]+)"/;

    my $href = $1;

    $data->{Data} =~ /\s+type\s*=\s*"([^"]+)"/;

    my $type = $1;
	
	if( ! $this->{config}->getNoCompilance() ) {
		$this->{chain}->add2chain( $type, $this->{config}->{apr}->document_root . "/" . $href );
	} else {
		$this->{chain}->add2chain( $type, $href );
	}
}

1;
