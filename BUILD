load("@rules_cc//cc:defs.bzl", "cc_library", "cc_binary")
load("//bazel:zh_comp.bzl", "zh_comp_all")
load("//bazel:variables.bzl", "C_OPTS", "ZH_COMP_OPTS", 
    "ZH_Z18_COMP_OPTS", "ZH_Z18_HEADERS", "L_OPTS", "L_OPTS_2",
    "POSTGRESQL_LIB" )

F18_LIB = "klijent"

cc_binary(
    name = "F18-klijent",
    srcs = [ ":F18_" + F18_LIB + "_zh" ],
    deps = [
        "//zh_zero:headers",
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
        #"//zh_xlsxwriter:zh_xlsxwriter",
        #"//zh_xlsxwriter:zh_xlsxwriter_zh_c",
        #"//zh_harupdf:zh_harupdf",
        #"//zh_harupdf:zh_harupdf_zh_c",
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
    copts = C_OPTS,
    linkstatic = True,
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



ZH_F18_COMP_OPTS=[
    "-n",
    "-izh_zero", 
    "-izh_rtl",
    "-izh_rtl/gt",
    "-iF18/include",
    "-izh_harupdf",
    "-DGT_DEFAULT_CONSOLE",
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