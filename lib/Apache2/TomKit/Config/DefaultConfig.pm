package Apache2::TomKit::Config::DefaultConfig;

use strict;
use warnings;

our $AUTOLOAD;

our %Config = (
    AxNoCache    => 0,
    XSLTEnhancedDynamicTagLibLoading => 0,
);

sub new {
    my $class = shift;
    my $apr   = shift;

    my $this = { apr => $apr, config => $apr->dir_config() };

    bless $this, $class;
}

sub getProcessorDefs {
    my $this = shift;
    my @processors = $this->{config}->get("AxAddProcessorDef");

    return @processors;
}

sub getProcessorsMap {
    my $this = shift;
    my @processorsMap = $this->{config}->get("AxAddProcessorMap");

    return @processorsMap;
}

sub getTagLibs {
    my $this = shift;
    my @taglibs = $this->{config}->get("AxAddXSPTaglib");

    return @taglibs;
}

sub AUTOLOAD {
    ## todo insert method for next time
    my $this = shift;
    my ($methodName) = $AUTOLOAD =~ /get(\w+)$/;

    if( defined  $methodName) {
        $methodName = "Ax$methodName";
        my $configValue = $this->{config}->{$methodName};

        if( ! defined $configValue ) {
            $configValue = $Config{$methodName};
        }

        return $configValue;
    }
}

1;
