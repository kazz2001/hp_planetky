###########################################################
#                   BBS_HTML_ERROR.PL
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
#   Print out the HTML for the ERROR Screen
# 
############################################################
 

print qq!
<HTML>
<HEAD>
<TITLE>Problem In BBS Occurred</TITLE>
</HEAD>
<BODY>
<h1>Problem In BBS Occurred</h1>
<HR>
<blockquote>
$error
</blockquote>
<HR>
</BODY></HTML>!;
1;

