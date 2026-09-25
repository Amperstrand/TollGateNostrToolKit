#!/bin/sh
# Function to mine a proof-of-work
mine() {
    difficulty_target=$1
    epoch_time=$(date +%s)
    nonce=0
    echo "Starting mining with epoch time: $epoch_time"
    echo "Difficulty Target: $difficulty_target leading zeros"
    while true; do
        input="${epoch_time}:${nonce}"
        # Compute double SHA256 hash
        hash=$(echo -n "${input}" | openssl dgst -sha256 -binary | openssl dgst -sha256 -hex | awk '{print $2}')
        # Check if the hash meets the required number of leading zeros
        leading_zeros=$(echo "$hash" | awk '{
            match($0, "^0+");
            print RLENGTH;
        }')
        if [ "$leading_zeros" -ge "$difficulty_target" ]; then
            echo "Proof of work found!"
            echo "Epoch Time: $epoch_time"
            echo "Nonce: $nonce"
            echo "Hash: $hash"
            echo "Proof: ${epoch_time}:${nonce}"
            break
        fi

        nonce=$(expr "$nonce" + 1)
    done
}
# Function to verify the proof-of-work
verify() {
    proof=$1
    difficulty_target=$2

    # Split proof into epoch_time and nonce based on separator ":"
    epoch_time=$(echo "$proof" | cut -d':' -f1)
    nonce=$(echo "$proof" | cut -d':' -f2)
    # Reconstruct the input and compute the hash
    input="${epoch_time}:${nonce}"
    hash=$(echo -n "${input}" | openssl dgst -sha256 -binary | openssl dgst -sha256 -hex | awk '{print $2}')
    # Check if the hash meets the required number of leading zeros
    leading_zeros=$(echo "$hash" | awk '{
        match($0, "^0+");
        print RLENGTH;
    }')

    if [ "$leading_zeros" -ge "$difficulty_target" ]; then
        echo "Proof of work is valid."
        echo "Epoch Time: $epoch_time"
        echo "Nonce: $nonce"
        echo "Hash: $hash"
    else
        echo "Proof of work is invalid."
    fi
}
# Main script logic to decide whether to mine or verify
if [ "$1" = "mine" ]; then
    # Mining mode: provide difficulty target as the second argument
    if [ -z "$2" ]; then
        echo "Usage: $0 mine <difficulty_target>"
        exit 1
    fi
    mine "$2"
elif [ "$1" = "verify" ]; then
    # Verification mode: provide proof and difficulty target as arguments
    if [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: $0 verify <proof> <difficulty_target>"
        exit 1
    fi
    verify "$2" "$3"
else
    echo "Usage: $0 <mine|verify> [arguments...]"
    exit 1
fi
