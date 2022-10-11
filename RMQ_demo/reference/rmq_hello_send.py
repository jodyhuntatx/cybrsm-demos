#!/usr/bin/env python

# RabbitMQ Hello world sender
# From: https://www.rabbitmq.com/tutorials/tutorial-one-python.html

import pika, sys 

message = ' '.join(sys.argv[1:]) or "Hello World!"

connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = connection.channel()
channel.queue_declare(queue='hello')

channel.basic_publish(exchange='',
                      routing_key='hello',
                      body=message)
print(" [x] Sent %r" % message)
connection.close()
