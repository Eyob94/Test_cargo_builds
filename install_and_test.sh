#!/bin/bash

set -euo pipefail

rm -rf crate_build_test

cargo new crate_build_test
cd crate_build_test

secret_crates=("secrets" "memsecurity" "memsec")

binary_targets=(
    "x86_64-unknown-linux-gnu" "x86_64-unknown-linux-musl" "aarch64-unknown-linux-gnu"
    "aarch64-unknown-linux-musl" "armv7-unknown-linux-gnueabihf" "armv7-unknown-linux-musleabihf"
    "mips-unknown-linux-gnu" "mips64-unknown-linux-gnuabi64" "powerpc-unknown-linux-gnu"
    "powerpc64le-unknown-linux-gnu" "s390x-unknown-linux-gnu" "x86_64-apple-darwin"
    "aarch64-apple-darwin" "x86_64-pc-windows-msvc" "x86_64-pc-windows-gnu"
    "aarch64-pc-windows-msvc" "i686-pc-windows-msvc" "i686-pc-windows-gnu"
    "aarch64-linux-android" "armv7-linux-androideabi" "armv5te-linux-androideabi"
    "x86_64-linux-android" "x86-linux-android" "armv7a-linux-androideabi"
    "thumbv7neon-linux-androideabi" "aarch64-apple-ios" "armv7-apple-ios" "x86_64-apple-ios"
    "wasm32-unknown-unknown" "wasm32-wasi" "i686-unknown-linux-gnu" "i686-unknown-linux-musl"
    "x86_64-unknown-freebsd" "x86_64-unknown-netbsd" "x86_64-unknown-openbsd" 
    "riscv64gc-unknown-linux-gnu" "riscv64imac-unknown-none-elf" "thumbv6m-none-eabi"
    "thumbv7m-none-eabi" "thumbv7em-none-eabi" "thumbv7em-none-eabihf" "nvptx64-nvidia-cuda"
    "spirv-unknown-unknown"
)

rm -rf "crate_build_results.md"
touch "crate_build_results.md"

printf "| %-32s | %-12s | %-12s | %-12s |\n" "Targets" "Secrets" "MemSecurity" "Memsec" >> "crate_build_results.md"
printf "|----------------------------------|--------------|--------------|--------------|\n" >> "crate_build_results.md"

for target in "${binary_targets[@]}"
do
    echo "Adding target: $target"
    if rustup target add "$target"; then
        printf "| %-32s " "$target" >> "crate_build_results.md"
        echo "Target $target added successfully."
    else
        echo "Failed to add target $target!" >&2
        continue
    fi


    for crate in "${secret_crates[@]}"
    do
        if cargo add "$crate"; then
            echo "Crate $crate added successfully."

            cargo clean
            if cargo build --target "$target"; then
                echo "Build for $target completed successfully."
                build_status="success"
            else
                echo "Build for $target failed!" >&2
                build_status="fail"
            fi

            printf "| %-12s " "$build_status" >> "crate_build_results.md"
        else
            echo "Failed to add crate $crate!" >&2
            exit 1
        fi


        sleep 2
        if cargo remove "$crate"; then
            echo "$crate removed successfully"
        else
            echo "Error removing crate. Aborting"
            exit 1
        fi
    done

    sleep 2

    printf "|\n" >> "crate_build_results.md"

done
