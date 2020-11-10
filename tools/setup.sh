#!/bin/bash

if [ -z "$GENDEV" ]; then
    GENDEV=/opt/gendev
    export GENDEV
fi

GENDEV_AUTHOR="kubilus1"
GENDEV_REPO="gendev"
GENDEV_AUTHOR_REPO="$GENDEV_AUTHOR/$GENDEV_REPO"
OUTDIR="./tools/data"

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

finalise_install() {
    export GENDEV

    path_formatted=$(echo "$PATH" | tr '[:upper:]' '[:lower:]')
    if [ $path_formatted != *"gendev" ]; then
        printf "If everything went according to plan you can now add $GENDEV to your path.\n"
    fi
}

_install_src() {
    mkdir -p "$OUTDIR"
    cd "$OUTDIR"

    git clone "https://github.com/$GENDEV_AUTHOR_REPO"

    if [ -d "$GENDEV_REPO" ]; then
        cd "$GENDEV_REPO"
        make
        sudo make install
        cd ..
    fi

    cd ..

    if [ $? == 0 ]; then
        finalise_install
    fi
}

_install_bin() {
    EXTRACTION_PATH="/"
    PACKAGE_TERM="http.*txz"

    install_backup() {
        curl -L $GENDEV_RELEASE_BACKUP -o "$OUTDIR/$GENDEV_PACKAGE_BACKUP"
        if [ $? != 0 ]; then
            printf "Got package $GENDEV_PACKAGE\n"
            printf "Extracting...\n"
            sudo tar -xzf "$OUTDIR/$GENDEV_PACKAGE_BACKUP" -C "$EXTRACTION_PATH"
            if [ $? != 0 ]; then
                printf "Failed to install.\n"
            else
                printf "Extracted"
            fi
        else
            printf "Failed to download.\n"
        fi
    }

    GENDEV_LATEST_RELEASE=$(get_latest_release "$GENDEV_AUTHOR_REPO")
    GENDEV_PACKAGE="gendev_$GENDEV_LATEST_RELEASE.txz"
    GENDEV_LATEST_PACKAGE_URL=$(get_latest_release_package_url $GENDEV_AUTHOR_REPO)

    GENDEV_REPO="https://github.com/"$GENDEV_AUTHOR_REPO
    GENDEV_RELEASE_BACKUP=$GENDEV_REPO"/releases/download/0.4.1/gendev_0.4.1.txz"
    GENDEV_PACKAGE_BACKUP=$(echo $GENDEV_RELEASE_BACKUP | tr "/" "\n" | tail -n1)

    printf "Downloading gendev...\n"
    mkdir -p "$OUTDIR"
    curl -L "$GENDEV_LATEST_PACKAGE_URL" -o "$OUTDIR/$GENDEV_PACKAGE"

    if [ $? != 0 ]; then
        printf "Failed to download the latest version: attempting backup...\n"
        install_backup
    else
        printf "Got package $GENDEV_PACKAGE\n"
        printf "Extracting...\n"
        sudo tar -xzf "$OUTDIR/$GENDEV_PACKAGE" -C "$EXTRACTION_PATH"
        if [ $? != 0 ]; then
            printf "Failed to install the latest version: attempting backup...\n"
            install_backup
        else
            printf "Extracted\n"
        fi
    fi

    if [ $? == 0 ]; then
        finalise_install
    fi
}

install() {
    if [ $FROM_BIN ]; then
        _install_bin
    else
        _install_src
    fi
}

clean() {
    BUILD_DIR_LIST_SEP=", "

    if [ -n "$MD_BUILD_DIRS" ]; then
        IFS="$BUILD_DIR_LIST_SEP" read -ra MD_BUILD_DIRS <<< "$MD_BUILD_DIRS"
    else
        MD_BUILD_DIRS=("./tools/data" "./build" "./bin" "./dist")
    fi

    printf "Cleaning build directories...\n"
    for object in "${MD_BUILD_DIRS[@]}";
    do
        rm -rf "$object"
    done
}

uninstall() {
    sudo rm -rf "$GENDEV" && printf "Uninstalled.\n"
}

show_usage() {
    BASENAME=$(basename "$0")
    printf "Script to setup the build environment.\n"
    printf "\n"
    printf "usage: $BASENAME [options]\n"
    printf "options:\n"
    printf " -i, --install, none\n"
    printf " \t--from-src, none\tbuild tools from source\n"
    printf " \t--from-bin\tinstall from binary sources\n"
    printf " -c, --clean\n"
    printf " -a, --all\tinstall and clean\n"
    printf " -u, --uninstall, -r, --remove\tuninstall build tools\n"
    printf " -h, --help\n"
}

for i in "$@";
do
    if [ "$i" == "--from-bin" ]; then
        FROM_BIN=1
    else
        FROM_SRC=1
    fi
done

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