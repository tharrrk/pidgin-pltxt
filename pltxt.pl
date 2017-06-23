#
# Plaintext-only chat messages plugin for Pidgin
#   Tharrrk (tharrrk@tharrrk.net)
#   2017-Jun-23
#
#   Based on Base64 plugin by
#   Chetan Vaity (chetanv@gmail.com)
#   22 June 2008
#

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111-1301  USA


use Purple;
use HTML::Strip;

%PLUGIN_INFO = (
    perl_api_version => 2,
    name => "Plaintext-only chat messages",
    version => "0.5",
    summary => "Plaintext-only chat messages",
    description => "Plaintext-only chat messages",
    author => "Tharrrk",
    url => "https://github.com/tharrrk/pidgin-pltxt",

    load => "plugin_load",
    unload => "plugin_unload",
    prefs_info => "prefs_info_cb"
);

sub plugin_init {
    return %PLUGIN_INFO;
}

sub plugin_load {
    $plugin = shift;

    Purple::Debug::info("pltxt", "plugin_load() - init\n");

    # Preferences
    Purple::Prefs::add_none("/plugins/core/pltxt");
    Purple::Prefs::add_string("/plugins/core/pltxt/account", "None");

    # A pointer to the handle to which the signal belongs
    $convs_handle = Purple::Conversations::get_handle();

    # Connect the perl sub 'sending_im_msg_cb' to the event 'sending-im-msg'
    Purple::Signal::connect($convs_handle, "sending-im-msg", $plugin,
                            \&sending_im_msg_cb, "xxx");

    Purple::Debug::info("pltxt", "plugin_load() - PLTXT plugin loaded\n");
}

sub plugin_unload {
    my $plugin = shift;
    Purple::Debug::info("pltxt", "plugin_unload() - PLTXT plugin unloaded.\n");
}

sub sending_im_msg_cb {
    my ($account, $who, $msg) = @_;
    $accountname = $account->get_username();
    $pltxtaccount = Purple::Prefs::get_string("/plugins/core/pltxt/account");
    if ($accountname eq $pltxtaccount) { 
        my $hs = HTML::Strip->new( emit_spaces => 0, decode_entities => 0 );
        $msg =~ s/<br[ \t]*[\/]?[ \t]*>/\r\n/gi ; # Deal with line breaks first, change to windows-style CRLF to support some of clients
        $_[2] = $hs->parse( $msg ); # Strip off the rest of html tags
        $hs->eof;
    }
    Purple::Debug::info("pltxt", "accountname=". $accountname . "who=". $who . ", msg_before='" . $msg . "', msg_after='" . $_[2] . "'\n");
}

sub prefs_info_cb {
    # Get all accounts to show in the drop-down menu
    @accounts = Purple::Accounts::get_all();

    $frame = Purple::PluginPref::Frame->new();

    $acpref = Purple::PluginPref->new_with_name_and_label(
        "/plugins/core/pltxt/account", "Plaintext-only messages for account: ");
    $acpref->set_type(1); # To indicate a drop-down choice
    @acnames = [];
    for ($i=0; $i<=$#accounts; $i++) {
        Purple::Debug::info("pltxt", "accountname=". $accounts[$i]->get_username(). "\n");
        $acnames[$i] = $accounts[$i]->get_username();
    }

    for ($i=0; $i<=$#acnames; $i++) {
        $acpref->add_choice($acnames[$i], $acnames[$i]);
    }

    $acpref->add_choice("None", "None"); # The default choice

    $frame->add($acpref);

    return $frame;
}
