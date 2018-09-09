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

use strict;
use MIME::Base64 qw( encode_base64 );
use JSON qw( );

sub get_config
{
	my ($config_file) = @_;
	my $json_text = do {
	   open(my $json_fh, "<:encoding(UTF-8)", $config_file) or die("Can't open \$config_file\": $!\n");
	   local $/;
	   <$json_fh>
	};

	return decode_json($json_text);
}

sub decode_json
{
	my ($json_text) = @_;
	my $json = JSON->new;
	return $json->decode($json_text);
}

sub random_base64_string
{
	my @chars = ("A".."Z", "a".."z");
	my $string;
	$string .= $chars[rand @chars] for 1..8;
	return encode_base64($string);
}

sub string_to_ints
{
    my ($string) = @_;
    my @ints_array;
    for (my $i=0; $i < length($string); $i++) {
       $ints_array[$i] = ord(substr($string, $i, 1));
    }
    return @ints_array;
}

1;