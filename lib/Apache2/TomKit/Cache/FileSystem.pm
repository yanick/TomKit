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

package Apache2::TomKit::Cache::FileSystem;

use strict;

use base qw( Apache2::TomKit::Cache::AbstractCache );

use Apache2::TomKit::Cache::Entry;
use File::Path;
use warnings;

sub new {
    my $class      = shift;
    my $logger     = shift;
    my $config     = shift;

    my $this = $class->SUPER::new($logger,$config);

    my $key      = $this->{keyBuilder}->buildKey();
    my $cacheDir = $this->{config}->getCacheDir();

    if ( ! defined $cacheDir ) {
        $cacheDir = File::Spec->tmpdir();
        $cacheDir .= "/axkit";
    }


    if( ! -e $cacheDir ) {
        mkpath $cacheDir;
    }

    $this->{key}       = $key;
    $this->{cachefile} = $cacheDir;

    $this->{logger}->debug( 9, "Setting up the cache with Filesystem in directory: " .  $cacheDir );

    return $this;
}

sub deliverFromCacheImpl {
    my $this           = shift;
    my $mtime          = shift;
    my $processorChain = shift;

    my $keyBuilder = new Apache2::TomKit::Cache::DefaultKeyBuilder( $this->{logger}, $this->{config} );
    my $key = $keyBuilder->buildKey();

    my $rv = new Apache2::TomKit::Cache::Entry( $this->{logger}, $key, $this, $processorChain );
    my $useCached = 1;

    if( -e $this->{cachefile} . "/$key" ) {
        my $docTime = (stat($this->{cachefile} . "/$key/content"))[9];

		$this->{logger}->debug( 9, "Content-File mtime (" . $mtime . ") < doctime(" . $docTime . ")"  );

        if ( $mtime < $docTime ) {
            my $i = 0;

			$this->{logger}->debug( 9, "Source document has not changed. Testing providers." );

            open( PROCESSORS, "<" . $this->{cachefile} . "/$key/processors" );
                my $time;
                my @loadtimes;
                my @processorDefs;

                while( my $processor = <PROCESSORS> ) {
                    chomp($processor);
                    my @tmp = split("#",$processor);
                    push @loadtimes, shift @tmp;
                    push @processorDefs, (join "=>",@tmp);
                }
            close( PROCESSORS );

            &Apache2::TomKit::Util::setUpProcessor($processorChain,$this->{logger},$this->{config},@processorDefs);
            my $loadtime;
			my $processor;

            foreach $processor ( @{ $processorChain->{chain} } ) {
                $loadtime = shift @loadtimes;
                $this->{logger}->debug( 9, "Load-Time: $loadtime => " . $processor->getMTime() );
                if( $loadtime >= $processor->getMTime() ) {
                    $useCached = 1;
                } else {
                    $useCached = 0;
                }

                last if ! $useCached;
            }

            ## now we check the dependencies
            if( $useCached ) {
                my @line;
                my $provider;
                my $mtime;
                my $definition;

                open(DEPS,"<". $this->{cachefile} . "/$key/dependencies");
                    while( <DEPS> ) {
                        ($loadtime,$provider,$definition) = split("#",$_);
                        chomp($definition);
                        $this->{logger}->debug( 7, "Checking $loadtime for: $provider => $definition" );
                        if( $loadtime >= $provider->new($this->{logger}, $this->{config}, $definition)->getMTime() ) {
                            $useCached = 1;
                        } else {
                            $useCached = 0;
                        }

                        last if ! $useCached;
                    }
                close(DEPS);
            }

            if ($useCached) {
                $this->{logger}->debug( 7, "We can use the cached file" );
                $rv->{isCached} = 1;
                local $/ = undef;
                open(CONTENT,"<" . $this->{cachefile} . "/$key/content");
                    $rv->{content}  = <CONTENT>;
                close(CONTENT);
            } else {
                $this->{logger}->debug( 7, "One of the dependencies must have changed. We can not use the cached content" );
            }
        } else {
            $this->{logger}->debug( 7, "The file timestamp is newer than the one of the last delivery. We need to recreate everything." );
            &Apache2::TomKit::Util::setUpProcessor($processorChain,$this->{logger},$this->{config},$this->{config}->getProcessorDefs());
        }
    } else {
        $this->{logger}->debug( 7, "No cache found. Set up everything from scratch!" );
        &Apache2::TomKit::Util::setUpProcessor($processorChain,$this->{logger},$this->{config},$this->{config}->getProcessorDefs());
    }

    return $rv;
}

sub restore {
    my $this       = shift;
    my $cacheEntry = shift;

    $this->{logger}->debug( 9, "Restoring the content in the cache for later retrevial" );

    if ( ! $cacheEntry->{isNew} ) {
        $this->{logger}->debug( 9, "Erasing old content");
        unlink $this->{cachefile} . "/" . $cacheEntry->{key};
    }

    mkdir $this->{cachefile} . "/". $cacheEntry->{key};

    open( CONTENT, ">".$this->{cachefile} . "/". $cacheEntry->{key} . "/content" );
        print CONTENT $cacheEntry->{content};
    close(CONTENT);

    open( PROCESSORS, ">" . $this->{cachefile} . "/". $cacheEntry->{key} . "/processors" );
        foreach ( @{ $cacheEntry->{processorChain}->{chain} } ) {
            $this->{logger}->debug( 9, "Restoring processor for document-id (".$cacheEntry->{key}.").");
            print PROCESSORS $_->getMTime() . "#" . $_->getMappingType() . "#" . $_->getProcessorDefinition() . "\n";
        }
    close( PROCESSORS );

    open( DEPENDENCIES, ">" . $this->{cachefile} . "/". $cacheEntry->{key} . "/dependencies" );
        foreach( $cacheEntry->getDependencies() ) {
            $this->{logger}->debug( 9, "Restoring dependency: " . $_ . " => " . $_->{definition} );
            print DEPENDENCIES $_->getMTime() . "#".ref( $_ ) . "#" . $_->{definition} . "\n";
        }
    close(DEPENDENCIES);
}

1;