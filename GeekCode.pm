# $File: //member/autrijus/GeekCode/GeekCode.pm $ $Author: autrijus $
package Convert::GeekCode;
require 5.001;

$Convert::GeekCode::VERSION = '0.5';

use strict;
use vars qw/@ISA @EXPORT $VERSION $DELIMITER/;

use YAML ();
use Exporter;

=head1 NAME

Convert::GeekCode - Convert and generate geek code sequences

=head1 SYNOPSIS

    use Convert::GeekCode; # exports geek_decode()

    my @out = geek_decode(q(
    -----BEGIN GEEK CODE BLOCK-----
    Version: 3.12
    GB/C/CM/CS/CC/ED/H/IT/L/M/MU/P/SS/TW/AT d---x s+: a-- C++++ UB++++$
    P++++$ L+ E--->+ W+++$ N++ !o K w--(++) O-- M-@ !V PS+++ PE Y+>++
    PGP++ t+ 5? X+ R+++ !tv b++++ DI+++@ D++ G++++ e-(--) h* r++(+) z++*
    ------END GEEK CODE BLOCK------
    )); # yes, that's the author's geek code

    my ($key, $val);
    print "[$key]\n$val\n\n" while (($key, $val) = splice(@out, 0, 2));

=head1 DESCRIPTION

B<Convert::GeekCode> converts and generates Geek Code sequences (cf.
L<http://geekcode.com/>). It supports different langugage codes and
user-customizable codesets.

Since version 0.5, this module uses B<YAML> to represent the geek code
tables, for greater readability and ease of deserialization.  Please
refer to L<http://www.yaml.org/> for more related information.

The F<geekgen> and F<geekdec> utilities are installed by default,
and may be used to generate / decode geek code blocks, respectively.

=cut

@ISA	= qw/Exporter/;
@EXPORT	= qw/geek_encode geek_decode/;
$DELIMITER = " ";

sub new {
    my $class   = shift;
    my $id      = shift || 'geekcode';
    my $version = shift || '3.12';
    my $lang    = shift || 'en_us';
    my ($cursec, $curcode, $curval);

    $lang =~ tr/-/_/; # paranoia

    my $file = locate("$id/$version/$lang.yaml")
        or die "cannot locate $id/$version/$lang.yaml in @INC";
        
    my $self = YAML::LoadFile($file);
    return bless($self, $class);
}

sub decode {
    my ($self, $code) = @_;

    die "can't find geek code block; stop."
	unless $code =~ m|\Q$self->{Head}\E([\x00-\xff]+)\Q$self->{Tail}\E|;

    $code = $1; $code =~ s|[\x00-\xff]*?^$self->{Begin}|_|m or die;

    my @ret;

    foreach my $chunk (split(/[\s\t\n\r]+/, $code)) {
        next unless $chunk =~ m|^(\!?\w+)\b|;

        my $head = $1;
        while ($head) {
            if (exists($self->{_}{$head})) {
                my $sec = $self->{_}{$head};
                my $out;

                push @ret, $sec->{_};
                $chunk = substr($chunk, length($head));
                $out = $sec->{''} . $DELIMITER
                    if !$chunk or $chunk =~ /^[\>\(]/;

                while ($chunk) {
                    next if $self->tokenize($sec, \$chunk, \$out);
                    next if $self->tokenize($self->{_}{''}, \$chunk, \$out);

                    warn "parse error: ", substr($chunk, 0, 1);
                    $chunk = substr($chunk, 1);
                }

                push @ret, $out;
                last;
            }

            $head = substr($head, 0, -1);
        }
    }

    return @ret;
}

sub encode {
    my ($self, $code) = @_;

    my @out;
    foreach my $sec (split(/[\s\t\n\r]+/, $self->{Sequence})) {
        my $secref = $self->{_}{$sec} or next;
        $sec = $self->{Begin} if $sec eq '_';
        push @out, $code->($secref->{_}, map {
            my $sym = $secref->{$_};
            s/[\x27\/]//g;
            (((index($_, $sec) > -1) 
		? $_ : ($_ eq '!' ? "$_$sec" : "$sec$_")
	    ), $sym);
        } grep {
            $_ ne '_'
        } sort {
            calcv($a) cmp calcv($b);
        } keys(%{$secref}));

        $out[-1] =~ s|\s+|/|g;
        $out[-1] =~ s|/+$||;
        $out[-1] =~ s|(?<=.)$sec||g;
    }

    return join("\n",
        $self->{Head},
        $self->{Ver}.$self->{Version},
        join(' ', @out),
        $self->{Tail},
        '',
    );
}

sub calcv {
    my $sym = shift or return '';

    return chr(0) x (10 - length($sym))	if substr($sym, 0, 1) eq '+';
    return chr(2) x length($sym)	if substr($sym, 0, 1) eq '-';
    return chr(1)			if $sym eq '';
    return $sym;
}

sub tokenize {
    my ($self, $sec, $chunk, $out) = @_;

    foreach my $key (sort {length($b) <=> length($a)} keys(%{$sec})) {
        next if $key eq '_' or !$key;

        if ($key =~ m|/(.+)/|) {
            if ($$chunk =~ s|^$1||) {
                $$out .= $sec->{$key} . $DELIMITER;
                return 1;
            }
        }
        elsif ($$chunk =~ s/^\Q$key\E//) {
	    $$out .= $sec->{$key} . $DELIMITER;
	    return 1;
        }
    }

    return;
}

sub locate {
    my $path = (caller)[0];
    my $file = $_[0];

    $path =~ s|::|/|g;
    $path =~ s|\w+\$||;

    unless (-e $file) {
        foreach my $inc (@INC) {
            last if -e ($file = join('/', $inc, $_[0]));
            last if -e ($file = join('/', $inc, $path, $_[0]));
        }
    }

    return -e $file ? $file : undef;
}

sub geek_decode {
    my $code = shift;
    my $obj = __PACKAGE__->new(@_); # XXX should auto-detect version

    return $obj->decode($code);
}

sub geek_encode {
    my $code = shift;
    my $obj = __PACKAGE__->new(@_); # XXX should auto-detect version

    return $obj->encode($code);
}

1;

__END__

=head1 SEE ALSO

L<geekgen>, L<geekdec>, L<YAML>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2001, 2002 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
