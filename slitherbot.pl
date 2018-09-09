#!/usr/bin/perl -w

#
# This file is part of slitherbot.
#
# slitherbot is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# slitherbot is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with tdbot. If not, see <http://www.gnu.org/licenses/>.
#

require "misc.pl";

use strict;
#use warnings;
use IO::Async::Loop;
use Net::Async::WebSocket::Client;

my $version = "1.0";
print("\nslitherbot $version\nhttps://github.com/bcattaneo\n\n");

# Get nick (user input)
print "Nickname: ";
my $nick = <STDIN>;
chomp $nick;
exit 0 if ($nick eq "");
print("\n");

# Process configuration data
my $config_data = get_config('config.json');

# Slither configuration
my $url             = $config_data->{slither}{url};
my $host            = $config_data->{slither}{host};

# Const
my $EOL     = "\015\012";
my $BLANK   = $EOL x 2;

# Websocket client
my $client = Net::Async::WebSocket::Client->new(
    on_binary_frame => sub {
        my ( $self, $frame ) = @_;
        my $message_code = get_message_code($frame);
        my $response = process_message($message_code, $frame);

        $self->send_binary_frame($response) if $response ne "";

        # Specific init messages (only for code 6)
        if ($message_code eq "6") {
            # Send nickname
            $self->send_binary_frame("\x73\x0a\x0f\x07$nick");
        }
    },
);

# Async loop
my $loop = IO::Async::Loop->new;
$loop->add( $client );

print("Connecting... ");
 
# Connecting to server
$client->connect(
   url => "ws://$host$url",
)->then( sub {
    # Send first message: connect
    $client->send_binary_frame("\x63");
})->get;

print("OK\n");

# Start loop
$loop->run;

# Decode preinit message
# Translated to perl. Original java code: https://github.com/ClitherProject/Slither.io-Protocol/blob/master/Protocol.md#type_6_detail
sub decode_secret
{
    my (@secret) = @_;

    my $result;

    my $global_value = 0;
    for (my $i=0; $i < 24; $i++) {
        my $value1 = $secret[17 + $i * 2];
        if ($value1 <= 96) {
            $value1 += 32;
        }
        $value1 = ($value1 - 98 - $i * 34) % 26;
        if ($value1 < 0) {
            $value1 += 26;
        }

        my $value2 = $secret[18 + $i * 2];
        if ($value2 <= 96) {
            $value2 += 32;
        }
        $value2 = ($value2 - 115 - $i * 34) % 26;
        if ($value2 < 0) {
            $value2 += 26;
        }

        my $interim_result = ($value1 << 4) | $value2;
        my $offset = $interim_result >= 97 ? 97 : 65;
        $interim_result -= $offset;
        if ($i == 0) {
            $global_value = 2 + $interim_result;
        }
        $result .= chr(($interim_result + $global_value) % 26 + $offset);
        $global_value += 3 + $interim_result;
    }
    return $result;
}

# Process incoming messages
sub process_message
{
    my ($message_code, $frame) = @_;

    # Preinit
    if ($message_code eq "6") {
        my @secret = string_to_ints($frame);
        return decode_secret(@secret);
    }
    #elsif {
    #    # TODO: More messages
    #}
    return "";

}

# Get current message code
sub get_message_code
{
    my ($frame) = @_;
    return substr($frame, 2, 1);
}