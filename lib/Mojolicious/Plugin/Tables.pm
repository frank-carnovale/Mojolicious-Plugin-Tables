package Mojolicious::Plugin::Tables;
use Mojo::Base 'Mojolicious::Plugin';

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';

use Mojolicious::Plugin::Tables::Model;

our $VERSION = '0.01';

sub register {
    my ($self, $app, $conf) = @_;

    my $log = $app->log;

    $app->helper(add_stash => sub {
        my ($c, $slot, $val) = @_;
        push @{$c->stash->{$slot} ||= []}, $val;
    });

    $app->helper(add_flash => sub {
        my ($c, $slot, $val) = @_;
        push @{$c->session->{new_flash}{$slot} ||= []}, $val;
    });

    $app->helper(shipped => sub {
        # special stash slot for sending json-able structs to js;
        # get/set logic here cloned from Mojo::Util::_stash.
        my $c = shift;
        my $shipped = $c->stash->{shipped} ||= {};
        return $shipped unless @_;
        return $shipped->{$_[0]} unless @_>1 || ref $_[0];
        my $values = ref $_[0]? $_[0] : {@_};
        @$shipped{keys %$values} = values %$values;
    });

    $app->config(default_theme=>'redmond');
    $app->defaults(layout=>'tables');
    
    my $model_class = $conf->{model_class} ||= 'Mojolicious::Plugin::Tables::Model';
    $model_class->log($log);
    my $model       = $model_class->setup($conf);
    $app->config(model=>$model);

    my $plugin_resources = catdir dirname(__FILE__), 'Tables', 'resources';
    push @{$app->routes->namespaces}, 'Mojolicious::Plugin::Tables::Controller';
    push @{$app->renderer->paths}, catdir($plugin_resources, 'templates');
    push @{$app->static->paths},   catdir($plugin_resources, 'public');

    my $r = $app->routes;
    $r->get('/' => sub{shift->redirect_to('tables')}) unless $conf->{nohome};

    my $crud_gets  = [qw/view edit del nuke navigate/];
    my $crud_posts = [qw/save/];

    for ($r->under('tables')                   ->to('auth#ok'   )) {
        for ($_->under()                       ->to('tables#ok' )) {
            $_->get                            ->to('#page'     );
            for ($_->under(':table')           ->to('#table_ok' )) {
                $_->any                        ->to('#table'    );
                $_->get('add')                 ->to('#add'      );
                $_->post('save')               ->to('#save'     );
                for ($_->under(':id')          ->to('#id_ok'    )) {
                    $_->get(':action'=>[action=>$crud_gets]     );
                    $_->post(':action'=>[action=>$crud_posts]   );
                    $_->get('add_child/:child')->to('#view'     );
                    $_->any(':children')       ->to('#children' );
                }
            }
        }
    }

    my @tablist = @{$model->{tablist}};
    $log->info ("'Tables' Framework enabled.");
    $log->debug("Route namespaces are..");
    $log->debug("--> $_") for @{$app->routes->namespaces};
    $log->debug("Renderer paths are..");
    $log->debug("--> $_") for @{$app->renderer->paths};
    $log->debug("Static paths are..");
    $log->debug("--> $_") for @{$app->static->paths};
    $log->info ("/tables routes are in place. ".scalar(@tablist)." tables available");
    $log->debug("--> $_") for @tablist;

    $log->debug($app->dumper($model)) if $ENV{TABLES_DEBUG};

}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Tables -- Quickstart and grow a Tables-Maintenance application

=head1 SYNOPSIS

    # in a new Mojolicious app..
 
    $app->plugin( Tables => {connect_info=>['dbi:Pg:dbname="mydatabase"', 'uid', 'pwd']} );

    # when ready to grow..

    $app->plugin( Tables => {model_class => 'StuffDB'} );

=head1 DESCRIPTION

L<Mojolicious::Plugin::Tables> is a L<Mojolicious> plugin which helps you grow a high-featured web app by
starting with basic table / relationship maintenance and growing by overriding default behaviours.

By supplying 'connect_info' (DBI-standard connect parameters) you get a presentable database maintenance
web app, featuring full server-side support for paged lists of large tables using
'Datatables' (datatables.net), plus ajax handling for browsing 1-many relationships, plus
JQueryUI-styled select lists for editing many-to-1 picklists.

By supplying your own Model Class you can override most of the default behaviours
and build an enterprise-ready rdbms-based web app.

By supplying your own templates for context-specific calls you can start to give your app a truly 
specialised look and feel.

=head1 STATUS

This is a first release.  Guides and more override-hooks coming Real Soon Now.

=head1 REFERENCE

=head2 Ground Zero Startup

    tables dbi-connect-params..

The 'tables' script is supplied with this distribution.  Give it standard DBI-compatible parameters on the 
commandline and it will run a minimal web-server at localhost:3000 to allow maintenance on the named database.

=head2 Day One

In your Mojolicious 'startup'..

    $self->plugin(Tables => { connect_info => [ connect-param, connect-param, .. ] };

Add this line to a new Mojolicious app then run it using any Mojo-based server (morbo, prefork, hypnotoad..) to achieve exactly the same functionality as the 'tables' script.

=head2 Infinity and Beyond

    $self->plugin(Tables => { model_class => 'MyDB' } );

Where model_class implements the specification given below.  This lets you start to customise and grow your web app.

=head1 Customising model_class

Prepare your own model_class to override the default database settings which "Tables" has determined from the 
database.  This class (and its per-table descendants) can be within or without your Mojolicious application.

=head2 model_class PARENT

Your model_class must inherit from Mojolicious::Plugin::Tables::Model.  So, e.g.

    package StuffDB;

    use strict;
    use warnings;

    use base qw/Mojolicious::Plugin::Tables::Model/;

    ...

=head2 model_class METHODS

Your model_class optionally overrides any of the following methods.

=head3 connect_info

A sub returning an arrayref supplying your locally declared DBI parameters. e.g.

    sub connect_info { [ 'dbi:Pg:dbname="stuff"', '', '' ] }

which works for a Postgres database called 'stuff' accepting IDENT credentials.

=head3 glossary

A sub returning a hashref which maps "syllables" to displaynames.  "Syllables" are all the abbreviated words that
are separated by underscores in your database table and column names.  Any syllable by default is made into a nice
word by simply init-capping it, so the glossary only needs to supply non-obvious displaynames.
The mapping 'id=>Identifier' is built-in.
So for example with table or column names such as "stock", "active_stock", "stock_id", "stock_name",
"dyngrp_id", "mkt_ldr", "ccld_ts" we would supply just this

    sub glossary { +{
        ccld   => 'Cancelled',
        dyngrp => 'Dynamic Group',
        mkt    => 'Market',
        ldr    => 'Leader',
        ts     => 'Timestamp',
    } }

.. and we will see labels "Stock", "Active Stock", "Stock Identifier", "Stock Name",
"Dynamic Group Identifier", "Market Leader", "Cancelled Timestamp" in the generated application.
 
=head3 input_attrs

A sub returning a hashref giving appropriate html5 form-input tag attributes for any fieldname.  By default these
attributes are derived depending on field type and database length. But these can be overriden here, e.g.

    sub input_attrs { +{
        var_pct => { min=>-100, max=>100 },
        vol_pct => { min=>-100, max=>500 },
        name    => { size=>80 },
        picture => { size=>80, type=>'url' },
        email   => { size=>40, type=>'email' },
        email_verified => { type=>'checkbox' },
        ts      => { step=>1 },
    } }

=head3 rel_name_map

A sub returning a hashref which maps default generated relationship names to more appropriate choices.  More detail
in L<DBIx::Class::Schema::Loader>.  e.g.

    sub rel_name_map { +{
        AssetRange => { range_age => 'range' },
        Asset      => { symbol    => 'lse_security' },
        Dyngrp     => { dyngrps   => 'subgroups' },
        Trader     => { authority_granters => 'grants_to',
                        authority_traders  => 'audit_trail' },
    } }

=head2 ResultClass Methods

After creating a model_class as described above you will automatically be able to introduce 'ResultClass' classes
for any of the tables in your database.  Place these directly 'under' your model_class, e.g. if StuffDB is
your model_class and you want to introduce a nice stringify rule for the table 'asset', then you can
create the class StuffDB::Asset and give it just the stringify method. e.g. from http://octalfutures.com :

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
        return sprintf '%s (%s)%s', $self->name, $self->dataset_code, $latest_str
    }

    1;

Any of these ResultClasses will inherit all methods of DBIx::Class::Row.
In addition these methods inherit all methods of Mojolicious::Plugin::Tables::Model::Row, namely:

=head3 stringify

It's recommended to implement this.  The stringification logic for this table.  The default implementation 
tries to use any columns such as 'cd' or 'description', and falls back to joining the primary keys.

=head3 present

Generate a presentation of a row->column value, formatted depending on type.  Args: column_name, a hash-ref containing schema info about that column, and a hashref containing context info (currently just 'foredit=>1').

=head3 options

Given: column_name, a hash-ref containing schema info about that column, a hash-ref containing info about the parent table, the full DBIX::Class schema, and a hash-ref containing schema information about all tables..

Generate the full pick-list that lets the fk $column pick from its parent,
in a structure suitable for the Mojolicious 'select_field' tag.  The default version simply lists all choices
(limited by safety row-count of 200) but inherited versions are expected to do more
context-sensitive filtering.  Works as a class method to support the 'add' context.

=head3 nuke

Perform full depth-wise destruction of a database record.  The default implementation runs an alghorithm to delete
all child records and finally delete $self.  Override this to prohibit (by dieing) or perform additional work.

=head3 all the rest

Of course, all the methods described at L<DBIx::Class::Row> can be overriden here.

=head1 CAVEAT

We use dynamically-generated DBIx::Class classes.  This technique does not scale well for very large numbers
of tables.  Previous (private) incarnations of this Framework used specially prepared high-performance versions of 
Class::DBI::Loader to speed this up.  So that speeding-up at start-time is a TODO for this DBIx::Class-based release.

=head1 SOURCE and ISSUES REPOSITORY

Open-Sourced at Github: L<https://github.com/frank-carnovale/Mojolicious-Plugin-Tables>.  Please use the Issues register there.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016, Frank Carnovale <frankc@cpan.org>

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<DBIx::Class::Schema::Loader>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
