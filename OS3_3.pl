#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(dup2);

$| = 1;

sub process_cmd {
    my ($cmd) = @_;
    if ($cmd =~ /\|/) {
        my @pipe_cmds = split /\|/, $cmd;
        my ($rh, $wh);
        pipe($rh, $wh);

        if (fork() == 0) {
            close $rh;
            dup2(fileno($wh), 1);
            close $wh;
            my @args = split ' ', $pipe_cmds[0];
            exec @args;
            exit;
        }
        close $wh;
        wait;

        if (fork() == 0) {
            dup2(fileno($rh), 0);
            close $rh;
            my @args = split ' ', $pipe_cmds[1];
            exec @args;
            exit;
        }
        close $rh;
        wait;
    } else {
        if (fork() == 0) {
            my @args = split ' ', $cmd;
            exec @args;
            exit;
        }
        wait;
    }
}

print "prompt> ";
while (<>) {
    chomp;
    my @cmds = split /;/;
    for my $cmd (@cmds) {
        if ($cmd =~ /^\s*\((.*)\)\s*$/) {
            my $blk = $1;
            my @blk_cmds = split /&/, $blk;
            for my $blk_cmd (@blk_cmds) {
                process_cmd($blk_cmd);
            }
        } else {
            process_cmd($cmd);
        }
    }
    print "prompt> ";
}