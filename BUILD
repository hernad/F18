load("@rules_cc//cc:defs.bzl", "cc_library", "cc_binary")
load("//bazel:windows_dll_library.bzl", "windows_dll_library")
load("//bazel:zh_comp.bzl", "zh_comp_all")
load("//bazel:variables.bzl", "C_OPTS", "ZH_COMP_OPTS", 
    "ZH_Z18_COMP_OPTS", "ZH_Z18_HEADERS", "L_OPTS", "L_OPTS_2",
     "POSTGRESQL_HEADERS", "POSTGRESQL_COPT", "POSTGRESQL_LIB" )

F18_LIB = "klijent"

cc_binary(
    name = "F18-klijent",
    srcs = [ ":F18_" + F18_LIB + "_zh" ],
    deps = [
        ":ziher",
        "//zh_zero:headers",
        "//zh_rtl:headers",
        #"//F18:Z18_klijent_zh_c",
        #"//zh_zero:zh_zero", 
        #"//zh_vm:zh_vm",
        #"//zh_vm:zh_vm_zh_c",
        #"//zh_macro:zh_macro",
        #"//zh_rtl:zh_rtl",
        #"//zh_rtl:zh_rtl_zh_c",
        #"//zh_rtl/gt:zh_rtl_gt",
        #"//zh_rtl/gt:zh_rtl_gt_zh_c",
        #"//zh_rtl/rdd:zh_rtl_rdd",
        #"//zh_rtl/rdd:zh_rtl_rdd_zh_c",
        #"//zh_tools:zh_tools",
        #"//zh_tools:zh_tools_zh_c",
        #"//third_party/xlsxwriter:xlsxwriter",
        #"//zh_minizip:zh_minizip",
        #"//zh_minizip:zh_minizip_zh_c",
        #"//third_party/minizip:minizip",
        #"//zh_pgsql:zh_pgsql",
        #"//zh_pgsql:zh_pgsql_zh_c",
        #"//third_party/png:png",
        #"//zh_tcp_ip:zh_tcp_ip",
        #"//zh_tcp_ip:zh_tcp_ip_zh_c",
        #"//zh_ssl:zh_ssl",
        #"//zh_ssl:zh_ssl_zh_c",
        #"//zh_debug:zh_debug_zh_c",
        #"//zh_debug:zh_debug"
    ] + POSTGRESQL_LIB,
    linkopts = L_OPTS + L_OPTS_2,
    #copts = C_OPTS,
    copts = [
        "-Izh_zero",
        "-Izh_rtl",
        #"-DZH_DYNIMP",
        #"-DZH_TR_LEVEL=5",
    ],
    #linkstatic = True,
    visibility = ["//visibility:public"],
)



#cc_library(
#    name = "F18_" + Z18_LIB + "_zh_c",
#    srcs = [ ":F18_" + Z18_LIB + "_zh" ],
#    hdrs = glob([
#        "*.h",
#    ]),
#    copts = C_OPTS,
#    deps = [ 
#       "//zh_zero:zh_zero", 
#       "//zh_rtl:zh_rtl",
#       "//zh_vm:zh_vm"
#    ],
#    alwayslink=1,
#    visibility = ["//visibility:public"],
#)

windows_dll_library(
    name = "ziher",
    srcs = [ 
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
       "//third_party/zlib:c_sources",
       "//third_party/pcre2:c_sources",
       "//third_party/xlsxwriter:c_sources",
       "//third_party/harupdf:c_sources",
       "//third_party/png:c_sources",
       "//third_party/minizip:c_sources",
    ],
    hdrs = glob([
        "*.h",
        "*.zhh"
    ]) + POSTGRESQL_HEADERS,
    deps = [ 
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
    ] + POSTGRESQL_LIB,
    linkopts = L_OPTS + L_OPTS_2,
    copts = [
        "-DSUPPORT_UNICODE",
        "-DHAVE_CONFIG_H",
        "-DPCRE2_CODE_UNIT_WIDTH=8",
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
        "-Ithird_party/harupdf",
        "-Ithird_party/xlsxwriter",
        "-DUSE_STANDARD_TMPFILE", # xlsxwriter don't use tmpfileplus
        "-Ithird_party/png",
        "-DZH_DYNLIB",
        #"-DZH_TR_LEVEL=4", #INFO
        #"-DZH_TR_LEVEL=5", DEBUG
    ]  + POSTGRESQL_COPT,
    #linkstatic = False,
    #linkshared = True,
    visibility = ["//visibility:public"],
)


ZH_F18_COMP_OPTS=[
    "-n",
    "-izh_zero", 
    "-izh_rtl",
    "-izh_rtl/gt",
    "-iF18/include",
    "-izh_harupdf",
    "-Ithird_party/harupdf",
    "-Ithird_party/xlsxwriter",
    "-DGT_DEFAULT_CONSOLE",
    "-DF18_POS",
    "-DF18_DEBUG",
    "-b"
]

ZH_F18_HEADERS=[
    "//zh_zero:headers", 
    "//zh_rtl:headers",
    "//F18/include:headers",
    "//zh_harupdf:headers"
]

zh_comp_all(
    name = "F18_" + F18_LIB + "_zh", 
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
    args = ZH_F18_COMP_OPTS,
    deps = ZH_F18_HEADERS,
    visibility = ["//visibility:public"],
)