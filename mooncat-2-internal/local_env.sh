#/bin/sh

declare readonly BIN_PATH="${HOME}/go/bin"
declare readonly OS=$(uname -s)
declare readonly PLATFORM=$(uname -m)
declare readonly GO_VERSION="1.19.5"
declare readonly GO_MD5="09e7f3b3ef34eb6099fe7312ecc314be"
declare readonly CRE_VERSION="v5.0.0-rc2"
declare readonly BIN_PATH="${HOME}/go/bin"
declare readonly GITHUB_REPO="crescent-network/crescent"
declare readonly GITHUB_URL="https://github.com/${GITHUB_REPO}"
declare readonly GITHUB_RAW="https://raw.githubusercontent.com/${GITHUB_REPO}/${CRE_VERSION}"


declare GTMPDIR="${TMPDIR:-/tmp}"

main(){
    init_environment
    init_node
}

init_environment(){
    PATH="${BIN_PATH}:${PATH}"
    # check if binary exists/create binary
    if [ -z "$(which crescentd)" ] ; then 
        create_binary
    fi
}

#get_peers(){
#    for (( i=0; i<3; i++ )); do
#        curl -sSL "https://testnet-endpoint2.crescent.network/rpc/crescent/status" | \
#        awk -vRS=',' -vFS='"' '/id":"/{print $4}; /listen_addr":"[0-9]/{print $4}' |\
#        paste -sd "@" -
#    done | paste -sd "," -
#}

create_binary(){
    local binary="crescentd"
    local tmpdir=$(mktemp -d)
    install_prereqs
    download_go ${tmpdir}
    download_source ${tmpdir}
    cd ${tmpdir}/crescent*
    export PATH="${tmpdir}/go/bin:${PATH}"
    export GOROOT="${tmpdir}/go"
    echo "Building ${binary}..."
    mkdir -p "${BIN_PATH}"
    make install
    echo "Binary is located at ${BIN_PATH}/${binary}"
    rm -rf ${tmpdir}
}

install_prereqs(){
    if [ $OS == "Linux" ] && [ -n "$(which apt)" ]; then 
        sudo apt update -y
        sudo apt install -y build-essential
    elif [ $OS == "Linux" ] && [ -n "$(which yum)" ]; then
        sudo yum update -y
        sudo yum group install -y "Development Tools"
    else
        echo "WARNING: You may need to install the gcc compiler"
    fi
}

download_go (){
    local tmpdir=$1
    if [ $OS == "Linux" ] && [ $PLATFORM == "x86_64" ]; then
       GO_GZ="go${GO_VERSION}.linux-amd64.tar.gz" 
    elif [ $OS == "Darwin" ] && [ $PLATFORM == "arm64" ]; then
       GO_GZ="go${GO_VERSION}.darwin-arm64.tar.gz"
    else
        error "Unsupported OS/Platform"
    fi
    GO_DOWNLOAD="https://go.dev/dl/${GO_GZ}"
    cd ${GTMPDIR}
    if [ ! -f "${GO_GZ}" ]; then
        echo "Downloading go from ${GO_DOWNLOAD}"
        curl -L "${GO_DOWNLOAD}" -o ${GO_GZ}
    fi
    echo "Extracting ${GO_GZ}"
    # need to check md5sum
    tar -xzf ${GO_GZ} -C "${tmpdir}"
    echo
}

download_source (){
    local tmpdir=$1
    CRE_GZ="${CRE_VERSION}.tar.gz" 
    CRE_DOWNLOAD="${GITHUB_URL}/archive/refs/tags/${CRE_GZ}"
    cd ${GTMPDIR}
    if [ ! -f "${CRE_GZ}" ]; then
        echo "Downloading Crescent from ${CRE_DOWNLOAD}"
        curl -sSL "${CRE_DOWNLOAD}" -o ${CRE_GZ}
    fi
    # need to check md5sum
    echo "Extracting ${CRE_GZ}"
    tar -xzf ${CRE_GZ} -C "${tmpdir}"
    echo
}

init_node(){
    # run init if genesis file does not exist
    if [ ! -f "${HOME}/.crescent/config/genesis.json" ]; then
        echo "Initializing node"
        ${BINARY} init "mm-node" --chain-id "mooncat-2-internal" 2>&1 | sed -e 's/{.*}//' 
    fi
    
    # download genesis file
    echo "Downloading genesis file"
    curl -sSL "https://blocksnapshot.s3.ap-northeast-2.amazonaws.com/crescent-1-genesis.json" -o "${HOME}/.crescent/config/genesis.json"

    # get peers list
    echo "Getting peer list"
    #PEERS="$(get_peers)"
    #PEERS_LIST=66f26fe655c624986d23af5f1c4f5b462220787f@13.124.45.5:26656,
    #PEERS_LIST+=PEERS
    sed -i "s/persistent_peers = \".*\"/persistent_peers = \"66f26fe655c624986d23af5f1c4f5b462220787f@13.124.45.5:26656\"/" $HOME/.crescent/config/config.toml
    sed -i "s/persistent_peers = \".*\"/persistent_peers = \"66f26fe655c624986d23af5f1c4f5b462220787f@13.124.45.5:26656\"/" $HOME/.crescent/config/config.toml
    
    echo "Setting State Sync"
    SNAP_RPC="http://13.124.45.5:26657"
    LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
    BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
    TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

    sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
    s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
    s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
    s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.crescent/config/config.toml
    echo

    cli=$(crescentd tendermint show-node-id --home $HOME/.crescent 2>&1 | jq -r '.')
    echo "Please make sure to inform the partner channel of the ID. With your external IP $cli"
}

error(){
    echo "Error: $1"
    exit 1
}

main $@