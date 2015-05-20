#!/usr/bin/perl
package Voxbone::VoxSMS::Fragment;
use Encode qw/encode decode/;
use utf8;
use strict;

use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);

@EXPORT = qw(voxsms_fragment_message);

my $encoding_map = { "GSM-7" => {"no_frag" => 160, "frag" => 152},
		     "LATIN-1" => {"no_frag" =>140, "frag" => 133},
		     "UCS2" => {"no_frag" => 70, "frag" => 66}};

sub voxsms_fragment_message {
	my $msg = shift;
	my @fragments;
	my $encoding = voxsms_get_encoding($msg);

	if ( length ($msg) > $encoding_map->{$encoding}->{no_frag} ) {
		my $frag_size = $encoding_map->{$encoding}->{frag};
		while ( length ($msg) > $frag_size ) {
			push @fragments, substr $msg, 0, $frag_size;
			$msg = substr $msg, $frag_size;
		}

		if ( length ($msg) > 0 )  {
			push @fragments, $msg;
		}
	} else { 
		push @fragments, $msg;
	}

	return @fragments;
}

sub voxsms_get_encoding {
	my $utf8 = shift;

        my $gsm0338 = decode("gsm0338", encode("gsm0338", $utf8)); 
        if ($gsm0338 eq $utf8) {
                return "GSM-7";
        } 
        my $latin = decode("iso-8859-15", encode("iso-8859-15", $utf8)); 
        if ($latin eq $utf8) {
                return "LATIN-1";
        } 

	return "UCS2";
}

1;
__END__

=head1 NAME

Voxbone::Fragment - Utility Library To Find Optimal Size of SMS messages

=head1 SYNOPSIS

    use Voxbone::Fragment;
    my  @fragments = voxsms_fragment_message($msg); # returns an array of fragments

=head1 DESCRIPTION

This method determines the most compact encoding that can be uses for the given message and splits the message based on the maximum length for that encoding

=head1 AUTHOR

Torrey Searle <torrey@voxbone.com>

=cut
