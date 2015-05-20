# SYNOPSIS

    use strict;
    use Voxbone::VoxSMS::Server;
    use Data::UUID;

    my $handle\_sms = sub {
	         my $sms = shift;
		 my $ug = Data::UUID->new
		 my $uuid = $ug->create\_str();

		 print "Got an sms $sms->{msg}\n";

		 return $uuid;
    }

    my $handle\_delivery\_report = sub {
	         my $report = shift;

		 print "Got a delivery report $sms->{delivery\_status}\n";

		 return $uuid;
    }

    my $app = sub {
	        return Voxbone::VoxSMS::Server->new(handle\_sms => $handle\_sms, 
				                    handle\_delivery\_report => $handle\_delivery\_report
						   )->run(@\_);
    };

# METHODS

## Voxbone::VoxSMS::Server->new(handle_sms => $func1, handle_delivery_report => $func2)

This creates an instance of the VoxSMS PSGI framwork. It takes 2 subroutine reference as named parameters.  At least one of the two callbacks must be defined or an error will be thrown.

- handle\_sms

If passed, this subroutine will be invoked when an SMS is received from VoxSMS

- handle\_delivery\_report

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

    - frag\_ref

    The unique id to relate all fragments of an sms together

    - frag\_total

    Total number of fragments the sms was split into

    - frag\_num

    The sequence number (starting from 1 of this sms)

- delivery report

Indicates if delivery reports were requested can have the following values

                - none
            - success
        - failure
    - all



## delivery_report

- orig\_from

+E164 of the sender of the original SMS (receiver of the delivery report)

- orig\_to

+E164 of the receiver of the original SMS (sender of the delivery report)

- transaction\_id

the transaction id used to match the delivery report to the original sms

- delivery\_status

delivery status code, can have the following values:

                            - message\_waiting
                        - delivered\_to\_network
                    - delivered\_to\_terminal
                - delivery\_expired
            - delivery\_failed
        - delivery\_rejected
    - delivery\_impossible

- status\_code

status code of the delivery report, can have the following values:

                        - ok
                    - accepted
                - bad\_request
            - message\_to\_long
        - not\_found
    - forbidden

- submit\_date

utc time the sms was originally sent in YYYY-MM-DD HH:MM:SS format

- done\_date

utc time the sms arrived at destination  in YYYY-MM-DD HH:MM:SS format

# Callback Functions

## handle_sms

the handle\_sms subroutine reference passed into the new() will get invoked with an sms object as a parameter.  The return value should be the desired transaction\_id (used for later sending delivery reports later).  After returning, the framwork will add a key transaction\_id to the sms object with either the returned transaction\_id value or the auto generated transaction\_id if this subroutine doesn't return one.

## handle_delivery_report

the handle\_delivery\_report subroutine reference passed into the new() will be invoked with the delivery report object as a parameter.  Any return value of this method is ignored.

# AUTHOR

Torrey Searle <torrey@voxbone.com>