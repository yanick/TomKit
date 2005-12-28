package Apache2::TomKit::Cache::DefaultKeyBuilder;

use strict;
use Digest::MD5 qw( md5_hex );
use Apache2::RequestRec;
use Apache2::Cookie;
use warnings;

sub new {
    my $class  = shift;
    my $logger = shift;
    my $config = shift;

    bless { logger => $logger, config => $config }, $class;
}

sub buildKey {
    my $this = shift;
    my $host = $this->{config}->{apr}->hostname();
    my $uri  = $this->{config}->{apr}->uri();

    my $keySourceString = $host . $uri;

    ## add the request params to the key for caching
    if( $this->{config}->getEnableCGICache() ) {
        my @keys = $this->{config}->getCGICacheKeys();

        if( scalar @keys == 0 ) {
            @keys = $this->{config}->{apr}->param();
        }

        foreach( @keys ) {
            $keySourceString .= ";$_=>" . (join ",", $this->{config}->{apr}->param( $_ ) );
        }
    }

    ## add the cookie information to the caching key
    if( $this->{config}->getEnableCookieCache() ) {
        my @keys = $this->{config}->getCookieCacheKeys();
        my $j = Apache2::Cookie::Jar->new($this->{config}->{apr});

        if( scalar @keys == 0 ) {
            @keys = $j->cookies();
        }

        foreach( @keys ) {
            $keySourceString .= ";$_=>" . $j->cookies($_);
        }
    }

    ## TODO add the session information to the caching key
    my $md5 = md5_hex( $keySourceString );

    $this->{logger}->debug(9,"The key: " . $host . $uri . " => " . $md5 );

    return $md5;
}

1;