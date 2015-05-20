# voxsms-client-perl-lib

To build run
perl Makefile.PL
make
make install

The API consists of 3 parts

[Voxbone::VoxSMS::Fragment](/Voxbone::VoxSMS::Fragment.md) - a tool to split a string into SMS-sized chunks

[Voxbone::VoxSMS::Client](/Voxbone::VoxSMS::Client.md) - a tool to send requests to the VoxSMS server

[Voxbone::VoxSMS::Server](/Voxbone::VoxSMS::Server.md) - a PSGI framework to handle Rest requests from the VoxSMS platform
