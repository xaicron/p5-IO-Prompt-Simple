use strict;
use warnings;
use Test::More;
use lib "./t";
use Util;

test_prompt(
    input  => 'foo',
    answer => '',
    opts   => {
        anyone => [qw/y n/],
    },
    prompt => 'prompt (y/n) : foo
# Please answer `y` or `n`
prompt (y/n) : 
',
    isa_tty => 0,
    desc    => 'anyone (y/n), miss match',
);

done_testing;
