FROM pandoc/latex:3

# Install necessary packages, including inotify-tools and dumb-init
RUN apk update && apk add \
  inotify-tools \
  dumb-init \
  pandoc \
  make \
  && tlmgr install \
  fancyvrb \
  tcolorbox \
  listings \
  xcolor

# Set dumb-init as the entry point
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Set the default command to keep the container running
CMD ["tail", "-f", "/dev/null"]

# Commands are run from the latexer.sh script
