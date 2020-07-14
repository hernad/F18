# F18

## build

### Windows MSVC

#### set developer toolset x64:

    cd c:\dev\
    set_developer_toolset.cmd
    x64_VS_2019.lnk
    cd \dev

#### set developer toolset x86:

    cd c:\dev\
    set_developer_toolset_x86.cmd
    x86_VS_2019.lnk
    cd \dev

#### `c:\dev\F18` build debug:

    build_debug.cmd

Notes:
- `HB_DBG_PATH` is set

#### `c:\dev\F18` build release:

    build_release.cmd

### `c:\dev\F18` run F18-klijent.exe in eShell-dev:

    run_in_eshell.cmd

### upload F18-klijent.exe + dlls to bintray

    upload.cmd


 