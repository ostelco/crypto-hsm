NR<4 {next}
$3~/0000$|9999$/ {next}
$1~/EOF/ {next}
{print $1}
