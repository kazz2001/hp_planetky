#!/usr/bin/perl -T

#######################################################################
#                     Application Information                          #
########################################################################

# Application Name: BBS_ENTRANCE.CGI
# Application Authors: Gunther Birznieks and Eric Tachibana (Selena Sol)
# Version: 1.0
# Last Modified: 17NOV98
#    
# Copyright:
#    
#     You may use this code according to the terms specified in
#     the "Artistic License" included with this distribution.  The license
#     can be found in the "Documentation" subdirectory as a file named
#     README.LICENSE. If for some reason the license is not included, you
#     may also find it at www.extropia.com.
#
#     Though you are not obligated to do so, please let us know if you  
#     have successfully installed this application.  Not only do we
#     appreciate seeing the wonderful things you've done with it, but we
#     will then be able to contact you in the case of bug reports or
#     security announcements.  To register yourself, simply send an
#     email to register@extropia.com.
#    
#    Finally, if you have done some cool modifications to the scripts,
#    please consider submitting your code back to the public domain and
#    getting some community recognition by submitting your modifications
#    to the Extropia Cool Hacks page.  To do so, send email to
#    hacks@extropia.com
# 
# Description:
# 
#    Provide a front entrance to the bbs_forum.cgi script
#    to show some of its features.
# 
#    All this script does is print out an HTML form. It really does no
#    other significant processing at all.
#
#    SPECIAL NOTE: THIS IS NOT A NECESSARY SCRIPT TO RUN THE BBS. IT
#    MERELY EXISTS TO PROVIDE AN *EXAMPLE* OF DIFFERENT PARAMETERS THAT
#    CAN BE USED TO ENTER A BBS FORUM.
#
#    Read the Comments in the header of the bbs_forum.cgi script
#    with advice on how to call it directly from an HTML Document.
#
# Basic Usage:
#     
#    1. The file should have read and execute access but need not have
#       write access.
#    
# More Information
# 
# 
#    You will find more information in the Documentation sub-directory.
#    We recommend opening the index.html file with your web browser to
#    get a listing of supporting documentation files.

########################################################################
#                     Application Code                                 #
########################################################################

print "Content-type: text/html\n\n";

print qq!
<HTML>
<HEAD>
<TITLE>BBS Version 4.0 Sample Entrance</TITLE>
</HEAD>
<BODY BGCOLOR = "FFFFFF" TEXT = "000000">
<CENTER>
<H1>BBS Sample Entrance</H1>
<HR>
</CENTER>
<FORM ACTION="bbs_forum.cgi" METHOD=POST>

<TABLE BORDER = "1">
<TR>
<TH ALIGN = "left">Forum</TH>
<TD><SELECT NAME = "forum">
<OPTION VALUE = "open">Open Forum
</SELECT>
</TD>
</TR>
<TR>
<TH ALIGN = "left">
Display messages with what keywords?</TH>
<TD><INPUT TYPE = "text" NAME = "keywords"></TD>
</TR>
<TR>
<TH ALIGN = "left">
Exact Match for keyword search?</TH>
<TD><INPUT TYPE = "checkbox" NAME = "exact_match"></TD>
</TR><TR>
<TH ALIGN = "left">
Range of Dates Posted (First date in range to view 
messages i.e. 12/03/98)</TH>
<TD><INPUT TYPE = "text" NAME = "first_date"></TD>
</TR>
<TR>
<TH ALIGN = "left">
Range of Dates Posted (Last date in range to view 
messages i.e. 12/03/98)</TH>
<TD><INPUT TYPE = "text" NAME = "last_date"></TD>
</TR>
<TR>
<TH ALIGN = "left">
Range of Age of posts (earliest number of days old to 
view msgs)</TH>
<TD><INPUT TYPE = "text" NAME = "first_days_old"></TD>
</TR>
<TR>
<TH ALIGN = "left">
Range of Age of posts (latest number of days old to
view 
msgs)</TH>
<TD><INPUT TYPE = "text" NAME = "last_days_old"></TD>
</TR></TABLE><P>
<CENTER>
<INPUT TYPE = "submit" 
VALUE = "Enter the BBS with these parameters">
</CENTER>
<BLOCKQUOTE>
<STRONG>Instructions:</STRONG> All the fields that
appear above are option except for the forum field.
The forum is needed in order to determine which 
messages to view. Normally all messages in a forum
are displayed. However, entering values into the above
fields will narrow down the messages that are displayed.
<P>
Entering a keyword will display only messages with that
keyword. The keyword search can also be specified as an
exact match search.
<P>
You can also specify a range of dates to view the 
posts. In other words, you can specify to view only
the posts that were created between a certain range
of days.
<P>
In addition to the above date range search, you
can choose to narrow down the age of posts as 
a factor of days instead of an actual date range.
For example, if you wanted to view only posts 2 days
old and newer, then you would enter a "2" into the 
"earliest number of days to view messages" field.

</BLOCKQUOTE>
</BODY>
</HTML>!;
