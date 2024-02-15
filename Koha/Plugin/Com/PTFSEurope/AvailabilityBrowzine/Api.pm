package Koha::Plugin::Com::PTFSEurope::AvailabilityBrowzine::Api;

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use JSON         qw( decode_json );
use MIME::Base64 qw( decode_base64 );
use URI::Escape  qw ( uri_unescape );
use LWP::UserAgent;
use HTTP::Request::Common;

use Mojo::Base 'Mojolicious::Controller';
use Koha::Database;
use Koha::Plugin::Com::PTFSEurope::AvailabilityBrowzine;

sub search {

    # Validate what we've received
    my $c = shift->openapi->valid_input or return;

    my $base = $c->req->url->base;

    # FIXME: Use base_url below for local DEV
    # my $base_url = "http://localhost:8081/api/v1/contrib/browzine/search";
    my $base_url = lc $base->scheme . "://" . $base->host . "/api/v1/contrib/browzine/search";

    # Gather together what we've been passed
    my $metadata = $c->validation->param('metadata') || '';
    $metadata = decode_json( decode_base64( uri_unescape($metadata) ) );

    # Get the DOI
    my $doi = $metadata->{doi};

    # Get the PMID
    my $pmid = $metadata->{pmid} || $metadata->{pubmedid};

    my $using = {};
    if ( $pmid && length $pmid > 0 ) {
        $using->{identifier} = 'pmid';
        $using->{value}      = $pmid;
    } elsif ( $doi && length $doi > 0 ) {
        $using->{identifier} = 'doi';
        $using->{value}      = $doi;
    }

    if ( scalar keys %{$using} == 0 ) {
        _return_response( { error => 'Must supply either DOI or PMID' }, $c );
    }

    my $ua       = LWP::UserAgent->new;
    my $response = $ua->get("${base_url}?$using->{identifier}=$using->{value}");

    if ( $response->is_success ) {
        my $to_send = [];

        # Parse the BrowZine response and prepare our response
        my $res = decode_json( $response->decoded_content );
        if (
            $res->{results}->{result}->{data} &&
            (
                $res->{results}->{result}->{data}->{availableThroughBrowzine} ||
                $res->{results}->{result}->{data}->{openAccess} )
            )
        {
            my $data = $res->{results}->{result}->{data};
            push @{$to_send}, {
                title  => $data->{title},
                author => $data->{authors},
                url    => _determine_url($data),
                source => Koha::Plugin::Com::PTFSEurope::AvailabilityBrowzine::get_name(),
                date   => $data->{date}
            };
        } else {
            $to_send = [];
        }

        _return_response( { success => $to_send }, $c );
    } else {
        _return_response( { error => $response->status_line }, $c );
    }
}

sub _determine_url {
    my ($data) = @_;
    if ( $data->{fullTextFile} && length $data->{fullTextFile} > 0 ) {
        return $data->{fullTextFile};
    } elsif ( $data->{contentLocation} && length $data->{contentLocation} > 0 ) {
        return $data->{contentLocation};
    } elsif ( $data->{ILLURL} && length $data->{ILLURL} > 0 ) {
        return $data->{ILLURL};
    }
    return '';
}

sub _return_response {
    my ( $response, $c ) = @_;
    return $c->render(
        status  => $response->{errorcode} || 200,
        openapi => {
            results => {
                search_results => $response->{success} || [],
                errors         => $response->{error}   || []
            }
        }
    );
}

1;
