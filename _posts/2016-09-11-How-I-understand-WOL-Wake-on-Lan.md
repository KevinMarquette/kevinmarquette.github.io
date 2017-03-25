---
layout: post
title: "How I understand WOL (Wake on Lan)"
date: 2016-09-11
tags: [WOL,Other]
---
The way WOL works is that the NIC has to receive the magic packet. This packet has a special bit pattern and the MAC address of the NIC. If you want to wake up 5 machines, that is 5 different magic packets. All you have to do is get this packet to the machine.

The two ways are unicast and broadcast. If you broadcast the packet to the broadcast address for the given subnet, then every machine on that subnet will receive the packet. Generally, you have to be on the same subnet that you are targeting for this to work. So if you are in subnet A, you cannot sent it to the broadcast address of subnet B. It is possible to change a switch configuration to allow this but it is disabled by default for security/stability of the network.

You can also unicast to the last known IP address in some cases. Even if your network uses DHCP. This is because the switch may maintain a route to that device in the routing table. The longer the machine is turned off, the least likely this will work.

You also have to configure the machine/nic to enable WOL. This is often a BIOS option. While you are in the BIOS, look for the sleep state or the energy savings levels. Some supper efficient levels will remove power from the NIC so it can't watch for WOL. For good measure, research if windows can cause issues here too. I know it can remove power from devices to save energy. I can't say that it will do it for a wired nic but worth validating.

In my environment, I could not enable cross subnet broadcast packets. I got around it by ensuring that I had a computer in every subnet on a list. I BIOS configured those machines to auto power on at a set time and whenever they lost power to power on. Call these my zombie systems.

I then had a set of scripts that would connect to those zombie machines and have them issue the magic packet to their own subnet. So for every machine I needed to wake, each zombie would sent a packet to do it. I could target individual machines or just wake every system we had using that method.

That was one of my favorite things to do. Go to a lab of 50+ machines and wake them all up. The whole room would click on, the fans spin up, and the room glow as the monitors came on all at the same time.