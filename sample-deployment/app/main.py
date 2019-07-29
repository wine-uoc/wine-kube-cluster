from flask import Flask
import socket
app = Flask(__name__)

li = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p']

@app.route("/")
def hello():
    s = "Hello from Xavi in {0}!".format(socket.gethostname())
    return s
        
@app.route("/compute")    
def compute():
    return str(permute(4,li))   

    
#the recursive permutation    
def permute(s, list):
    if s == 1:
        return list
    else:
        return [ y + x
                 for y in permute(1, list)
                 for x in permute(s - 1, list)
                 ]     
                 
if __name__ == "__main__":
    app.run(host='0.0.0.0')
