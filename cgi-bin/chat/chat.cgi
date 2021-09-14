#!/usr/bin/perl -T

#######################################################################
#                     Application Information                          #
########################################################################

# Application Name: CHAT.CGI
# Application Authors: Gunther Birznieks and Eric Tachibana (Selena Sol)
# Version: 5.0
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
#    Provides a script for real-time chatting on A Web Page
#
# Special Notes: 
#
#    This script uses similar routines to the
#    authentication library.  The session file is used to
#    store last_read counter for the chat.
#     
# Basic Usage:
#     
#    1. Read the README.CHANGES, README.LICENSE, and README.SECURITY
#       files and follow any directions contained there
#     
#    2. Change the first line of each of the scripts so that they
#       reference your local copy of the Perl interpreter. (ie:
#       #!/usr/local/bin/perl) (Make sure that you are using Perl 5.0 or
#       higher.)
#
#    3. Set the read, write and access permissions for files in the    
#       application according to the instructions in the
#       README.INSTALLATION file.
#    
#    4. Define the global variables in calendar.setup.cgi according to the
#       instructions in the README.INSTALLATION file.
# 
#    5. Point your web browser at the script
#       (ie:http://www.yourdomain.com/cgi-bin/chat.cgi)
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
#                         CHAT.CGI
#
# This script was written by Gunther Birznieks (gunther@extropia.com)
# Date Created: 5-15-96
#
# 
#
############################################################

# Always set a path to the external libraries
$lib = ".";
require "$lib/cgi-lib.pl";
require "./chat-html.pl";

# Read the form variables in
&ReadParse;

# 
# We print the magic header.  HOWEVER, since 
# we are constantly forcing the user to reload
# the web page for new chat information, if there
# is currently a session going on, we need to
# send a no-cache message to the browser to tell
# it not to waste memory/disk space caching the
# multiple Chat Pages.
#
print "Content-type: text/html\n";

if ($in{'session'} ne "") {
    print "Pragma: no-cache\n\n";
} else {
    print "\n";
}

#
# The chat_ variables are initial form
# variables read in from the first screen
# where the user signs up for the chat mode
#
# $refresh_rate is > 0 if the user
# has a browser that supports auto 
# refreshing using the META Tag such as
# Netscape.
#
# How many old, is the amount of 
# old messages to display with the new
# messages.
#
# The above to variables are written to
# the session files.
#
$chat_username = $in{'chat_username'};
$chat_email = $in{'chat_email'};
$chat_http = $in{'chat_http'};
$refresh_rate = $in{'refresh_rate'};
$how_many_old = $in{'how_many_old'};

#
# Are we using frames? 
# $frames = "on" if we are using them
# 
# $fmsgs means the script was called
# from the frame with the messages in them
# 
# $fsubmit means the script was called
# from the frame with the submit chat 
# message form in it.
#
$frames = $in{'frames'};
$fmsgs = $in{'fmsgs'};
$fsubmit = $in{'fsubmit'};

# 
# $user_last_read is the last read
# chat message for the user in the chat
# room
#
$user_last_read = 0;

#
# $chat_room is the chat_room a person
# is in.
#
# $setup is the setup file to read.  If
# no setup is specified, then $setup will
# be set equal to "chat".
#
$chat_room = $in{'chat_room'};
$setup_file = $in{"setup"};

# We have to untaint the setup file variable
# So we filter it so that it needs to be word
# characters or dash characters.

if ($setup_file =~ /([\w-]+)/) {
    $setup_file = $1;
} else {
    $setup_file = "";
}


if ($setup_file eq "") {
    $setup_file = "chat";
}

require "./$setup_file.setup";

#
# Set up a default chat_script
# if we did not define one
#
if ($chat_script eq "") {
    $chat_script = "chat.cgi";
}

#
# The following are variables
# related to the various chat operations
#

$enter_chat = $in{'enter_chat'};
$refresh_chat = $in{'refresh_chat'};
$submit_message = $in{'submit_message'};
$logoff = $in{'logoff'};
$occupants = $in{'occupants'};

# 
# The following are needed for submitting
# a message
#

$chat_to_user = $in{'chat_to_user'};
$chat_message = $in{'chat_message'};

$session = $in{'session'};

#
# If there is no session id, we need to create one
#

$new_session = "no";
if ($session eq "") {
    if ($chat_username eq "") {
        if ($enter_chat eq "") {
            &PrintChatEntrance($setup,"");
        } else {
            &PrintChatEntrance($setup,
             "Hey! You did not " .
             "enter a username.");
        }
    exit;
    }
    $new_session = "yes";
    $session = &MakeSessionFile($chat_username, $chat_email,
        $chat_http, $refresh_rate, 
        $how_many_old, "0");
}

#
# If the user logs in correctly, we
# should be able to get the chat room info
# we need
# 

($chat_room_name, $chat_room_dir) =
  &GetChatRoomInfo($chat_room);

#
# We need to get the current session
# information including the current
# high message number.
# 

($user_name, $user_email, $user_http,
 $refresh_rate, $how_many_old, 
 $user_last_read, $high_message) = 
          &GetSessionInfo($session, $fsubmit, $frames);

#
# If we are announcing the entry of
# users in the chat room, we need to submit
# a message to that effect
#

if ($chat_announce_entry eq "on" &&
    $new_session eq "yes") {
    $submit_message = "on";
    $chat_to_user = "ALL";
    $chat_message = "Automatic Message: $user_name Joined Chat Room";
}

#
# If the logoff button was pressed, we generate
# an automatic message
#

if ($logoff ne "") {
    $submit_message = "on";
    $chat_to_user = "ALL";
    $chat_message = "Automatic Message: $user_name Logged Off";
}

#
# We use the current date and time
# in the program
#
($min, $hour, $day, $mon, $year) = 
    (localtime(time))[1,2,3,4,5];
$mon++;
if (length($min) < 2) {
    $min = "0" . $min;
}
$ampm = "AM";
$ampm = "PM" if ($hour > 11);
$hour = $hour - 12 if ($hour > 12);
$year += 1900;
$current_date_time = 
    "$mon/$day/$year $hour:$min $ampm";

# If we are entering a new message,
# we need to write it to a file
#
if ($submit_message ne "") {
    if ($chat_to_user eq "" ||
        $chat_to_user =~ /^all$/i ||
        $chat_to_user =~ /everyone/i) {
        $chat_to_user  = "ALL";
    }
  
    $high_number = &GetHighMessageNumber;
    $high_number++; 
    $high_number = sprintf("%6d",$high_number);
    $high_number =~ tr/ /0/;           
    open(MSGFILE, ">$chat_room_dir/$high_number.msg");
    print MSGFILE "$user_name\n";
    print MSGFILE "$user_email\n";
    print MSGFILE "$user_http\n";
    print MSGFILE "$chat_to_user\n";
    print MSGFILE "$current_date_time\n";
    print MSGFILE "$chat_message\n";
    close(MSGFILE);

# we need to get rid of old messages
    &PruneOldMessages($chat_room_dir);

#
# We need to be able to GetSessionInfo
# again since the state of the messages that
# are available have changed since the 
# user last read the information.
#
# How, last_read has not changed, so we
# keep track of it with a temporary 
# variable (old_last_read) and reset it
# afterwards.
#
    $old_last_read = $user_last_read;
    ($user_name, $user_email, $user_http,
     $refresh_rate, $how_many_old, 
     $user_last_read, $high_message) = 
	 &GetSessionInfo($session, $fsubmit, $frames);
    $user_last_read = $old_last_read;

}

# Clear the chat buffer
$chat_buffer = "";
#
# $chat_buffer will have the occupants list
# in it if the button selected was the
# view occupants button
#
if ($occupants ne "") {
    opendir(CHATDIR, "$chat_room_dir");
    @files = grep(/who$/,readdir(CHATDIR));
    closedir(CHATDIR);
    $chat_buffer .= "<H2>Occupants List</H2><P>";
    if (@files > 0) {
	foreach $whofile (@files) {
	    open (WHOFILE,"<$chat_room_dir/$whofile");
	    $wholine = <WHOFILE>;
	    @whofields = split(/\|/,$wholine);
	    close(WHOFILE);
	    if ($whofields[1] ne "") {
		$chat_buffer .= qq!<A HREF=MAILTO:! .  
		    qq!$whofields[1]>!;
	    }
	    $chat_buffer .= $whofields[0];
	    if ($whofields[1] ne "") {
		$chat_buffer .= "</A>";
	    }
	    $chat_buffer .= " last viewed msgs at ";
	    $chat_buffer .= $whofields[3];
	    if ($whofields[2] ne "") {
		$chat_buffer .= 
		    qq! (<A HREF="$whofields[2]">! . 
			     qq!Home Page</A>)!;
	    }
		$chat_buffer .= "<P>";
	}
    } else {
	$chat_buffer .= "No Occupants Found";
    } # End of no occupants
    $chat_buffer .= 
	"<P><H2>End of Occupants List</H2><P>";

} # End of occupants processing

#
# We do not want to read in a chat_buffer
# if we are only printing the submit
# chat message frame
# 

if ($fmsgs eq "on" || 
    ($frames ne  "on" && 
     $fsubmit ne "on")) {

#
# Now that we have session information
# we need to gather the message info
# from the chat_room_directory.
#


# We want to make sure the "WHO" file 
# for a user is written in order
# to keep track of who is in the room.
#

    if ($session =~ /(\w+)/) {
      $session = $1;
    } else {
      $session = "";
    }

$whofile = "$chat_room_dir/$session.who";
unlink($whofile);
open(WHOFILE, ">$whofile");
print WHOFILE 
    "$user_name|$user_email|$user_http|$current_date_time\n";
close (WHOFILE);
&RemoveOldWhoFiles;

#
# We add one to the user last read
# because we do not want to read the
# last read message.
# We subtract how many old messages
# we are allowed to read.

$msg_to_read = $user_last_read + 1;
$msg_to_read -= $how_many_old;
if ($msg_to_read < 1) {
    $msg_to_read = 1;
}
if ($high_message >= $msg_to_read) {
    for ($x = $high_message; $x >= $msg_to_read; $x--) {
        $x = sprintf("%6d",$x);
        $x =~ tr/ /0/;   
        if (-e "$chat_room_dir/$x.msg") {
            open(MSG,"<$chat_room_dir/$x.msg") ||
              &CgiDie("Could not open $x.msg");
        $msg_from_user = <MSG>;
	$msg_from_user = &HtmlFilter($msg_from_user);
        $msg_email = <MSG>;
	$msg_email = &HtmlFilter($msg_email);
        $msg_http = <MSG>;
        $msg_http = &HtmlFilter($msg_http);
        $msg_to_user = <MSG>;
        $msg_to_user = &HtmlFilter($msg_to_user);
        $msg_date_time = <MSG>;
        chop($msg_from_user);    
        chop($msg_email);
        chop($msg_http);
        chop($msg_to_user);    
        chop($msg_date_time);
        if ($msg_to_user eq "ALL" ||
            $msg_to_user =~ /^$user_name$/i ||
            $msg_from_user =~ /^$user_name$/i) {
        $chat_buffer .= "<TABLE>\n";
        $chat_buffer .= "<TR><TD>";
        $chat_buffer .= "From:</TD><TD>";
        if ($msg_email ne "") {
          $chat_buffer .= qq!<A HREF=MAILTO:! .  
                          qq!$msg_email>!;
        }
        $chat_buffer .= $msg_from_user;
        if ($msg_email ne "") {
          $chat_buffer .= "</A>";
        }

        if ($msg_http ne "") {
          $chat_buffer .= qq! (<A HREF="$msg_http">! . 
                          qq!Home Page</A>)!;
        }
        $chat_buffer .= "</TD>\n";
        $chat_buffer .= "\n<TD>";
        if ($x > $user_last_read) {
            $chat_buffer .= " (New Msg) "
        }
        $chat_buffer .= " at $msg_date_time</TD>";
        $chat_buffer .= "</TR>\n";
        if ($msg_to_user =~ /^$user_name$/i ||
            ($msg_from_user =~ /^$user_name$/i &&
             $msg_to_user ne "ALL")) {
        $chat_buffer .= "<TR><TD>";
        $chat_buffer .= "Private Msg To:" .
                        "</TD><TD>$msg_to_user</TD>" . 
                        "</TR>\n";
        }
        $chat_buffer .= "</TABLE>\n";
        $chat_buffer .= "<BLOCKQUOTE>\n";
        while(<MSG>) {
            $_ = &HtmlFilter($_);
            $chat_buffer .= "$_<BR>";
            }
            close(MSG);
            $chat_buffer .= "\n";
        }
        $chat_buffer .= "</BLOCKQUOTE>\n";
        } # End of IF msg is to all or just us
    }
}

} 
# End of IF we are not in the submit msg frame
#    or simply printing the main frameset
#    document

#
# If the user has logged off, we remove their
# who file so they do not show up in the 
# occupants list
#

if ($logoff ne "") {
    $whofile = "$chat_room_dir/$session.who";
    unlink($whofile);
}

# Print the chat screen.
&PrintChatScreen($chat_buffer, $refresh_rate, 
                 $session, $chat_room, $setup,
                 $frames, $fmsgs, $fsubmit);

#######################
#                     #
# END OF MAIN ROUTINE #
#                     #
#######################

############################################################
#
# subroutine: GetSessionInfo 
#   Usage:
#   ($session, $username, @extra_fields,
#    = &GetSessionInfo($session, "script name",
#    *in);
#
#   Parameters:
#     $session = session id.  Null if it is not defined yet
#     $fsubmit = we are printing the submit portion of
#        a chat frame so do not do new message processing
#     $frames = we are printing the main frameset HTML 
#        document so do not do new message processing
#
#   Output:
#     $session = session id
#     An array of fields consisting of:
#       $username, $email, $home page,
#       $refresh_rate, $old_message_count
#     $high_message = high message number
#
############################################################

sub GetSessionInfo {
local($session, $fsubmit,$frames) = @_;
local($session_file);
local($temp,@fields, @f);
local($high_number, $high_message);

$session =~ /(\w*)/;
$session = $1;

$session_file = "$session.dat";

#
# Open the session file
#
open (SESSIONFILE, "<$chat_session_dir/$session_file");
while (<SESSIONFILE>) {
$temp = $_;
} 
chop($temp);


@fields = split(/\|/, $temp);

close (SESSIONFILE);                  

#
# Get the highest message number 
#
$high_message = &GetHighMessageNumber;

# Keep track of old fields
@f = @fields;
# Update last read field
@fields[@fields - 1] = $high_message;
#
# We need to write the new last read variable out
# to the session file
#

if ($fsubmit ne "on" &&
    $frames ne "on") {
    open (SESSIONFILE, ">$chat_session_dir/$session_file");
    print SESSIONFILE join ("\|", @fields);
    print SESSIONFILE "\n";
    close (SESSIONFILE);
}
(@f, $high_message);

} # End of GetSessionInfo


############################################################
#
# subroutine: GetHighMessageNumber
#   Usage:
#     $high_message = &GetHighMessageNumber;
#
#  This routine returns the highest message number
#  for the chat room.
#
#   Output:
#     $high_message_number
#
############################################################

sub GetHighMessageNumber {
local($last_file, @files);

# Read in all the files and sort them
opendir(CHATDIR, "$chat_room_dir");
@files = sort(grep(/msg/, readdir(CHATDIR)));
closedir(CHATDIR);

# Return highest message or 0 if no files
if (@files > 0) {
    $last_file = $files[@files - 1];
} else {
    $last_file = "0000000";
}

# Return the first 6 characters of the filename
substr($last_file,0,6);

} # End of GetHighMessageNumber

############################################################
#
# subroutine: MakeSessionFile
#   Usage:
#   $session = &MakeSessionFile(@fields);
#
#  This routine makes a session file on the basis of the
#  fields that make up a user such as first name and last
#  name.
#
#  Parameters:
#   @fields = a list of fields that make up the user
#
#   Output:
#     $session = session id
#
############################################################
                                       
sub MakeSessionFile {
local(@fields) = @_;
local($session, $session_file);

#
# RemoveOldSessions
#
&RemoveOldSessions;

# Seed the random generator
srand($$|time);
$session = int(rand(60000));
# pack the time, process id, and random $session into a
# hex number which will make up the session id.
$session = unpack("H*", pack("Nnn", time, $$, $session));

$session_file = "$session.dat";

#
# Create the actual session file
# 
open (SESSIONFILE, ">$chat_session_dir/$session_file");      
print SESSIONFILE join ("\|", @fields);
print SESSIONFILE "\n";

close (SESSIONFILE);

$session;                                

} # End of MakeSessionFile


############################################################
#
# subroutine: RemoveOldSessions
#   Usage:
#     &RemoveOldSessions;
#
# This routine removes old session files based on the
# age determined by the defined variables 
# ($chat_session_length).                     
#
#  Parameters:
#    None.
#
#  Output:
#     None.
############################################################

sub RemoveOldSessions
{
local(@files, $file);
# Open up the session directory.
opendir(SESSIONDIR, "$chat_session_dir");
# read all entries except "." and ".."
@files = grep(!/^\.\.?$/,readdir(SESSIONDIR));
closedir(SESSIONDIR);                 
                         
# Go through each file
foreach $file (@files)
        {
# If it is older than session_length, delete it
# Note that the filename needs to be untainted before removing.
        if ($file =~ /([\w-.]+)/) {
            $file = $1;
        } else {
            $file = ".dat";
        }
        if (-M "$chat_session_dir/$file" > $chat_session_length)
                {
                unlink("$chat_session_dir/$file");
                }

        }
} # End of RemoveOldSessions
                                      
############################################################
#
# subroutine: RemoveOldWhoFiles
#   Usage:
#     &RemoveOldWhoFiles;
#
# This routine removes old who files based on the age
# determined by the defined variables
# ($chat_who_length)
#
#  Parameters:
#    None.
#
#  Output:
#     None.
############################################################

sub RemoveOldWhoFiles
{
local(@files, $file);
# Open up the chat_dir directory.
opendir(CHATDIR, "$chat_room_dir");
# read only "who" files
@files = grep(/who$/,readdir(CHATDIR));
closedir(CHATDIR);                 
                         
# Go through each file
foreach $file (@files)
        {
# If it is older than chat_who_length, delete it
# Note that the filename needs to be untainted before removing.
        if ($file =~ /([\w-.]+)/) {
            $file = $1;
        } else {
            $file = ".dat";
        }

        if (-M "$chat_room_dir/$file" > $chat_who_length)
                {
                unlink("$chat_room_dir/$file");
                }

        }
} # End of RemoveOldWhoFiles

############################################################
#
# subroutine: GetChatRoomInfo
#  Usage:
#    &GetChatRoomInfo($chat_room);
#
#   Parameters:
#     $chat_room = abbreviated chat room identifier
#
#   Output:
#     Returns an array of the chat room name and
#     chat room directory.
#
############################################################

sub GetChatRoomInfo {
   local($chat_room) = @_;           
   local($chat_room_name, $chat_room_dir, $x);
   local($chat_room_number, $error);

$chat_room_number = -1;

for ($x = 1; $x <= @chat_room_variable; $x++)
        {
        if ($chat_room_variable[$x - 1] eq $chat_room)
                {
                $chat_room_number = $x - 1;
                last;
                }
        } # End of FOR chat_room_variables

if ($chat_room_number > -1) {
    $chat_room_name = $chat_rooms[$chat_room_number];
    $chat_room_dir = $chat_room_directories[$chat_room_number];    
} else {
    $chat_room_name="";
    $chat_room_dir = "";
    $chat_room = "None Given" if ($chat_room eq "");
    $error =
        "<strong>Chat Room: '$chat_room' Not Found</strong>";
    &PrintChatError($error);
    die;
}
($chat_room_name, $chat_room_dir);

} # end of GetChatRoomInfo
                                   
############################################################
#
# subroutine: PruneOldMessages
#  Usage:
#    &PruneOldMessages($chat_room_dir);
#
#   Parameters:
#     $chat_room_dir = directory of chat room
#
#   Output:
#     Unlinks (deletes) messages
#     in the chat room directory based on age or sequence
#     number as defined in the setup file.
#
############################################################
                                                                        
sub PruneOldMessages {
    local($chat_room_dir) = @_;
    local($x, @files);
    local($prunefile);
#
# We prune on the basis of
#
# AGE IN DAYS:
# $prune_how_many_days
#
# AGE BY SEQUENCE NUMBER
# $prune_how_many_sequences
#
    opendir(CHATDIR, "$chat_room_dir");
    @files = sort(grep(/msg/, readdir(CHATDIR)));
    closedir(CHATDIR);

    for ($x = @files; $x >= 1; $x--) {
        $prunefile = "$chat_room_dir/$files[$x - 1]";
        # we need to untaint the filename to be pruned...
        if ($prunefile =~ /([\w-.]+[\w-.\/]+)/) {
            $prunefile = $1;
        } else {
            $prunefile = "";
        }
        # First we check the age in days
        if ((-M "$prunefile" > $prune_how_many_days) &&
            ($prune_how_many_days > 0)) {
            unlink("$prunefile");
            &RemoveElement(*files, $x - 1);
            next;
        }


        #
        # Check the sequence and delete if it is too old
        #

        if (($x <= (@files - $prune_how_many_sequences))
            && ($prune_how_many_sequences != 0)) {
            unlink("$prunefile");
            &RemoveElement(*files, $x - 1);
            next;
        }
    } # End of for all files

} # End of PruneOldMessages

############################################################
#
# subroutine: RemoveElement
#  Usage:
#    &RemoveElement;
#
#   Parameters:
#     *file_list = array of message numbers
#     $number = pointer into the array of the
#               element to remove
#
#   Output:
#     *file_list without the $number element.
#
############################################################

sub RemoveElement
{
local(*file_list, $number) = @_;

if ($number > @file_list)
        {
        die "Number was higher than " .
            "number of elements in file list";
        }
splice(@file_list,$number,1);

@file_list;

} # End of RemoveElement

############################################################
#
# subroutine: HtmlFilter
#  Usage:
#    $filtertext = &HtmlFilter($filterthis);
#
#   Parameters:
#    $filter = text to filter HTML in
#
#   Output:
#     Filtered string
#
############################################################

sub HtmlFilter
{
local($filter) = @_;
# 
# The following filters the HTML images
# out, if they are disallowed.  The code
# after this, filters out all HTML if it
# is disallowed.
#
if ($no_html_images eq "on")
{
    $filter =~ s/<(IMG\s*SRC.*)>/&LT;$1&GT;/ig;
} # End of parsing out no images

if ($no_html eq "on")
{
    $filter =~ s/<([^>]+)>/\&LT;$1&GT;/ig;
} # End of No html                                         

$filter;

} # End of HTML Filter
