#######################################################################
#                     Application Information                          #
########################################################################

# Application Name: AUTH-LIB-FAIL-HTML.PL
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
#    This script contains all the cosmetic HTML output
#    routines related to a general program failure in the
#    authentication scripts
#
# Main Procedures:
#
#   Only one procedure -- an output of HTML complaining of
#   a problem in accessing information or files.
#
# Basic Usage:
#     
#    1. This file is not really meant to be used on its own.  As we
#       mentioned above, it is a support file for authentication   
#    
#    2. The file should have read access but need not have write access 
#       nor execute access.
#    
# More Information
#  
#    You will find more information in the Documentation sub-directory.
#    We recommend opening the index.html file with your web browser to
#    get a listing of supporting documentation files.

########################################################################
#                     Application Code                                 #
########################################################################

print qq!
<HTML>
<HEAD>
<TITLE>Error Occurred</TITLE>
</HEAD>
<BODY>
<CENTER>
<BLOCKQUOTE>
Sorry, there appears to be a problem accessing a session file.
</BLOCKQUOTE>
</CENTER>
</BODY>
</HTML>!;

1;
