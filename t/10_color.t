use strict;
use warnings;
use Test::More;
use t::Util;
use Term::ANSIColor qw(colored);

test_prompt(
    input  => 'y',
    answer => 'y',
    opts   => { color => 'red' },
    prompt => colored(['red'], 'prompt ').': ',
    desc   => 'color (scalar)',
);

test_prompt(
    input  => 'y',
    answer => 'y',
    opts   => { color => ['red'] },
    prompt => colored(['red'], 'prompt ').': ',
    desc   => 'color (array)',
);

done_testing;
