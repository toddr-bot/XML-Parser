use strict;
use warnings;
use Test::More tests => 4;

use XML::Parser;

# GH#101 — xpcarp() and setHandlers() used single quotes, preventing
# variable interpolation of $line and $type respectively.

# Test 1-2: xpcarp() should interpolate $line (not literal '$line')
{
    my $xml    = '<root>text</root>';
    my $parser = XML::Parser->new(
        Handlers => {
            Start => sub {
                my $expat = shift;
                $expat->xpcarp("test warning");
            },
        },
    );

    my $warning = '';
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    $parser->parse($xml);

    like( $warning, qr/at line \d+/,
        'xpcarp message contains interpolated line number' );
    unlike( $warning, qr/\$line/,
        'xpcarp message does not contain literal $line' );
}

# Test 3-4: setHandlers() on Expat object should interpolate $type in error
# We trigger this by parsing XML with a Start handler that calls setHandlers
# on the Expat object with an invalid (non-coderef) handler.
{
    my $err = '';
    my $parser = XML::Parser->new(
        Handlers => {
            Start => sub {
                my $expat = shift;
                $expat->setHandlers( Char => 'not_a_coderef' );
            },
        },
    );
    eval { $parser->parse('<root/>'); };
    $err = $@ || '';

    like( $err, qr/Handler for Char not a Code ref/,
        'setHandlers error contains interpolated handler type' );
    unlike( $err, qr/\$type/,
        'setHandlers error does not contain literal $type' );
}
