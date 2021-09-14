###########################################################
#                   BBS_HTML_FORUM.PL
#
# This script was written by Gunther Birznieks.
# Date Created: 4-18-96
#
# Copyright:
#    
#     You may use this code according to the terms specified in
#     the "Artistic License" included with this distribution.  The license
#     can be found in the "Documentation" subdirectory as a file named
#     README.LICENSE. If for some reason the license is not included, you
#     may also find it at www.extropia.com.
#
# Purpose:
#   Print out the HTML for the Forum/Threaded 
#   Message List Screen
# 
############################################################
 
# Hidden fields need to get passed from screen to screen

$print_hidden_fields = &HiddenFields;

print qq!
<HTML><HEAD>
<TITLE>The Message Board</TITLE>
</HEAD>
<BODY BGCOLOR = "FFFFFF" TEXT = "000000">
<CENTER>
<H2>Welcome To The $forum_name Message Board</H2>
</CENTER>
$create_msg_error
<HR>
<B>Messages:</B>
<BR>
$message_html
<CENTER>
<P>
<FORM ACTION=$bbs_script METHOD=POST>
<INPUT TYPE=HIDDEN NAME=forum VALUE=$forum>
$print_hidden_fields

<HR>
<P>
<INPUT TYPE=IMAGE NAME=post_op SRC="$bbs_buttons/post.gif" BORDER=0>
</CENTER>
</FORM>
</BODY></HTML>!;

1;
