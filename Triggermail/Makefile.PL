use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Sailthru',
    VERSION_FROM      => 'lib/Sailthru.pm',
    PREREQ_PM         => { Digest::MD5 => 0,
								   JSON::XS => 0,								
									LWP => 0,
									HTTP::Request => 0,
									URI::Escape => 0,
									Params::Validate => 0},
    ABSTRACT_FROM  => 'lib/Sailthru.pm',
    AUTHOR         => 'Sam Gerstenzang <sgerstenzang@stanford.edu>'
);
