package Voxbone::VoxSMS::Server;
use strict;
use JSON::XS;
use Data::UUID;
use URI::Encode qw(uri_encode uri_decode);
use Carp qw( croak );
use vars qw($VERSION);

$VERSION = '1.0';
=head1 NAME

Voxbone::VoxSMS::Server - PSGI framework for receiving SMS via Rest

=head1 SYNOPSIS

 use strict;
 use Voxbone::VoxSMS::Server;
 use Data::UUID;

 my $handle_sms = sub {
	         my $sms = shift;
		 my $ug = Data::UUID->new
		 my $uuid = $ug->create_str();

		 print "Got an sms $sms->{msg}\n";

		 return $uuid;
 }

 my $handle_delivery_report = sub {
	         my $report = shift;

		 print "Got a delivery report $sms->{delivery_status}\n";

		 return $uuid;
 }

 my $app = sub {
	        return Voxbone::VoxSMS::Server->new(handle_sms => $handle_sms, 
				                    handle_delivery_report => $handle_delivery_report
						   )->run(@_);
 };

=head1 METHODS

=head2 Voxbone::VoxSMS::Server->new(handle_sms =E<gt> $func1, handle_delivery_report =E<gt> $func2)

This creates an instance of the VoxSMS PSGI framwork. It takes 2 subroutine reference as named parameters.  At least one of the two callbacks must be defined or an error will be thrown.

=over

=item handle_sms

If passed, this subroutine will be invoked when an SMS is received from VoxSMS

=item handle_delivery_report

If passed, this subroutine will be invoked when a Delivery Report is received from VoxSMS

=back

=cut

sub new {
	my $class = shift;
	my %params = @_;

	my $self = {};

	croak "Parameter required!" unless %params;
	croak "At least one method must be defined the interface!" unless (exists $params{handle_sms} || exists $params{handle_delivery_report});
	
	$self->{handle_sms} = $params{handle_sms};
	$self->{handle_delivery_report} = $params{handle_delivery_report};


	return bless $self, $class;
}

=head2 run(env)

reads in the PSGI environment, invokes the required subroutine references defined in the new() returns the approprate PSGI formatted response

=cut

sub run {
	my $self = shift;
	my $env = shift;
	
	my $method = $env->{REQUEST_METHOD};
	
	if ($method eq "POST") {
		return $self->handle_post($env);
	} elsif ($method eq "PUT") {
		return $self->handle_put($env);
	} elsif ($method eq "GET") {
		return [ '200', ['Content-Type' => 'text/plain' ] , ["Your VoxSMS Rest Application is successfully running\n"]];
	}

	return [400 ];


}

sub handle_post {
	my $self = shift;
	my $env = shift;

	my $path = $env->{PATH_INFO};
	my @fields = split(/\//, $path);

	my $body_handle = $env->{'psgi.input'};
	my $postData;
	$env->{'psgi.input'}->read($postData,  $env->{CONTENT_LENGTH});
	my $json_data = decode_json ($postData);
	$json_data->{'to'} = '+' . $fields[1];
	my $command;

	if (! (defined $self->{handle_sms}) ) {
		return ['404', ['Content-Type' => 'text/plain' ], ["No sms handler defined"] ];
	}

	my $uuid = $self->{handle_sms}($json_data);
	
	my $response = [200];
	if ( defined $uuid || ($json_data->{'delivery_report'} && $json_data->{'delivery_report'} ne 'none') ) {
		if ( ! (defined $uuid) ) {
			my $ug = Data::UUID->new;
			$uuid = $ug->create_str();
		}
		$response = { 'transaction_id' => $uuid };
		$response = [ '200', ['Content-Type' => 'application/json'], [encode_json($response)]];
		$json_data->{'transaction_id'} = $uuid;
	}
	return $response;
}

sub handle_put {
	my $self = shift;
	my $env = shift;
	my $path = $env->{PATH_INFO};
	my @fields = split(/\//, $path);

	if ($fields[2] ne "report") {
		return [404];
	}

	my $body_handle = $env->{'psgi.input'};
	my $putData;
	$env->{'psgi.input'}->read($putData,  $env->{CONTENT_LENGTH});
	my $json_data = decode_json ($putData);
	$json_data->{'transaction_id'} = uri_decode($fields[3]);
	$json_data->{'orig_from'} = '+' . $fields[1];

	if (! (defined $self->{handle_delivery_report}) ) {
		return ['404', ['Content-Type' => 'text/plain' ], ["No delivery report handler defined"] ];
	}

	$self->{handle_delivery_report}($json_data);

	return [200];
}

1;

__END__

=head1 Objects

=head2 sms

=over

=item from

sender E164 with a +

=item to

destination E164 with a +

=item time

UTC time in YYYY-MM-DD HH:MM:SS format

=item msg

the content of the SMS

=item frag

This key only exists if sms fragmentation occured.  If it does exist  it will contain the following fields

=over

=item frag_ref

The unique id to relate all fragments of an sms together

=item frag_total

Total number of fragments the sms was split into

=item frag_num

The sequence number (starting from 1 of this sms)

=back

=item delivery report

Indicates if delivery reports were requested can have the following values

=over

=item none

=item success

=item failure

=item all

=back


=back

=head2 delivery_report

=over

=item orig_from

+E164 of the sender of the original SMS (receiver of the delivery report)

=item orig_to

+E164 of the receiver of the original SMS (sender of the delivery report)

=item transaction_id

the transaction id used to match the delivery report to the original sms

=item delivery_status

delivery status code, can have the following values:

=over

=item message_waiting

=item delivered_to_network

=item delivered_to_terminal

=item delivery_expired

=item delivery_failed

=item delivery_rejected

=item delivery_impossible

=back

=item status_code

status code of the delivery report, can have the following values:

=over

=item ok

=item accepted

=item bad_request

=item message_to_long

=item not_found

=item forbidden

=back

=item submit_date

utc time the sms was originally sent in YYYY-MM-DD HH:MM:SS format

=item done_date

utc time the sms arrived at destination  in YYYY-MM-DD HH:MM:SS format

=back

=head1 Callback Functions

=head2 handle_sms

the handle_sms subroutine reference passed into the new() will get invoked with an sms object as a parameter.  The return value should be the desired transaction_id (used for later sending delivery reports later).  After returning, the framwork will add a key transaction_id to the sms object with either the returned transaction_id value or the auto generated transaction_id if this subroutine doesn't return one.

=head2 handle_delivery_report

the handle_delivery_report subroutine reference passed into the new() will be invoked with the delivery report object as a parameter.  Any return value of this method is ignored.

=head1 AUTHOR

Torrey Searle <torrey@voxbone.com>
