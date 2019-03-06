#! env perl

use 5.22.0;
use WWW::Mechanize::Query;
use Text::CSV_XS;
use Carp qw(longmess);
use FileHandle;
STDOUT->autoflush();

my $mech = WWW::Mechanize::Query->new(onerror => sub { print longmess @_ });
my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
open my $out, ">:encoding(utf8)", "out.csv";
$out->autoflush();
open my $in, "<", "in.csv";
my $header = <$in>;   # Don't parse header
$header =~ s/[\r\n]+//g;
$csv->say($out, [ split /,/, $header ]);
while (<$in>) {
  s/[\r\n]+//g;
  my @line = split /,/, $_, -1;
  # Limit to a couple problem cases reported in Issue #1
  # next unless ($line[0] =~ /(CASE-17-00845|CASE-16-01401|CASE-17-00146)/);
  my $url = $line[7];
  print ".";
  my @owner = fetch_owner($url);
  if (@owner == 3) {
    # We found 3 lines of "Owner" so leave [9] "OWNER_NAME2" blank:
    $line[8] = shift @owner;  # OWNER_NAME
    splice @line, 10, 2, @owner;
  } else {
    # We (probably) found 4 lines of "Owner" so push it all onto the CSV:
    # See Issue #1
    splice @line, 8, 4, @owner;
  }
  $csv->say($out, [ @line ]);
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

