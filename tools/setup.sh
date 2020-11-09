#!/bin/bash

if [ -z "$GENDEV" ]; then
    GENDEV=/opt/gendev
fi
EXTRACTION_PATH="/"

install() {
    PACKAGE_TERM="http.*txz"

    get_latest_release() {
        # *** Original lukechilds ***
        curl --silent "https://api.github.com/repos/$1/releases/latest" |   # Get latest release from GitHub api
            grep '"tag_name":' |                                            # Get tag line
            sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
        # Usage
        # $ "author/repo"
    }

    get_latest_release_package_url() {
        # *** Original xerus2000 ***
        curl --silent "https://api.github.com/repos/$1/releases/latest" | grep -o $PACKAGE_TERM | tail -n1
    }

    install_backup() {
        curl -L $GENDEV_RELEASE_BACKUP -o "$OUTDIR/$GENDEV_PACKAGE_BACKUP"
        if [ $? -ne 0 ]; then
            printf "Got package $GENDEV_PACKAGE\n"
            printf "Extracting...\n"
            sudo tar -xzf "$OUTDIR/$GENDEV_PACKAGE_BACKUP" -C "$EXTRACTION_PATH"
            if [ $? -ne 0 ]; then
                printf "Failed to install.\n"
            else
                printf "Extracted"
            fi
        else
            printf "Failed to download.\n"
        fi
    }

    GENDEV_AUTHOR_REPO="kubilus1/gendev"
    GENDEV_LATEST_RELEASE=$(get_latest_release "$GENDEV_AUTHOR_REPO")
    GENDEV_PACKAGE="gendev_$GENDEV_LATEST_RELEASE.txz"
    GENDEV_LATEST_PACKAGE_URL=$(get_latest_release_package_url $GENDEV_AUTHOR_REPO)
    OUTDIR="./tools/data"

    GENDEV_REPO="https://github.com/"$GENDEV_AUTHOR_REPO
    GENDEV_RELEASE_BACKUP=$GENDEV_REPO"/releases/download/0.4.1/gendev_0.4.1.txz"
    GENDEV_PACKAGE_BACKUP=$(echo $GENDEV_RELEASE_BACKUP | tr "/" "\n" | tail -n1)

    printf "Downloading gendev...\n"
    mkdir -p "$OUTDIR"
    curl -L "$GENDEV_LATEST_PACKAGE_URL" -o "$OUTDIR/$GENDEV_PACKAGE"

    if [ $? -ne 0 ]; then
        printf "Failed to download the latest version: attempting backup...\n"
        install_backup
    else
        printf "Got package $GENDEV_PACKAGE\n"
        printf "Extracting...\n"
        sudo tar -xzf "$OUTDIR/$GENDEV_PACKAGE" -C "$EXTRACTION_PATH"
        if [ $? -ne 0 ]; then
            printf "Failed to install the latest version: attempting backup...\n"
            install_backup
        else
            printf "Extracted\n"
        fi
    fi

    export GENDEV

    path_formatted=$(echo "$PATH" | tr '[:upper:]' '[:lower:]')
    if [ $path_formatted != *"gendev" ]; then
        printf "You can now add $GENDEV to your path.\n"
    fi
}

clean() {
    BUILD_DIR_LIST_SEP=", "

    if [ -n "$MD_BUILD_DIRS" ]; then
        IFS="$BUILD_DIR_LIST_SEP" read -ra MD_BUILD_DIRS <<< "$MD_BUILD_DIRS"
    else
        MD_BUILD_DIRS=("./tools/data" "./build" "./bin" "./dist")
    fi

    OBJECT_REMOVED=0

    for object in "${MD_BUILD_DIRS[@]}";
    do
        rm -rf "$object" & OBJECT_REMOVED=1
    done

    if [ $OBJECT_REMOVED ]; then
        printf "Successfully removed filesystem object(s)!\n"
    else
        printf "No operations made.\n"
    fi
}

uninstall() {
    sudo rm -rf "$GENDEV" && printf "Uninstalled.\n"
}

show_usage() {
    BASENAME=$(basename "$0")
    echo -e "Script to setup the build environment."
    echo -e
    echo -e "usage: $BASENAME [options]"
    echo -e "options:"
    echo -e " -i, --install, none"
    echo -e " -c, --clean"
    echo -e " -a, --all\tinstall and clean"
    echo -e " -u, --uninstall, -r, --remove\tuninstall build tools"
    echo -e " -h, --help"
}

if [ "$1" == "-i" ] || [ "$1" == "--install" ]; then
    install
elif [ "$1" == "-c" ] || [ "$1" == "--clean" ]; then
    clean
elif [ "$1" == "-a" ] || [ "$1" == "--all" ]; then
    install
    clean
elif [ "$1" == "-u" ] || [ "$1" == "--uninstall" ] || [ "$1" == "-r" ] || [ "$1" == "--remove" ]; then
    uninstall
elif [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    show_usage
else
    install
fi