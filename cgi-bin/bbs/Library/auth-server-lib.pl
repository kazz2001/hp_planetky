#######################################################################
#                     Application Information                          #
########################################################################

# Application Name: AUTH-SERVER-LIB.PL
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
#    This script would contain the routines particular
#    to your server if you were using server based authentication
# 
#    We put this file out here as an example stub file, it really
#    does not do anything valid since if you are using this
#    library for an Intranet there are a variety of business rules
#    and databases you may want to integrate this with.
# 
# Main Procedures:
#
#    One procedure to process server authentication
#    $username has been previously set to REMOTE_USER
#    in auth-extra-lib.pl.
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

# Note: $username is already set previously.
#
#
# Here you would call a routine to fill in the other
# variables, presumably from a previous database such
# as an address book in Sybase or Oracle.
# 
# Since this is a generic script, I am simply providing
# some base logic to show that it works.
#
$firstname = "Gunther";
$lastname = "Birznieks";
$email = "you\@yourdomain.com";
$group = "$auth_default_group";

$session = 
	&MakeSessionFile( ($username, $group, $firstname, 
	$lastname,$email));

1;

