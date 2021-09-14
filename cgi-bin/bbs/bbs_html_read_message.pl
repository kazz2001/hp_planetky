###########################################################
#                   BBS_HTML_READ_MESSAGE.PL
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
#   Print out the HTML for the Read Message Screen
# 
############################################################
 
# Hidden fields need to get passed from screen to screen

$print_hidden_fields = &HiddenFields;

print qq!

<HTML><HEAD>
<TITLE>Reading Messages</TITLE>
</HEAD>
<BODY BGCOLOR = "FFFFFF" TEXT = "000000">

<TABLE BORDER=0>
<TR>
<TH align=left>Name:</TH>
<TD>$poster_firstname $poster_lastname</TD>
</TR>
<TR>
<TH align=left>E-Mail:</TH>
<TD><A HREF="mailto:$poster_email">$poster_email</A></TD>
</TR>
<TR>
<TH align=left>Date/Time:</TH>
<TD>$post_date_time</TD>
</TR>
<TR>
<TH align=left>Subject:</TH>
<TD>$post_subject</TD>
</TR>
</TABLE>

<B>Body:</B>
<BLOCKQUOTE>
$post_message
</BLOCKQUOTE>
<FORM METHOD=POST ACTION="$bbs_script">
<B>Replies:</B>
$print_hidden_fields
<INPUT TYPE=HIDDEN NAME=post_subject VALUE="$post_subject">
<INPUT TYPE=HIDDEN NAME=forum VALUE="$forum">
<INPUT TYPE=HIDDEN NAME=reply_to_message VALUE="$message">
<BLOCKQUOTE>
$post_replies
</BLOCKQUOTE>
$post_attach_html

<CENTER><P>
<INPUT TYPE=IMAGE NAME=reply_op SRC="$bbs_buttons/post_a_reply.gif"
BORDER="0">
<INPUT TYPE=IMAGE NAME=post_op SRC="$bbs_buttons/post.gif" 
BORDER="0">
<INPUT TYPE=IMAGE NAME=toplevel_op SRC="$bbs_buttons/message_archive_top.gif"
BORDER="0">
</CENTER>
</FORM>
</BODY></HTML>!;
1;
