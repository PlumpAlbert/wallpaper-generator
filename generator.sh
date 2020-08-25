#!/bin/sh

# Get display dimensions
WIDTH=$(xdpyinfo | awk '/dimensions/ {split($2, D, "x"); print D[1]}')
HEIGHT=$(xdpyinfo | awk '/dimensions/ {split($2, D, "x"); print D[2]}')

# Generate gradient
convert -size "$HEIGHT"x"$WIDTH" gradient: -rotate 90 \
  \( +size xc:'#8a2387' xc:'#e94057' xc:'#f27121' +append \) -clut \
  /tmp/gradient.png

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

