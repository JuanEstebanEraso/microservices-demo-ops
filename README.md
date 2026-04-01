# Microservices Demo Ops

Repositorio de operaciones para despliegue e infraestructura del demo de microservicios.

## Alcance

Este repositorio contiene solo componentes de Ops:

- Chart de infraestructura compartida: `infrastructure/`
- Charts de despliegue de servicios: `vote/chart/`, `worker/chart/`, `result/chart/`
- Orquestacion de despliegue en Okteto: `okteto.yml`
- Politicas y flujo de trabajo de operaciones: `branching-ops.md`

El codigo fuente de las aplicaciones (Java, Go, Node.js) vive en el repositorio Dev.

## Arquitectura

![Architecture diagram](architecture.png)

- `vote`: frontend web
- `worker`: consumidor Kafka que persiste votos
- `result`: frontend de resultados en tiempo real
- `kafka` y `postgresql`: infraestructura base

## Despliegue en Okteto

```bash
okteto login
okteto deploy
```

`okteto deploy` ejecuta los charts Helm de infraestructura y servicios usando los valores versionados en este repositorio.

## Flujo recomendado Dev -> Ops

1. Dev genera y publica imagenes inmutables por servicio (tag o digest).
2. Ops actualiza referencias de imagen en:
	- `vote/chart/values.yaml`
	- `worker/chart/values.yaml`
	- `result/chart/values.yaml`
3. Se valida por PR (helm lint/template + revisiones).
4. Se hace merge a `main` y se despliega.

## Branching y governance

La estrategia de ramas y reglas operativas estan en `branching-ops.md`.
