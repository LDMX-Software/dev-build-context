BEGIN {
    in_install=0;
}
{
  # check if this line is in an install command
  if (in_install && NF > 0) {
    # print out all entires on line except the line continuation backslash
    for (i=1; i <= NF; i++) {
      if ($i != "\\") {
        print $i;
      }
    }
  }
  # update for next lines if we are opening an install command or closing
  if ($0 ~ /^RUN install-ubuntu-packages.*$/) {
    in_install=1;
  } else if (NF == 0 || $1 == "RUN" && $2 != "install-ubuntu-packages") {
    in_install=0;
  }
}
