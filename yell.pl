use strict;

sub cmd_yell{
	my($param,$serv,$chan) = @_;
	my $line;
	for my $n ($chan->nicks()){
		if($n->{nick} eq $serv->{nick}){ next; }
		$line=$n->{nick}.': '.$param;
		Irssi::signal_emit('send text', $line,  $serv, $serv->window_item_find($chan->{name}));
		Irssi::signal_stop();
	}
}

Irssi::command_bind('yell', 'cmd_yell');
