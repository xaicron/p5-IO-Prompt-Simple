use inc::Module::Install;
use Module::Install::AuthorTests;

name 'IO-Prompt-Simple';
all_from 'lib/IO/Prompt/Simple.pm';

#requires '';

test_requires 'Test::More', 0.96;

tests join q{ }, map { sprintf 't%s.t', '/*' x $_ } 1..3;
author_tests 'xt';

repository 'http://github.com/xaicron/p5-IO-Prompt-Simple/';
bugtracker 'http://github.com/xaicron/p5-IO-Prompt-Simple/issues';

WriteAll;
