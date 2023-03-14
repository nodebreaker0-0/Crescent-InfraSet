#/bin/sh

declare readonly BIN_PATH="${HOME}/go/bin"
declare readonly OS=$(uname -s)
declare readonly PLATFORM=$(uname -m)
declare readonly GO_VERSION="1.19.5"
declare readonly GO_MD5="09e7f3b3ef34eb6099fe7312ecc314be"
declare readonly CRE_VERSION="v4.0.0"
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
        ${BINARY} init "mm-node" --chain-id "crescent-1" 2>&1 | sed -e 's/{.*}//' 
    fi
    
    # download genesis file
    echo "Downloading genesis file"
    curl -sSL "https://blocksnapshot.s3.ap-northeast-2.amazonaws.com/crescent-1-genesis.json" -o "${HOME}/.crescent/config/genesis.json"

    # get peers list
    echo "Getting peer list"
    #PEERS="$(get_peers)"
    #PEERS_LIST=66f26fe655c624986d23af5f1c4f5b462220787f@13.124.45.5:26656,
    #PEERS_LIST+=PEERS
    sed -i "s/seeds = \".*\"/seeds = \"929f22a7b04ff438da9edcfebd8089908239de44@18.180.232.184:26656\"/" $HOME/.crescent/config/config.toml
    sed -i "s/persistent_peers = \".*\"/persistent_peers = \"bb2a2b742ba69cdf7ad635778d6f7784b264b6b6@54.95.40.202:26656,f373e6a868ee7e67060bc49efec58cd9b82ac764@54.178.136.194:26656,68787e8412ab97d99af7595c46514b9ab4b3df45@54.250.202.17:26656,0ed5ed53ec3542202d02d0d47ac04a2823188fc2@52.194.172.170:26656,04016e800a079c8ee5bdb9361c81c026b6177856@34.146.27.138:26656,24be64cd648958d9f685f95516cb3b248537c386@52.197.140.210:26656,83b3ba06b43fda52c048934498c6ee2bd4987d2d@3.39.144.72:26656,7e59c83196fdc61dcf9d36c42776c0616bc0fc8c@3.115.85.120:26656,06415494b86316c55245d162da065c3c0fee83fc@172.104.108.21:26656,4293ce6b47ee2603236437ab44dc499519c71e62@45.76.97.48:26656,4113f7496857d3f161921c7af8d62022551a7e6b@167.179.75.240:26656,2271e3739ea477bce0df39dd9e95f8b952a2106e@198.13.62.7:26656,b34115ba926eb12059ca0ade4d1013cac2f8d289@crescent-mainnet-01.01node.com:26656,d7556e41ba2f333379f6d87b1af3cce2ca545f79@34.88.102.246:26656,26011ac36240fb49852cc7196f71a1884434b8c4@34.84.227.139:26656,b840926fb6a2bd04fc70e501002f9286655c9179@52.199.91.143:30732,86030850dd635cab1f136979568087407a025491@46.101.153.158:26656,3bcffbcb11e96edc84c04a5628639f5ed94b9db2@128.0.51.5:26656,3b468af82b8ffa049b3e1f67dc4615a31ec8f01e@50.21.167.131:26656,a562b68bebfb281d48478e52454a12c971abcaa9@167.179.68.71:26656,420840bf326e2c75e149d86b90747a58c35b4653@54.238.127.223:26656\"/" $HOME/.crescent/config/config.toml
    
    echo "Setting State Sync"
    SNAP_RPC="http://54.95.40.202:26657"
    LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
    BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
    TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

    sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
    s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
    s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
    s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.crescent/config/config.toml
    echo

    cli=$(crescentd tendermint show-node-id --home $HOME/.crescent)
    echo "Please make sure to inform the partner channel of the ID. With your external IP $cli"
}

error(){
    echo "Error: $1"
    exit 1
}

main $@
