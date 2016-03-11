package Mojolicious::Plugin::Tables::Model;

use strict;
use warnings;

use base qw/DBIx::Class::Schema::Loader/;

use Data::Dumper;

__PACKAGE__->mk_group_accessors(inherited => qw/log connect_info/);

sub glossary { +{ id => 'Identifier' } }

sub input_attrs { +{ name => { size=>80 } } }

sub make_label {
    my $self = shift;
    my $name = shift;
    my @label = split '_', $name;
    for (@label) {
        $_ = $self->glossary->{$_}, next if $self->glossary->{$_};
        $_ = ucfirst
    }
    join(' ', @label)
}

sub custom_column_info {
    my ($class, $table, $column, $column_info) = @_;
    my $info = { label => $class->make_label($column) };
    my $attrs1;
    for ($column_info->{data_type}) {
        $attrs1 =
            /numeric|integer/ ? {type=>'number'} :
            /timestamp/       ? {type=>'datetime-local'} :
            /date|time/       ? {type=>$_} :
            {};
    }
    my $attrs2 = $class->input_attrs->{$column} || {};
    $info->{input_attrs} = {%$attrs1, %$attrs2} if keys(%$attrs1) || keys(%$attrs2);
    $info
};

sub rel_name_map { +{} }

sub setup {
    my ($class, $conf) = @_;
    if (my $connect_info = $conf->{connect_info}) {
        $class->connect_info($connect_info)
    } else {
        die "Provide connect_info either as a config value or an override"
            unless $class->connect_info
    }

    $class->loader_options(
        components              => qw[ InflateColumn::DateTime ],
        additional_base_classes => qw[ Mojolicious::Plugin::Tables::Model::Row ],
        rel_name_map            => $class->rel_name_map,
        custom_column_info      => sub { $class->custom_column_info(@_) },
    );

    $class->naming('v8');
    $class->use_namespaces(0);
    $class->connection( @{$class->connect_info} );
    return $class->model;
}

sub model {
    my $schema  = shift;
    my @tablist = ();
    my %bytable = ();
    #my $log     = $schema->log;
    #$log->debug("$schema is building its model");
    for my $source (sort $schema->sources) {
        my $s = $schema->source($source);
        my @has_a;
        my %has_many;
        for my $rel ($s->relationships) {
            my $info   = $s->relationship_info($rel);
            my $ftable = $info->{class}->table;
            my $attrs  = $info->{attrs};
            my $card   = $attrs->{accessor};
            if ($card eq 'single') {
                my $fks = $attrs->{fk_columns};
                my @fks = keys %$fks;
                push @has_a, { fkey=>$fks[0], parent=>$rel, label=>$schema->make_label($rel), ptable=>$ftable }
                    if @fks == 1
            } elsif ($card eq 'filter') {
                my @ffkeys = keys %{$info->{cond}};
                if (@ffkeys == 1) {
                    (my $cfkey = $ffkeys[0]) =~ s/^foreign\.//;
                    push @has_a, { fkey=>$cfkey, parent=>$rel, label=>$schema->make_label($rel), ptable=>$ftable }
                } else {
                    warn __PACKAGE__." model: $source: $rel: multi-barrelled M-1 keys not supported\n"
                }
            } elsif ($card eq 'multi') {
                my $fsource_name = $info->{source};
                my $fsource      = $schema->source($fsource_name);
                my $fpkey        = join(',', $fsource->primary_columns);
                my @ffkeys       = keys %{$info->{cond}};
                if (@ffkeys == 1) {
                    (my $cfkey = $ffkeys[0]) =~ s/^foreign\.//;
                    $has_many{$rel} = {ctable=>$ftable, cpkey=>$fpkey, cfkey=>$cfkey, label=>$schema->make_label($rel)};
                } else {
                    warn __PACKAGE__." model: $source: $rel: multi-barrelled 1-M keys not supported\n"
                }
            } else {
                warn __PACKAGE__." model: $source: $rel: strange cardinality: $card\n";
                warn "rel_info " . Dumper($info);
            }
        }
        my %bycolumn = map {
                          my %info = %{$s->column_info($_)};
                          delete $info{name};
                          /^_/ && delete $info{$_} for keys %info;
                          ( $_ => \%info )
                      } $s->columns;
        for (@has_a) {
            my $fkey = $_->{fkey};
            my $parent = delete $_->{parent};
            $bycolumn{$fkey}->{parent} = $parent if $bycolumn{$fkey};
            $bycolumn{$parent} = $_; # gets {fkey=>, label=>, ptable=>,}
        }
        my $pkeys   = [$s->primary_columns];
        my $pknum   = 0;
        for (@$pkeys) {
            $bycolumn{$_}{is_primary_key} = ++$pknum
        }
        my @columns = map { $_, $bycolumn{$_}{parent}? ($bycolumn{$_}{parent}): () }
                      $s->columns;
        my $label   = $schema->make_label($s->name);
        my $tabinfo = {
                source   => $source,
                columns  => \@columns,
                bycolumn => \%bycolumn,
                has_many => \%has_many,
                label    => $label,
                pkeys    => $pkeys,
        };
        push @tablist, $s->name;
        $bytable{$s->name} = $tabinfo;
    }
    {schema=>$schema, tablist=>\@tablist, bytable=>\%bytable}
}

1;

