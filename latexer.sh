#!/bin/bash

# Set the default image and container name
IMAGE_NAME="latexer"
CONTAINER_NAME="latex_compiler"
DOCKERFILE_PATH="."
WATCH=false
TLMGR_PACKAGES=""

# Function to show usage information
show_help() {
  echo "Usage: $0 [options] <filename>"
  echo ""
  echo "Options:"
  echo "  -w, --watch            Enable file watching using inotifywait"
  echo "  --tlmgr <packages>     Install additional LaTeX packages using tlmgr"
  echo "  -h, --help             Display this help message"
  echo ""
  exit 0
}

# Parse the arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -w|--watch)
      WATCH=true
      shift
      ;;
    --tlmgr)
      TLMGR_PACKAGES="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      ;;
    -*|--*)
      echo "Unknown option: $1"
      show_help
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

# Restore positional arguments
set -- "${POSITIONAL[@]}"

# Check if there is an argument passed to the script
if [ $# -eq 0 ]; then
  echo "Error: No filename provided."
  show_help
fi

# Get the filename and its parent directory
FILE="$1"
FILE_DIR="$(readlink -f $(dirname "$FILE"))"
FILE_NAME="$(basename "$FILE")"
STY_DIR="$FILE_DIR/sty"
EXT="${FILE##*.}"

# Function to compile the document
compile() {
  if [ "$EXT" == "tex" ]; then
    docker exec -it $CONTAINER_NAME pdflatex -output-directory "/workspace" -include-directory="/workspace/sty" "/workspace/${FILE_NAME}"
  elif [ "$EXT" == "md" ]; then
    docker exec -it $CONTAINER_NAME pandoc "/workspace/${FILE_NAME}" -o "/workspace/${FILE_NAME%.md}.pdf"
  else
    echo "Unsupported file type: $EXT"
    exit 1
  fi
}

# Function to build the Docker image if it doesn't exist
build_image_if_needed() {
  if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
    echo "Docker image $IMAGE_NAME not found. Building the image..."
    docker build -t $IMAGE_NAME $DOCKERFILE_PATH
    if [ $? -ne 0 ]; then
      echo "Error building the Docker image."
      exit 1
    fi
  else
    echo "Docker image $IMAGE_NAME found."
  fi
}

# Function to install additional tlmgr packages
install_tlmgr_packages() {
  if [ -n "$TLMGR_PACKAGES" ]; then
    echo "Installing additional LaTeX packages: $TLMGR_PACKAGES"
    docker exec -it $CONTAINER_NAME tlmgr install $TLMGR_PACKAGES
    if [ $? -ne 0 ]; then
      echo "Error installing LaTeX packages with tlmgr."
      exit 1
    fi
  fi
}

# Check if the image needs to be built
build_image_if_needed

# Check if the container is running
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" == "" ]; then
  echo "Starting a new container..."
  docker run -d --name $CONTAINER_NAME -v "$FILE_DIR":/workspace -v "$STY_DIR":/workspace/sty $IMAGE_NAME tail -f /dev/null
else
  echo "Container $CONTAINER_NAME is already running."
fi

# Install additional tlmgr packages if provided
install_tlmgr_packages

# Run initial compilation
compile

# Function to watch for changes using inotifywait
watch_for_changes() {
  while true; do
    inotifywait -r -e modify "$FILE_DIR" "$STY_DIR"
    sleep 5 # Wait for 5 seconds to avoid rapid recompilation on small changes
    echo "Change detected. Recompiling..."
    compile
  done
}

# Start watching for changes if the watch option is enabled
if [ "$WATCH" = true ]; then
  watch_for_changes
fi

