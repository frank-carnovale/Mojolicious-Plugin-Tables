package StuffDB;

use strict;
use warnings;

use base qw/Mojolicious::Plugin::Tables::Model/;

sub connect_info { [ 'dbi:Pg:dbname="stuff"', '', '' ] }

sub glossary { +{
    abs       => 'Absolute',
    avg       => 'Average',
    cap       => 'Capitalization',
    cd        => 'Code',
    dyngrp    => 'Dynamic Group',
    dyngrps   => 'Dynamic Groups',
    id        => 'Identifier',
    ip        => 'IP Number',
    isin      => 'ISIN',
    fca       => 'FCA',
    lse       => 'LSE',
    mkt       => 'Market',
    pargrp    => 'Parent Group',
    pct       => '%',
    prc       => 'Price',
    subgroups => 'Sub-Groups',
    feedbacks => 'Feedback',
    tidm      => 'TIDM',
    ts        => 'Timestamp',
    var       => 'Variance',
    vol       => 'Volume',
    marketsegmentcode => 'Market Segment Code',
    marketsectorcode  => 'Market Sector Code',
    subsector         => 'Sub-Sector',
} }

sub input_attrs { +{
    var_pct => { min=>-100, max=>100 },
    vol_pct => { min=>-100, max=>500 },
    details => { cols=>60 },
    name    => { size=>80 },
    aud     => { size=>80 },
    azp     => { size=>80 },
    description => { size=>80 },
    hd      => { size=>80 },
    picture => { size=>80, type=>'url' },
    email   => { size=>40, type=>'email' },
    email_verified => { type=>'checkbox' },
    ts      => { step=>1 },
    joined  => { step=>1 },
} }

sub rel_name_map { +{
    AssetRange => { range_age => 'range' },
    Asset      => { symbol    => 'lse_security' },
    Dyngrp     => { dyngrps   => 'subgroups' },
    Trader     => { authority_granters => 'grants_to',
                    authority_traders  => 'audit_trail' },
} }

1;

