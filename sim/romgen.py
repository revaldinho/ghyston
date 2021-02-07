
import random;

#for i in range (0, 8192):
#    print(hex(random.randint(0,2**24))[2:])


## ADD R7, RZERO, RZERO, 0
## 1001_1001_1100_0000_0000_0000
print( "99C000")
## ADD R6, RZERO, RZERO, 0
## 1001_1001_1000_0000_0000_0000
print( "998000")
## ADD R5, RZERO, RZERO, 1
## 1001_1001_0100_0000_0000_0001
print( "994001")
## ADD R4, RZERO, RZERO, 1
## 1001_1001_0000_0000_0000_0001
print( "990001")
for i in range (1, 8188,4):
    ## STO.B R7, RZERO, R6, 0
    ## 0000_1101_1100_0001_1000_0000
    print("0DC180")    
    ## ADD R7, R7, R4, 0
    ## 1001_1001_1101_1101_0000_0000
    print("99DD00")
    ## ADD R6, R6, RZERO, 1
    ## 1001_1001_1001_1000_0000_0001
    print("999801")
    ## AND RZERO, R6, RZERO, 0
    ## 1001_1000_0001_1000_0000_0000
    print("981800")
