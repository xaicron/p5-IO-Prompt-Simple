use strict;
use warnings;
use Test::Requires 'Encode';
use Test::More;
use lib "./t";
use Util;

test_prompt(
    input  => "\x82\xA0",
    answer => "\x{3042}",
    opts   => {
        encode => 'cp932',
    },
    prompt => 'prompt : ',
    desc   => 'encode',
);

done_testing;
