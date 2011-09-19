package t::Util;

use strict;
use warnings;
use Test::More;
use base 'Exporter';
use IO::Prompt::Simple;

our @EXPORT = 'test_prompt';

sub test_prompt {
    my %specs = @_;
    my ($input, $answer, $prompt, $desc, $default, $opts) =
        @specs{qw/input answer prompt desc default opts/};

    $opts ||= {};
    $input = "$input\n" if defined $input;

    # using PerlIO::scalar
    open my $in, '<', \$input or die $!;
    open my $out, '>', \my $output or die $!;

    $opts->{input}  = $in;
    $opts->{output} = $out;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $line = (caller)[2];

    note "$desc at line $line"; do {
        my $got = prompt 'prompt', $default, $opts;
        if (ref $prompt eq 'Regexp') {
            like $output, $prompt, 'prompt ok';
        }
        else {
            is $output, $prompt, 'prompt ok';
        }
        is $got, $answer, 'expects ok';
    };
}

1;
