#!/usr/bin/perl -w
#
# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: Apache-2.0
#

use strict;
use warnings;

use File::Basename;

use Data::Dumper;
use Net::GitHub::V3;

my $chromium_tag = shift;
my $rpm_asset_path = shift;
my $tarball_asset_path = shift;

print "Opening $rpm_asset_path\n";
open(my $rpm_asset_data, $rpm_asset_path)
    or die "Unable to open $rpm_asset_path";

print "Opening $tarball_asset_path\n";
open(my $tarball_asset_data, $tarball_asset_path)
    or die "Unable to open $tarball_asset_path";

my $gh = Net::GitHub::V3->new({
    access_token => $ENV{GITHUB_API_TOKEN},
    RaiseError => 1
});

my $repos = $gh->repos;

$repos->set_default_user_repo('chromium-ppc64le', 'chromium-ppc64le');

my @releases = grep { $_->{tag_name} eq $chromium_tag } $repos->releases();

print Dumper(\@releases);

my $release;

if (@releases) {
    print "Using existing GitHub release:\n";
    $release = $releases[0];
} else {
    print "Creating GitHub release:\n";
    $release = $repos->create_release({
        "tag_name" => "$chromium_tag",
        "name" => "Chromium $chromium_tag"
    })
}

print Dumper(\$release);

print "Uploading $rpm_asset_path\n";
my $release_rpm_asset = do {
    local $/;
    $repos->upload_asset(
        $release->{id},
        basename($rpm_asset_path),
        'application/x-rpm',
        <$rpm_asset_data>
    );
};

print "Uploaded artifacts to GitHub:\n";
print Dumper(\$release_rpm_asset);

print "Uploading $tarball_asset_path\n";
my $release_tarball_asset = do {
    local $/;
    $repos->upload_asset(
        $release->{id},
        basename($tarball_asset_path),
        'application/x-xz',
        <$tarball_asset_data>
    );
};

print "Uploaded artifacts to GitHub:\n";
print Dumper(\$release_tarball_asset);

