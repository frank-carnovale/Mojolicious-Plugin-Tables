package StuffDB::Asset;

use strict;
use warnings;

sub stringify {
    my $self = shift;
    my $latest_str = '';
    if (my $latest = $self->latest) {
        $latest_str = " $latest";
        if (my $var_pct = $self->var_pct) {
            $latest_str .= sprintf ' (%+.2f%%)', $var_pct
        }
    }
    if (my $secty = $self->lse_security) {
        return sprintf '%s %s (%s)%s', $secty->company_name, $secty->security_name, $self->symbol, $latest_str
    }
    return sprintf '%s (%s)%s', $self->name, $self->dataset_code, $latest_str
}

sub short {
    my $self = shift;
    sprintf '%s (%s)', $self->name, $self->dataset_code
}

sub asset_ranges_descending {
    my $self = shift;
    my $cond = shift;
    $self->asset_ranges->search($cond, {order_by=>{-desc=>'range_age'}});
}

sub fn { # filename
    my $self = shift;
    sprintf "$ENV{QUANDL}/%s/%s.out", $self->database->id, $self->dataset_code;
}

1;

