use XML::LibXML;
use XML::LibXSLT;
use strict;

print "Started\n";

my $parser = new XML::LibXML();
my $content;

{
  local $/ = undef;
  open(XML,"<base.xml");
    $content = <XML>;
  close(XML);
}
print "Parsed\n";

my $contentDoc = $parser->parse_string($content);

{
  local $/ = undef;
  open(XML,"<base.xsl");
     $content = <XML>;
  close(XML);
}

print "XSL-Parsed\n";
my $xslt = new XML::LibXSLT();

my $callback = new XML::LibXML::InputCallback();
$callback->register_callbacks([\&match_cb,\&open_cb,\&read_cb,\&close_cb]);
$xslt->input_callbacks($callback);

my $styledoc = $parser->parse_string($content);
my $stylesheet = $xslt->parse_stylesheet($styledoc);

print "OUT-PUT: " . $stylesheet->transform($contentDoc)->toString() . "\n";

sub match_cb {
    my $uri = shift;
    print "Callback for: " . $uri . "\n";
    return 0;
}

sub open_cb {
}

sub read_cb {
}

sub close_cb {
}
