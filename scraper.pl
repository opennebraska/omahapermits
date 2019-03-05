#! env perl

use 5.22.0;
use WWW::Mechanize::Query;
use Carp qw(longmess);
use FileHandle;
STDOUT->autoflush();

my $mech = WWW::Mechanize::Query->new(onerror => sub { print longmess @_ });
open my $out, ">", "out.csv";
$out->autoflush();
open my $in, "<", "in.csv";
my $header = <$in>;   # Don't parse header
print $out $header;
while (<$in>) {
  my @line = split /,/;
  my $url = $line[7];
  print ".";
  my @owner = fetch_owner($url);
  $line[8]  = $owner[0];  # OWNER_NAME
  $line[10] = $owner[1];  # ADDRESS
  $line[11] = $owner[2];  # OWNER_CITY-ST-ZIP
  print $out join ",", @line;
  print $out "\n";
}

say "Exiting";


sub fetch_owner {
  my ($url) = @_;
  $mech->get($url);
  my @owner;
  # Gah. This is a really scarily non-specific CSS selector to use, but seems to work :/
  # It would be nice if I could figure out how to get to the sibling span of the h1
  # that has a child span whose id matches *permitdetail_label_owner*
  # but I couldn't get that CSS selector working... See DOM example below.
  $mech->find('td[style="vertical-align:top"]')->each(sub { push @owner, $_->text });
  return @owner;
}

__END__
Example DOM snippet we're trying to grab:
From https://www.omahapermits.com/permitinfo/Cap/CapDetail.aspx?Module=Enforcement&TabName=Enforcement&capID1=18CAP&capID2=00000&capID3=003ME

<h1>
  <span id="ctl00_PlaceHolderMain_PermitDetailList1_per_permitdetail_label_owner636873222828512865">Owner:</span>
</h1>
<span class="ACA_SmLabel ACA_SmLabel_FontSize">
  <table role='presentation' style='TEMPLATE_STYLE' class='table_child'>
    <tr>
      <td class='td_child_left font12px'></td>
      <td>
        <table role='presentation' border='0' cellpadding='0' cellspacing='0'>
          <tr>
            <td style='vertical-align:top'>PROOF EXTERIORS LLC</td>
          </tr>
          <tr>
            <td style='vertical-align:top'>2419 N 84 ST #3</td>
          </tr>
          <tr>
            <td style='vertical-align:top'>OMAHA NE 68134 </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</span>

