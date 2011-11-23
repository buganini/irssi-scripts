use strict;

use vars qw($VERSION %IRSSI);
$VERSION = '2011112300';
%IRSSI = (
	authors		=> 'Buganini',
	contact		=> 'buganini@gmail.com',
	name		=> 'offline',
	description	=> 'offline',
	license		=> 'BSD',
	url		=> 'http://github.com/buganini/irssi-scripts',
);

my %db=();

sub try_delivery {
	my($serv, @nicks) = @_;
	my $net=$serv->{chatnet} || $serv->{tag};
	for my $nick (@nicks){
		$nick=$nick->{nick};
		while(defined($db{$net}{$nick}) && @{$db{$net}{$nick}}){
			my $msg=shift @{$db{$net}{$nick}};
			$serv->command("msg -$net $nick $msg");
			Irssi::print("send offline message to ${net}::$nick: $msg");
		}
	}
};

sub sig_massjoin {
	my($chan, $nicks) = @_;
	Irssi::print('massjoin');
	try_delivery($chan->{server}, @$nicks);
}

sub sig_nick_mode_changed {
	my($chan, $nick) = @_;
	Irssi::print('nick mode changed');
	if ($chan->{synced} && $chan->{server}{nick} eq $nick->{nick}) {
		try_delivery($chan->{server}, $chan->nicks);
	}
}

sub sig_channel_sync {
	my($chan) = @_;
	Irssi::print('channel sync');
	try_delivery($chan->{server}, $chan->nicks);
}

sub cmd_olmsg {
	my($param,$serv,$chan) = @_;
	my($nick, $msg) = split(/ +/, $param, 2);
	my $net=$serv->{chatnet} || $serv->{tag};
	push(@{$db{$net}{$nick}}, $msg);
	Irssi::print("save offline message to ${net}::$nick: $msg");
	if(defined($chan)){
		try_delivery($serv, $chan->nicks);
	}
}

Irssi::signal_add_last("massjoin", "sig_massjoin");
Irssi::signal_add_last("nick mode changed", "sig_nick_mode_changed");
Irssi::signal_add_last("channel sync", "sig_channel_sync");
Irssi::command_bind('olmsg', 'cmd_olmsg');
