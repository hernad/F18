/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2024 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#define F18_COLOR_P1               "GR+/N"

/*
         -----------------------------------------------------------------------
         Color          Letter    Number  Monochrome
         -----------------------------------------------------------------------
         Black          N, Space  0       Black
         Blue           B         1       Underline
         Green          G         2       White
         Cyan           BG        3       White
         Red            R         4       White
         Magenta        RB        5       White
         Brown          GR        6       White
         White          W         7       White
         Gray           N+        8       Black
         Bright Blue    B+        9       Bright Underline
         Bright Green   G+        10      Bright White
         Bright Cyan    BG+       11      Bright White
         Bright Red     R+        12      Bright White
         Bright Magenta RB+       13      Bright White
         Yellow         GR+       14      Bright White
         Bright White   W+        15      Bright White
         Black          U                 Underline
         Inverse Video  I                 Inverse Video
         Blank          X                 Blank
         -----------------------------------------------------------------------

         SET COLOR  TO
             1) <standard>
             2) <enhanced>
             3) <border>
             4) <background>
             5) <unselected>
*/


// VAR aColors           INIT { "W+/BG", "N/BG", "R/BG", "N+/BG", "W+/B", "GR+/B", "W/B", "N/W", "R/W", "N/BG", "R/BG" }

// "Border", "Text", "Text High", "Text PPO", "Text Selected", ;
// "Text High Sel.", "Text PPO Sel.", "meni_0", "meni_0 High", ;
// "meni_0 Selected", "meni_0 High Sel."


#define F18_COLOR_NORMAL                "W/B,R/N,W/R,N/G,N/W" // bijela/plava,crvena/crna
#define F18_COLOR_NORMAL_STARA_SEZONA   "W+/N,R/BG,W/R,N/G,GR+/N" // bijela/crna,crvena/crna
//#define F18_COLOR_NORMAL_STARA_SEZONA   "N/BG,W/B,W/R,N/G,N/W" // bijela/cyan,crvena/crna


#define F18_COLOR_INFO_PANEL       hb_ColorIndex(SetColor(), 0)
#define F18_COLOR_ERROR_PANEL      hb_ColorIndex(SetColor(), 2)
#define F18_COLOR_NAGLASENO        "GR+/B"
#define F18_COLOR_NAGLASENO_STARA_SEZONA  "W+/N"

#define F18_COLOR_ORGANIZACIJA     hb_ColorIndex(f18_color_normal(), 4)+","+hb_ColorIndex(f18_color_normal(), 3)+","+hb_ColorIndex(f18_color_normal(), 2)+","+hb_ColorIndex(f18_color_normal(), 1)+","+hb_ColorIndex(f18_color_normal(), 0)


#define F18_COLOR_NORMAL_BW        "W/N,N/W,,,N/W"


#define F18_COLOR_BACKUP           "N/W"
#define F18_COLOR_BACKUP_OK        "W+/B+"
#define F18_COLOR_BACKUP_ERROR     "W+/R+"

#define F18_COLOR_PASSWORD         "BG/BG"
#define F18_COLOR_MSG_BOTTOM       "GR+/B"
#define F18_COLOR_BROWSE_GET       "W+/BG,W+/B"
#define F18_COLOR_STATUS           "GR+/B"
#define F18_COLOR_POSEBAN_STATUS   "W/R+"
#define F18_COLOR_OKVIR            "W+/N"
#define F18_COLOR_NASLOV           "GR+/N"
#define F18_COLOR_TEKST            "GR+/N"
