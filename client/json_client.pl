#!/usr/bin/perl

#requires json
#apt-get install libjson-perl libwww-perl liburi-encode-perl libhttp-server-simple-perl libuuid-perl libnet-server-perl libhttp-server-simple-psgi-perl libplack-perl libdigest-hmac-perl libossp-uuid-perl libio-socket-ssl-perl libjson-xs-perl

use strict;
use utf8;
use JSON::XS;
use Data::UUID;
use IO::Select;
use MyWebServer;
use FileHandle;
use Voxbone::VoxSMS::Fragment;
use Voxbone::VoxSMS::Client;
use Voxbone::VoxSMS::Server;

#UNCOMMENT TO ENABLE DIGEST AUTH 
#use Plack::Middleware::Auth::Digest;


our $api_baseurl = "https://be.sms.voxbone.com:4443/sms/v1/";

my ($parentfd, $childfd) = FileHandle::pipe;
select $childfd;
$| = 1;
select $parentfd;
$| = 1;
select STDOUT;
$| = 1;

our $server = MyWebServer->new(8443);

my $handle_sms = sub {
	my $sms = shift;
	my $uuid;
	if ($sms->{'delivery_report'} && $sms->{'delivery_report'} ne 'none') {
		my $ug = Data::UUID->new;
		$uuid = $ug->create_str();
		$sms->{'transaction_id'} = $uuid;
	}

	my $command;
	$command->{'command'} = "sms";
	$command->{'data'} = $sms;
	print $childfd encode_json($command) . "\n";

	return $uuid;
};

my $handle_delivery_report = sub {
	my $report = shift;
	my $command;
	$command->{'command'} = "delivery_report";
	$command->{'data'} = $report;
	print $childfd encode_json($command) . "\n";
};



my $app = sub {
	return Voxbone::VoxSMS::Server->new(handle_sms => $handle_sms, handle_delivery_report => $handle_delivery_report)->run(@_);
};

my $user = ask({question=>"Username", default=>"test"});
my $password = ask({question=>"Password", default=>"test"});
my $api_baseurl = ask({question=>"Api Baseurl", default=>$api_baseurl});
my $client = new Voxbone::VoxSMS::Client(user=>$user, pass=>$password, api_baseurl=>$api_baseurl);


#UNCOMMENT TO ENABLE DIGEST AUTH 
#$app = Plack::Middleware::Auth::Digest->wrap($app, realm => "Secured", secret => "blahblahblah",
#authenticator => sub {
#  my ($username, $env) = @_;
#  return $password; 
#});


$server->app($app);
my $pid = $server->background();

print "My pid is $$ webserver is $pid\n";

$SIG{INT} = \&interrupt;
$SIG{__WARN__} = \&interrupt;
$SIG{__DIE__} = \&interrupt;

sub cleanup()
{
	print "Shutting down webserver\n";
	kill(15, $pid);
	exit;
}

sub interrupt {
	print STDERR "Caught a signal: . @_\n";
	cleanup();
}

our %messages;
our %reports;

sub process_command
{
	my $line = shift;
	my $command = decode_json ($line);
	print "\n";
	print "command: $command->{'command'}\n";
	if ($command->{'command'} eq "sms") {
		my $json_data = $command->{'data'};
		print "SMS To: " . $json_data->{'to'} . " From: " . $json_data->{'from'} . "\n";
		print "Got body of\n$json_data->{'msg'}\n";

		if ($json_data->{'transaction_id'}) {
			print "storing message with id of " . $json_data->{'transaction_id'} . "\n";
			$messages{$json_data->{'transaction_id'}} = $json_data;
		}
	} elsif ($command->{'command'} eq "delivery_report") {
		my $json_data = $command->{'data'};
		print "got delivery report for $json_data->{'transaction_id'}\n";
		print "Delivery Status: $json_data->{'delivery_status'} Status Code: $json_data->{'status_code'}\n";
		
		if (exists $reports{$json_data->{'transaction_id'}}) {
			$reports{$json_data->{'transaction_id'}}{delivery_status} = $json_data->{'delivery_status'};
			$reports{$json_data->{'transaction_id'}}{status_code} = $json_data->{'status_code'};
		} else  {
			print "Unexpected Delivery Report!\n";
		}

	}
}

sub ask {
	my $params = shift;
	my $question = $params->{'question'};
	my $values = $params->{'values'};
	my $default = $params->{'default'};


	print "\n$question:\n";
	if (defined $values) {
		print "\nPossible Values:\n";

		foreach my $value (@$values) {
			print "\t$value\n";
		}
	}
	print "\n";

	my $value = $default;

	if (defined $value) {
		print "[$value]>";
	} else {
		print ">";
	}

	my $answer = <>;
	chomp($answer);

	if ($answer ne "") {
		$value = $answer;
	}

	return $value;
}

sub print_options
{
	print "Please specify a command:\n";
	print "\n";
	print "- 1 send an sms\n";
	print "- 2 send delivery report\n";
	print "- 3 view received reports\n";
	print "- 0 exit\n";
	print ">";

}

my @delivery_statuses = ("delivered_to_terminal", "message_waiting", "delivered_to_network", "delivery_expired", "delivery_failed", "delivery_rejected", "delivery_impossible");

my @status_codes = ("ok", "accepted", "bad_request", "message_too_long", "not_found", "forbidden", "limit_exceeded", "overload", "temporarily_unavailable", "internal_error", "unknown_error", "timeout");

sub process_option_delivery_report 
{
	my @keys = keys %messages;
	if($#keys >= 0)  {
		my $trans_id = ask({question=>"Please select the transaction id of the sms you want send a delivery report for", values=>\@keys});

		if (!$messages{$trans_id}) {
			print "Transaction $trans_id not found\n";
			return;
		}

		my $dstatus = ask({question=>"Please pick a delivery status",values=>\@delivery_statuses,default=>$delivery_statuses[0]});
		my $scode = ask({question=>"Please pick a status code",values=>\@status_codes,default=>$status_codes[0]});

		my $result = $client->send_delivery_report(delivery_status=>$dstatus, status_code=>$scode, orig_req=>$messages{$trans_id});
		if ($result) {
			print "Delivery report sent!\n";
			delete $messages{$trans_id};
		} else { 
			print "Error sending Delivery report!\n";
		}

	} else {
		print "There are currently no messages pending a delivery report\n";
		return;
	}
}

my @delivery_request_types = ("none", "success", "failure", "all");


sub process_option_send_multi_sms
{

	my $frag_ref = int(rand(65534));
	my @msgs = ();

	my $to = ask({question=>"Please specify destination number"});
	my $from = ask({question=>"Please specify a source number"});
	my $msg = ask({question=>"Please specify the message to send"});

	@msgs = voxsms_fragment_message($msg);

	my $delivery_report = ask({question=>"Please delivery report mode", values=>\@delivery_request_types,default=>$delivery_request_types[0]});

	print "\nSending message in " . scalar @msgs . " sms\n";

	my $frag = undef;
	
	if (scalar @msgs > 1) {
		$frag = { frag_ref => $frag_ref, frag_num => 1, frag_total => scalar @msgs};
	}


	foreach my $msg (@msgs)  {
		my $transaction_id = $client->send_sms(to=>$to, from=>$from, msg=>$msg, frag=>$frag, delivery_report=>$delivery_report);

		print "SMS sent with transaction id of $transaction_id\n";

		if (defined $transaction_id && $delivery_report ne "none") {
			$reports{$transaction_id} = (delivery_status=>undef, status_code=>undef);
		}

		if (defined $frag) {
			$frag->{frag_num}++;
		}
	}

}

sub process_option_view_reports
{
	print "\n";

	print "Transaction ID \t\t\t\t|\tdelivery_status\t|\tstatus_code\n";
	foreach my $transaction_id (keys %reports) {
		print $transaction_id . "\t|\t" . $reports{$transaction_id}{delivery_status} . "\t|\t" . $reports{$transaction_id}{status_code} . "\n";
	}
}

sub process_option
{
	my $line = shift;

	if ($line =~ /.*([0-9]+).*/) {
		$line = $1;
	} else {
		print "Please type a number to choose your option\n";
		return;
	}

	
	if ( $line eq "0" ) {
		cleanup();
	} elsif ( $line eq "1" ) {
		process_option_send_multi_sms();
	} elsif ( $line eq "2" ) {
		process_option_delivery_report();
	} elsif ( $line eq "3" ) {
		process_option_view_reports();
	} else  {
		print "Unknown option $line\n";
	}
}



my $s = IO::Select->new();
$s->add(\*STDIN);
$s->add($parentfd);

binmode(STDIN, ":encoding(utf8)");
binmode(STDOUT, ":utf8");


print_options();


my @ready;
while (@ready = $s->can_read) {

	foreach my $fd (@ready) {
		my $line = <$fd>;

		if ($fd == \*STDIN) {
			process_option($line);
		} else {
			if (!$line) {
				print "socket closed?\n";
				$s->remove($fd);
				cleanup();

			} else  {
				process_command($line);
			}
		}
	}
	print_options();
}

cleanup();
 
