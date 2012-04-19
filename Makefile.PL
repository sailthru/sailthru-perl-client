use ExtUtils::MakeMaker;
WriteMakefile(
	NAME         => 'Sailthru::Client',
	VERSION_FROM => 'lib/Sailthru/Client.pm',
	PREREQ_PM    => {
		Digest::MD5          => 0,
		HTTP::Request        => 0,
		JSON::XS             => 0,
		LWP                  => 0,
		LWP::Protocol::https => 0,
		Params::Validate     => 0,
		URI                  => 0,
		URI::Escape          => 0,
	},
	ABSTRACT_FROM => 'lib/Sailthru/Client.pm',
	AUTHOR        => 'Sam Gerstenzang <sgerstenzang@stanford.edu>, Steve Miketa <steve@sailthru.com>'
);
