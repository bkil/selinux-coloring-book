#!/bin/sh
# sudo apt install gettext itstool librsvg2-bin fonts-georgewilliams poppler-utils
# TODO: missing some more fonts

WORKDIR="`dirname "$0"`/.."

main() {
  mkdir -p "$WORKDIR/generated" || exit 1
  [ "$1" = "-r" ] && FORCE_RSVG="1"

  get_fonts

  local LANG="hu"
  local SVG="$WORKDIR/generated/selinux-coloring-book_source_$LANG.svg"
  local PDF="$WORKDIR/generated/`basename "$SVG" .svg`.pdf"

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
  sed -i -r "
    s~(</?)default:(tspan)~\1\2~g
    s~(;font-family:Interstate)-Regular~\1~g
    s~(;font-family:)Sans~\1FreeSans~g
    s~(;font-family:)Knewave Outline~\1Atavyros~g
    s~(;font-family:)Knewave(;)~\1,Luckiest Guy\2~g
    s~(;font-family:Miso)~\1,Amiri~g
    " "$SVG"
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
      svg2pdf_single_page "$SVGPAGE" "$PDFPAGE"

      PAGENUMBER=`expr $PAGENUMBER + 1`
    done
    echo "page generation done" >&2
  } |
  xargs echo |
  {
    read PDFNAMES
    pdfunite $PDFNAMES "$PDF" || return 1
  }
}

svg2pdf_single_page() {
  local SVGPAGE="$1"
  local PDFPAGE="$2"
  if [ -z "$FORCE_RSVG" ] && which inkscape > /dev/null; then
    inkscape --export-pdf="$PDFPAGE" "$SVGPAGE"
  else
    rsvg-convert --x-zoom 0.7787 --y-zoom 0.85 -f pdf -o "$PDFPAGE" "$SVGPAGE"
  fi
}

get_fonts() {
  local FONTDIR="$HOME/.fonts"
  mkdir -p "$FONTDIR"
  local NEW=""
  local ZIP="download_extract_zip $FONTDIR"
  local GET="download $FONTDIR"

  # https://www.dafont.com/architect-s-daughter.font
  $ZIP "https://dl.dafont.com/dl/?f=architect_s_daughter" "ArchitectsDaughter.ttf" && NEW=1

  # https://www.dafont.com/titan-one.font
  $ZIP "https://dl.dafont.com/dl/?f=titan_one" "TitanOne-Regular.ttf" && NEW=1

  # http://theleagueofmoveabletype.com/ Tyler Finck
  $GET https://github.com/theleagueof/knewave/raw/master/knewave.ttf && NEW=1
  $GET https://github.com/theleagueof/knewave/raw/master/knewave-outline.ttf && NEW=1

  # https://dafontfamily.com/interstate-font-free-download/ 1993 (c) Tobias Frere-Jones
  $ZIP https://dafontfamily.com/download/interstate-font/ Interstate-Regular-Font.ttf && NEW=1

  # https://www.ffonts.net/Luckiest-Guy.font Astigmatic One Eye Typographic Institute - Brian J. Bonislawsky
  $ZIP https://www.ffonts.net/Luckiest-Guy.font.zip LuckiestGuy.ttf && NEW=1

  # https://www.ffonts.net/Miso.font http://martennettelbladt.se/miso/ Copyright (c) Mårten Nettelbladt, 2006
  $ZIP https://www.ffonts.net/Miso.font.zip miso-regular.ttf && NEW=1

  if [ -n "$NEW" ]; then
    echo "debug: regenerating font cache" >&2
    fc-cache -f -v "$FONTDIR"
  fi
}

download() {
  local FONTDIR="$1"
  local URL="$2"
  if [ $# -eq 3 ]; then
    local BASE="$3"
  else
    local BASE="`basename $URL`"
  fi
  local FILE="$FONTDIR/$BASE"

  if [ -f "$FILE" ]; then
    return 1
  else
    wget --output-document="$FILE" "$URL"
  fi
}

download_extract_zip() {
  local FONTDIR="$1"
  local URL="$2"
  local FILE="$3"
  local TMP="$WORKDIR/generated/tmp.zip"

  if [ -f "$FONTDIR/$FILE" ]; then
    return 1
  else
    wget --output-document="$TMP" "$URL"
    unzip -d "$FONTDIR" "$TMP" "$FILE"
  fi
}

list_fonts() {
  sed "s~>~&\n~g" "$WORKDIR/generated/selinux-coloring-book_source_HU.svg" |
  grep 'font-family:' |
  sed -r 's~.*font-family:([^;"]*)[";].*~\1~' |
  uniq |
  sort -u
}

main "$@"
