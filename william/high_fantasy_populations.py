#!/usr/bin/python

from math import sqrt

Area=input("What is the square kilometer size of your kingdom?: ")
Area=float(Area)
Popdens=input("How many people live within one square kilometer of your kingdom?: ")
Popdens=float(Popdens)
Age=input("How old is your kingdom?: ")
Age=int(Age)

Population= Popdens*Area
Population=int(Population)
KingText="The population of your kingdoms"

print;

print "The population of your kingdom is:", Population

Largestcity= int(sqrt(Population)*18)
Cities=1

print KingText, "largest city is:",Largestcity
City=int(Largestcity*.8)
Cities=2

print KingText, "second largest city is:", City

if City >=20000:
    print KingText, "third largest city is:",City*.40
    City=int(City*.40)
    Cities=3
if City >=20000:
    print KingText, "fourth largest city is:",City*.40
    City=int(City*.40)
    Cities=4
if City >=20000:
    print KingText, "fifth largest city is:",City*.40
    City=int(City*.40)
    Cities=5
if City >=20000:
    print KingText, "sixth largest city is:",City*.40
    City=int(City*.40)
    Cities=6
if City >=20000:
    print KingText, "seventh largest city is:",City*.40
    City=int(City*.40)
    Cities=7
if City >=20000:
    print KingText, "eigth largest city is:",City*.40
    City=int(City*.40)
    Cities=8
if City >=20000:
    print KingText,"ninth largest city is:",City*.40
    City=int(City*.40)
    Cities=9
if City >=20000:
    print KingText,"tenth largest city is:",City*.40
    City=int(City*.40)
    Cities=10
else:
    Towns=int(Cities*16)
    print "The number of towns in your kingdom is:", Towns
    print "The rest of your people live in villages, or in isolated dwellings."

Castles = int(Population/50000)
print "There are", Castles,"functioning castles in your kingdom."
Ruins = int(Population/5000000*sqrt(Age))
print "And there are", Ruins,"ruins in your kingdom."
