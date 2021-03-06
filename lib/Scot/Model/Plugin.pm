package Scot::Model::Plugin;

use lib '../../lib';
use strict;
use warnings;
use v5.10;

use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use namespace::autoclean;

=head1 NAME
 Scot::Model::Plugin - a moose obj rep of a Scot Plugin

=head1 DESCRIPTION
   A plugin describes how to talk to an outside utility, and provide it user supplied options, and information about what data the user wants the utility to process.;
=cut

extends 'Scot::Model';


=head2 Attributes

=cut
with (  
    'Scot::Roles::Loggable',
    'Scot::Roles::Permittable', 
    'Scot::Roles::Dumpable', 
    'Scot::Roles::Hashable',
);

has plugin_id   => (
    is          => 'rw',
    isa         => 'Maybe[Int]',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item C<idfield>
 since my integer id fields in models include the model name in them 
 instead of just "id", this field gives us an easy way to figure out
 what the id attribute is.  We can debate the original choice later...
=cut
has idfield    => (
    is          => 'ro',
    isa         => 'Str',
    required    =>  1,
    default     => 'plugin_id',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<collection>
 easy way to keep track of object to collection mapping.  
 We can debate the original choice later...
=cut
has collection => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'plugins',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        serializable    => 0,
    },
);

=item C<name>
 link to an alert type -> a guide for this type of alert
=cut
has name  => (
    is          => 'rw',
    isa         => 'Str',
    default     => 'unspecified',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

enum 'plugin_type', [qw(simple advanced)];

=item C<type>
 If this is a "simple", or "advanced" style plugin.
=cut
has type  => (
    is          => 'rw',
    isa         => 'plugin_type',
    default     => 'simple',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);

=item C<plugin_html>
 HTML describing options to collect from user when running plugin
=cut
has plugin_html => (
     is       =>'rw',
     isa      =>'Str',
     default  => '',
     metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
      description => {
          gridviewable    => 1,
          serializable    => 1
      },
);

=item C<file_field>
 When a POST is sent to a URL in a multimime/form-data type format, each piece of data has a name
 and a value.  This is used to identify each piece of uploaded data on the server side.
   i.e. entity_value=192.168.0.1
 Files are uploaded via POST commands, so the file must have a form name.  
 For the scotty plugin, this is 'sample[file]', which is not the name of the file itself, but
 the field in which the file is uploaded.
=cut
has file_field => (
     is       =>'rw',
     isa      =>'Str',
     default  => '',
     metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
      description => {
          gridviewable    => 1,
          serializable    => 1
      },
);

=item C<submitURL>
 The URL that SCOT calls to initiate the plugin. 
=cut
has submitURL => (
     is       =>'rw',
     isa      =>'Str',
     default  => '',
     metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
      description => {
          gridviewable    => 1,
          serializable    => 1
      },
);

=item C<statusURL>
 The URL that SCOT calls to check on status of initiated plugin. 
=cut
has statusURL => (
     is       =>'rw',
     isa      =>'Str',
     default  => '',
     metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
      description => {
          gridviewable    => 1,
          serializable    => 1
      },
);

=item C<run>
 The metagroup the user must be in to run this plugin
=cut
has run => (
     is       =>'rw',
     isa      =>'Str',
     default  => 'scot',
     metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
      description => {
          gridviewable    => 1,
          serializable    => 1
      },
);

=item C<edit>
 The metagroup the user must be in to edit this plugin
=cut
has edit => (
     is       =>'rw',
     isa      =>'Str',
     default  => 'scot',
     metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
      description => {
          gridviewable    => 1,
          serializable    => 1
      },
);

=item C<entity_types>
 which types of entities should this show up in the menu for? ip address, hashes, domains, etc.
=cut
has entity_types  => (
    is          => 'rw',
    isa         => 'ArrayRef',
    traits      => [ 'Array' ],
    builder     => '_build_empty_array',
    metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
    description => {
        gridviewable    => 1,
        serializable    => 1
    },
);


=item custom new
    if you pass a Mojo::Message::Requst in as only parameter
        parse it and then do normal moose instantiation
=cut
around BUILDARGS    => sub {
    my $orig    = shift;
    my $class   = shift;

    if (@_ == 1 && ref $_[0] eq 'Scot::Controller::Handler') {
        my $req     = $_[0]->req;
        my $json    = $req->json;
        my $href    = {
            name  => $json->{'name'},
            env   => $_[0]->env,
        };
        my $rg = $json->{'readgroups'};
        my $mg = $json->{'modifygroups'};

        if (scalar(@$rg) > 0) {
            $href->{readgroups} = $rg;
        }

        if (scalar(@$mg) > 0 ) {
            $href->{modifygroups} = $mg;
        }

        return $class->$orig($href);
    }
    # pulls from db will be a hash ref
    # which moose will handle normally
    else {
        return $class->$orig(@_);
    }
};

sub _build_empty_array {
    return [];
}

#sub BUILD {
#    my $self    = shift;
#    my $log     = $self->log;
#    $log->debug("BUILT GUIDE OBJ");
#}

sub apply_changes {
    my $self    = shift;
    my $mojo    = shift;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];

    $log->debug("JSON received ".Dumper($json));

    while ( my ($k,$v) =  each %$json ) {
        if ($k eq "cmd") {
            $log->debug("command encounterd, but not expected");
        } 
        else {
            my $orig    = $self->$k;
            $self->$k($v);
            push @$changes, "Changed $k from $orig to $v";
        }
    }
    $self->updated($now);
}

sub build_modification_cmd {
    my $self    = shift;
    my $mojo    = shift;
    my $user    = $mojo->session('user');
    my $log     = $self->log;
    my $req     = $mojo->req;
    my $json    = $req->json;
    my $now     = $self->_timestamp();
    my $changes = [];
    my $data_href   = {};

    while ( my ($k, $v) = each %$json ) {
        if ( $k eq "cmd" ) {
            $log->error("command encountered but not expected");
        }
        else {
            my $orig    = $self->$k;
            if ($self->constraint_check($k,$v)) {
                push @$changes, "updated $k from $orig";
                $data_href->{'$set'}->{$k} = $v;
            }
            else {
                $log->error("Value $v does not pass type constraint for attribute $k!");
                $log->error("Requested update ignored");
            }
        }
    }
    $data_href->{'$set'}->{updated} = $now;
    my $modhref = {
        collection  => "plugins",
        match_ref   => { plugin_id  => $self->plugin_id },
        data_ref    => $data_href,
    };
    return $modhref;
}

 __PACKAGE__->meta->make_immutable;
1;
