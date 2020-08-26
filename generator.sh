#!/bin/sh
fail() {
  echo "$1"
  exit 1
}

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
[[ -z "$TEXT" && ! -t 0 ]] && export TEXT="$(cat -)" \
  || fail "No message was provided"
[ -z "$AUTHOR" ] && export AUTHOR="$(whoami)"

# Get display dimensions
WIDTH=$(xdpyinfo | awk '/dimensions/ {split($2, D, "x"); print D[1]}')
HEIGHT=$(xdpyinfo | awk '/dimensions/ {split($2, D, "x"); print D[2]}')

# Generate gradient
gradient() {
  GRADIENTS_LEN=$(jq -cr '. | length' gradients.json)
  COLORS="$(jq -cr ".[$(( RANDOM % GRADIENTS_LEN  ))].colors" gradients.json | sed -e 's/[][]//g')"
  COLORS=(${COLORS//,/ })
  IM_COLORS=""
  for c in "${COLORS[@]}"; do
    export IM_COLORS="$IM_COLORS xc:$c"
  done

  # Generating gradient image
  ARGS=$(echo "$IM_COLORS" | xargs -i echo "-size 1080x1920 gradient: -rotate 90 \\( +size {} +append \\) -clut /tmp/gradient.png")
  echo $ARGS | xargs convert
}

gradient

# Add text over the image
convert \
  -background none -gravity center \
  -fill white -font 'Google-Sans-Regular' \
  -pointsize 32 \
  label:"$(echo "$TEXT" | fold -w 72 -s)" \
  /tmp/text.png

convert \
  -background none \
  -fill white -font 'Google-Sans-Regular' \
  -pointsize 16 \
  label:"$(echo "$AUTHOR" | fold -w 64 -s)" \
  /tmp/author.png

composite -gravity center \
  /tmp/text.png /tmp/gradient.png \
  image.png

TEXT_HEIGHT="$(identify -format '%h' /tmp/text.png)"

composite \
  -gravity center -geometry +0+"$TEXT_HEIGHT" \
  /tmp/author.png image.png \
  image.png

