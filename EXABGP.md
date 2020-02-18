Using ExaBGP to inject test routes locally
==========================================

Network Configuration
---------------------

Let's create the VRF ExaBGP will run on:

    ip link add bgp-vrf0 type vrf table 10
    ip link set bgp-vrf0 up

Now we need to create the virtual ethernet pair interface to connect the new
VRF with FRR:

    ip link add bgp-net0 type veth peer name bgp-peer0
    ip link set bgp-peer0 vrf bgp-vrf0
    ip link set bgp-net0 up
    ip link set bgp-peer0 up

Add addresses to identify FRR and ExaBGP networks:

    ip addr add dev bgp-net0 192.168.100.1/24
    ip addr add dev bgp-peer0 192.168.100.2/24


Routing Rules
-------------

Connecting two VRFs locally won't work out of the box, there are some rules
that prevent it. To change that lets check the default rules (tested with Linux
4.15) with the command `ip rule`:

    0:      from all lookup local
    1000:   from all lookup [l3mdev-table]
    32766:  from all lookup main
    32767:  from all lookup default

This rules will make ExaBGP fail to lookup for FRR's address (and vice versa)
by default. Change the order of the local lookup to make this setup work:

    ip rule add pref 2000 table local
    ip rule del pref 0

Now we should have the rules in the correct places:

    1000:   from all lookup [l3mdev-table] 
    2000:   from all lookup local 
    32766:  from all lookup main 
    32767:  from all lookup default

And you can confirm it worked with:

    ping -c 1 192.168.100.2


Configuration Samples
---------------------

ExaBGP:

    neighbor 192.168.100.1 {
      local-address 192.168.100.2;
      local-as 100;
      peer-as 100;

      static {
        route 192.168.254.1/32 next-hop 192.168.100.2;
        route 192.168.254.2/32 next-hop 192.168.100.2;
        route 192.168.254.3/32 next-hop 192.168.100.2;
        route 192.168.254.4/32 next-hop 192.168.100.2;
      }
    }


FRR:

    router bgp 100
     neighbor 192.168.100.2 remote-as 100
    !
