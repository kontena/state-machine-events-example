# State Machines and Events Microservices Example

Example microservice application that utilize a mix of state machines and RabbitMQ to create a robust asynchronous event system with replay capabilities.

*Note* All examples assume you are running inside a Kontena Shell, such as the integrated Kontena Cloud web terminal.  If you are running from a local command line, you can enter the shell by running:

```
kontena plugin install shell
kontena shell
```

Otherwise, you can also just prefix each command below with `kontena` to run outside the Kontena Shell.


## To install from public stack registry

1. Install RabbitMQ stack
  - `volume create --scope instance --driver local harbur-rabbitmq-cluster-seed-data`
  - `volume create --scope instance --driver local harbur-rabbitmq-cluster-node-data`
  - `stack install kontena/harbur-rabbitmq-cluster`

2. Install the tutorial application stack
  - `stack install kontena/state-machine-events`

