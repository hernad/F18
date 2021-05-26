load("@rules_cc//cc:defs.bzl", "cc_library", "cc_binary")
load("//bazel:shared_library.bzl", "shared_library")
load("//bazel:zh_comp.bzl", "zh_comp_all")
load("//bazel:variables.bzl", "C_OPTS", "ZH_COMP_OPTS", 
    "ZH_Z18_COMP_OPTS", "L_OPTS", "L_OPTS_2",
     "POSTGRESQL_HEADERS", "POSTGRESQL_COPT", "POSTGRESQL_LIB", "WINDOWS_LINUX" )

ZIHER_TRACE_LEVEL=["-DZH_TR_LEVEL_DEBUG"] #debug
#"-DZH_TR_LEVEL=4" #INFO


ZH_COMP_OPTS_F18=[
    "-n",
    "-gc3", # generate real C code 0=compact (default) 1=normal 2=verbose 3=generate real C code
    "-izh_zero", 
    "-izh_rtl",
    "-izh_rtl/gt",
    "-iF18/include",
    #"-iF18/fin", #enabavke_eisporuke.zhh
    "-izh_harupdf",
    "-Ithird_party/harupdf",
    "-Ithird_party/xlsxwriter",
    "-DGT_DEFAULT_CONSOLE",
    "-DELECTRON_HOST",
    #"-DGT_DEFAULT_GUI",
    "-DF18_POS",
    #"-DF18_DEBUG",
    #"-b" no debug
]

filegroup(
    name = "fin_headers_filegroup",
    srcs = glob([
        "fin/*.zhh",
    ]),
    visibility = ["//visibility:public"],
)

ZH_DEPS_F18=[ 
    "//zh_zero:headers_filegroup", 
    "//zh_rtl:headers_filegroup",
    "//F18/include:headers_filegroup",
    ":fin_headers_filegroup",
    #"//F18/fin:headers_filegroup",
    "//zh_harupdf:headers_filegroup"
]



shared_library(
    name = "F18-klijent-lib",
    os = "linux",
    srcs = [ "F18-klijent.c" ],
    hdrs = glob([
        "*.h",
        "*.zhh",
    ]) + POSTGRESQL_HEADERS,
    deps = [ "//zh_zero:headers", ":F18_import", ":ziher_import"],
    linkopts = L_OPTS + L_OPTS_2,
    copts = [
        "-Izh_zero",
        "-I/usr/include/python3.9",
        "-Izh_vm",
        "-Izh_rtl",
        "-DZH_DYNLIB",
        "-DSHARED_LIB",
    ]  + POSTGRESQL_COPT + ZIHER_TRACE_LEVEL,
    visibility = ["//visibility:public"],
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
)

cc_binary(
    name = "F18-klijent",
    srcs = [ "F18-klijent.c" ],
    deps = select({
            "//bazel:windows": [ "//zh_zero:headers", ":F18_dll_import", ":ziher_dll_import"], 
            "//conditions:default": [ "//zh_zero:headers", ":F18_import", ":ziher_import"],
        }),  #+ POSTGRESQL_LIB
    linkopts = L_OPTS + L_OPTS_2,
    copts = [
        "-Izh_zero",
        "-DZH_DYNIMP",
    ] + ZIHER_TRACE_LEVEL,
    #linkstatic = True,
    visibility = ["//visibility:public"],
)


shared_library(
    name = "F18",
    os = "windows",
    srcs = [ ":F18_zh" ],
    hdrs = glob([
        "*.h",
        "*.zhh",
    ]) + POSTGRESQL_HEADERS,
    deps = [
        "//zh_zero:headers", 
        "//zh_vm:headers", 
        "//zh_rtl:headers", 
        ":ziher_dll_import"] + POSTGRESQL_LIB,
    linkopts = L_OPTS + L_OPTS_2,
    copts = [
        "-Izh_zero",
        "-Izh_vm",
        "-Izh_rtl",
        "-DZH_DYNLIB",
    ]  + POSTGRESQL_COPT + ZIHER_TRACE_LEVEL,
    visibility = ["//visibility:public"],
    exec_compatible_with = [
        #"@platforms//cpu:x86_64",
        "@platforms//os:windows",
    ],
)

shared_library(
    name = "F18",
    os = "linux",
    srcs = [ ":F18_zh" ],
    hdrs = glob([
        "*.h",
        "*.zhh",
    ]) + POSTGRESQL_HEADERS,
    deps = [ 
        "//zh_zero:headers", 
        "//zh_rtl:headers",
        "//zh_vm:headers",
        ":ziher_import"] + POSTGRESQL_LIB,
    linkopts = L_OPTS + L_OPTS_2,
    copts = [
        "-Izh_zero",
        "-Izh_vm",
        "-Izh_rtl",
        "-DZH_DYNLIB",
    ]  + POSTGRESQL_COPT + ZIHER_TRACE_LEVEL,
    visibility = ["//visibility:public"],
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
)

_ZIHER_SRCS = [ 
       "//zh_zero:c_sources",
       "//zh_vm:c_sources", 
       "//zh_vm:zh_vm_zh",
       "//zh_macro:c_sources",
       "//zh_rtl:c_sources",
       "//zh_rtl:zh_rtl_zh",
       "//zh_rtl/gt:c_sources",
       "//zh_rtl/gt:zh_rtl_gt_zh",
       "//zh_rtl/rdd:c_sources",
       "//zh_rtl/rdd:zh_rtl_rdd_zh",
       "//zh_xlsxwriter:c_sources",
       "//zh_xlsxwriter:zh_xlsxwriter_zh",
       "//zh_harupdf:c_sources",
       "//zh_harupdf:zh_harupdf_zh",
       "//zh_tools:zh_tools_zh",
       "//zh_tools:c_sources",
       "//zh_minizip:zh_minizip_zh",
       "//zh_minizip:c_sources",
       "//zh_pgsql:zh_pgsql_zh",
       "//zh_pgsql:c_sources",
       "//zh_tcp_ip:c_sources",
       "//zh_tcp_ip:zh_tcp_ip_zh",
       "//third_party/zlib:c_sources",
       "//third_party/pcre2:c_sources",
       "//third_party/xlsxwriter:c_sources",
       "//third_party/harupdf:c_sources",
       "//third_party/png:c_sources",
       "//third_party/minizip:c_sources",
    ]

_ZIHER_DEPS = [ 
        "//zh_zero:headers",
        "//zh_vm:headers",
        "//zh_macro:headers",
        "//zh_comp:headers",
        "//zh_rtl:headers",
        "//zh_rtl/gt:headers",
        "//zh_rtl/rdd:headers",
        "//zh_xlsxwriter:headers",
        "//zh_harupdf:headers",
        "//zh_tools:headers",
        "//zh_minizip:headers",
        "//zh_pgsql:headers",
        "//third_party/zlib:headers",
        "//third_party/pcre2:headers",
        "//third_party/harupdf:headers",
        "//third_party/xlsxwriter:headers",
        "//third_party/png:headers",
        "//third_party/minizip:headers",
    ] + POSTGRESQL_LIB

_ZIHER_COPTS = [
        "-DUNICODE", # gt_wvt
        "-Izh_zero",
        "-Izh_vm",
        "-Izh_rtl",
        "-Izh_harupdf",
        "-Izh_rtl/gt",
        "-Izh_rtl/rdd/rdd_sql",
        "-Ithird_party/zlib",
        "-Ithird_party/minizip",
        "-DCREATE_LIB", # minizip no main
        "-Ithird_party/pcre2",
        "-DSUPPORT_UNICODE", #pcre2
        "-DHAVE_CONFIG_H", #pcre2
        "-DPCRE2_CODE_UNIT_WIDTH=8", #pcre2
        "-Ithird_party/harupdf",
        "-Ithird_party/xlsxwriter",
        "-DUSE_STANDARD_TMPFILE", # xlsxwriter don't use tmpfileplus
        "-Ithird_party/png",
        "-DZH_DYNLIB",
    ]  + POSTGRESQL_COPT + ZIHER_TRACE_LEVEL

shared_library(
    name = "ziher",
    os = "windows",
    srcs = _ZIHER_SRCS,
    hdrs = glob([
        "*.h",
        "*.zhh"
    ]) + POSTGRESQL_HEADERS,
    deps = _ZIHER_DEPS,
    linkopts = L_OPTS + L_OPTS_2,
    copts = _ZIHER_COPTS,
    visibility = ["//visibility:public"],
    exec_compatible_with = [
        #"@platforms//cpu:x86_64",
        "@platforms//os:windows",
    ],
)

shared_library(
    name = "ziher",
    os = "linux",
    srcs = _ZIHER_SRCS,
    hdrs = glob([
        "*.h",
        "*.zhh"
    ]) + POSTGRESQL_HEADERS,
    deps = _ZIHER_DEPS,
    linkopts = L_OPTS + L_OPTS_2 + ["-lX11"],
    copts = _ZIHER_COPTS,
    visibility = ["//visibility:public"],
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
)

zh_comp_all(
    name = "F18_zh", 
    srcs = glob([ 
        "*.zh",
        "common/*.zh",
        "common_legacy/*.zh",
        "core/*.zh",
        "core_dbf/*.zh",
        "core_pdf/*.zh",
        "core_reporting/*.zh",
        "core_semafori/*.zh",
        "core_sql/*.zh",
        "core_string/*.zh",
        "core_ui2/*.zh",
        "fin/*.zh",
        "fin/*.zhh",
        "kalk/*.zh",
        "kalk_legacy/*.zh",
        "fakt/*.zh",
        "fiskalizacija/*.zh",
        "ld/*.zh",
        "pos/*.zh",
        "os/*.zh",
        "virm/*.zh",
        "epdv/*.zh",
    ]),
    args = ZH_COMP_OPTS_F18,
    deps = ZH_DEPS_F18,
    visibility = ["//visibility:public"],
)