package Apache2::TomKit::Logging;

use Apache2::Request;
use Apache2::RequestRec;
use Apache2::Log;
use warnings;

sub new {
    my $class  = shift;
    my $config = shift;

    bless {
        debugLevel => ($config->getDebugLevel() || 0),
        apr        => $config->{apr}
    }, $class;
}

sub debug {
    my $this    = shift;
    my $level   = shift;
    my $message = shift;

    if( $level <= $this->{debugLevel} ) {
        $this->{apr}->log_error( $message );
    }
}

1;
