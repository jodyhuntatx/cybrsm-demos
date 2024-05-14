#!/usr/bin/env python

# From: https://www.rabbitmq.com/tutorials/tutorial-one-python.html

RMQ_HOST = 'localhost'
RMQ_QNAME = 'cybrPwdChange'

import pika, sys, os, time

def main():
    parameters = pika.ConnectionParameters(host=RMQ_HOST)
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    channel.queue_declare(queue=RMQ_QNAME)

    def callback(ch, method, properties, body):
        print("RMQ Receiver: Received %r" % body.decode())
        ch.basic_ack(delivery_tag = method.delivery_tag)
        # do stuff with msg here
        print(" [x] Done")

    channel.basic_consume(queue=RMQ_QNAME, on_message_callback=callback)

    print('RMQ Receiver: Waiting for messages. To exit press CTRL+C')
    channel.start_consuming()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('Interrupted')
        try:
            sys.exit(0)
        except SystemExit:
            os._exit(0)
