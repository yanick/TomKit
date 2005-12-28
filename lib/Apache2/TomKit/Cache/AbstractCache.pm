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
        $config->{apr}->set_handlers("PerlResponseHandler" => sub { $provider->instanceHandler( $config->{apr} ) });
    } else {
        $logger->debug( 9, "Ok. It seems that the standard-apache is handling the source." );
        $mtime = $config->{apr}->finfo()->mtime();
        $logger->debug( 9, "Calculated mtime for " . $config->{apr}->filename().":" . $mtime );
    }

    if( $mtime < 0 ) {
#       &setUpProcessor($chain,$logger,$config,$config->getProcessorDefs());
        return undef ;
    } else {
        return $this->deliverFromCacheImpl( $mtime, $chain );
    }
}


1;