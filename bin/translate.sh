#!/bin/sh
# sudo apt install gettext itstool librsvg2-bin fonts-georgewilliams fonts-ldco poppler-utils
# TODO: missing some more fonts


main() {
  mkdir -p generated || exit 1

  local SVG="generated/selinux-coloring-book_source.svg"
  local PDF="generated/`basename "$SVG" .svg`.pdf"
  po2svg SRC/hu/*.po "$SVG" &&
  svg2pdf "$SVG" "$PDF"
}

po2svg() {
  local PO="$1"
  local SVG="$2"
  local MO="generated/tmp.mo"

  echo "debug: po2svg" >&2
  msgfmt -o "$MO" "$1" &&
  itstool \
    -m "$MO" \
    -o "$SVG" \
    SRC/selinux-coloring-book_source.svg
}

svg2pdf() {
  local SVG="$1"
  local PDF="$2"
  local SVGPAGE="generated/tmp.svg"
  grep '^  <g' "$SVG" |
  sed -r 's~^.* id="([^"]*)".*$~\1~' |
  {
    local PAGENUMBER=0
    local ID
    while read ID; do
      printf " $ID " >&2
      sed -r "
        s~(id=\"layer1\".*style=\"display:)inline(\")~\1none\2~

        s~(id=\"$ID\".*style=\"display:)none(\")~\1inline\2~
        s~(style=\"display:)none(\".*id=\"$ID\")~\1inline\2~

        s~(id=\"$ID\".*transform=\"translate\()0,-62.35975(\)\")~\1(-2000,-2062.35975)\2~
        s~(transform=\"translate\()0,-62.35975(\)\".*id=\"$ID\")~\1(-2000,-2062.35975)\2~
        " "$SVG" > "$SVGPAGE"
      
      local PDFPAGE="generated/page-$PAGENUMBER.pdf"
      echo "$PDFPAGE"
      rsvg-convert --x-zoom 0.7787 --y-zoom 0.85 -f pdf -o "$PDFPAGE" "$SVGPAGE"
      PAGENUMBER=`expr $PAGENUMBER + 1`
    done
  } |
  xargs echo |
  {
    read PDFNAMES
    pdfunite $PDFNAMES "$PDF"
  }
}

get_fonts() {
  sed "s~>~&\n~g" generated/selinux-coloring-book_source_HU.svg |
  grep 'font-family:' |
  sed -r 's~.*font-family:([^;"]*)[";].*~\1~' |
  uniq |
  sort -u
}

main "$@"

exit $?

rsvg-convert -f pdf -o x.pdf in.svg
inkscape --export-pdf=x.pdf in.svg

  <g inkscape:label="Front Cover" inkscape:groupmode="layer" id="layer1" transform="translate(0,-62.35975)" style="display:inline" sodipodi:insensitive="true">
  <g transform="translate(0,-62.35975)" id="g5994" inkscape:groupmode="layer" inkscape:label="Pages 1" style="display:none" sodipodi:insensitive="true">
