#!/bin/sh
# sudo apt install gettext itstool librsvg2-bin fonts-georgewilliams fonts-ldco poppler-utils
# TODO: missing some more fonts

WORKDIR="`dirname "$0"`/.."

main() {
  mkdir -p "$WORKDIR/generated" || exit 1

  get_fonts

  local LANG="hu"
  local SVG="$WORKDIR/generated/selinux-coloring-book_source_$LANG.svg"
  local PDF="$WORKDIR/generated/`basename "$SVG" .svg`.pdf"

  if [ -f "$SVG" ]; then
    echo "debug: using cached version of $SVG" >&2
  else
    po2svg $WORKDIR/SRC/"$LANG"/*.po "$SVG"
  fi

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
    echo "page generation done" >&2
  } |
  xargs echo |
  {
    read PDFNAMES
    pdfunite $PDFNAMES "$PDF" || return 1
  }
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
    wget --no-clobber --output-document="$TMP" "$URL"
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
