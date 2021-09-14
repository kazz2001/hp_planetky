#######################################################################
#                     Application Information                          #
########################################################################

# Application Name: AUTH-EXTRA-HTML.PL
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
#    routines related to the authentication routines.
#
#    Main Procedures:
#    All the routines are ancillary to the auth-extra-lib.pl 
#    file.
#
# Special Notes: 
#
#    Nearly all the routines below accept some sort of parameter.  These
#    parameters are only for printing out extra information.  They are not
#    doing any significant processing.
#
# Basic Usage:
#     
#    1. This file is not really meant to be used on its own.  As we
#       mentioned above, it is a support file for auth-extra-lib.pl
#
#    2. The file should have read access but need not have write access
#       nor execute access.
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

############################################################
#
# subroutine: PrintLogonPage
#
#  This routine outputs the logon HTML page along with
#  a bad logon message if one exists.  Hidden form tags
#  are generated automatically if we are passing previous
#  form data from the main script.
#
############################################################

sub PrintLogonPage {
    local($bad_logon_message, $main_script, *in) = @_;
    local($form_tags);
    local($register_tag);
    local($search_tag);

    if (length($auth_logon_title) < 1) {
        $auth_logon_title = "Submit Logon";
    }

    if (length($auth_logon_header) < 1) {
        $auth_logon_header = "Enter Your Logon Information";
    }

    $register_tag = "";
    $search_tag = "";

    if ($auth_allow_register eq "on") {
	$register_tag = qq!
<input type=submit name=auth_register_screen_op 
value="Register For An Account"><p>!;
}

    if ($auth_allow_search eq "on") {
	$search_tag = qq!
<input type=submit name=auth_search_screen_op 
value="Search For Old Account"><p>!;
    } 
   $form_tags = &PrintCurrentFormVars(*in);

    print qq!
    <HTML>
    <HEAD>
    <TITLE>$auth_logon_title</TITLE>
    </HEAD>
    <BODY>
    <CENTER>
    <H1>$auth_logon_header</h1>
    <hr>
    $bad_logon_message
    <FORM METHOD = "POST" ACTION = "$main_script">
    $form_tags
    <TABLE>
    <TR>
    <TH>Username</TH>
    <TD><INPUT TYPE=TEXT NAME=auth_user_name></td>
    </TR>
    <TR>
    <th>Password</th>
    <td><input type=password name=auth_password></td></tr>
    </TABLE><p>
    <input type=submit name=auth_logon_op 
           value="Logon To The System"><p>
    $register_tag
    $search_tag
    <hr>
    </center>
    </form>
    </body>
    </HTML>!;
} # End of PrintLogonPage

############################################################
#
# subroutine: PrintSearchPage
#
#  This routine outputs the Search HTML page if one exists.  
#  Hidden form tags are generated automatically if we are 
#  passing previous form data from the main script.
#
############################################################

sub PrintSearchPage {
local($main_script,*in) = @_;
    local($form_tags);
    $form_tags = &PrintCurrentFormVars(*in);
    print qq!
<HTML>
<HEAD>
<TITLE>Search For An Account</TITLE>
</HEAD>
<BODY>
<CENTER>
<H1>Search For Matching Username</h1>
<hr>
<h2>Enter Your Email Address To Search For A Matching Username</h2>
<FORM METHOD = "POST" ACTION = "$main_script">
$form_tags
<TABLE>
<TR>
<TH>Email</TH>
<TD><INPUT TYPE = "TEXT" NAME = "auth_email"></TD>
</TR>
</TABLE>
<P>
<input type=submit name=auth_search_op value="Submit Search">
<input type=submit name=auth_logon_screen_op value="Return to Logon Screen">
<P>
</CENTER>
</FORM>
</BODY>
</HTML>!;

} # End of PrintSearchPage

############################################################
#
# subroutine: HTMLPrintSearchResults
#
#   This routine outputs the results of the search for 
#   usernames using an email address
#
############################################################

sub HTMLPrintSearchResults {
    local($main_script, $form_tags, $user_list) =
	@_;
	print qq!
<HTML>
<HEAD>
<TITLE>User Found</TITLE>
</HEAD>
<BODY>
<CENTER>
<H1>User Was Found In The Search</h1>
<hr>
<h2>List Of Users</h2>
<strong>$user_list</strong>
<FORM METHOD=POST ACTION=$main_script>
$form_tags
<input type=submit name=auth_logon_screen_op
value="Return to Logon Screen">
<hr>
</center>
</form>
</body>
</HTML>!;

} # End of HTMLPrintSearchResults


############################################################
#
# subroutine: HTMLPrintNoSearchResults
#
#   This routine prints the HTML related to not having
#   found any results from the search on email address.
#
############################################################

sub HTMLPrintNoSearchResults {
    local($main_script, $form_tags) = @_;
	print qq!
<HTML>
<HEAD>
<TITLE>No Users Found</TITLE>
</HEAD>
<BODY>
<CENTER>
<H1>Sorry, No Users Found</h1>
<hr>
<h2>Sorry, No users were found that matched your email address</h2>
<FORM METHOD=POST ACTION=$main_script>
$form_tags
<input type=submit name=auth_logon_screen_op
value="Return to Logon Screen">
<hr>
</center>
</form>
</body>
</HTML>!;

} # End HTMLPrintNoSearchResults


############################################################
#
# subroutine: PrintRegisterPage
#
#  This routine outputs the Register HTML page.  Hidden form 
#  tags are generated automatically if we are passing previous
#  form data from the main script.
#
############################################################

sub PrintRegisterPage {
local($main_script,*in) = @_;
local($form_tags);
local($more_form_input,$password_input, $x);
    $form_tags = &PrintCurrentFormVars(*in);
local ($password_message);

#
# We also check for the extra fields and output HTML
# asking for input on the extra fields.
#
$more_form_input = "";
for ($x = 0; $x <= @auth_extra_fields - 1; $x++) {
    $more_form_input .= qq!
<TR><TH>$auth_extra_desc[$x]</TH>
<TD><INPUT TYPE=TEXT NAME=$auth_extra_fields[$x]></td></tr>!;
}
$password_input = "";
if ($auth_generate_password ne "on") {
    $password_input = qq!
<tr><th>Password</th>
<td><input type=password name=auth_password1></td></tr>
<tr><th>Password Again</th>
<td><input type=password name=auth_password2></td></tr>!;
} 
$password_message = "";
if ($auth_generate_password eq "on") {
$password_message = qq!
Your password will be automatically generated and sent
to you via your e-mail address.!;
} 
    print qq!
<HTML>
<HEAD>
<TITLE>Register For An Account</TITLE>
</HEAD>
<BODY>
<CENTER>
<H1>Enter The Registration Information</h1>
<hr>
<FORM METHOD=POST ACTION=$main_script>
$form_tags
<TABLE>
<tr><th>User Name</th>
<td><input type=Username name=auth_user_name></td></tr>
$password_input
$more_form_input
</TABLE>
<p>
<input type=submit name=auth_register_op value="Submit Information">
<input type=submit name=auth_logon_screen_op value="Return to Logon Screen">
<P>
$password_message
</center>
</form>
</body>
</HTML>!;
} # End of PrintRegisterPage

############################################################
#
# subroutine: HTMLPrintRegisterSuccess
#
#  This routine prints the HTML for a successful user
#  registration.
#
############################################################

sub HTMLPrintRegisterSuccess {
    local($main_script, $form_tags) = 
	@_;
    print qq!
<HTML>
<HEAD>
<TITLE>Registration Added</TITLE>
</HEAD>
<BODY>
<CENTER>
<H2>You Have been added to the user database</h2>
</center>
<hr>
<FORM METHOD=POST ACTION=$main_script>
$form_tags
<BLOCKQUOTE>
    $auth_register_message
</Blockquote>
<center>
<input type=submit name=auth_logon_screen_op value="Return to Logon Screen")
</center>
</form>
</body>
</HTML>!;
} # End of RegisterSuccess


############################################################
#
# subroutine: HTMLPrintRegisterFoundDuplicate
#
#  This routine prints the HTML for a failed user
#  registration because of finding a duplicate username
#
############################################################


sub HTMLPrintRegisterFoundDuplicate {
    local($main_script, $form_tags) = 
	@_;
print qq!
<HTML>
<HEAD>
<TITLE>Problem with Registration</TITLE>
</HEAD>
<BODY>
<CENTER>
<H1>Problem with Registration</h1>
</center>
<hr>
<FORM METHOD=POST ACTION=$main_script>
$form_tags
<BLOCKQUOTE>
Sorry, your username is already in the database
</Blockquote>
<center>
<input type=submit name=auth_logon_screen_op value="Return to Logon Screen")
</center>
</form>
</body>
</HTML>!;
} # End of HTMLPrintRegisterFoundDuplicate

############################################################
#
# subroutine: HTMLPrintRegisterNoPasswordMatch
#
#  This routine prints the HTML for a failed user
#  registration because the two passwords did not match
#
############################################################

sub HTMLPrintRegisterNoPasswordMatch {
    local($main_script, $form_tags) = 
	@_;

    print qq!
<HTML>
<HEAD>
<TITLE>Problem with Registration</TITLE>
</HEAD>
<BODY>
<CENTER>
<H1>Problem with Registration</h1>
</center>
<hr>
<FORM METHOD=POST ACTION=$main_script>
$form_tags
<BLOCKQUOTE>
Sorry, the two passwords you typed in did not match.
</Blockquote>
<center>
<input type=submit name=auth_logon_screen_op value="Return to Logon Screen")
</center>
</form>
</body>
</HTML>!;
} # End of HTMLPrintRegisterNoPasswordMatch

############################################################
#
# subroutine: HTMLPrintRegisterFoundDuplicate
#
#  This routine prints the HTML for a failed user
#  registration because of finding a missing value or
#  a value that has a PIPE in it.
#
############################################################

sub HTMLPrintRegisterNoValidValues {
    local ($main_script, $form_tags) =
	@_;
    print qq!
<HTML>
<HEAD>
<TITLE>Problem with Registration</TITLE>
</HEAD>
<BODY>
<CENTER>
<H1>Problem with Registration</h1>
</center>
<hr>
<FORM METHOD=POST ACTION=$main_script>
$form_tags
<BLOCKQUOTE>
Sorry, you need to enter a valid value for every field
</Blockquote>
<center>
<input type=submit name=auth_logon_screen_op value="Return to Logon Screen")
</center>
</form>
</body>
</HTML>!; 
} # End of HTMLPrintRegisterNoValidValues

1;

