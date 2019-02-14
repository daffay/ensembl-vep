=head1 LICENSE

Copyright [2016-2019] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut


=head1 CONTACT

 Please email comments or questions to the public Ensembl
 developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

 Questions may also be sent to the Ensembl help desk at
 <http://www.ensembl.org/Help/Contact>.

=cut

# EnsEMBL module for Bio::EnsEMBL::VEP::OutputFactory::VEP_output
#
#

=head1 NAME

Bio::EnsEMBL::VEP::OutputFactory::VEP_output - VEP format output factory

=head1 SYNOPSIS

my $of = Bio::EnsEMBL::VEP::OutputFactory::VEP_output->new({
  config => $config,
});

# print headers
print "$_\n" for @{$of->headers};

# print output
print "$_\n" for @{$of->get_all_lines_by_InputBuffer($ib)};

=head1 DESCRIPTION

An OutputFactory class to generate VEP-format output.

This is a tab-delimited format designed to present one line of
data per VariationFeatureOverlapAllele object (i.e. one line
per variant allele/feature combination).

There are 13 fixed fields and one further "Extra" field that
contains semicolon-separated KEY=VALUE pairs for any data that
does not go in the fixed fields, similar to the INFO field in
VCF.

The class shares a base class with
Bio::EnsEMBL::VEP::OutputFactory::Tab as there are several
methods that are shared between the two (but not with other
sub-classes of OutputFactory).

=head1 METHODS

=cut


use strict;
use warnings;

package Bio::EnsEMBL::VEP::OutputFactory::VEP_output;

use base qw(Bio::EnsEMBL::VEP::OutputFactory::BaseTab);

use Bio::EnsEMBL::VEP::Utils qw(convert_arrayref);
use Bio::EnsEMBL::VEP::Constants;

my %OUTPUT_COLS_HASH = map {$_ => 1} @Bio::EnsEMBL::VEP::Constants::DEFAULT_OUTPUT_COLS;


=head2 output_hash_to_line

  Arg 1      : hashref $vf_hash
  Example    : $line = $of->output_hash_to_line($vf_hash);
  Description: Takes a hashref as generated by get_all_output_hashes_by_InputBuffer
               and returns a tab-delimited string ready for printing.
  Returntype : string
  Exceptions : none
  Caller     : get_all_lines_by_InputBuffer()
  Status     : Stable

=cut

sub output_hash_to_line {
  my $self = shift;
  my $hash = shift;

  # "core" fields
  my @line = map {defined($hash->{$_}) ? convert_arrayref($hash->{$_}) : '-'} @Bio::EnsEMBL::VEP::Constants::DEFAULT_OUTPUT_COLS;

  # add additional fields to "Extra" col at the end
  my %extra =
    map {$_ => $hash->{$_}}
    grep {!$OUTPUT_COLS_HASH{$_}}
    keys %$hash;

  my $field_order = $self->field_order;

  push @line, (
    join(';',
      map {$_.'='.convert_arrayref($extra{$_})}
      sort {
        (defined($field_order->{$a}) ? $field_order->{$a} : 100)
        <=>
        (defined($field_order->{$b}) ? $field_order->{$b} : 100)

        ||

        $a cmp $b
      }
      keys %extra
    )
    || '-'
  );

  return join("\t", @line);
}


=head2 description_headers

  Example    : $headers = $of->description_headers();
  Description: Gets column description headers e.g.
               ## Field1 : description1
  Returntype : arrayref of strings
  Exceptions : none
  Caller     : headers()
  Status     : Stable

=cut

sub description_headers {
  my $self = shift;

  my $field_descs = \%Bio::EnsEMBL::VEP::Constants::FIELD_DESCRIPTIONS;

  my @headers = '## Column descriptions:';

  push @headers,
    map {'## '.$_.' : '.($field_descs->{$_} || '?')}
    @Bio::EnsEMBL::VEP::Constants::DEFAULT_OUTPUT_COLS;
  
  push @headers, '## Extra column keys:';
  push @headers,
    map {'## '.$_.' : '.($field_descs->{$_} || '?')}
    @{$self->fields};

  push @headers, map {'## '.$_->[0].' : '.$_->[1]} @{$self->get_plugin_headers}, @{$self->get_custom_headers};

  return \@headers;
}


=head2 column_header

  Example    : $header = $of->column_header();
  Description: Gets column header e.g.
               #col1  col2  col3  col4
  Returntype : string
  Exceptions : none
  Caller     : headers()
  Status     : Stable

=cut

sub column_header {
  return '#'.join("\t", (@Bio::EnsEMBL::VEP::Constants::DEFAULT_OUTPUT_COLS, 'Extra'));
}


=head2 fields

  Example    : $fields = $of->fields();
  Description: Gets list of fields to be populated
  Returntype : arrayref of strings
  Exceptions : none
  Caller     : field_order(), 
  Status     : Stable

=cut

sub fields {
  my $self = shift;
  return $self->{fields} ||= $self->flag_fields;
}


=head2 field_order

  Example    : $order = $of->field_order();
  Description: Gets hashref giving the order of each field e.g.
               {
                 field1 => 1,
                 field2 => 2,
               }
  Returntype : hashref
  Exceptions : none
  Caller     : output_hash_to_line(), 
  Status     : Stable

=cut

sub field_order {
  my $self = shift;

  if(!exists($self->{field_order})) {
    my @fields = @{$self->fields};
    
    $self->{field_order}->{$fields[$_]} = $_ for 0..$#fields;
  }

  return $self->{field_order};
}

1;
