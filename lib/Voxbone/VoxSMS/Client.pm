package Voxbone::VoxSMS::Client;
use strict;
use URI::Split qw(uri_split uri_join);
use URI::Encode qw(uri_encode uri_decode);
use JSON::XS;
use LWP::UserAgent;
use Data::Dumper;

use vars qw($VERSION);

$VERSION = '1.0';

=head1 NAME

Voxbone::VoxSMS::Client - A rest client for the VoxSMS API

=head1 SYNOPSIS

 use strict;
 use Voxbone::VoxSMS::Client;

 my $client = new Voxbone::VoxSMS::Client(user=>"user", pass=>"password");

 my $transaction_id = $client->send_sms(to=>"+3228080000", from=>"+15555555555", msg=>"Hello World!");

=head1 METHODS

=head2 new

creates a new instance of the voxsms api client has the following parameters

=over

=item user

username to use in digest authentication of requests to the VoxSMS server

=item pass

password to use in digest authentication of requests to the VoxSMS server

=item api_baseurl

Specifies the server where to send http requests to. Normally should not be set but can be usefull for testing.  Defaults to https://sms.voxbone.com:4443/sms/v1/

=back

=cut

sub new {
	my $class = shift;
	my %params = @_;
	my $self = {api_baseurl => "https://sms.voxbone.com:4443/sms/v1/",
		    ua => LWP::UserAgent->new};


	if (%params) {
		if (exists $params{user}) {
			$self->{user} = $params{user};
		}
		if (exists $params{pass}) {
			$self->{pass} = $params{pass};
		}
		if (exists $params{api_baseurl}) {
			$self->{api_baseurl} = $params{api_baseurl};
		}

	}

        my @fields = uri_split($self->{api_baseurl});
        $self->{netloc} = $fields[1];

	if (defined $self->{user} ) {
        	my $realm = "Voxbone";
        	$self->{ua}->credentials($self->{netloc}, $realm, $self->{user}, $self->{pass});
	}

	return bless $self, $class;
}

=head2 send_sms

Sends an SMS to the VoxSMS server.  Returns a transaction_id if successfull undefined otherwise.  Can take the following parameters:

=over

=item to

+E164 of the destination

=item from

+E164 of the sender

=item msg

The message to send, must not exceed the maximum SMS length see L<Voxbone::VoxSMS::Fragment> for help splitting a message into appropriate chunks

=item frag

Optional parameter, used to send fragmentation information if needed, if present it must be a hashref with the following keys

=over

=item frag_ref

the unique used to correlate all related sms fragments

=item frag_total

the total number of fragments the message is split into

=item frag_num

the sequence number starting from 1 indicating which fragment of frag_total this message is

=back 

=back


=cut

sub send_sms
{
	my $self = shift;
	my %params = @_;
	my $to = $params{to};
	my $from = $params{from};
	my $msg = $params{msg};
	my $frag = $params{frag};
	my $delivery_report=$params{delivery_report};
	my $ua = $self->{ua};

	$to =~ s/\+([0-9]+)/$1/;
	$from =~ s/\+([0-9]+)/$1/;

	$from = "+" . $from;

	my $url = $self->{api_baseurl} . $to; 

	if (!defined $delivery_report) {
		$delivery_report = 'none';
	}


	my $datestr = gmtime();
	my $request = {'from' => $from,
			'msg' => $msg,
			'delivery_report' => $delivery_report};

	if ($frag) {
		$request->{'frag'} = $frag;
	}

	my $req = HTTP::Request->new(POST => $url);
	$req->header('Content-Type' => "application/json;charset=utf8");
	$req->content(JSON::XS->new->utf8(1)->pretty(1)->encode($request));
	my $resp = $ua->request($req);

	if ($resp->is_success) {
		my $json_data = decode_json($resp->decoded_content);
		return $json_data->{transaction_id};
	}
}

=head2 send_delivery_report

sends a delivery report for a previously received sms.  Takes teh following parameters:

=over

=item orig_req

The original sms object as received from handle_sms subroutine reference in L<Voxbone::VoxSMS::Server> 

=item delivery_status

delivery status for the sms, can be one of the following values:

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

status code for the sms delivery, can be one of the following values

=over

=item ok

=item accepted

=item bad_request

=item message_too_long

=item not_found

=item forbidden

=item limit_exceeded

=item overload

=item temporarily_unavailable

=item internal_error

=item unknown_error

=item timeout

=back

=back

=cut

sub send_delivery_report
{
	my $self = shift;
	my %params = @_;
	my $delivery_status = $params{delivery_status};
	my $status_code = $params{status_code};
	my $orig_req = $params{orig_req};
	my $ua = $self->{ua};
	

	my $to = $orig_req->{'to'};
	$to =~ s/\+([0-9]+)/$1/;

	my $url = $self->{api_baseurl} . $to . "/report/" . uri_encode($orig_req->{'transaction_id'});

	my $datestr = gmtime();
	my $response = {'orig_from' => $orig_req->{'from'},
			'delivery_status' => $delivery_status,
			'status_code' => $status_code,
			'submit_date' => $datestr,
			'done_date' => $datestr};


	my $req = HTTP::Request->new(PUT => $url);
	$req->header('Content-Type' => "application/json;charset=utf8");
	$req->content(JSON::XS->new->utf8(1)->pretty(1)->encode($response));

	my $resp = $ua->request($req);

	return $resp->is_success;

}

1;
