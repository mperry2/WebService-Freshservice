package WebService::Freshservice::User;

use v5.010;
use strict;
use warnings;
use Method::Signatures 20140224;
use List::MoreUtils qw(any);
use Carp qw( croak );
use JSON qw( encode_json );
use WebService::Freshservice::User::CustomField;
use Moo;
use MooX::HandlesVia;
use namespace::clean;

# ABSTRACT: Freshservice User

# VERSION: Generated by DZP::OurPkg:Version

=head1 SYNOPSIS

  use WebService::Freshservice::User;

  my $request = WebService::Freshservice::User->new( api => $api, id => '1234567890' );

Requires an 'WebService::Freshservice::API' object and user id.

=head1 DESCRIPTION

Provides a Freshservice user object. Though users are referred to
as 'Requesters' and 'Agents', agents are a super set of a user.

=cut

my $Ref = sub {
    croak("api isn't a 'WebService::Freshservice::API' object!") unless $_[0]->DOES("WebService::Freshservice::API");
};

# Library Fields
has 'api'               => ( is => 'rw', required => 1, isa => $Ref );
has 'id'                => ( is => 'ro', required => 1 );
has '_attributes'       => ( is => 'rwp', lazy => 1, builder => 1 );
has '_attributes_rw'    => ( is => 'rwp', lazy => 1, builder => 1 );
has '_raw'              => ( is => 'rwp', lazy => 1, builder => 1, clearer => 1 );

# Fixed fields
has 'active'            => ( is => 'rwp', lazy => 1, builder => '_build_user', clearer => 1 );
has 'created_at'        => ( is => 'rwp', lazy => 1, builder => '_build_user', clearer => 1 );
has 'deleted'           => ( is => 'rwp', lazy => 1, builder => '_build_user', clearer => 1 );
has 'department_names'  => ( is => 'rwp', lazy => 1, builder => '_build_user', clearer => 1 );
has 'helpdesk_agent'    => ( is => 'rwp', lazy => 1, builder => '_build_user', clearer => 1 );
has 'updated_at'        => ( is => 'rwp', lazy => 1, builder => '_build_user', clearer => 1 );

# Updateable Fields
has 'address'           => ( is => 'rw', lazy => 1, builder => '_build_user', clearer => 1 );
has 'description'       => ( is => 'rw', lazy => 1, builder => '_build_user', clearer => 1 );
has 'email'             => ( is => 'rw', lazy => 1, builder => '_build_user', clearer => 1 );
has 'external_id'       => ( is => 'rw', lazy => 1, builder => '_build_user', clearer => 1 );
has 'language'          => ( is => 'rw', lazy => 1, builder => '_build_user', clearer => 1 );
has 'location_name'     => ( is => 'rw', lazy => 1, builder => '_build_user', clearer => 1 );
has 'job_title'         => ( is => 'rw', lazy => 1, builder => '_build_user', clearer => 1 );
has 'mobile'            => ( is => 'rw', lazy => 1, builder => '_build_user', clearer => 1 );
has 'name'              => ( is => 'rw', lazy => 1, builder => '_build_user', clearer => 1 );
has 'phone'             => ( is => 'rw', lazy => 1, builder => '_build_user', clearer => 1 );
has 'time_zone'         => ( is => 'rw', lazy => 1, builder => '_build_user', clearer => 1 );

method _build__raw {
  return $self->api->get_api( "itil/requesters/".$self->id.".json" );
}

method _build_user {
  # Grab our calling method by dropping 'WebService::Freshservice::User::'
  my $caller = substr((caller 1)[3],32);
  return $self->_raw->{user}{$caller};
}

method _build__attributes {
  my @attributes = qw( 
    active custom_field created_at deleted department_names
    helpdesk_agent updated_at
  );
  push(@attributes, @{$self->_attributes_rw});
  return \@attributes;
}

method _build__attributes_rw {
  my @attributes = qw( 
    address description email external_id language 
    location_name job_title mobile name phone time_zone 
  );
  return \@attributes;
}

method _clear_all {
  foreach my $attr (@{$self->_attributes}) {
    my $clearer = "clear_$attr";
    $self->$clearer;
  }
  $self->_clear_raw;
  return;
}

=method delete_requester

  $requester->delete_requester;

Returns 1 on success. Croaks on failure.

=cut

method delete_requester {
  return $self->api->delete_api( "itil/requesters/".$self->id.".json" );
}

=method update_requester
  
  $requester->update_requester;

The following attributes can be updated and 'PUT' against
the API:

  address description email external_id language 
  location_name job_title mobile name phone time_zone
    
Optionally takes named attributes of 'attr' and 'value' if only updating
a single attribute.

  $requester->update_requester( attr => 'address', value => 'Some new address' );
  
API returns 200 OK and no content regardless if the put resulted in a
successful change. Returns 1, croaks on failure.

=cut

method update_requester(:$attr?, :$value?) {
  if ( $attr ) {
    croak "'value' required if providing an 'attr'" unless $value;
    croak "'$attr' is not a valid attribute, valid attributes are".join(" ", @{$self->_attributes_rw}) unless
      any { $_ eq $attr } @{$self->_attributes_rw};
    my $update->{user}{$attr} = $value;
    $self->api->put_api( "itil/requesters/".$self->id.".json", $update);
    $self->_clear_all;
    return 1;
  }
  $self->api->put_api( "itil/requesters/".$self->id.".json", $self);
  $self->_clear_all;
  return 1;
}

=method custom_fields

  $requester->custom_fields;
  
Will return a hash of WebService::Freshservice::User::CustomField objects. Returns
an empty object if your freshservice instance doesn't have any custom fields
configured.

=cut

has 'custom_field' => (
  is            => 'rwp',
  handles_via   => 'Hash',
  lazy          => 1,
  builder       => 1,
  clearer       => 1,
  handles       => {
    _get_cf       => 'get',
    _set_cf       => 'set',
    custom_fields => 'keys'
  },
);

method _build_custom_field {
  my $custom_field = $self->_raw->{user}{custom_field};
  my $fields = { };
  foreach my $key ( keys $custom_field ) {
    $fields->{$key} = WebService::Freshservice::User::CustomField->new(
      id      => $self->id,
      api     => $self->api,
      field   => $key,
      value   => $custom_field->{$key},
    ) if defined $key;
  }
  return $fields;
}

=method set_custom_field

  $requester->set_custom_field(
    field => 'cf_field_name',
    value => 'field value',
  );

Set a custom field value. Takes an optional attribute of 'update'
which can be set to '0' and it will not 'PUT' the changes (handy
if you are trying to limit API calls and want are calling
'$requester->update_requester' later);

=cut

method set_custom_field(:$field, :$value, :$update = 1) {
  my $custom_field = $self->_get_cf($field);
  $custom_field->value($value);
  $custom_field->update_custom_field if $update;
  return;
}

=method get_custom_field

  say $updated->get_custom_field('cf_field_name')->value;

  or

  $custom_field = $updated->get_custom_field('cf_field_name');

Returns a WebService::Freshservice::User::CustomField object of
the named Custom Field. Croaks if the field doesn't exist in
freshservice.

=cut

method get_custom_field($field) {
  croak "Custom field must exist in freshservice" 
    unless exists $self->_raw->{user}{custom_field}{$field};
  return $self->_get_cf($field);
}

# Internal method that returns a clean perl data structure
# for encode_json
method TO_JSON {
  my $data->{user} = {
    address       => $self->address,
    description   => $self->description,
    custom_field  => $self->custom_field,
    email         => $self->email,
    external_id   => $self->external_id,
    language      => $self->language,
    location_name => $self->location_name,
    job_title     => $self->job_title,
    mobile        => $self->mobile,
    name          => $self->name,
    phone         => $self->phone,
    time_zone     => $self->time_zone,
  };
  return $data;
}

1;
