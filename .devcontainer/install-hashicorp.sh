#!/bin/bash

# Parameters
# NAME - defaults to terraform
# VERSION - defaults to latest
# OS - defaults to linux
NAME=${1:-terraform}
VERSION=${2:-latest}
OS=${3:-linux}
ARCH=${4:-amd64}

INSTALL_DIR="/usr/local/bin"


# List the product names based on this call
# https://api.releases.hashicorp.com/v1/products
list_products (){
    echo "Available HashiCorp products:"
    curl -s https://api.releases.hashicorp.com/v1/products | jq -r '.'
}

# use this url: https://api.releases.hashicorp.com/v1/releases/{product}
get_release(){
    # filter json:
    # .builds[] where each array item os == $OS and arch == "$ARCH"
    RELEASE_URL="https://api.releases.hashicorp.com/v1/releases/${NAME}/${VERSION}"
    curl -s "$RELEASE_URL" | jq -r --arg OS "$OS" --arg ARCH "$ARCH" '.builds[] | select(.os == $OS and .arch == $ARCH)'

}

# Main function
main (){
    echo "Installing HashiCorp tool: $NAME"
    echo "Version: $VERSION"
    echo "Operating System: $OS"

    # Temp directory
    temp_dir="./tmp/${NAME}/${VERSION}"

    # if $temp_dir exists then remove it\
    if [ -d "$temp_dir" ]; then
        echo "Removing existing temp directory: $temp_dir"
        rm -rf "$temp_dir"
    fi

    # make a temp directory: /tmp/${NAME}/${VERSION}
    mkdir -p "$temp_dir"
    echo "Created temp directory: $temp_dir"

    # get the download url from the get_release function
    download_url=$(get_release | jq -r '.url')
    echo "Download URL: $download_url"
    # download the file to $temp_dir and unzip it to $temp_dir
    echo "Downloading $NAME from $download_url"
    curl -o "$temp_dir/$NAME.zip" $download_url
    # dont move everything to /usr/local/bin 
    # just the binary who's name matches $NAME
    unzip -o "$temp_dir/$NAME.zip" -d "$temp_dir"

    mv "$temp_dir/$NAME" ${INSTALL_DIR}
    chmod +x ${INSTALL_DIR}/${NAME}
    echo "$NAME installed to ${INSTALL_DIR}$NAME"

     # if $temp_dir exists then remove it\
    if [ -d "$temp_dir" ]; then
        echo "Removing existing temp directory: $temp_dir"
        rm -rf "$temp_dir"
    fi
}

# Run the main function
main "$@"