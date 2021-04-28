import os

def ext_prgch_zhzhh(file_name):
    base = os.path.splitext(file_name)[0]
    if os.path.splitext(file_name)[1] == '.prg':
        os.rename(file_name, base + '.zh')
        print('prg -> ' +  base + '.zh')
    if os.path.splitext(file_name)[1] == '.ch':
        os.rename(file_name, base + '.zhh')
        print('ch -> ' +  base + '.zhh')



def convert_content_hb_zh(file_name):
    import re

    if not os.path.splitext(file_name)[1] in ['.zh', '.zhh']:
        # only .zh, .zhh convert
        return

    if os.path.exists(file_name + '.cnv'):
        os.remove(file_name + '.cnv')
    os.rename(file_name, file_name + '.cnv')
    output_file = open(file_name, "w")

    with open (file_name + '.cnv', 'r' ) as f:
        content = f.read()
        #content_new = re.sub('(\d{2}|[a-yA-Y]{3})\/(\d{2})\/(\d{4})', r'\1-\2-\3', content, flags = re.M)
        content_new = re.sub('#include "f18.ch"', '#include "f18.zhh"', content, flags = re.M)
        #hb_default()
        content_new = re.sub('hb_([a-zA-Z]+)', r'zh_\1', content_new, flags = re.M)
        #HB_GTI_DESKTOPWIDTH
        content_new = re.sub('HB_([_a-zA-Z]+)', r'ZH_\1', content_new, flags = re.M)

        #include "setcurs.ch"
        content_new = re.sub('"setcurs.ch"', '"set_curs.zhh"', content_new, flags = re.M)
        #include "rddsys.ch"
        content_new = re.sub('"rddsys.ch"', '"rdd_sys.zhh"', content_new, flags = re.M)
        #include "hbusrrdd.ch"
        content_new = re.sub('"hbusrrdd.ch"', '"rdd_usr.zhh"', content_new, flags = re.M)
        #include "fileio.ch"
        content_new = re.sub('"fileio.ch"', '"file_io.zhh"', content_new, flags = re.M)
        #include "error.ch"
        content_new = re.sub('"error.ch"', '"error.zhh"', content_new, flags = re.M)
        #include "dbstruct.ch"
        content_new = re.sub('"dbstruct.ch"', '"db_struct.zhh"', content_new, flags = re.M)
        #include "common.ch"
        content_new = re.sub('"common.ch"', '"common.zhh"', content_new, flags = re.M)
        #include "getexit.ch"
        content_new = re.sub('"getexit.ch"', '"get_exit.zhh"', content_new, flags = re.M)
        #include "inkey.ch"
        content_new = re.sub('"inkey.ch"', '"inkey.zhh"', content_new, flags = re.M)
        #include "fmk.ch"
        content_new = re.sub('"fmk.ch"', '"fmk.zhh"', content_new, flags = re.M)
        #include "rt_vars.ch"
        content_new = re.sub('#include "rt_vars.ch"', '// #include "rt_vars.zhh"', content_new, flags = re.M)
        content_new = re.sub('#include "rt_main.ch"', '// #include "rt_main.zhh"', content_new, flags = re.M)
        #include "hbthread.ch"
        content_new = re.sub('"hbthread.ch"', '"thread.zhh"', content_new, flags = re.M)
        content_new = re.sub('"hbgtinfo.ch"', '"gt_info.zhh"', content_new, flags = re.M)
        content_new = re.sub('"set.ch"', '"set.zhh"', content_new, flags = re.M)
        content_new = re.sub('"box.ch"', '"box.zhh"', content_new, flags = re.M)
     
        content_new = re.sub('"dbedit.ch"', '"dbedit.zhh"', content_new, flags = re.M)
        content_new = re.sub('"achoice.ch"', '"achoice.zhh"', content_new, flags = re.M)
        content_new = re.sub('"rddsql.ch"', '"rdd_sql.zhh"', content_new, flags = re.M)
        content_new = re.sub('"dbinfo.ch"', '"db_info.zhh"', content_new, flags = re.M)
        content_new = re.sub('"pdf_cls.ch"', '"pdf_class.zhh"', content_new, flags = re.M)
        content_new = re.sub('"memoedit.ch"', '"memo_edit.zhh"', content_new, flags = re.M)


        content_new = re.sub('"o_f18.ch"', '"o_f18.zhh"', content_new, flags = re.M)
        content_new = re.sub('"f_f18.ch"', '"f_f18.zhh"', content_new, flags = re.M)
        content_new = re.sub('"f18_separator.ch"', '"f18_separator.zhh"', content_new, flags = re.M)
        content_new = re.sub('"f18_release.ch"', '"f18_release.zhh"', content_new, flags = re.M)
        content_new = re.sub('"f18_rabat.ch"', '"f18_rabat.zhh"', content_new, flags = re.M)
        content_new = re.sub('"f18_request.ch"', '"f18_request.zhh"', content_new, flags = re.M)
        content_new = re.sub('"f18_cre_all.ch"', '"f18_cre_all.zhh"', content_new, flags = re.M)
        content_new = re.sub('#require "sddpg.ch"', '// #require "sddpg.zhh"', content_new, flags = re.M)

        #include "f18_color.ch"
        content_new = re.sub('"f18_color.ch"', '"f18_color.zhh"', content_new, flags = re.M)
        #include "hbclass.ch"
        content_new = re.sub('"hbclass.ch"', '"class.zhh"', content_new, flags = re.M)
        #include "f18_ver.ch"
        content_new = re.sub('"f18_ver.ch"', '"f18_ver.zhh"', content_new, flags = re.M)
        #include "simpleio.ch"
        content_new = re.sub('"simpleio.ch"', '"simple_io.zhh"', content_new, flags = re.M)
        #include "enabavke_eisporuke.ch"
        content_new = re.sub('"enabavke_eisporuke.ch"', '"enabavke_eisporuke.zhh"', content_new, flags = re.M)
        #include "hbapi.h"
        content_new = re.sub('#include "hbapi.h"', '#include "zh_api.h"', content_new, flags = re.M)
        #include "hbapifs.h"
        content_new = re.sub('#include "hbapifs.h"', '#include "zh_fs_api.h"', content_new, flags = re.M)
        #include "hbapierr.h"
        content_new = re.sub('#include "hbapierr.h"', '#include "zh_error_api.h"', content_new, flags = re.M)
        #include "hbapigt.h"
        content_new = re.sub('#include "hbapigt.h"', '#include "zh_gt_api.h"', content_new, flags = re.M)
        #include "hbapiitm.h"
        content_new = re.sub('#include "hbapiitm.h"', '#include "zh_item_api.h"', content_new, flags = re.M)
        
        # HBEditor
        content_new = re.sub('HBEditor', 'ZHEditor', content_new, flags = re.M)
        output_file.write(content_new)
        

    
def walk_1():
    print("================ convert prg, ch => zh, zhh ==================================")
    for root, dirs, files in os.walk(".", topdown=True):
        for name in files:
            print("file:", os.path.join(root, name))
            ext_prgch_zhzhh(os.path.join(root, name))
        for name in dirs:
            print("dir:", os.path.join(root, name))



#walk_1()


def walk_2():
    print("================ convert content hb_ -> zh_ ==================================")
    for root, dirs, files in os.walk(".", topdown=True):
        for name in files:
            print("file:", os.path.join(root, name))
            convert_content_hb_zh(os.path.join(root, name))
        for name in dirs:
            print("dir:", os.path.join(root, name))

walk_2()