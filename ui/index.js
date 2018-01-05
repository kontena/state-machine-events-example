const express = require('express');
const fetch = require('node-fetch');
const app = express();
const server = require('http').createServer(app);
const io = require('socket.io')(server);
const amqp = require('amqplib/callback_api');
const amqpUri = process.env.RABBITMQ_URI || 'amqp://localhost';
const port = process.env.PORT || 9000;
const apiUrl = process.env.API_URL || 'http://localhost:8000';
const replayEventsUrl = `${apiUrl}/events?prefix=ui`;

function listenEvents(ch, io, exchange, routing_key) {
  ch.assertExchange(exchange, 'topic', { durable: true });

  ch.assertQueue('', { exclusive: true }, (err, q) => {
    ch.bindQueue(q.queue, exchange, routing_key);

    ch.consume(q.queue, (msg) => {
      io.emit(exchange, msg.content.toString());
      console.log(" [x] %s:'%s'", msg.fields.routingKey, msg.content.toString());
    }, { noAck: true });
  });
}

app.get('/', (req, res, next) => {
  res.sendFile(__dirname + '/index.html');
});

app.get('/health', (req, res,next) => {
  res.setHeader('Content-Type', 'application/json')
  res.send("{ status: 'OK' }");
});

amqp.connect(amqpUri, (err, conn) => {
  conn.createChannel((err, ch) => {
    // Listen for events published by API
    listenEvents(ch, io, 'entity_events', 'entity_event.#');

    // Listen for events replayed by API that we requested
    listenEvents(ch, io, 'entity_events', 'ui.entity_event.#');

    io.on('connection', socket => {
      console.log(`socket ${socket.id} connected`);

      socket.on('disconnect', () => {
        console.log(`socket ${socket.id} disconnected`);
      });

      console.log(`Requesting replay of events from ${replayEventsUrl}`);
      fetch(replayEventsUrl);
    });
  });
});

server.listen(9000, function() {
  console.log(`server listening on port ${port}`);
});