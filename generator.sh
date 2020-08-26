#!/bin/sh

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

# Get quote text
if ! [ -f "$HOME/.cache/qod" ]; then
  export data="$(curl -sL 'https://quotes.rest/qod')"
  echo $data > "$HOME/.cache/qod"
else
  export data="$(cat "$HOME/.cache/qod")"
fi
TEXT="$(echo "$data" | jq -rc '.contents.quotes[0].quote' | fold -w 64 -s)"
AUTHOR="$(echo "$data" | jq -rc '.contents.quotes[0].author' | fold -w 64 -s)"

# Add text over the image
convert \
  -background none -gravity center \
  -fill white -font 'Google-Sans-Regular' \
  -pointsize 32 \
  label:"$TEXT" \
  /tmp/text.png

convert \
  -background none \
  -fill white -font 'Google-Sans-Regular' \
  -pointsize 16 \
  label:"$AUTHOR" \
  /tmp/author.png

composite -gravity center \
  /tmp/text.png /tmp/gradient.png \
  image.png

TEXT_HEIGHT="$(identify -format '%h' /tmp/text.png)"

composite \
  -gravity center -geometry +0+"$TEXT_HEIGHT" \
  /tmp/author.png image.png \
  image.png

