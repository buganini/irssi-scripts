use strict;
use Storable;

use vars qw($VERSION %IRSSI);
$VERSION = '2011112300';
%IRSSI = (
	authors		=> 'Buganini',
	contact		=> 'buganini@gmail.com',
	name		=> 'offline',
	description	=> 'offline msg',
	license		=> 'BSD',
	url		=> 'http://github.com/buganini/irssi-scripts',
);

my($file) = Irssi::get_irssi_dir."/offline-messages";
my %db = ();
if (-e $file){
	my $hashref = retrieve($file);
	%db = %$hashref;
}

sub try_delivery {
	my($serv, @nicks) = @_;
	my $net = $serv->{chatnet} || $serv->{tag};
	for my $nick (@nicks){
		while(defined($db{$net}{$nick}) && @{$db{$net}{$nick}}){
			my $msg = shift @{$db{$net}{$nick}};
			$serv->command("msg -$net $nick $msg");
			Irssi::print("send offline message to ${net}::$nick: $msg");
		}
	}
	store \%db, $file;
}

sub sig_massjoin {
	my($chan, $nicks) = @_;
	try_delivery($chan->{server}, map{ $_->{nick} } @$nicks);
}

sub sig_nick_mode_changed {
	my($chan, $nick) = @_;
	if ($chan->{synced} && $chan->{server}{nick} eq $nick->{nick}) {
		try_delivery($chan->{server}, $nick->{nick});
	}
}

sub sig_channel_sync {
	my($chan) = @_;
	try_delivery($chan->{server}, map{ $_->{nick} } $chan->nicks);
}

sub cmd_olmsg {
	my($param,$serv,$chan) = @_;
	my($nick, $msg) = split(/ +/, $param, 2);
	my($net);
	if($nick =~ /^-/){
		$net = substr($nick, 1);
		($nick, $msg) = split(/ +/, $msg, 2);
	}else{
		$net = $serv->{chatnet} || $serv->{tag};
	}
	push(@{$db{$net}{$nick}}, $msg);
	Irssi::print("save offline message to ${net}::$nick: $msg");
	my @chans = Irssi::channels;
	for my $chan (@chans){
		my $n = $chan->{server}->{chatnet} || $chan->{server}->{tag};
		if($n eq $net){
			try_delivery($chan->{server}, map{ $_->{nick} } $chan->nicks);
		}
	}
}

Irssi::signal_add_last("massjoin", "sig_massjoin");
Irssi::signal_add_last("nick mode changed", "sig_nick_mode_changed");
Irssi::signal_add_last("channel sync", "sig_channel_sync");
Irssi::command_bind('olmsg', 'cmd_olmsg');
