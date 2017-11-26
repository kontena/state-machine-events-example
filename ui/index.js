const express = require('express');
const app = express();
const server = require('http').createServer(app);
const io = require('socket.io')(server);
const amqp = require('amqplib/callback_api');
const amqpUri = process.env.RABBITMQ_URI || 'amqp://localhost';

app.get('/', (req, res,next) => {
    res.sendFile(__dirname + '/index.html');
});

app.get('/health', (req, res,next) => {
  res.setHeader('Content-Type', 'application/json')
  res.send("{ status: 'OK' }");
});

io.on('connection', socket => {
  console.log('socket connected');
});

amqp.connect(amqpUri, (err, conn) => {
  conn.createChannel((err, ch) => {
    const exchange = 'entity_events';

    ch.assertExchange(exchange, 'topic', { durable: true });

    ch.assertQueue('', { exclusive: true }, (err, q) => {
      ch.bindQueue(q.queue, exchange, '#');

      ch.consume(q.queue, (msg) => {
        io.emit(exchange, msg.content.toString());
        console.log(" [x] %s:'%s'", msg.fields.routingKey, msg.content.toString());
      }, { noAck: true });
    });
  });
});

server.listen(9000);