use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	             => 'Voxbone::VoxSMS',
    'AUTHOR'             => q{rnd <rnd@voxbone.com>},
    'PL_FILES'           => {},
    'PREREQ_PM' 	 => {
        'JSON::XS' => 0,
        'Data::UUID' => 0,
        'URI::Encode' => 0,
        'URI::Split' => 0,
        'LWP::UserAgent' => 0,
        'Data::Dumper' => 0,
        'Encode' => 0,
    },
    'CONFIGURE_REQUIRES' => {
        'ExtUtils::MakeMaker' => 0,
    },

);

