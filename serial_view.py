import serial 

s = serial.Serial("/dev/ttyACM0", 115200)
while True:
    print(s.readline().decode("utf-8").strip())      
