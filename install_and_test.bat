@echo off
setlocal enabledelayedexpansion

REM Set variables
set "CRATE_DIR=crate_build_test"
set "RESULTS_FILE=crate_build_results.md"

REM Remove existing crate directory if it exists
if exist %CRATE_DIR% rd /s /q %CRATE_DIR%

REM Create new crate
cargo new %CRATE_DIR%
cd %CRATE_DIR%

REM Define arrays
set "SECRET_CRATES=secrets memsecurity memsec"
set "BINARY_TARGETS=x86_64-unknown-linux-gnu x86_64-unknown-linux-musl aarch64-unknown-linux-gnu aarch64-unknown-linux-musl armv7-unknown-linux-gnueabihf armv7-unknown-linux-musleabihf mips-unknown-linux-gnu mips64-unknown-linux-gnuabi64 powerpc-unknown-linux-gnu powerpc64le-unknown-linux-gnu s390x-unknown-linux-gnu x86_64-apple-darwin aarch64-apple-darwin x86_64-pc-windows-msvc x86_64-pc-windows-gnu aarch64-pc-windows-msvc i686-pc-windows-msvc i686-pc-windows-gnu aarch64-linux-android armv7-linux-androideabi armv5te-linux-androideabi x86_64-linux-android x86-linux-android armv7a-linux-androideabi thumbv7neon-linux-androideabi aarch64-apple-ios armv7-apple-ios x86_64-apple-ios wasm32-unknown-unknown wasm32-wasi i686-unknown-linux-gnu i686-unknown-linux-musl x86_64-unknown-freebsd x86_64-unknown-netbsd x86_64-unknown-openbsd riscv64gc-unknown-linux-gnu riscv64imac-unknown-none-elf thumbv6m-none-eabi thumbv7m-none-eabi thumbv7em-none-eabi thumbv7em-none-eabihf nvptx64-nvidia-cuda spirv-unknown-unknown"

REM Remove previous results file if it exists
if exist %RESULTS_FILE% del %RESULTS_FILE%

REM Create new results file
(
    echo | set /p="| %-32s | %-12s | %-12s | %-12s |"
    echo | set /p=" Targets  | Secrets | MemSecurity | Memsec |"
    echo | set /p="|----------------------------------|--------------|--------------|--------------|"
) > %RESULTS_FILE%

REM Loop through targets
for %%T in (%BINARY_TARGETS%) do (
    echo Adding target: %%T
    rustup target add %%T >nul 2>&1
    if errorlevel 1 (
        echo Failed to add target %%T!
        goto :continue
    )

    set "BUILD_STATUS=success"
    echo | set /p="| %-32s " %%T >> %RESULTS_FILE%

    REM Loop through crates
    for %%C in (%SECRET_CRATES%) do (
        cargo add %%C >nul 2>&1
        if errorlevel 1 (
            echo Failed to add crate %%C!
            exit /b 1
        )

        cargo clean >nul 2>&1
        cargo build --target %%T >nul 2>&1
        if errorlevel 1 (
            echo Build for %%T failed!
            set "BUILD_STATUS=fail"
        ) else (
            echo Build for %%T completed successfully.
        )

        echo | set /p="| %-12s " !BUILD_STATUS! >> %RESULTS_FILE%

        REM Remove crate
        cargo remove %%C >nul 2>&1
        if errorlevel 1 (
            echo Error removing crate. Aborting
            exit /b 1
        )
    )

    echo | set /p="|" >> %RESULTS_FILE%

    :continue
)

endlocal
