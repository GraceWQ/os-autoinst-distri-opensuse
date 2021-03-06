# SUSE's openQA tests
#
# Copyright © 2016 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# Summary: This test verifies guest migration between two different hosts, either xen to xen, or kvm to kvm.
#          This is the part to run on the destination host.
# Maintainer: alice <xlai@suse.com>

use base multi_machine_job_base;
use strict;
use testapi;
use lockapi;
use mmapi;

sub run() {
    my ($self) = @_;

    my $ip_out = $self->execute_script_run('ip route show|grep kernel|cut -d" " -f12|head -1', 30);
    set_var('DST_IP',   $ip_out);
    set_var('DST_USER', "root");
    set_var('DST_PASS', "nots3cr3t");
    bmwqemu::save_vars();

    #workaround for weird mount failure
    $self->workaround_for_reverse_lock("SRC_IP", 3600);
    my $src_ip       = $self->get_var_from_child("SRC_IP");
    my $src_user     = $self->get_var_from_child("SRC_USER");
    my $src_pass     = $self->get_var_from_child("SRC_PASS");
    my $hypervisor   = get_var("HOST_HYPERVISOR", "kvm");
    my $args         = "-d $src_ip -v $hypervisor -u $src_user -p $src_pass";
    my $pre_test_cmd = "/usr/share/qa/virtautolib/lib/guest_migrate.sh " . $args;
    type_string("$pre_test_cmd \n");
    save_screenshot;
    sleep 10;
    send_key("ctrl-c");
    sleep 3;
    save_screenshot;
    #workaround end

    #mark ready state and wait for child finish
    $self->execute_script_run("rm -r /var/log/qa/ctcs2/* /tmp/prj3* -r", 30);
    mutex_create('DST_READY_TO_START');
    wait_for_children;

    #upload logs
    script_run("xl dmesg > /tmp/xl-dmesg.log");
    my $logs = "/var/log/libvirt /var/log/messages /var/log/xen /var/lib/xen/dump /tmp/xl-dmesg.log";
    &virt_autotest_base::upload_virt_logs($logs, "guest-migration-dst-logs");
}

1;
