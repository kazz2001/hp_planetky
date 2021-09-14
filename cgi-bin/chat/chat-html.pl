#######################################################################
#                     Application Information                          #
########################################################################

# Application Name: CHAT-HTML.PL
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
#    Prints out the various HTML screens for the Chat
#    Script
#
# Basic Usage:
#     
#    1. This is essentially a support file.  Just set it to be readable
#       by the web server and modify any HTML you wish.
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
# subroutine: PrintChatEntrance
#
# This routine prints the first chat screen people see.
# It includes an error message when it is printed again
# if not all the required information is entered 
# correctly.
#
############################################################


sub PrintChatEntrance {
local($setup,$chat_error) = @_;
local ($chat_room_options);

$setup = "" if ($setup eq "chat");

# 
# The chat room options
# are derived from the 
# available chat rooms in the
# array of chat rooms in the
# chat.setup script
$chat_room_options = "";
for (0..@chat_rooms - 1) {
$chat_room_options .=
  "<OPTION VALUE=$chat_room_variable[$_]>" .
  "$chat_rooms[$_]\n";
}

if ($chat_room_options eq "") {
    $chat_room_options = 
        "<OPTION>Chat Room Not Set Up\n";
}

print qq!
<HTML>
<HEAD>
<TITLE>Chat Page</TITLE>
</HEAD>
<BODY>
<H1>Welcome To The Chat Page</H1>
<H2>$chat_error</H2>
<FORM METHOD=POST ACTION=$chat_script>
<INPUT TYPE=HIDDEN NAME=setup VALUE=$setup>
<HR>
<STRONG>Enter Information Below:</STRONG><p>

<TABLE BORDER=1>
<TR>
<TD ALIGHT=RIGHT>User Name:</TD>
<TD><INPUT NAME=chat_username></TD>
</TR>
<TR>
<TD ALIGHT=RIGHT>Your Email Address(*):</TD>
<TD><INPUT NAME=chat_email></TD>
</TR>
<TR>
<TD ALIGHT=RIGHT>Your Home Page (*):</TD>
<TD><INPUT NAME=chat_http></TD>
</TR>
<TR>
<TD ALIGHT=RIGHT>How Many Old Messages To Display:</TD>
<TD><INPUT NAME=how_many_old VALUE="10"></TD>
</TR>
<TR>
<TD ALIGHT=RIGHT>Automatic Refresh Rate (Seconds):</TD>
<TD><INPUT NAME=refresh_rate VALUE="0"></TD>
</TR>
<TR>
<TD ALIGHT=RIGHT>Use Frames?:</TD>
<TD><INPUT TYPE=checkbox NAME=frames></TD>
</TR>
<TR>
<TD ALIGHT=RIGHT>Chat Room</TD>
<TD><SELECT NAME=chat_room>
$chat_room_options
</SELECT>
</TD>
</TR>
</TABLE>
<P>
<INPUT TYPE=SUBMIT NAME=enter_chat
VALUE="Enter The Chat Room">

<P>
<STRONG>Special Notes:</STRONG><P>
(*) Indicates Optional Information<P>
Choose <STRONG>how many old messages</STRONG> to display if you want to
display some older messages along with the new ones whenever you refresh
the chat message list.
<P>
Additionally, if you use Netscape 2.0 or another browser that supports
the HTML <STRONG>Refresh</STRONG> tag, then you can state the number of
seconds you want to pass before the chat message list is automatically
refreshed for you. This lets you display new messages automatically.
<P>
If you are using Netscape 2.0 or another browser that supports
<STRONG>Frames</STRONG>, it is highly suggested that you turn frames ON.
This allows the messages to be displayed in one frame, while you submit
your own chat messages in another one on the same screen.

 <HR> 
</FORM>
</BODY>
</HTML>!;

} # end of PrintChatEntrance


############################################################
#
# subroutine: PrintChatScreen
#
# Prints the main chat screen.  This includes the form
# for chatting.
#
# Parameters:
#   $chat_buffer = all the chat messages
#   $refresh-rate = refresh rate for use with the META
#                   operator
#   $session = session id
#   $chat_room = chat room name
#   $setup = setup file.
#   $frames = "on" for Printing Main Frame HTML
#   $fmsgs = "on" for printing Messages Frame
#   $fsubmit = "on" for printing chat Messages Frame
#
############################################################

sub PrintChatScreen {
local($chat_buffer, 
      $refresh_rate, $session,
      $chat_room, $setup,
      $frames, $fmsgs, $fsubmit) = @_;

local($chat_message_header, $more_url,
      $more_hidden, $chat_refresh);

$setup = "" if ($setup eq "chat");

#
# $more_url contains setup information
# that needs to get passed from screen to
# screen and is used with the META Tag.
#
# $more_hidden is the same thing but is
# used as a hidden variable in the form
# posted below.
#
$more_url = "";
$more_hidden = "";
if ($setup ne "") {
    $more_url = "&setup=$setup";
    $more_hidden = "<INPUT TYPE=HIDDEN NAME=setup " .
                   "VALUE=$setup>";
}
$more_url = "session=$session" . 
               "&chat_room=$chat_room" .
		$more_url;


# When we generate a meta tag, we need to
# make sure the hidden variables get passed to
# the URL since we can not post using the
# META operator
#
if ($refresh_rate > 0) {
    $chat_refresh =
      qq!<META HTTP-EQUIV="Refresh" ! .
      qq!CONTENT="$refresh_rate; ! .
      qq!URL=$chat_script?$more_url!;

    if ($frames ne "on" && $fmsgs eq "on") {
        $chat_refresh .= "&fmsgs=on";
    }
    $chat_refresh .= qq!">!;
} else {
    $chat_refresh = "";
}


if ($frames ne "on" && $fsubmit eq "on") {
    $chat_refresh = "";
}

if ($frames eq "on") {
    print qq!
<HTML>
<HEAD>
<TITLE>$chat_room_name</TITLE>
</HEAD>

<FRAMESET ROWS="*,210">
   <FRAME NAME="_fmsgs" SRC=$chat_script?fmsgs=on&$more_url>
   <FRAME NAME="_fsubmit" SRC=$chat_script?fsubmit=on&$more_url>
</FRAMESET>
</HTML>!;
}

if ($frames ne "on") {
print qq!
<HTML>
$chat_refresh
<HEAD>
<TITLE>$chat_room_name</TITLE>
</HEAD>
<BODY>!;
}

if ($fsubmit eq "on") {

$form_header = qq!
<FORM METHOD=POST ACTION=$chat_script TARGET="_fmsgs">!;
} else {
$form_header = qq!
<FORM METHOD=POST ACTION=$chat_script>!;
}



if ($fsubmit eq "on") {
    $form_header .= qq!<INPUT TYPE=HIDDEN NAME=fmsgs! .
                    qq! VALUE=on>!;
}

if ($fmsgs eq "on") {
    $form_header = "";
}

$chat_message_header = "";
if ($fmsgs ne "on") {
    $chat_message_header = "<H2>Chat Messages:</H2>";
}

if (($frames ne "on" &&
     $fsubmit ne "on") ||
    $fmsgs eq "on") {
    print qq!
<H1>Welcome To $chat_room_name Chat</H1>!;
}

#
# SUBMIT CHAT FORM
#

    if ($fsubmit eq "on" ||
        ($frames ne "on" && $fmsgs ne "on")) {
	print qq!
$form_header

<INPUT TYPE=HIDDEN NAME=session VALUE=$session>
<INPUT TYPE=HIDDEN NAME=chat_room VALUE=$chat_room>
$more_hidden
<STRONG>Enter Chat Message Below:</STRONG>
<BR>
<TEXTAREA NAME=chat_message
ROWS=3 COLS=40 WRAP=physical></TEXTAREA>
<BR>
Which User To Send To:
<INPUT TYPE=TEXT NAME=chat_to_user
VALUE="ALL">
<BR>
<INPUT TYPE=SUBMIT NAME=submit_message
VALUE="Send Message">
<INPUT TYPE=SUBMIT NAME=refresh_chat
VALUE="New Messages">
<INPUT TYPE=SUBMIT NAME=logoff
VALUE="Log Off">
<INPUT TYPE=SUBMIT NAME=occupants
VALUE="View Occupants">
<INPUT TYPE=RESET
VALUE="Clear Form">
</FORM>!;

if ($fsubmit ne "on") {
    print "<HR>\n";
}
}


if (($frames ne "on" &&
     $fsubmit ne "on") ||
    $fmsgs eq "on") {
    print qq!
$chat_message_header
$chat_buffer!;

if ($fmsgs ne "on") {
    print "<HR>\n";
}
}


    if ($frames ne "on") {
	print qq!
</BODY>
</HTML>!;
}


} # end of PrintChatScreen

############################################################
#
# subroutine: PrintChatError
#
# This routine outputs an error page if something
# happened incorrectly in the chat room.
#
############################################################

sub PrintChatError {
local($error) = @_;

print qq!
<HTML><HEAD>
<TITLE>Problem In Chat Occurred</TITLE>
</HEAD>
<BODY>
<h1>Problem In Chat Occurred</h1>
<HR>
<blockquote>
$error
</blockquote>
<HR>
</BODY></HTML>!;

} # End of PrintChatError

# We also have to end the required library
# with a function call of 1 
1;

