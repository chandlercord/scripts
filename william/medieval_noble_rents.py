#!/usr/bin/python

#income=float(input("What is your yearly income before taxes?: ")
#You can combine float and input to one single line of code.
income=input("What is your estate's income of taxable livres?: ")
income=float(income)

if income >=5000:
    print ("The king levies 5/10s of your revenues for the cost of his protection.")
    tax=income * .5
    netincome=income-tax
    print ("Your estate revenues after the king's levy is:", netincome)
elif income >=2500:
    print ("The king levies 4/10s of your revenues for the cost of his protection.")
    tax=income*.4
    netincome=income-tax
    print ("Your estate revenues after the king's levy is:", netincome)
elif income >=1500:
    print ("The king levies 3/10s of your revenues for the cost of his protection.")
    tax=income*.3
    netincome=income-tax
    print ("Your estate revenues after the king's levy is:", netincome)
elif income >=1000:
    print ("The king levies 2/10s of your revenues for the cost of his protection.")
    tax=income*.2
    netincome=income-tax
    print ("Your estate revenues after the king's levy is:", netincome)
elif income >=500:
    print ("The king levies 1/10 of your revenues for the cost of his protection.")
    tax=income*.1
    netincome=income-tax
    print ("Your estate revenues after the king's levy is:", netincome)
else:
    print ("The king will levy no taxes upon you")
