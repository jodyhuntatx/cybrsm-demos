#!/usr/bin/env python3

# RabbitMQ variables
RMQ_HOST = '192.168.35.207'     # RabbitMQ host to send messages to
RMQ_QNAME = 'cybrPwdChange'	# name of message queue
RMQ_ECHO_MESSAGES = False       # echo messages to console before sending

# Syslog listener variables
HOST, PORT = "0.0.0.0", 1514
LOG_MESSAGES = True             # log incoming syslog messages to log file
LOG_FILE = 'cybrsyslog.txt'

#########################################
import pika, sys

def RMQsend(message):
    if RMQ_ECHO_MESSAGES :
        print("RMQ Forwarder: Sending message: " + message)
    connection = pika.BlockingConnection(pika.ConnectionParameters(RMQ_HOST))
    channel = connection.channel()
    channel.queue_declare(queue=RMQ_QNAME)
    channel.basic_publish(exchange='',
                      routing_key=RMQ_QNAME,
                      body=message)
    connection.close()

#########################################
import sys, json
from pyparsing import Word, alphas, Combine, nums, string, Regex
from time import strftime

class Parser(object):
  def __init__(self):
    ints = Word(nums)

    # timestamp
    month = Word(string.ascii_uppercase , string.ascii_lowercase, exact=3)
    day   = ints
    hour  = Combine(ints + ":" + ints + ":" + ints )
    timestamp = month + day + hour

    # hostname
    hostname = Word(alphas + nums + "_" + "-" + ".")

    # message
    message = Regex(".*")
  
    # pattern build
    self.__pattern = timestamp + hostname + message
    
  def parse(self, line):
		# remove root folder name from account name
    xline = line.replace("Root\\","")
    parsed = self.__pattern.parseString(xline)

		# parse initial payload into dictionary
    payload = {}
    payload["timestamp"] = strftime("%Y-%m-%d %H:%M:%S")
    payload["hostname"]  = parsed[3]
    payload["message"] = parsed[4]

		# parse json message into dictionary,
		# then add timestamp & vault hostname values
    payloadj = json.loads(payload["message"])
    payloadj["timestamp"] = payload["timestamp"]
    payloadj["vaultHostname"] = payload["hostname"]
    		# return as json
    return json.dumps(payloadj)

#########################################
## Tiny Syslog Server in Python.
##
## This is a tiny syslog server that is able to receive UDP based syslog
## entries on a specified port and save them to a file.
## That's it... it does nothing else...
## There are a few configuration parameters. (see above)

import logging
import socketserver

logging.basicConfig(level=logging.INFO, format='%(message)s', datefmt='', filename=LOG_FILE, filemode='a')

class SyslogUDPHandler(socketserver.BaseRequestHandler):

    def handle(self):
        data = bytes.decode(self.request[0].strip())
        socket = self.request[1]
        if LOG_MESSAGES :
            print("RMQ Forwarder: Syslog message received.")
            logging.info(str(data))
        RMQsend(parser.parse(str(data)))

#########################################
if __name__ == "__main__":
    try:
        print("RMQ Forwarder: Starting parser.")
        parser = Parser()
        print("RMQ Forwarder: Starting syslog listener.")
        server = socketserver.UDPServer((HOST,PORT), SyslogUDPHandler)
        server.serve_forever(poll_interval=0.5)
    except (IOError, SystemExit):
        raise
    except KeyboardInterrupt:
        print ("RMQ Forwarder: Crtl+C Pressed. Shutting down.")
