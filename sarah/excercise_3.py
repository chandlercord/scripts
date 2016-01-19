'''
homework_3_visit_cities.py

Ask the user to input the names of cities they would like to visit.
The program will then create a sentance about those cities.
'''

def NumCitiesUserWantstoTravel ():
    raw_numcities = raw_input ('How many cities would you like to travel to? ')
    return int (raw_numcities)

def CitiesUserWantstoTravel ():
    raw_cities = raw_input ('Name of City you want to travel to ')
    return raw_cities

def AddCityNumber (message):
    i = 0
    while i<len(message):
        if message [i].isdigit ():
            message = message[:i] + str (int(message[i]) + 1 ) + message [i+1:]
        i = i+1
    print message

totalcities = NumCitiesUserWantstoTravel ()
count = 0
listofcities = []
while count <totalcities:
    city_name = CitiesUserWantstoTravel ()
    print city_name
    if city_name in listofcities:
        print "duplicate try again"
    else: 
        listofcities.append (city_name)
        count = count+1

count = 0
message = "You would like to visit "
while count < totalcities:
    count= count+1
    message = message + listofcities [count-1] + " as city " + str (count) + " "

message = message + "on your trip."

print message

AddCityNumber (message)