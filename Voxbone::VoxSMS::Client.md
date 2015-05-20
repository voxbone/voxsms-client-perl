# NAME

Voxbone::VoxSMS::Client - A rest client for the VoxSMS API

# SYNOPSIS

    use strict;
    use Voxbone::VoxSMS::Client;

    my $client = new Voxbone::VoxSMS::Client(user=>"user", pass=>"password");

    my $transaction_id = $client->send_sms(to=>"+3228080000", from=>"+15555555555", msg=>"Hello World!");

# METHODS

## new

creates a new instance of the voxsms api client has the following parameters

- user

username to use in digest authentication of requests to the VoxSMS server

- pass

password to use in digest authentication of requests to the VoxSMS server

- api_baseurl

Specifies the server where to send http requests to. Normally should not be set but can be usefull for testing.  Defaults to https://sms.voxbone.com:4443/sms/v1/

## send_sms

Sends an SMS to the VoxSMS server.  Returns a transaction_id if successfull undefined otherwise.  Can take the following parameters:

- to

+E164 of the destination

- from

+E164 of the sender

- msg

The message to send, must not exceed the maximum SMS length see [Voxbone::VoxSMS::Fragment](http://search.cpan.org/perldoc?Voxbone::VoxSMS::Fragment) for help splitting a message into appropriate chunks

- frag

Optional parameter, used to send fragmentation information if needed, if present it must be a hashref with the following keys

    - frag_ref

    the unique used to correlate all related sms fragments

    - frag_total

    the total number of fragments the message is split into

    - frag_num

    the sequence number starting from 1 indicating which fragment of frag_total this message is



## send_delivery_report

sends a delivery report for a previously received sms.  Takes teh following parameters:

- orig_req

The original sms object as received from handle_sms subroutine reference in [Voxbone::VoxSMS::Server](http://search.cpan.org/perldoc?Voxbone::VoxSMS::Server) 

- delivery_status

delivery status for the sms, can be one of the following values:

    - message_waiting
    - delivered_to_network
    - delivered_to_terminal
    - delivery_expired
    - delivery_failed
    - delivery_rejected
    - delivery_impossible

- status_code

status code for the sms delivery, can be one of the following values

    - ok
    - accepted
    - bad_request
    - message_too_long
    - not_found
    - forbidden
    - limit_exceeded
    - overload
    - temporarily_unavailable
    - internal_error
    - unknown_error
    - timeout
