#!/bin/sh
fail() {
  echo "$1"
  exit 1
}

SCRIPT_LOCATION="${0%/*}"

# Parse arguments
while [ $# -ne 0 ]; do
  case $1 in
    -a | --author)
      shift
      export AUTHOR="$1"
      ;;
    *)
      export TEXT="$1"
      ;;
  esac
  shift
done
[[ -z "$TEXT" && ! -t 0 ]] && export TEXT="$(cat -)"
[ -z "$TEXT" ] && fail "No message was provided"
[ -z "$AUTHOR" ] && export AUTHOR="$(whoami)"

# Get display dimensions
WIDTH=$(xdpyinfo | awk '/dimensions/ {split($2, D, "x"); print D[1]}')
HEIGHT=$(xdpyinfo | awk '/dimensions/ {split($2, D, "x"); print D[2]}')

# Generate gradient
gradient() {
  GRADIENTS_LEN=$(jq -cr '. | length' "$SCRIPT_LOCATION/gradients.json")
  COLORS="$(jq -cr ".[$(( RANDOM % GRADIENTS_LEN ))].colors" "$SCRIPT_LOCATION/gradients.json" | sed -e 's/[][]//g')"
  COLORS=(${COLORS//,/ })
  IM_COLORS=""
  for c in "${COLORS[@]}"; do
    export IM_COLORS="$IM_COLORS xc:$c"
  done

  # Generating gradient image
  echo "$IM_COLORS" | \
    xargs -i echo "-size \"$HEIGHT\"x$WIDTH gradient: -rotate 90 \\( +size {} +append \\) -clut -blur 3x3 /tmp/gradient.png" | \
    xargs convert
}

gradient

# Add text over the image
convert \
  -background none -gravity center \
  -fill white \
  -pointsize 32 \
  pango:"<span face='Google Sans' fallback='true'>$(echo "$TEXT" | fold -bsw 72)</span>" \
  /tmp/text.png

convert \
  -background none \
  -fill white \
  -pointsize 16 \
  pango:"<span style='italic' face='Google Sans' fallback='true'>$(echo "$AUTHOR" | fold -bsw 64)</span>" \
  /tmp/author.png

composite -gravity center \
  /tmp/text.png /tmp/gradient.png \
  image.png

TEXT_HEIGHT="$(identify -format '%h' /tmp/text.png)"

composite \
  -gravity center -geometry +0+"$(( (TEXT_HEIGHT / 2) + 48 ))" \
  /tmp/author.png image.png \
  image.png

