#!/usr/bin/python

from math import sqrt

Area=input("What is the square milage of your kingdom?: ")
Area=float(Area)
Popdens=input("How many people live within one square mile of your kingdom?: ")
Popdens=float(Popdens)
Age=input("How old is your kingdom?: ")
Age=int(Age)

Population= Popdens*Area
Population=int(Population)

print("The population of your kingdom is: ", Population)

Largestcity= int(sqrt(Population)*15)
Cities=1
print("The population of your kingdom's largest city is: ", Largestcity)
City=int(Largestcity*.5)
Cities=2
print("The second largest city in your kingdom is: ", City)
if City >=80000:
    print("The third largest city in your kingdom is: ",City*.25)
    City=int(City*.25)
    Cities=3
if City >=80000:
    print("The fourth largest city in your kingdom is: ",City*.25)
    City=int(City*.25)
    Cities=4
if City >=80000:
    print("The fifth largest city in your kingdom is: ",City*.25)
    City=int(City*.25)
    Cities=5
if City >=80000:
    print("The sixth largest city in your kingdom is: ",City*.25)
    City=int(City*.25)
    Cities=6
if City >=80000:
    print("The seventh largest city in your kingdom is: ",City*.25)
    City=int(City*.25)
    Cities=7
if City >=80000:
    print("The eigth largest city in your kingdom is: ",City*.25)
    City=int(City*.25)
    Cities=8
if City >=80000:
    print("The ninth largest city in your kingdom is: ",City*.25)
    City=int(City*.25)
    Cities=9
if City >=80000:
    print("The tenth largest city in your kingdom is: ",City*.25)
    City=int(City*.25)
    Cities=10
else:
    Towns=int(Cities*9)
    print("The number of towns in your kingdom is: ", Towns)
    print("The rest of your people live in villages, or in isolated dwellings.")

Castles = int(Population/50000)
print("There are", Castles,"functioning castles in your kingdom.")
Ruins = int(Population/5000000*sqrt(Age))
print("And there are", Ruins,"ruins in your kingdom.")

