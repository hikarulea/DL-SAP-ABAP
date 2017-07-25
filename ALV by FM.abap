*&---------------------------------------------------------------------*
*& Report  ZLG_ALV                                                     *
*&                                                                     *
*&---------------------------------------------------------------------*
*& 测试alv各项参数                                                     *
*& 未完全 - v01 - 20081212                                             *
*& 未完全 - v02 - 20090731                                             *
*&---------------------------------------------------------------------*
*& ALV显示可以用的FM包括：                                             *
*& 1、REUSE_ALV_GRID_DISPLAY                                           *
*& 2、REUSE_ALV_GRID_DISPLAY_LVC                                       *
*& 3、REUSE_ALV_BLOCK_LIST_DISPLAY                                     *
*&                                                                     *
*& ALV显示相关FM包括：                                                 *
*& 1、REUSE_ALV_FIELDCATALOG_MERGE - 制作  类型的 fieldcatalog         *
*& 2、LVC_FIELDCATALOG_MERGE - 制作 LVC_T_FCAT 类型的 fieldcatalog     *
*& 3、REUSE_ALV_BLOCK_LIST_INIT                                        *
*& 4、REUSE_ALV_BLOCK_LIST_APPEND                                      *
*& 5、REUSE_ALV_EVENTS_GET                                             *
*&                                                                     *
*&---------------------------------------------------------------------*
*& ALV(REUSE_ALV_GRID_DISPLAY)输出必须的内容：                         *
*& 1、output itab                                                      *
*& 2、fieldcatalog                                                     *
*&---------------------------------------------------------------------*
*&                          相关FM注意事项                             *
*& 一、REUSE_ALV_FIELDCATALOG_MERGE                                    *
*& 1、I_INTERNAL_TABNAME所用的变量对应结构体必须用DATA+BEGIN申明，     *
*&    不可以使用DATA+TYPE line type，否则不会返回Fieldcatalog。        *
*& 2、修改了I_INTERNAL_TABNAME对应结构体后，                           *
*&    必须/N后重新进去SE38时，才会生效。                               *
*& 3、程序代码每行不能太长，不然容易报错，                             *
*&    具体内容见FORM f_fieldcatalog。                                  *
*&                                                                     *
*&                                                                     *
*& 二、REUSE_ALV_GRID_DISPLAY                                          *
*& 1、使用标准GUI：STANDARD_FULLSCREEN                                 *
*& 2、标准GUI中的&OLO中显示的列名取决于fieldcatalog中的设置            *
*&                                                                     *
*& 三、REUSE_ALV_BLOCK_LIST_DISPLAY                                    *
*& 1、首先用 REUSE_ALV_BLOCK_LIST_INIT 初始化                          *
*& 2、然后用 REUSE_ALV_BLOCK_LIST_APPEND 添加需要显示的ALV             *
*& 3、最后用 REUSE_ALV_BLOCK_LIST_DISPLAY 显示                         *
*&                                                                     *
*&---------------------------------------------------------------------*
*& 参考自：
*& http://www.itpub.net/viewthread.php?tid=1051462&highlight=ALV%2B%D7%DC%BD%E1
*&---------------------------------------------------------------------*
REPORT  zlg_alv                                 .
*&---------------------------------------------------------------------*
*& 导入                                                                *
*&---------------------------------------------------------------------*
*include:<ICON>.
*-----------------------------------------------------------------------
*  Instead of statement 'INCLUDE <icon>.', please use
*  statement 'TYPE-POOLS: icon.' directly.
*-----------------------------------------------------------------------

*&---------------------------------------------------------------------*
*& 类型池引用申明                                                      *
*&---------------------------------------------------------------------*
TYPE-POOLS:slis.
TYPE-POOLS:icon."代替 include <icon>

*&---------------------------------------------------------------------*
*& 类型定义                                                            *
*&---------------------------------------------------------------------*
*ALV输出表类型
TYPES:BEGIN OF typ_alv,
       icon          TYPE icon-id,
       box(1)        TYPE c,
       c10(10)       TYPE c,
       n10(10)       TYPE n,
       n5(5)         TYPE n,
       c             TYPE c,
       d             TYPE d,
       t             TYPE t,
       x             TYPE x,
       i             TYPE i,      "普通I型数字
       i2            TYPE i,      "负数普通显示
       i3            TYPE i,      "no_sign
       i4            TYPE i,      "负号前置
       quantity      TYPE p DECIMALS 5,"数量
       qunit         TYPE meins,"数量参考单位
       p             TYPE p DECIMALS 5,
       cp(33)        TYPE c,      "放置P，32+1？
       currency      TYPE p DECIMALS 5,
       cunit         TYPE bkpf-waers,
       cunit2        TYPE c LENGTH 5,
       f             TYPE f,
       string        TYPE string, "内表型类型?
       xstring       TYPE xstring,"内表型类型?
       bname         TYPE bname,
       bnamel(30)    TYPE c,     "与bname对齐方式不同
       bnamel2(30)   TYPE c,     "热点
       matnr         TYPE matnr,                            "F4help - 1
       datum         TYPE datum,                            "F4help - 2
       linecolor(4)  TYPE c,     "用于保存行颜色代码
       cellcolor     TYPE slis_t_specialcol_alv,"用于保存单元格颜色代码
      END OF typ_alv.
*&---------------------------------------------------------------------*
*& 变量定义                                                            *
*&---------------------------------------------------------------------*
*ALV输出用内表相关
DATA:itab_alv TYPE STANDARD TABLE OF typ_alv,
     wa_alv   TYPE typ_alv.

*ALV Layout相关
DATA:wa_layout TYPE slis_layout_alv.

*ALV Sort相关
DATA:itab_alv_sort TYPE slis_t_sortinfo_alv,
     wa_alv_sort   TYPE slis_sortinfo_alv.

*ALV Event相关
DATA:itab_alv_event TYPE slis_t_event,
     wa_alv_event   TYPE slis_alv_event.

*ALV Fieldcatalog相关
DATA:itab_alv_fieldcatalog TYPE slis_t_fieldcat_alv,
     wa_alv_fieldcatalog   TYPE slis_fieldcat_alv.

*只用于REUSE_ALV_FIELDCATALOG_MERGE
DATA:BEGIN OF cns_alv,
       icon          LIKE icon-id,"这里只能用like，用type会无效
       box(1)        TYPE c,
       c10(10)       TYPE c,
       n10(10)       TYPE n,
       n5(5)         TYPE n,
       c             TYPE c,
       d             TYPE d,
       t             TYPE t,
       x             TYPE x,
       i             TYPE i,
       i2            TYPE i,      "负数
       i3            TYPE i,      "显示no_sign效果
       i4            TYPE i,      "显示负号前置效果
       quantity      TYPE p DECIMALS 5,"数量
       qunit         TYPE meins,"数量参考单位
       p             TYPE p,
       cp(33)        TYPE c,      "放置P，32+1？
       currency      TYPE p DECIMALS 5,
       cunit         TYPE bkpf-waers,
       cunit2        TYPE c LENGTH 5,"货币单位没有被FM加入fieldcatlog中
       f             TYPE f,
       string        TYPE string, "内表型类型?
       xstring       TYPE xstring,"内表型类型?
       bname         TYPE bname,
       bnamel(30)    TYPE c,     "与bname对齐方式不同
       bnamel2(30)   TYPE c,     "热点
       matnr         TYPE matnr,                            "F4help - 1
       datum         TYPE datum,                            "F4help - 2
       linecolor(4)  TYPE c,     "用于保存行颜色代码
       cellcolor     TYPE slis_t_specialcol_alv,"用于保存单元格颜色代码
      END OF cns_alv.

*隐藏标准按钮
DATA:itab_alv_excluding   TYPE slis_t_extab ,
     wa_alv_excluding     TYPE slis_extab .

*全局常量
DATA:cns_tabname          TYPE slis_tabname  VALUE 'CNS_ALV',
     cns_repid            TYPE sy-repid      VALUE 'ZLG_ALV'," sy-repid
     cns_pf_status_set    TYPE slis_tabname  VALUE '',
     cns_user_command     TYPE slis_formname VALUE 'F_USER_COMMAND',
     cns_html_top_of_page TYPE slis_formname VALUE 'F_HTML_TOP_OF_PAGE',
     cns_grid_title       TYPE lvc_title     VALUE 'ALV title',
     cns_l(1)             TYPE c             VALUE 'L',
     cns_c(1)             TYPE c             VALUE 'C',
     cns_r(1)             TYPE c             VALUE 'R',
     cns_a(1)             TYPE c             VALUE 'A',
     cns_u(1)             TYPE c             VALUE 'U',
     cns_x(1)             TYPE c             VALUE 'X',
     cns_space(1)         TYPE c             VALUE space,
     cns_half             TYPE i             VALUE '0.5'.

*全局变量
DATA:g_color_id(1) TYPE c,
     g_cellcolor   TYPE slis_specialcol_alv,
     g_datum       TYPE datum,
     g_flg_alv     TYPE i,"ALV类型标识
     g_flg_random  TYPE i."分歧变量
*&---------------------------------------------------------------------*
*& 选择屏幕                                                            *
*&---------------------------------------------------------------------*
*与form f_check_alv_type相关
PARAMETERS:fagd    TYPE c RADIOBUTTON GROUP alv DEFAULT 'X',"alv grid
           fagdlvc TYPE c RADIOBUTTON GROUP alv,"alv grid lvc
           fabl    TYPE c RADIOBUTTON GROUP alv."alv block list
*&---------------------------------------------------------------------*
*& 初始化                                                              *
*&---------------------------------------------------------------------*
INITIALIZATION.
  CLEAR:itab_alv_fieldcatalog.
*生成随机数
  PERFORM f_get_random.
*&---------------------------------------------------------------------*
*& 填充数据及部分设置                                                  *
*&---------------------------------------------------------------------*
START-OF-SELECTION.
*ALV输出用内表 - 填充
  PERFORM f_get_data.

*&---------------------------------------------------------------------*
*& 设置及显示                                                          *
*&---------------------------------------------------------------------*
END-OF-SELECTION.
*判断显示哪种ALV
  PERFORM f_check_alv_type CHANGING g_flg_alv.

*ALV Fieldcatalog - 设置
  PERFORM f_fieldcatalog_all .

*ALV layout - 设置
  PERFORM f_layout_all.

*ALV Sort - 设置
  PERFORM f_sort_all.

*ALV Evnet - 设置
  PERFORM f_event_all.

*ALV GUI - 设置
  PERFORM f_gui_all.

*ALV输出结果
  PERFORM f_show_alv_all.
*&---------------------------------------------------------------------*
*&      Form  f_get_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_get_data .
  g_datum = sy-datum.
  DO 100 TIMES .
    CLEAR wa_alv."清空内表型组件(如cellcolor)的值
    wa_alv-icon    = '@0A@'."red light 可以查看类型池ICON中的值
    wa_alv-c10     = sy-index.
    wa_alv-n10     = sy-index ** 2.
    wa_alv-i       = sy-index.
    wa_alv-i2      = wa_alv-i * -1.
    wa_alv-i3      = wa_alv-i2.
    wa_alv-i4      = wa_alv-i2 * wa_alv-i * wa_alv-i.
    CASE sy-index.
      WHEN 1.
        wa_alv-p = 1.
      WHEN 2.
        wa_alv-p = '1.5436'.
      WHEN OTHERS.
        wa_alv-p = '0.5436'.
    ENDCASE.
    wa_alv-quantity   = sy-index * 1000.
    wa_alv-qunit     = 'MT'.
    CASE sy-index.
      WHEN 1.
        wa_alv-qunit     = 'MT'.
      WHEN 2.
        wa_alv-qunit     = 'MT'.
      WHEN OTHERS.
        wa_alv-qunit     = 'KG'.
    ENDCASE.
    wa_alv-cp      = wa_alv-p.
    wa_alv-currency = 1000.
    CASE sy-index.
      WHEN 1.
        wa_alv-cunit   = 'RMB'.
      WHEN 2.
        wa_alv-cunit   = 'CNY'.
      WHEN OTHERS.
        wa_alv-cunit   = 'JPY'.
    ENDCASE.
    wa_alv-cunit2  = wa_alv-cunit.
    wa_alv-datum   = g_datum.
    g_datum        = g_datum + 1.
    wa_alv-bname   = sy-uname.
    wa_alv-bnamel  = sy-uname.
    wa_alv-bnamel2 = sy-uname.

*--颜色相关
    PERFORM f_alv_color.

    APPEND wa_alv TO itab_alv.

  ENDDO .

ENDFORM.                    " f_get_data
*&---------------------------------------------------------------------*
*&      Form  f_check_alv_type
*&---------------------------------------------------------------------*
*       判断显示哪种ALV
*----------------------------------------------------------------------*
*      <--P_FLG_ALV  ALV种类
*----------------------------------------------------------------------*
FORM f_check_alv_type  CHANGING p_flg_alv.
*----------------------------------------------------------------------*
*      注意修改各个ALL中的CASE语句:
*FORM f_layout_all .
*FORM f_fieldcatalog_all .
*FORM f_sort_all .
*FORM f_gui_all .
*FORM f_show_alv_all .
*----------------------------------------------------------------------*
  IF fagd = 'X'.
    p_flg_alv = 1.
  ELSEIF fagdlvc = 'X'.
    p_flg_alv = 2.
  ELSEIF fabl = 'X'.
    p_flg_alv = 3.
  ENDIF.
ENDFORM.                    " f_check_alv_type
*&---------------------------------------------------------------------*
*&      Form  f_layout_all
*&---------------------------------------------------------------------*
*       各种ALV处理LAYOUT相关设置
*----------------------------------------------------------------------*
FORM f_layout_all .
  CASE g_flg_alv.
    WHEN 1 OR 3.
      PERFORM f_layout CHANGING wa_layout.
    WHEN 2.
    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " f_layout_all
*&---------------------------------------------------------------------*
*&      Form  f_fieldcatalog_reuse
*&---------------------------------------------------------------------*
*       REUSE_ALV_FIELDCATALOG_MERGE
*----------------------------------------------------------------------*
*      -->P_REPID  text
*      -->P_TABNAME  text
*      <--PT_FIELDCATALOG  text
*----------------------------------------------------------------------*
*form f_fieldcatalog_reuse  tables
*                   PT_FIELDCATALOG1 structure wa_alv_fieldcatalog
FORM f_fieldcatalog_reuse USING p_repid         TYPE      sy-repid
                                p_tabname       LIKE      cns_tabname
                       CHANGING pt_fieldcatalog LIKE
                                                  itab_alv_fieldcatalog.
*----------------------------------------------------------------------*
*即使是注释也不能太长。
*原因：FM“K_KKB_FIELDCAT_MERGE”以下代码可能会报错：
* line:363
*    read report l_prog_tab_local into l_abap_source.
*    check sy-subrc eq 0.
*----------------------------------------------------------------------*
*& 其它功能实现相关处理内容：
*& 1、颜色设置
*& 2、F1帮助
*&
*----------------------------------------------------------------------*
*& 1、不能使用structure line of：系统提示参数数量不匹配
*&    只能使用structure
*& 2、对于REUSE_ALV_FIELDCATALOG_MERGE，只能用changing传内表，
*&    因为tables产生的是带有表头的内表参数
*& 3、不同名但同数据元素(数据库字段)会作为重复而排除
*&    但基本类型不会有这个问题
*&---------------------------------------------------------------------*
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
   EXPORTING
     i_program_name               = p_repid
     i_internal_tabname           = p_tabname
*   i_structure_name             = ' '
*   I_CLIENT_NEVER_DISPLAY       = 'X'
     i_inclname                   = p_repid
     i_bypassing_buffer           = 'X'"
*   I_BUFFER_ACTIVE              =
    CHANGING
      ct_fieldcat                  = pt_fieldcatalog
   EXCEPTIONS
     inconsistent_interface       = 1
     program_error                = 2
     OTHERS                       = 3
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    LOOP AT pt_fieldcatalog INTO wa_alv_fieldcatalog.
*-----
      PERFORM f_fieldcatalog_single.
*-----更新
      MODIFY pt_fieldcatalog FROM wa_alv_fieldcatalog
*                     TRANSPORTING seltext_l
*                                  emphasize
                                  .
    ENDLOOP.
  ENDIF.
ENDFORM.                    " f_fieldcatalog_reuse
*&---------------------------------------------------------------------*
*&      Form  f_fieldcatalog_all
*&---------------------------------------------------------------------*
*       各种控制ALV列显示
*----------------------------------------------------------------------*
FORM f_fieldcatalog_all .

  CASE g_flg_alv.
    WHEN 1 OR 3.
      PERFORM f_fieldcatalog_reuse USING    cns_repid
                                            cns_tabname
                                   CHANGING itab_alv_fieldcatalog.
    WHEN 2.
    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " f_fieldcatalog_all
*&---------------------------------------------------------------------*
*&      Form  f_layout
*&---------------------------------------------------------------------*
*       处理LAYOUT相关设置
*----------------------------------------------------------------------*
*      <--P_LAYOUT  ALV的LAYOUT结构体变量
*----------------------------------------------------------------------*
*& 其它功能实现相关处理内容：
*& 1、颜色设置
*& 2、求和（数字、字符型数字）
*&
*----------------------------------------------------------------------*
FORM f_layout  CHANGING pa_layout LIKE wa_layout.
*types: begin of slis_layout_alv.
*58项？
*         dummy,
*         no_colhead(1) type c,         " no headings
*         no_hotspot(1) type c,         " headings not as hotspot
*         zebra(1) type c,              " striped pattern
*         no_vline(1) type c,           " columns separated by space
*         no_hline(1) type c,        "rows separated by space B20K8A0N5D
*         cell_merge(1) type c,         " not suppress field replication
*         edit(1) type c,               " for grid only
*         edit_mode(1) type c,          " for grid only
*         numc_sum(1)     type c,       " totals for NUMC-Fields possib.
*         no_input(1) type c,           " only display fields
*         f2code like sy-ucomm,                              "
*         reprep(1) type c,             " report report interface active
*         no_keyfix(1) type c,          " do not fix keycolumns
*         expand_all(1) type c,         " Expand all positions
*         no_author(1) type c,          " No standard authority check
**        PF-status
*         def_status(1) type c,         " default status  space or 'A'
*         item_text(20) type c,         " Text for item button
*         countfname type lvc_fname,
**        Display options
*         colwidth_optimize(1) type c,
*         no_min_linesize(1) type c,    " line size = width of the list
*         min_linesize like sy-linsz,   " if initial min_linesize = 80
*         max_linesize like sy-linsz,   " Default 250
*         window_titlebar like sy-title,
*         no_uline_hs(1) type c,
**        Exceptions
*         lights_fieldname type slis_fieldname," fieldname for exception
*         lights_tabname type slis_tabname, " fieldname for exception
*lights_rollname like dfies-rollname," rollname f. exceptiondocu
*         lights_condense(1) type c,    " fieldname for exception
**        Sums
*         no_sumchoice(1) type c,       " no choice for summing up
*         no_totalline(1) type c,       " no total line
*         no_subchoice(1) type c,       " no choice for subtotals
*         no_subtotals(1) type c,       " no subtotals possible
*         no_unit_splitting type c,     " no sep. tot.lines by inh.units
*         totals_before_items type c,   " diplay totals before the items
*         totals_only(1) type c,        " show only totals
*totals_text(60) type c,       " text for 1st col. in total line
*         subtotals_text(60) type c,    " text for 1st col. in subtotals
**        Interaction
*         box_fieldname type slis_fieldname, " fieldname for checkbox
*         box_tabname type slis_tabname," tabname for checkbox
*         box_rollname like dd03p-rollname," rollname for checkbox
*expand_fieldname type slis_fieldname, " fieldname flag 'expand'
*hotspot_fieldname type slis_fieldname, " fieldname flag hotspot
*         confirmation_prompt,          " confirm. prompt when leaving
*         key_hotspot(1) type c,        " keys as hotspot " K_KEYHOT
*         flexible_key(1) type c,       " key columns movable,...
*         group_buttons(1) type c,      " buttons for COL1 - COL5
*         get_selinfos(1) type c,       " read selection screen
*         group_change_edit(1) type c,  " Settings by user for new group
*         no_scrolling(1) type c,       " no scrolling
**        Detailed screen
*         detail_popup(1) type c,       " show detail in popup
*         detail_initial_lines(1) type c, " show also initial lines
*         detail_titlebar like sy-title," Titlebar for detail
**        Display variants
*         header_text(20) type c,       " Text for header button
*         default_item(1) type c,       " Items as default
**        colour
*         info_fieldname type slis_fieldname, " infofield for listoutput
*         coltab_fieldname type slis_fieldname, " colors
**        others
*         list_append(1) type c,       " no call screen
*         xifunckey type aqs_xikey,    " eXtended interaction(SAPQuery)
*         xidirect type flag,          " eXtended INTeraction(SAPQuery)
*         dtc_layout type dtc_s_layo,  "Layout for configure the Tabstip
*types: end of slis_layout_alv.

**************补完以下参数******************
*         dummy,
*--没有列名行
*         no_colhead(1) type c,         " no headings
*  pa_layout-no_colhead = 'X'.
*--
*         no_hotspot(1) type c,         " headings not as hotspot
*  pa_layout-no_hotspot = 'X'."效果？
*--在非编辑状态ALV界面深蓝与浅蓝色交替显示行底色
*  pa_layout-zebra = 'X'.
*--用空格分隔各列，fieldcatalog部分除外。
*   pa_layout-no_vline = 'X'.
*--用空格分隔各行
*   pa_layout-no_hline = 'X'.
*--
*         cell_merge(1) type c,         " not suppress field replication
*--ALV处于可编辑状态，会自动出现最前端的BOX
*  pa_layout-edit  = 'X'." for grid only
*--
*         edit_mode(1) type c,          " for grid only
*--是否可以为字符型数字类型求和
*         numc_sum(1)     type c,       " totals for NUMC-Fields possib.
*  pa_layout-numc_sum = 'X'.
*         no_input(1) type c,           " only display fields
*--修改“显示详细”功能代码，默认为F2键
*         f2code like sy-ucomm,
*  pa_layout-layout-f2code = '&ETA'."设置成双击

*         reprep(1) type c,             " report report interface active
*         no_keyfix(1) type c,          " do not fix keycolumns
*         expand_all(1) type c,         " Expand all positions
*         no_author(1) type c,          " No standard authority check
**--------PF-status--------------------------------------------------
*--
*         def_status(1) type c,         " default status  space or 'A'
*         item_text(20) type c,         " Text for item button
*         countfname type lvc_fname,
**--------Display options--------------------------------------------
*--所有列宽度最优化
*  pa_layout-colwidth_optimize = 'X'.
*--
*         no_min_linesize(1) type c,    " line size = width of the list
*         min_linesize like sy-linsz,   " if initial min_linesize = 80
*         max_linesize like sy-linsz,   " Default 250
*--ALV窗口标题栏
  pa_layout-window_titlebar = 'window_titlebar'."like sy-title
*--
*         no_uline_hs(1) type c,
**--------Exceptions-------------------------------------------------
*         lights_fieldname type slis_fieldname," fieldname for exception
*         lights_tabname type slis_tabname, " fieldname for exception
*lights_rollname like dfies-rollname," rollname f. exceptiondocu
*         lights_condense(1) type c,    " fieldname for exception
**--------Sums-------------------------------------------------------
*         no_sumchoice(1) type c,       " no choice for summing up
*         no_totalline(1) type c,       " no total line
*         no_subchoice(1) type c,       " no choice for subtotals
*         no_subtotals(1) type c,       " no subtotals possible
*         no_unit_splitting type c,     " no sep. tot.lines by inh.units
*--求和
  pa_layout-totals_before_items = 'X'." 在ALV最顶端显示求和结果
*  pa_layout-totals_only         = 'X'."只显示总和（无效？）
*totals_text(60) type c,       " text for 1st col. in total line
*  pa_layout-totals_text         = '最长60字符，总和'."无效？
*         subtotals_text(60) type c,    " text for 1st col. in subtotals
**--------Interaction------------------------------------------------
*         box_fieldname type slis_fieldname, " fieldname for checkbox
*         box_tabname type slis_tabname," tabname for checkbox
*         box_rollname like dd03p-rollname," rollname for checkbox
*expand_fieldname type slis_fieldname, " fieldname flag 'expand'
*hotspot_fieldname type slis_fieldname, " fieldname flag hotspot
*         confirmation_prompt,          " confirm. prompt when leaving
*         key_hotspot(1) type c,        " keys as hotspot " K_KEYHOT
*         flexible_key(1) type c,       " key columns movable,...
*         group_buttons(1) type c,      " buttons for COL1 - COL5
*         get_selinfos(1) type c,       " read selection screen
*         group_change_edit(1) type c,  " Settings by user for new group
*--无效？
*         no_scrolling(1) type c,       " no scrolling
*  pa_layout-no_scrolling = 'X'.
**--------Detailed screen--------------------------------------------
*--是否在弹出窗口中显示详细（F2）
*  pa_layout-detail_popup = 'X'."无效？
*         detail_initial_lines(1) type c, " show also initial lines
*--弹出窗口标题栏
*         detail_titlebar like sy-title," Titlebar for detail
  pa_layout-detail_titlebar = '详细内容'."系统默认为“细节”
**--------Display variants-------------------------------------------
*         header_text(20) type c,       " Text for header button
*         default_item(1) type c,       " Items as default
**--------colour-----------------------------------------------------
*----颜色具体设置见FORM f_get_data、FORM f_alv_color
*--行颜色显示控制
*  指定颜色字段指定后fieldcatalog中该字段失效
*  pa_layout-info_fieldname = 'LINECOLOR'." infofield for listoutput
*--单元格颜色显示控制
*  注意该字段为内表，可以添加该行多个字段名
*  pa_layout-coltab_fieldname = 'CELLCOLOR'.
**--------others-----------------------------------------------------
*         list_append(1) type c,       " no call screen
*         xifunckey type aqs_xikey,    " eXtended interaction(SAPQuery)
*         xidirect type flag,          " eXtended INTeraction(SAPQuery)
*         dtc_layout type dtc_s_layo,  "Layout for configure the Tabstip
ENDFORM.                    " f_layout
*&---------------------------------------------------------------------*
*&      Form  f_alv_color
*&---------------------------------------------------------------------*
*       ALV颜色相关处理
*----------------------------------------------------------------------*
FORM f_alv_color .
*----------------------------------------------------------------------*
*颜色设置的优先级顺序从大到小:
*单元格（在内表字段及layout中控制）
*行    （在内表字段及layout中控制）
*列    （在fieldcatalog中控制）
*即若同时使用了上述3中更改颜色的方法，则列的颜色会被行的颜色覆盖掉，而行
*的颜色又会背单元格的颜色覆盖掉，最终只会显示出单元格的颜色.
*----------------------------------------------------------------------*
*& ALV中的颜色代码共有4位，
*& 第1位是固定为“C”（代表COLOR）,
*& 第2位代表是颜色编码(1到7),
*& 第3位是加强颜色的设置（1表示打开，0表示关闭），
*& 第4位是减弱颜色（1表示打开，0表示关闭）,
*& 在强化关闭的情况下,相反的作用是背景和字体的变化。
*& CX00:底色较柔和、前景色为黑色
*& CX01:底色为灰色、前景色为较肉色彩色
*& CX10:底色为强彩色、前景色为黑色
*& CX11:同CX10
*----------------------------------------------------------------------*
*--行颜色相关
  PERFORM f_row_color.
*--列颜色设置(见fieldcatalog)
*fieldcatalog-emphasize = '颜色代码'.
*--单元格颜色相关
  PERFORM f_cell_color.
ENDFORM.                    " f_alv_color
*&---------------------------------------------------------------------*
*&      Form  f_row_color
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_row_color .
*----------------------------------------------------------------------*
*& 必须在layout的info_fieldname中设置颜色字段名
*& 本例为：layout-info_fieldname = 'LINECOLOR'.
*----------------------------------------------------------------------*
  g_color_id = g_color_id + 1 .
  IF g_color_id = 8 .
    g_color_id = 1 .
  ENDIF .
  CONCATENATE 'C' g_color_id '00' INTO wa_alv-linecolor .
ENDFORM.                    " f_row_color
*&---------------------------------------------------------------------*
*&      Form  f_cell_color
*&---------------------------------------------------------------------*
*       控制单元格显示颜色
*----------------------------------------------------------------------*
FORM f_cell_color .
*----------------------------------------------------------------------*
*& 必须在layout的coltab_fieldname中设置颜色字段名
*& 本例为：coltab_fieldname = 'CELLCOLOR'.
*----------------------------------------------------------------------*
*& 可以设置多个字段显示成不同的颜色
*& 只要向组件cellcolor(内表)中添加多条记录
*----------------------------------------------------------------------*
  CLEAR:g_cellcolor.
  CASE wa_alv-c10+8(1).
    WHEN 1 OR 3 OR 5 OR 7 OR 9.
      g_cellcolor-fieldname = 'C10' . " 要修改颜色的字段名
      g_cellcolor-color-col = 6 .       " 颜色（1-7）
      g_cellcolor-color-inv = 1 .       " 前景字体（int代表背景颜色）
      APPEND g_cellcolor TO wa_alv-cellcolor .
    WHEN 2 OR 4 OR 6 OR 8.
      g_cellcolor-fieldname = 'C10' . " 要修改颜色的字段名
      g_cellcolor-color-col = 5 .       " 颜色（1-7）
      g_cellcolor-color-inv = 1 .       " 前景字体（int代表背景颜色）
      APPEND g_cellcolor TO wa_alv-cellcolor .
    WHEN OTHERS.
      g_cellcolor-fieldname = 'C10' . " 要修改颜色的字段名
      g_cellcolor-color-col = 1 .       " 颜色（1-7）
      g_cellcolor-color-inv = 1 .       " 前景字体（int代表背景颜色）
      APPEND g_cellcolor TO wa_alv-cellcolor .
  ENDCASE.
ENDFORM.                    " f_cell_color
*&---------------------------------------------------------------------*
*&      Form  f_fieldcatalog_single
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_fieldcatalog_single .
*----------------------------------------------------------------------*
*& 其它功能实现相关处理内容：
*& 1、颜色设置
*& 2、F1帮助
*& 3、求和
*----------------------------------------------------------------------*
*types: begin of slis_fieldcat_alv.
*         row_pos        like sy-curow, " output in row
*         col_pos        like sy-cucol, " position of the column
*         fieldname      type slis_fieldname,
*         tabname        type slis_tabname,
*         currency(5)    type c,
*         cfieldname     type slis_fieldname, " field with currency unit
*         ctabname       type slis_tabname,   " and table
*         ifieldname     type slis_fieldname, " initial column
*         quantity(3)    type c,
*         qfieldname     type slis_fieldname, " field with quantity unit
*         qtabname       type slis_tabname,   " and table
*         round          type i,        " round in write statement
*         exponent(3)       type c,     " exponent for floats
*         key(1)         type c,        " column with key-color
*         icon(1)        type c,        " as icon
*         symbol(1)      type c,        " as symbol
*         checkbox(1)    type c,        " as checkbox
*         just(1)        type c,        " (R)ight (L)eft (C)ent.
*         lzero(1)       type c,        " leading zero
*         no_sign(1)     type c,        " write no-sign
*         no_zero(1)     type c,        " write no-zero
*         no_convext(1)  type c,
*         edit_mask      type slis_edit_mask,                "
*         emphasize(4)   type c,        " emphasize
*         fix_column(1)   type c,       " Spalte fixieren
*         do_sum(1)      type c,        " sum up
*         no_out(1)      type c,        " (O)blig.(X)no out
*         tech(1)        type c,        " technical field
*         outputlen      like dd03p-outputlen,
*         offset         type dd03p-outputlen,     " offset
*         seltext_l      like dd03p-scrtext_l, " long key word
*         seltext_m      like dd03p-scrtext_m, " middle key word
*         seltext_s      like dd03p-scrtext_s, " short key word
*         ddictxt(1)     type c,        " (S)hort (M)iddle (L)ong
*         rollname       like dd03p-rollname,
*         datatype       like dd03p-datatype,
*         inttype        like dd03p-inttype,
*         intlen         like dd03p-intlen,
*         lowercase      like dd03p-lowercase,
*         ref_fieldname  like dd03p-fieldname,
*         ref_tabname    like dd03p-tabname,
*         roundfieldname type slis_fieldname,
*         roundtabname   type slis_tabname,
*         decimalsfieldname type slis_fieldname,
*         decimalstabname   type slis_tabname,
*         decimals_out(6)   type c,     " decimals in write statement
*         text_fieldname type slis_fieldname,
*         reptext_ddic   like dd03p-reptext,   " heading (ddic)
*         ddic_outputlen like dd03p-outputlen,
*         key_sel(1)     type c,        " field not obligatory
*         no_sum(1)      type c,        " do not sum up
*         sp_group(4)    type c,        " group specification
*         reprep(1)      type c,        " selection for rep/rep
*         input(1)       type c,        " input
*         edit(1)        type c,        " internal use only
*         hotspot(1)     type c,        " hotspot
*types: end of slis_fieldcat_alv.


*         row_pos        like sy-curow, " output in row
*         col_pos        like sy-cucol, " position of the column
*         fieldname      type slis_fieldname,
*         tabname        type slis_tabname,
*--
*         currency(5)    type c,
*         cfieldname     type slis_fieldname, " field with currency unit
*         ctabname       type slis_tabname,   " and table
  PERFORM f_currency_setting.
*--效果不明
*  perform f_filed_ifieldname.
*--
*         quantity(3)    type c,
*         qfieldname     type slis_fieldname, " field with quantity unit
*         qtabname       type slis_tabname,   " and table
  PERFORM f_field_quantity.
*--移动小数位
*         round          type i,        " round in write statement
  PERFORM f_field_round.
*--
*         exponent(3)       type c,     " exponent for floats
*--关键列
*         key(1)         type c,        " column with key-color, hikarulea @ 20141225:if be set this, the column will be displayed at first
  PERFORM f_field_key.
*--图标
*         icon(1)        type c,        " as icon
  PERFORM f_field_icon.
*         symbol(1)      type c,        " as symbol
*--多选框
*         checkbox(1)    type c,        " as checkbox
  PERFORM f_field_checkbox.
*--对齐方式
*         just(1)        type c,        " (R)ight (L)eft (C)ent.
  PERFORM f_field_just.
*--左端补零
*         lzero(1)       type c,        " leading zero
  PERFORM f_field_lzero.
*--没有符号
*         no_sign(1)     type c,        " write no-sign
  PERFORM f_field_nosign.
*--
*         no_zero(1)     type c,        " write no-zero
*--
*         no_convext(1)  type c,
*--输出格式控制
*         edit_mask      type slis_edit_mask,
  PERFORM f_field_editmask.
*--列颜色控制
*         emphasize(4)   type c,        " emphasize
  PERFORM f_column_color.
*--固定列
*         fix_column(1)   type c,       " Spalte fixieren
  PERFORM f_field_fix.
*--单列求和
*         do_sum(1)      type c,        " sum up
  PERFORM f_field_dosum.
*--
*         no_out(1)      type c,        " (O)blig.(X)no out
*--
*         tech(1)        type c,        " technical field
*--列的字符宽度
*         outputlen      like dd03p-outputlen,
  PERFORM f_field_outputlen.
*--
*         offset         type dd03p-outputlen,     " offset
*--列描述设置
*         seltext_l      like dd03p-scrtext_l, " long key word
*         seltext_m      like dd03p-scrtext_m, " middle key word
*         seltext_s      like dd03p-scrtext_s, " short key word
  PERFORM f_field_seltext.
*         ddictxt(1)     type c,        " (S)hort (M)iddle (L)ong
*--F1帮助
*         rollname       like dd03p-rollname,
  PERFORM f_field_f1help.
*--ABAP 字典中的数据类型
*         datatype       like dd03p-datatype,
*--ABAP 数据类型(C,D,N,...)
*         inttype        like dd03p-inttype,
*--以字节计的内部长度
*         intlen         like dd03p-intlen,
*--是否允许输入小写字母?
*         lowercase      like dd03p-lowercase,
  PERFORM f_field_lowercase.
*--F4帮助
*         ref_fieldname  like dd03p-fieldname,
*         ref_tabname    like dd03p-tabname,
  PERFORM f_field_f4help.
*         roundfieldname type slis_fieldname,
*         roundtabname   type slis_tabname,
*         decimalsfieldname type slis_fieldname,
*         decimalstabname   type slis_tabname,
*--控制小数位输出
  PERFORM f_field_decimalsout.
*         text_fieldname type slis_fieldname,
*         reptext_ddic   like dd03p-reptext,   " heading (ddic)
*         ddic_outputlen like dd03p-outputlen,
*         key_sel(1)     type c,        " field not obligatory
*         no_sum(1)      type c,        " do not sum up
*         sp_group(4)    type c,        " group specification
*         reprep(1)      type c,        " selection for rep/rep
*         input(1)       type c,        " input
*         edit(1)        type c,        " internal use only
  PERFORM f_field_edit.
*--热点
*         hotspot(1)     type c,        " hotspot
  PERFORM f_field_hotspot.
ENDFORM.                    " f_fieldcatalog_single
*&---------------------------------------------------------------------*
*&      Form  f_column_color
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_column_color .
*----------------------------------------------------------------------*
*&
*&
*&
*&
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'F'.
      wa_alv_fieldcatalog-emphasize = 'C711'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_column_color
*&---------------------------------------------------------------------*
*&      Form  f_field_f1help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_field_f1help .
*----------------------------------------------------------------------*
*& 1、可以在ALV的显示界面将鼠标放到该字段的位置后按F1会弹出该字段的说明
*& 2、指定数据元素之后，可以不指明字段的描述(如SCRTEXT_L、SCRTEXT_M、
*&    SCRTEXT_S），函数会自动将字段的描述显示，但是没有自己指定的灵活。
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'DATUM'.
      wa_alv_fieldcatalog-rollname = 'DATUM'." 指定数据元素
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_f1help
*&---------------------------------------------------------------------*
*&      Form  f_field_f4help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_field_f4help .
*----------------------------------------------------------------------*
*& 1、可以在ALV的显示界面将鼠标放到该字段的位置后按F1会弹出该字段的说明
*& 2、指定数据元素之后，可以不指明字段的描述(如SCRTEXT_L、SCRTEXT_M、
*&    SCRTEXT_S），函数会自动将字段的描述显示，但是没有自己指定的灵活。
*& 3、部分可以支持F4帮助的字段可能会没有F4HELP效果，例如BNAME
*&    F4HELP的效果是：单击后单元格最前端出现小图标
*& 4、字段不能设置hotspot
*& 5、字段A可以设置成另一个字段B
*&    例如，fieldname = 'BNAME',ref_fieldname = 'MATNR'
*&    所以和ALV的编辑功能一样，需要注意输入后的字段正确性验证
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'BNAME'.
*F4HELP无效：
*原因：SE11中没有F4HELP，只有DOMAIN的value table
      wa_alv_fieldcatalog-ref_fieldname = 'BNAME' .
      wa_alv_fieldcatalog-ref_tabname = 'USR02' .
    WHEN 'MATNR'.
*F4HELP有效：
      wa_alv_fieldcatalog-ref_fieldname = 'MATNR' .
      wa_alv_fieldcatalog-ref_tabname = 'MARA' .
    WHEN 'DATUM'.
      wa_alv_fieldcatalog-ref_fieldname = 'GLTGV' .
      wa_alv_fieldcatalog-ref_tabname = 'USR02' .
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_f4help
*&---------------------------------------------------------------------*
*&      Form  f_field_seltext
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_field_seltext .
*----------------------------------------------------------------------*
*& 1、seltext_m 优先级大于 seltext_l
*& 2、如果seltext_m为空，则使用seltext_l中的内容作为列描述
*& 3、seltext_s 可能只能用来做为列提示时的信息，如果seltext_s为空，则用
*&    列描述做为列信息显示
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'I2'.
      wa_alv_fieldcatalog-seltext_l = '普通负数的显示'.
    WHEN 'I3'.
      wa_alv_fieldcatalog-seltext_l = '去掉数字的符号'.
    WHEN 'I4'.
      wa_alv_fieldcatalog-seltext_l = '负号前置'.
    WHEN 'DATUM'.
    WHEN 'BNAME'.
    WHEN 'BNAMEL2'.
      wa_alv_fieldcatalog-seltext_l = '热点'.
    WHEN OTHERS.
      wa_alv_fieldcatalog-seltext_l = wa_alv_fieldcatalog-fieldname.
  ENDCASE.

ENDFORM.                    " f_field_seltext
*&---------------------------------------------------------------------*
*&      Form  f_field_just
*&---------------------------------------------------------------------*
*       列对齐方式
*----------------------------------------------------------------------*
FORM f_field_just .
*----------------------------------------------------------------------*
*& (R)ight (L)eft (C)ent
*& P.S. 列最优化时，看不出效果，拉开列宽后可以看到效果。
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'DATUM'.
      wa_alv_fieldcatalog-just = cns_c."居中
    WHEN 'BNAME'.
      wa_alv_fieldcatalog-just = cns_r."右对齐
    WHEN 'CP'.
      wa_alv_fieldcatalog-just = cns_r."右对齐
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_just
*&---------------------------------------------------------------------*
*&      Form  f_field_key
*&---------------------------------------------------------------------*
*       关键列
*----------------------------------------------------------------------*
FORM f_field_key .
*----------------------------------------------------------------------*
*& 1、固定列，当ALV显示界面中该字段左侧也为关键或固定列时，
*&    该列固定不动。
*& 2、列底色成为蓝色。
*& 3、列宽不优化时，效果明显。
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'C10'.
      wa_alv_fieldcatalog-key = 'X'.
    WHEN 'N10'.
*      wa_alv_fieldcatalog-key = 'X'."与固定列做对比
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_key
*&---------------------------------------------------------------------*
*&      Form  f_field_fix
*&---------------------------------------------------------------------*
*       固定列
*----------------------------------------------------------------------*
FORM f_field_fix .
*----------------------------------------------------------------------*
*& 1、固定列，当ALV显示界面中该字段左侧也为关键或固定列时，
*&    该列固定不动。
*& 2、列宽不优化时，效果明显。
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'N10'.
      wa_alv_fieldcatalog-fix_column = 'X'."与关键列做对比
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_fix
*&---------------------------------------------------------------------*
*&      Form  f_field_outputlen
*&---------------------------------------------------------------------*
*       列的字符宽度
*----------------------------------------------------------------------*
FORM f_field_outputlen .
*----------------------------------------------------------------------*
*& 在没有最优化列宽的前提下,显式指定某列列宽
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'N10'.
      wa_alv_fieldcatalog-outputlen = 10.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_outputlen
*&---------------------------------------------------------------------*
*&      Form  f_field_lowercase
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_field_lowercase .
*----------------------------------------------------------------------*
*&
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'BNAME'.
      wa_alv_fieldcatalog-lowercase = 'X'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_lowercase
*&---------------------------------------------------------------------*
*&      Form  f_field_dosum
*&---------------------------------------------------------------------*
*       字段求和
*----------------------------------------------------------------------*
FORM f_field_dosum .
*----------------------------------------------------------------------*
*& 1、需要设置fieldcatalog-totals_before_items
*& 2、不能对N型求和，除非设置layout-numc_sum = 'X'
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'N10'.
      wa_alv_fieldcatalog-do_sum = 'X'.
    WHEN 'I'.
      wa_alv_fieldcatalog-do_sum = 'X'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_dosum
*&---------------------------------------------------------------------*
*&      Form  f_field_lzero
*&---------------------------------------------------------------------*
*       左端补零
*----------------------------------------------------------------------*
FORM f_field_lzero .
*----------------------------------------------------------------------*
*& 1、对数字型无效
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'N10'.
      wa_alv_fieldcatalog-lzero = 'X'.
    WHEN 'I'.
      wa_alv_fieldcatalog-lzero = 'X'."无效
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_lzero
*&---------------------------------------------------------------------*
*&      Form  f_field_nosign
*&---------------------------------------------------------------------*
*       去除符号显示
*----------------------------------------------------------------------*
FORM f_field_nosign .
*----------------------------------------------------------------------*
*&
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'I3'.
      wa_alv_fieldcatalog-no_sign = 'X'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_nosign
*&---------------------------------------------------------------------*
*&      Form  f_field_hotspot
*&---------------------------------------------------------------------*
*       设置热点
*----------------------------------------------------------------------*
FORM f_field_hotspot .
*----------------------------------------------------------------------*
*& 1、字符下出现下划线
*& 2、鼠标移动至该列时，变成手指可点击形状
*& 3、单击即可触发user_command命令
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'BNAMEL2'.
      wa_alv_fieldcatalog-hotspot = 'X'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_hotspot
*&---------------------------------------------------------------------*
*&      Form  f_user_command
*&---------------------------------------------------------------------*
*       ALV用户命令
*----------------------------------------------------------------------*
FORM f_user_command USING p_ucomm    TYPE sy-ucomm
                          p_selfield TYPE slis_selfield.
*----------------------------------------------------------------------*
*& 1、selfield-sel_tab_field为“fieldcatalog-tabname”-“fieldname”
*----------------------------------------------------------------------*
*types: begin of slis_selfield,
*         tabname type slis_tabname,
*         tabindex like sy-tabix,
*         sumindex like sy-tabix,
*         endsum(1) type c,
*         sel_tab_field type slis_sel_tab_field,
*         value type slis_entry,
*         before_action(1) type c,
*         after_action(1) type c,
*         refresh(1) type c,
*         ignore_multi(1) type c, " ignore selection by checkboxes (F2)
*         col_stable(1) type c,
*         row_stable(1) type c,
**        colwidth_optimize(1) type c,"本项被SAP注释
*         exit(1) type c,
*         fieldname type slis_fieldname,
*         grouplevel type i,
*         collect_from type i,
*         collect_to type i,
*       end of slis_selfield.
  READ TABLE itab_alv INTO wa_alv INDEX p_selfield-tabindex.
  CHECK sy-subrc = 0.
  CASE p_ucomm.
    WHEN '&IC1'."双击
      CASE p_selfield-sel_tab_field.
        WHEN  'CNS_ALV-BNAME'.
          SET PARAMETER ID 'XUS' FIELD wa_alv-bname.
          CALL TRANSACTION 'SU01' AND SKIP FIRST SCREEN.
      ENDCASE.
  ENDCASE.
ENDFORM.                    " f_user_command
*&---------------------------------------------------------------------*
*&      Form  f_html_top_of_page
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CL_DD  text
*----------------------------------------------------------------------*
FORM f_html_top_of_page USING p_cl_dd TYPE REF TO cl_dd_document.
* 定义登录用户的描述
  DATA: l_name TYPE string ,
        name_first LIKE adrp-name_first ,
        name_last  LIKE adrp-name_last .
* 定义登录日期
  DATA: l_date TYPE string .
* 定义缓冲区变量
  DATA: m_p TYPE i ,
        m_buffer TYPE string .

* 得到登录用户的描述
  SELECT SINGLE adrp~name_first
                adrp~name_last
    INTO (name_first,name_last)
    FROM adrp
   INNER JOIN usr21 ON adrp~persnumber = usr21~persnumber
   WHERE usr21~bname = sy-uname .

  IF sy-subrc = 0 .
    CONCATENATE name_last name_first INTO l_name .
  ELSE .
    l_name = sy-uname .
  ENDIF.
  CLEAR name_first .
  CLEAR name_last .

* 拼接制表日期
  CONCATENATE sy-datum+0(4) '.'
              sy-datum+4(2) '.'
              sy-datum+6(2)
         INTO l_date .

* 开始输出表头标题
  m_buffer = '<HTML><CENTER><H1>ALV测试</H1></CENTER></HTML>' .
  CALL METHOD p_cl_dd->html_insert
    EXPORTING
      contents = m_buffer
    CHANGING
      position = m_p.

* 输出制表人和制表日期
  CONCATENATE '<P ALIGN = CENTER >出表人：' l_name
            '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&'
            'nbsp                     &nbsp'
            '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'
            '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'
            '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'
            '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'
            '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'
            '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'
            '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'
            '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'
            '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'
            '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'
            '出表日期：' l_date INTO m_buffer .
  CALL METHOD p_cl_dd->html_insert
    EXPORTING
      contents = m_buffer
    CHANGING
      position = m_p.

ENDFORM.                    " f_html_top_of_page
*&---------------------------------------------------------------------*
*&      Form  f_show_alv_all
*&---------------------------------------------------------------------*
*       各种ALV的显示
*----------------------------------------------------------------------*
FORM f_show_alv_all .
  CASE g_flg_alv.
    WHEN 1.
      PERFORM f_show_alv.
    WHEN 2.
    WHEN 3."垂直方向同屏幕显示多个ALV
      PERFORM f_show_alv_bl.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_show_alv_all
*&---------------------------------------------------------------------*
*&      Form  f_show_alv
*&---------------------------------------------------------------------*
*       REUSE_ALV_GRID_DISPLAY
*----------------------------------------------------------------------*
FORM f_show_alv .
*----------------------------------------------------------------------*
*FOR I_SAVE
* ' ' = Display variants cannot be saved
*   Defined display variants (such as delivered display variants) can
*   be selected for presentation regardless of this indicator. However,
*   changes cannot be saved.
* 'X' = Standard save mode
*   Display variants can be saved as standard display variants.
*   Saving display variants as user-specific is not possible.
* 'U' = User-specific save mode
*   Display variants can only be saved as user-specific.
* 'A' = Standard and user-specific save mode
*   Display variants can be saved both as user-specific and as standard
*   variants. Users make their choice on the dialog box for saving the
*   display variant.
*----------------------------------------------------------------------*
*FOR IT_SORT in FORM f_sort.
*----------------------------------------------------------------------*
*以下2个参数有部分效果相同，可以穿空值
*     i_callback_pf_status_set          = cns_pf_status_set
*     it_excluding                      = itab_alv_excluding
*----------------------------------------------------------------------*
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   EXPORTING
*   I_INTERFACE_CHECK                 = ' '
*   I_BYPASSING_BUFFER                = ' '
*   I_BUFFER_ACTIVE                   = ' '
     i_callback_program                = cns_repid " type SY-REPID
     i_callback_pf_status_set          = cns_pf_status_set
     i_callback_user_command           = cns_user_command
*   I_CALLBACK_TOP_OF_PAGE            = ' '
     i_callback_html_top_of_page       = cns_html_top_of_page
*   I_CALLBACK_HTML_END_OF_LIST       = ' '
*   I_STRUCTURE_NAME                  =
*   I_BACKGROUND_ID                   = ' '
     i_grid_title                      = cns_grid_title
*   I_GRID_SETTINGS                   =
     is_layout                         = wa_layout
     it_fieldcat                       = itab_alv_fieldcatalog
     it_excluding                      = itab_alv_excluding
*   IT_SPECIAL_GROUPS                 =
     it_sort                           = itab_alv_sort
*   IT_FILTER                         =
*   IS_SEL_HIDE                       =
*   I_DEFAULT                         = 'X'
     i_save                            = cns_x " space x u a
*   IS_VARIANT                        =
   it_events                         = itab_alv_event
*   IT_EVENT_EXIT                     =
*   IS_PRINT                          =
*   IS_REPREP_ID                      =
*   I_SCREEN_START_COLUMN             = 0
*   I_SCREEN_START_LINE               = 0
*   I_SCREEN_END_COLUMN               = 0
*   I_SCREEN_END_LINE                 = 0
*   IT_ALV_GRAPHICS                   =
*   IT_HYPERLINK                      =
*   IT_ADD_FIELDCAT                   =
*   IT_EXCEPT_QINFO                   =
*   I_HTML_HEIGHT_TOP                 =
*   I_HTML_HEIGHT_END                 =
* IMPORTING
*   E_EXIT_CAUSED_BY_CALLER           =
*   ES_EXIT_CAUSED_BY_USER            =
   TABLES
     t_outtab                          = itab_alv
   EXCEPTIONS
     program_error                     = 1
     OTHERS                            = 2
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " f_show_alv
*&---------------------------------------------------------------------*
*&      Form  f_sort_all
*&---------------------------------------------------------------------*
*       ALV显示排序
*----------------------------------------------------------------------*
FORM f_sort_all .
  CASE g_flg_alv.
    WHEN 1 OR 3.
      PERFORM f_sort.
    WHEN 2.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_sort_all
*&---------------------------------------------------------------------*
*&      Form  f_sort
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_sort .
*----------------------------------------------------------------------*
*       IT_SORT TYPE  SLIS_T_SORTINFO_ALV
*types: begin of slis_sortinfo_alv,
**        spos(2) type n,           "本项被SAP注释
*         spos like alvdynp-sortpos,
*         fieldname type slis_fieldname,
*         tabname type slis_fieldname,
**        up(1) type c,             "本项被SAP注释
**        down(1) type c,           "本项被SAP注释
**        group(2) type c,          "本项被SAP注释
**        subtot(1) type c,         "本项被SAP注释
*         up like alvdynp-sortup,
*         down like alvdynp-sortdown,
*         group like alvdynp-grouplevel,
*         subtot like alvdynp-subtotals,
*         comp(1) type c,
*         expa(1) type c,
*         obligatory(1) type c,
*       end of slis_sortinfo_alv.
*----------------------------------------------------------------------*
*wa_alv_sort-spos       = 1.
*wa_alv_sort-fieldname = 'N10'.
*wa_alv_sort-up        = 'X'.
*wa_alv_sort-subtot    = 'X'.
*append wa_alv_sort to itab_alv_sort.

  wa_alv_sort-spos       = 1.
  wa_alv_sort-fieldname = 'BNAME'.
  wa_alv_sort-up        = 'X'.
  wa_alv_sort-subtot    = 'X'.
  APPEND wa_alv_sort TO itab_alv_sort.
ENDFORM.                    " f_sort
*&---------------------------------------------------------------------*
*&      Form  f_field_icon
*&---------------------------------------------------------------------*
*       设置图标
*----------------------------------------------------------------------*
FORM f_field_icon .
*----------------------------------------------------------------------*
*& 1、ICON字段在fieldcatalog需要的结构体中只能用like定义
*& 2、ICON的值来自于类型池ICON、或者数据库表ICON
*& 3、如果只是用于显示红绿灯图标，可以使用以下方法：
*&    ICON(1)  TYPE C,"1:Red; 2:Yellow; 3:Green
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'ICON'.
      wa_alv_fieldcatalog-icon = 'X'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_icon
*&---------------------------------------------------------------------*
*&      Form  f_field_checkbox
*&---------------------------------------------------------------------*
*       设置多选框
*----------------------------------------------------------------------*
FORM f_field_checkbox .
*----------------------------------------------------------------------*
*& 1、需要配合编辑状态
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'BOX'.
      wa_alv_fieldcatalog-checkbox = 'X'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_checkbox
*&---------------------------------------------------------------------*
*&      Form  f_field_editmask
*&---------------------------------------------------------------------*
*       效果不明
*----------------------------------------------------------------------*
FORM f_field_editmask .
*----------------------------------------------------------------------*
*& 1、可以实现字段显示效果？的转换规则
*----------------------------------------------------------------------*
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'I4'.
*符号前置的一种方法，V后面的_可以任意数量，缺点：没有数字分割符
      wa_alv_fieldcatalog-edit_mask = 'V______'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_editmask
*&---------------------------------------------------------------------*
*&      Form  f_gui_all
*&---------------------------------------------------------------------*
*       设置用户接口相关内容
*----------------------------------------------------------------------*
FORM f_gui_all .
  CASE g_flg_random.
    WHEN 1 OR 3.
*ALV 功能键 - 设置
      PERFORM f_fcode_all.
    WHEN 2.
*自定义工具栏
      PERFORM f_pfstatus_all.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_gui_all
*&---------------------------------------------------------------------*
*&      Form  f_fcode_all
*&---------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
FORM f_fcode_all .
  CASE g_flg_alv.
    WHEN 1.
      PERFORM f_fcode.
    WHEN 2.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_fcode_all
*&---------------------------------------------------------------------*
*&      Form  f_fcode
*&---------------------------------------------------------------------*
*       设置要隐藏的按钮的“FCODE”
*----------------------------------------------------------------------*
FORM f_fcode .
  "&ETA     :细节
  "&EB9     :调用报表
  "&REFRESH :刷新
  "&ALL     :选择全部
  "&SAL     :取消选择全部
  "&OUP     :按升序排序
  "&ODN     :按降序排序
  "&ILT     :设置过滤器
  "&UMC     :总计
  "&SUM     :小计
  "&RNT_PREV:打印预览
  "&VEXCEL  :Microsoft Excel
  "&AQW     :字处理
  "%PC      :本地文件
  "%SL      :邮件收件人
  "&ABC     :ABC分析
  "&GRAPH   :图形
  "&OL0     :更改布局
  "&OAD     :选择布局
  "&AVE     :保存布局
  "&INFO    :信息
  wa_alv_excluding-fcode = '&AQW' .
  APPEND wa_alv_excluding TO itab_alv_excluding .
  wa_alv_excluding-fcode = '&ABC' .
  APPEND wa_alv_excluding TO itab_alv_excluding .
  wa_alv_excluding-fcode = '&ABC' .
  APPEND wa_alv_excluding TO itab_alv_excluding .
  wa_alv_excluding-fcode = '&OL0' .
  APPEND wa_alv_excluding TO itab_alv_excluding .
  wa_alv_excluding-fcode = '&OAD' .
  APPEND wa_alv_excluding TO itab_alv_excluding .
  wa_alv_excluding-fcode = '&AVE' .
  APPEND wa_alv_excluding TO itab_alv_excluding .
  wa_alv_excluding-fcode = '&INFO' .
  APPEND wa_alv_excluding TO itab_alv_excluding .
ENDFORM.                    " f_fcode
*&---------------------------------------------------------------------*
*&      Form  f_pfstatus_all
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_pfstatus_all .
  CASE g_flg_alv.
    WHEN 1.
      PERFORM f_pfstatus.
    WHEN 2.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_pfstatus_all
*&---------------------------------------------------------------------*
*&      Form  f_pfstatus
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_pfstatus .
  cns_pf_status_set = 'F_PF_STATUS_SET'.
ENDFORM.                    " f_pfstatus
*&---------------------------------------------------------------------*
*&      Form  f_pf_status_set
*&---------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
FORM f_pf_status_set USING p_extab TYPE slis_t_extab .
*“分隔符”的插入方法为：
*在需要插入分隔符的方框内选择菜单
*“Edit”->“Insert”->“Separator line”即可插入分隔符
  SET PF-STATUS 'ALV_STATUS' .
ENDFORM.                    " f_pf_status_set
*&---------------------------------------------------------------------*
*&      Form  f_get_random
*&---------------------------------------------------------------------*
*       获得随机数
*----------------------------------------------------------------------*
FORM f_get_random .
*----------------------------------------------------------------------*
*用 QF05_RANDOM_INTEGER 来获得随机数, 第一次使用的时候只是获得种子.
*所以在程序中使用的时候,要在最开始设置种子.
*不然每次获得的随机数都一样
*from：http://blog.chinaunix.net/u2/64493/showart_525094.html
*
*即：QF05_RANDOM_INTEGER第一次运行的结果必定一样
*RAN_INT参数不是必须的
*----------------------------------------------------------------------*
  CALL FUNCTION 'QF05_RANDOM_INTEGER'
   EXPORTING
     ran_int_max         = 10
     ran_int_min         = 1
* IMPORTING
*   RAN_INT             = g_flg_random
   EXCEPTIONS
     invalid_input       = 1
     OTHERS              = 2
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL FUNCTION 'QF05_RANDOM_INTEGER'
    EXPORTING
      ran_int_max   = 2
      ran_int_min   = 1
    IMPORTING
      ran_int       = g_flg_random
    EXCEPTIONS
      invalid_input = 1
      OTHERS        = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " f_get_random
*&---------------------------------------------------------------------*
*&      Form  f_field_round
*&---------------------------------------------------------------------*
*       移动小数位？
*----------------------------------------------------------------------*
FORM f_field_round .
*----------------------------------------------------------------------*
*& 1、效果类似 WRITE ... ROUND r
* WRITE ... ROUND r 的效果
*
* Scaled output of a field of type P.
*
* The decimal point is first moved r places to the left (r > 0) or to
* theright (r < 0); this is the same as dividing with the appropriate
* exponent 10**r. The value determined in this way is output with the
* valid number of digits before and after the decimal point. If the
* decimal point is moved to the left, the number is rounded.
*
* For further information about the interaction between the formatting
* options CURRENCY and DECIMALS, see the notes below.
*
*Example
*Effect of different ROUND specifications:
*
*DATA: X TYPE P DECIMALS 2 VALUE '12493.97'.
*
*WRITE: /X ROUND -2,   "output: 1,249,397.00
*       /X ROUND  0,   "output:    12,493.97
*       /X ROUND  2,   "output:       124.94
*       /X ROUND  5,   "output:         0.12
*
*所以，一般与fieldcatalog中的decimals_out一起使用
*-:放大，-2→数字=数字×100
*+:缩小， 2→数字=数字/100
*----------------------------------------------------------------------*
*         round          type i,        " round in write statement
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'P'.
      wa_alv_fieldcatalog-round = -2."小数点偏移位置
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_round
*&---------------------------------------------------------------------*
*&      Form  f_filed_ifieldname
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_filed_ifieldname .
*----------------------------------------------------------------------*
*& 1、
*----------------------------------------------------------------------*
*         ifieldname     type slis_fieldname, " initial column
*内部表字段的字段名称？
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'P'.
      wa_alv_fieldcatalog-ifieldname = ''.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_filed_ifieldname
*&---------------------------------------------------------------------*
*&      Form  f_show_alv_bl
*&---------------------------------------------------------------------*
*       垂直方向同屏幕显示多个ALV
*----------------------------------------------------------------------*
FORM f_show_alv_bl .
*----------------------------------------------------------------------*
*& 1、
*----------------------------------------------------------------------*
*改自: http://blog.chinaunix.net/u2/64493/showart.php?id=1090105
  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_INIT'
    EXPORTING
      i_callback_program             = cns_repid
*   I_CALLBACK_PF_STATUS_SET       = ' '
*   I_CALLBACK_USER_COMMAND        = ' '
*   IT_EXCLUDING                   =
            .
*添加第1个ALV
  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_APPEND'
    EXPORTING
      is_layout                        = wa_layout
      it_fieldcat                      = itab_alv_fieldcatalog
      i_tabname                        = 'ITAB_ALV'
      it_events                        = itab_alv_event
*   IT_SORT                          =
*   I_TEXT                           = ' '
    TABLES
      t_outtab                         = itab_alv
   EXCEPTIONS
     program_error                    = 1
     maximum_of_appends_reached       = 2
     OTHERS                           = 3
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
*添加第2个ALV
  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_APPEND'
    EXPORTING
      is_layout                        = wa_layout
      it_fieldcat                      = itab_alv_fieldcatalog
      i_tabname                        = 'ITAB_ALV'
      it_events                        = itab_alv_event
*   IT_SORT                          =
*   I_TEXT                           = ' '
    TABLES
      t_outtab                         = itab_alv
   EXCEPTIONS
     program_error                    = 1
     maximum_of_appends_reached       = 2
     OTHERS                           = 3
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
*显示
  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_DISPLAY'
* EXPORTING
*   I_INTERFACE_CHECK             = ' '
*   IS_PRINT                      =
*   I_SCREEN_START_COLUMN         = 0
*   I_SCREEN_START_LINE           = 0
*   I_SCREEN_END_COLUMN           = 0
*   I_SCREEN_END_LINE             = 0
* IMPORTING
*   E_EXIT_CAUSED_BY_CALLER       =
*   ES_EXIT_CAUSED_BY_USER        =
   EXCEPTIONS
     program_error                 = 1
     OTHERS                        = 2
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " f_show_alv_bl
*&---------------------------------------------------------------------*
*&      Form  f_event_all
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_event_all .
*----------------------------------------------------------------------*
*& 1、
*----------------------------------------------------------------------*
*types: begin of slis_alv_event,
*        name(30),
*        form(30),
*      end of slis_alv_event.
  CASE g_flg_alv.
    WHEN 1 OR 3.
      PERFORM f_event.
    WHEN 2.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_event_all
*&---------------------------------------------------------------------*
*&      Form  f_event
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_event .
*----------------------------------------------------------------------*
*& 1、
*----------------------------------------------------------------------*
  CALL FUNCTION 'REUSE_ALV_EVENTS_GET'
    EXPORTING
      i_list_type     = 0
    IMPORTING
      et_events       = itab_alv_event
    EXCEPTIONS
      list_type_wrong = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " f_event
*&---------------------------------------------------------------------*
*&      Form  f_field_decimalsout
*&---------------------------------------------------------------------*
*       控制输出小数位
*----------------------------------------------------------------------*
FORM f_field_decimalsout .
*----------------------------------------------------------------------*
*& 1、一般与fieldcatalog中的round字段一起使用
*----------------------------------------------------------------------*
*         decimals_out(6)   type c,     " decimals in write statement
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'P'.
      wa_alv_fieldcatalog-decimals_out = 0."输出的小数位数
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_decimalsout
*&---------------------------------------------------------------------*
*&      Form  f_currency_setting
*&---------------------------------------------------------------------*
*       货币设置
*----------------------------------------------------------------------*
*& 1、
*----------------------------------------------------------------------*
FORM f_currency_setting .
*         currency(5)    type c,
*         cfieldname     type slis_fieldname, " field with currency unit
*         ctabname       type slis_tabname,   " and table
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'CURRENCY'.
      wa_alv_fieldcatalog-cfieldname = 'CUNIT'.
      wa_alv_fieldcatalog-ctabname = 'ITAB_ALV'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_currency_setting
*&---------------------------------------------------------------------*
*&      Form  f_field_quantity
*&---------------------------------------------------------------------*
*       数量设置
*----------------------------------------------------------------------*
*& 1、
*----------------------------------------------------------------------*
FORM f_field_quantity .
*         quantity(3)    type c,
*         qfieldname     type slis_fieldname, " field with quantity unit
*         qtabname       type slis_tabname,   " and table
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'QUANTITY'.
*      wa_alv_fieldcatalog-quantity = 'MT'."无效
      wa_alv_fieldcatalog-qfieldname = 'QUNIT'.
      wa_alv_fieldcatalog-qtabname = 'ITAB_ALV'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " f_field_quantity
*&---------------------------------------------------------------------*
*&      Form  F_FIELD_EDIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_field_edit .
  CASE wa_alv_fieldcatalog-fieldname.
    WHEN 'MATNR'.
      wa_alv_fieldcatalog-edit = 'X'.
    WHEN OTHERS.
      wa_alv_fieldcatalog-edit = ''.

  ENDCASE.
ENDFORM.                    " F_FIELD_EDIT