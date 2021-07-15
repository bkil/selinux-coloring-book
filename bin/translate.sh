#!/bin/sh
# sudo apt install gettext itstool librsvg2-bin fonts-georgewilliams fonts-ldco poppler-utils
# TODO: missing some more fonts

WORKDIR="`dirname "$0"`/.."

main() {
  mkdir -p "$WORKDIR/generated" || exit 1

  local LANG="hu"
  local SVG="$WORKDIR/generated/selinux-coloring-book_source.svg"
  local PDF="$WORKDIR/generated/`basename "$SVG" .svg`_$LANG.pdf"
  po2svg $WORKDIR/SRC/"$LANG"/*.po "$SVG" &&
  svg2pdf "$SVG" "$PDF"
}

po2svg() {
  local PO="$1"
  local SVG="$2"
  local MO="$WORKDIR/generated/tmp.mo"

  echo "debug: po2svg" >&2
  msgfmt -o "$MO" "$1" &&
  itstool \
    -m "$MO" \
    -o "$SVG" \
    "$WORKDIR/SRC/selinux-coloring-book_source.svg" &&
  sed -i -r 's~(</?)default:(tspan)~\1\2~g' "$SVG"
}

svg2pdf() {
  local SVG="$1"
  local PDF="$2"
  local SVGPAGE="$WORKDIR/generated/tmp.svg"
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
      
      local PDFPAGE="$WORKDIR/generated/page-$PAGENUMBER.pdf"
      echo "$PDFPAGE"
      rsvg-convert --x-zoom 0.7787 --y-zoom 0.85 -f pdf -o "$PDFPAGE" "$SVGPAGE" || return 1
      # inkscape --export-pdf="$PDFPAGE" "$SVGPAGE"

      PAGENUMBER=`expr $PAGENUMBER + 1`
    done
  } |
  xargs echo |
  {
    read PDFNAMES
    pdfunite $PDFNAMES "$PDF" || return 1
  }
}

download() {
  echo wget --directory-prefix="$HOME/" --no-clobber --output-file="$2" "$1"
}

list_fonts() {
  sed "s~>~&\n~g" "$WORKDIR/generated/selinux-coloring-book_source_HU.svg" |
  grep 'font-family:' |
  sed -r 's~.*font-family:([^;"]*)[";].*~\1~' |
  uniq |
  sort -u
}

main "$@"
