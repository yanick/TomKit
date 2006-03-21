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

package Apache2::TomKit::Cache::AbstractCache;

use APR::Finfo ();
use Apache2::RequestRec ();

use strict;
use warnings;

sub new {
    my $class  = shift;
    my $logger = shift;
    my $config = shift;

    return bless { 
                    logger     => $logger, 
                    config     => $config,
                    keyBuilder => new Apache2::TomKit::Cache::DefaultKeyBuilder( $logger, $config )
                 }, $class;
}

sub deliverFromCache {
    my $this   = shift;
    my $chain  = shift;
    my $logger = $this->{logger};
    my $config = $this->{config};

    $logger->debug(9,"We try to deliver from cache");

    # my $keyBuilder = new Apache2::TomKit::Cache::DefaultKeyBuilder( $logger, $config );
    #my $keyBuilder = $this->{keyBuilder};
    #my $cache = new Apache2::TomKit::Cache::FileSystem( $logger, $config, $keyBuilder );

    my $mtime = -1;
    my $contentProvider = $config->getContentProvider();

    if( defined $config->{apr}->handler() ) {
        $logger->debug( 9, "There is some other handler let's to some more checking in future e.g. md5-based transforming" );
    } elsif( defined $contentProvider ) {
        $logger->debug( 9, "Oh. We have a custom content-provider :-). Pass on all available information to it." );
        &Apache2::TomKit::Util::loadModule( $contentProvider );
        my $provider = $contentProvider->new($logger,$config);
        $mtime = $provider->getMTime();
        $config->{apr}->handler("modperl");
        $config->{apr}->set_handlers("PerlResponseHandler" => sub { $provider->thandler( $config->{apr} ) });
    } else {
        $logger->debug( 9, "Ok. It seems that the standard-apache is handling the source." );
        $mtime = $config->{apr}->finfo()->mtime();
        $logger->debug( 9, "Calculated mtime for " . $config->{apr}->filename().":" . $mtime );
    }

    if( $mtime < 0 ) {
    	$logger->debug( 9, "There's no mtime known there no cache entry'" );
#       &setUpProcessor($chain,$logger,$config,$config->getProcessorDefs());
        return undef ;
    } else {
        return $this->deliverFromCacheImpl( $mtime, $chain );
    }
}


1;