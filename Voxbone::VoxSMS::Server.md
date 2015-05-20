# SYNOPSIS

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

# METHODS

## Voxbone::VoxSMS::Server->new(handle_sms => $func1, handle_delivery_report => $func2)

This creates an instance of the VoxSMS PSGI framwork. It takes 2 subroutine reference as named parameters.  At least one of the two callbacks must be defined or an error will be thrown.

- handle_sms

If passed, this subroutine will be invoked when an SMS is received from VoxSMS

- handle_delivery_report

If passed, this subroutine will be invoked when a Delivery Report is received from VoxSMS

## run(env)

reads in the PSGI environment, invokes the required subroutine references defined in the new() returns the approprate PSGI formatted response

# Objects

## sms

- from

sender E164 with a +

- to

destination E164 with a +

- time

UTC time in YYYY-MM-DD HH:MM:SS format

- msg

the content of the SMS

- frag

This key only exists if sms fragmentation occured.  If it does exist  it will contain the following fields

    - frag_ref

    The unique id to relate all fragments of an sms together

    - frag_total

    Total number of fragments the sms was split into

    - frag_num

    The sequence number (starting from 1 of this sms)

- delivery report

Indicates if delivery reports were requested can have the following values

    - none
    - success
    - failure
    - all



## delivery_report

- orig_from

+E164 of the sender of the original SMS (receiver of the delivery report)

- orig_to

+E164 of the receiver of the original SMS (sender of the delivery report)

- transaction_id

the transaction id used to match the delivery report to the original sms

- delivery_status

delivery status code, can have the following values:

    - message_waiting
    - delivered_to_network
    - delivered_to_terminal
    - delivery_expired
    - delivery_failed
    - delivery_rejected
    - delivery_impossible

- status_code

status code of the delivery report, can have the following values:

    - ok
    - accepted
    - bad_request
    - message_to_long
    - not_found
    - forbidden

- submit_date

utc time the sms was originally sent in YYYY-MM-DD HH:MM:SS format

- done_date

utc time the sms arrived at destination  in YYYY-MM-DD HH:MM:SS format

# Callback Functions

## handle_sms

the handle_sms subroutine reference passed into the new() will get invoked with an sms object as a parameter.  The return value should be the desired transaction_id (used for later sending delivery reports later).  After returning, the framwork will add a key transaction_id to the sms object with either the returned transaction_id value or the auto generated transaction_id if this subroutine doesn't return one.

## handle_delivery_report

the handle_delivery_report subroutine reference passed into the new() will be invoked with the delivery report object as a parameter.  Any return value of this method is ignored.

# AUTHOR

Torrey Searle <torrey@voxbone.com>
