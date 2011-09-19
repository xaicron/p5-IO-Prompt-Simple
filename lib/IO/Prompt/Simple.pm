package IO::Prompt::Simple;

use strict;
use warnings;
use 5.008_001;
use base 'Exporter';

our $VERSION = '0.01';

our @EXPORT = 'prompt';

sub prompt {
    my ($message, $default, $opts) = @_;
    _croak('Usage: prompt($message, [$default, $opts])') unless defined $message;

    my $dispaly_default = defined $default ? "[$default]: " : ': ';
    $default = defined $default ? $default : '';

    $opts ||= {};
    my $in  = _is_fh($opts->{input})  ? $opts->{input}  : *STDIN;
    my $out = _is_fh($opts->{output}) ? $opts->{output} : *STDOUT;

    my $ignore_case = $opts->{ignore_case} ? 1 : 0;
    my ($regexp, $hint);
    my ($exclusive_map, $check_anyone) = ({}, 0);
    if (ref $opts->{anyone} eq 'ARRAY' && @{$opts->{anyone}}) {
        my @anyone = _uniq(@{$opts->{anyone}});
        for my $stuff (@anyone) {
            $exclusive_map->{$ignore_case ? lc $stuff : $stuff} = 1;
        }
        $check_anyone = 1;
        $hint     = sprintf "# Please answer %s\n", join ' or ', map qq{`$_`}, @anyone;
        $message .= sprintf ' (%s)', join '/', @anyone;
    }
    elsif ($opts->{regexp}) {
        $regexp = ref $opts->{regexp} eq 'Regexp' ? $opts->{regexp}
            : $ignore_case ? qr/$opts->{regexp}/i : qr/$opts->{regexp}/;
        $hint   = sprintf "# Please answer pattern %s\n", $regexp;
        $regexp = qr/\A $regexp \Z/x;
    }

    # autoflush and reset format for output
    my $org_out = select $out;
    local $| = 1;
    local $\;
    select $org_out;

    my $isa_tty = _isa_tty($in, $out);
    my $use_default = $opts->{use_default} ? 1 : 0;
    my $answer;
    while (1) {
        print {$out} "$message $dispaly_default";
        if ($ENV{PERL_IOPS_USE_DEFAULT} || $use_default || (!$isa_tty && eof $in)) {
            print {$out} "$default\n";
            last;
        }
        $answer = <$in>;
        if (defined $answer) {
            chomp $answer;
        }
        else {
            print {$out} "\n";
        }

        if ($check_anyone) {
            last if defined $answer
                && $exclusive_map->{$ignore_case ? lc $answer : $answer};
            $answer = undef;;
            print {$out} $hint;
            next;
        }
        elsif ($regexp) {
            last if defined $answer && $answer =~ $regexp;
            $answer = undef;
            print {$out} $hint;
            next;
        }
        last;
    }

    $answer = $default if !defined $answer || $answer eq '';
    return $answer;
}

# using IO::Interactive::is_interactive() ?
sub _isa_tty {
    my ($in, $out) = @_;
    return -t $in && (-t $out || !(-f $out || -c $out)) ? 1 : 0; ## no critic
}

# taken from Test::Builder
sub _is_fh {
    my $maybe_fh = shift;
    return 0 unless defined $maybe_fh;

    return 1 if ref $maybe_fh  eq 'GLOB'; # its a glob ref
    return 1 if ref \$maybe_fh eq 'GLOB'; # its a glob

    return eval { $maybe_fh->isa('IO::Handle') }
        || eval { tied($maybe_fh)->can('TIEHANDLE') };
}

sub _uniq {
    my %h;
    grep !$h{$_}++, @_;
}

sub _croak {
    require Carp;
    Carp::croak(@_);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

IO::Prompt::Simple -

=head1 SYNOPSIS

  use IO::Prompt::Simple;

=head1 DESCRIPTION

IO::Prompt::Simple is

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
