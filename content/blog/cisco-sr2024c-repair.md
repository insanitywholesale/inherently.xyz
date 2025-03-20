---
title: "Cisco SR2024C Repair"
date: 2022-03-28T18:03:46+03:00
draft: false
tags: ["hardware", "networking", "homelab"]
---

One of my friends at university gave me a broken switch that seemed broken and I decided to fix it.
Join me on a pretty entertaining troubleshooting path that was not entirely necessary.

## Backstory
This semester in university I am taking a CCNA class.
The learning path is split across two semesters, next semester I'll take CCNA 2 to be ready to get the certification.
A few of my friends are also there an one of them happened to have a supposedly broken Cisco switch.
Great opportunity to use it for hands-on learning, I thought.
He said it wasn't fully broken, it could turn on fine but would turn off after 10-20 minutes.
Not that bad. A little fan was also missing from it but that would be no more than 5-10 euros to replace.
He gave it to me one day, I took it home and that was that.
After a bit of research I realized the switch wasn't managed meaning it didn't have Cisco iOS capabilities.
Nevertheless, I like tech necromancy and network gear seldom goes unused.
So that's basically how I got a [Cisco SR2024C](https://www.cisco.com/c/en/us/obsolete/switches/cisco-sr2024c-compact-24-port-10-100-1000-gigabit-switch.html).

## Initial Findings
After checking that the power plug looked fine and the ports didn't look damaged, I decided to turn it on.
Indeed, after roughly 20 minutes it started boot-looping so the behavior was as described.
The switch wouldn't completely shut off, instead it followed a little pattern:
- lights flash for a second the way they do when first plugged in
- lights go out same as when normally booting
- goto step 1

This meant that eventually anything plugged into it would drop off the network which is not good.
At this point I'm suspecting the power supply since the device is pretty old, about 7 years past its End-Of-Life date.

## Open Wide
Behavior confirmed and reproducible, we have a place to start from.
The device would need to be opened anyway in order to replace the fan and I'd like to inspect the inside too.
This specific switch is considered compact as noted by the ending `C` in its model number (SR2024C).
Its width is a bit more than the width of the ports, 24 RJ45 gigabit ethernet ports and two miniGBIC.
It has holes to attach rackmount ears if desired but I wasn't provided those.
On the front there is a plastic cover that fits over the 4 sets of ports (3 sets of 8xRJ45 and one set of the 2 miniGBIC) and also clips on to the top and bottom metal pieces.
I dinged the plastic since I used a pair of scissors to pry it off but that's alright, we're going for functional not pretty.
Following that, I had to carefully unhook some little metal tabs that held the top half of the metal case to the bottom half.
Push a little here, pull a little there and ta-da! We're in.
The metal tabs were annoying to hook and unhook so I used a pair of pliers to twist them off.
On the left side there is a mesh cutout big enough for a 40mm fan and on the right side it's almost entirely mesh.
Weird for a rackmountable device to have side-to-side airflow but what do I know.
The bottom is entirely bare and so is the top with the exception of a Cisco logo.

## Guts
There are two PCBs/boards inside, the main board and an open-frame power supply.
They are connected by a weird cable I've never seen before and have connectors I've never seen before.
On the PSU side it's a 6-pin and a smaller 2-pin that merge into an 8-pin on the main board side.
The power plug is attached to the PSU through a 2-pin cable with a similar connector as well as a chassis ground point.
One good thing is that they all look removable and fairly easy to probe with a multimeter.
Overall The internals appear understandable so I'm fairly confident I can at least identify the issue.

## Power
Even though I commented about the ease of probing with a multimeter, I'm sad to say that I didn't have one previous to this experience.
Since I mostly work with software, either configuring or writing it, there was never a real need to own a multimeter.
I hopped on to one of the local electronic hardware supply stores' website and found one for around 15 euros, the [UNI-T UT131C](https://www.uni-trend.com/meters/html/product/General_Meters/DigitalMultimeters/UT131_Series/UT131C.html).
It arrived the next morning so I got to work and confirmed what repair videos from similar switches said, the main board uses 5V power.
The thing is, in those other videos the voltage was lower and that was what was causing issues.
In my case it was nice and steady at 4,98V which is within margin of error meaning nowhere near enough to cause a malfunction.
You can never be certain though so I had ordered some alligator clips which I used for powering the main board from an ATX PSU's molex connector.
It didn't result in a normal boot but I at least got a power light.
This ruled out my main hypothesis this far which was that the switch's power supply was going bad.

## Accidental Solution
In the process of hooking the switch up to the ATX power supply, I had it open for troubleshooting.
Perhaps accidentally, just to confirm that the problem was still there I reconnected the built-in power supply again.
After leaving for an hour or so to do something else, I came back and saw it wasn't boot looping.

What?

Peculiar, I thought. Sure enough, plugging in my laptop to it showed a link light and the laptop got an IP address.
What the... WAIT! By hovering over it I could feel the power supply putting out some heat.
No way it could be this simple, right? Could it be overheating?
I turned it off, closed the case and put a 120mm fan right up against the right side to pull air out of the switch.
To my surprise that was adequate to keep it cool enough even while closed.
This was so embarassingly simple that I had to test again.
I turned the switch on, let it get to the point where it starts constantly resetting and then put the fan next to it.
After about 5 minutes it started operating completely fine, I was in awe of how simply the problem was.

## Fan Replacement
Moving on to a permanent solution, I needed a fan to replace then one that was missing.
Looking things up online, I realized I need a 5V 1W fan that is 40mm wide and 20mm thick.
However, th only thing I found was a 0.75W fan for 8,23 euros.
Good enough I guess I'll just get two of those, one for intake and one for exhaust.
Funny thing about plans, the store had only one of the 0.75W version and then one that was 0.54W.
Sigh... Fine, I'll see how I'll arrange them.
A day later they came in, I tested them both out to see that they worked and put in the 0.75W fan just to be sure the internals get enough airflow.
After a 24-hour testing period, I think it's safe to say that the problem is solved.

## Use Case
The current plan is to use the switch for a VLAN so I don't have to waste multiple ports from my main 24-port switch and be reconfiguring them.
Yes, port-based VLANs aren't ideal but I need a place to test my next network remake without bothering everything else.
Even with the new fan it's not very quiet probably due to the whine that small fans make but I have plenty of noisy things in my room.

## Conclusion
It was a long and weird journey but it ended well and I now have a new switch.
The troubleshooting was fun, as it always is, the new tools are fun to have and I got a lesson about assuming the problem is more complicated than it is.
Thank you for reading, I hope you enjoyed the journey cause I sure did.
