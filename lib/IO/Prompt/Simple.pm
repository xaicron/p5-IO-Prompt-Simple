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

    my $encoder = $opts->{encode} ? do {
        require Encode;
        Encode::find_encoding($opts->{encode});
    } : undef;

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
            $answer = $default;
            last;
        }
        $answer = <$in>;
        if (defined $answer) {
            chomp $answer;
        }
        else {
            print {$out} "\n";
        }

        $answer = $default if !defined $answer || $answer eq '';
        $answer = $encoder->decode($answer) if defined $encoder;
        if ($check_anyone) {
            last if $exclusive_map->{$ignore_case ? lc $answer : $answer};
            $answer = undef;
            print {$out} $hint;
            next;
        }
        elsif ($regexp) {
            last if $answer =~ $regexp;
            $answer = undef;
            print {$out} $hint;
            next;
        }
        last;
    }

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

IO::Prompt::Simple - provide a simple user input

=head1 SYNOPSIS

  # foo.pl
  use IO::Prompt::Simple;

  my $answer = prompt 'some question...';
  print "answer: $answer\n";

  # display prompt message, and wait your input.
  $ foo.pl
  some question: foo[Enter]
  answer: foo

=head1 DESCRIPTION

IO::Prompt::Simple is porting L<< ExtUtils::MakeMaker >>'s prompt() function.

Added a few more useful features.

THIS MODULE IS ALPHA LEVEL INTERFACE!!

=head1 FUNCTIONS

=head2 prompt($message, [$default, $option])

Display prompt message and wait your input.

  $answer = prompt $message;

Sets default value

  $answer = prompt 'sets default', 'def';
  is $answer, 'def';

Display like are:

  sets default [def]: [Enter]
  ...

supported options are:

=over

=item anyone: ARRAYREF

Choose any one.

  $answer = prompt 'choose', undef, { anyone => [qw/y n/] };

Display like are:

  choose (y/n) : [Enter]
  # Please answer `y` or `n`
  choose (y/n) : y[Enter]
  ...

=item regexp: STR | REGEXP

Sets regexp for answer.

  $answer = prompt 'regexp', undef, { regexp => '[0-9]{4}' };

Display like are:

  regexp : foo[Enter]
  # Please answer pattern (?^:[0-9{4}])
  regexp : 1234
  ...

It C<< regexp >> and C<< anyone >> is exclusive (C<< anyone >> is priority).

=item ignore_case: BOOL

Ignore case for anyone or regexp.

  # passed `Y` or `N`
  $answer = prompt 'ignore_case', undef, {
      anyone      => [qw/y n/],
      ignore_case => 1,
  };

=item use_default: BOOL

Force using for default value.
If not specified defaults to an empty string.

  $answer = prompt 'use default', 'foo', { use_default => 1 };
  is $answer, 'foo';

I think, CLI's C<< --force >> like option friendly.

=item input: FILEHANDLE

Sets input file handle (default: STDIN)

  $answer = prompt 'input from DATA', undef, { input => *DATA };
  is $answer, 'foobar';
  __DATA__
  foobar

=item output: FILEHANDLE

Sets output file handle (default: STDOUT)

  $answer = prompt 'output for file', undef, { output => $fh };

=item encode: STR | Encoder

Sets encodeing. If specified, returned a decoded string.

=back

=head1 NOTE

If prompt() detects that it is not running interactively
and there is nothing on C<< $input >>
or if the C<< $ENV{PERL_IOPS_USE_DEFAULT} >> is set to true
or C<< use_default >> option is set to true,
the C<< $default >> will be used without prompting.

This prevents automated processes from blocking on user input.

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
