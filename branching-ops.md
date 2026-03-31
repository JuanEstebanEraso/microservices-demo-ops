# Estrategia de Branching para Operaciones

## Trunk-based Development (TBD)

## 1. Objetivo

Este documento define la estrategia oficial de branching para operaciones en el proyecto Microservices Demo.

El objetivo es mantener una forma de trabajo simple, segura y auditable para cambios de despliegue e infraestructura.

## 2. Alcance de este repositorio

Este repositorio contiene componentes de aplicación y operaciones. Para la estrategia de ops, se consideran rutas críticas:

- infrastructure/
- vote/chart/
- worker/chart/
- result/chart/
- okteto.yml

## 3. Modelo de ramas

- Rama permanente única: main.
- Ramas temporales de trabajo: creadas desde main.
- No existen ramas por entorno (no staging, no production).

Reglas para main:

- Siempre desplegable.
- Prohibido push directo.
- Todo entra por Pull Request.
- Checks obligatorios en verde antes del merge.
- Aprobaciones mínimas:
  - 1 aprobación para cambios normales.
  - 2 aprobaciones para cambios críticos (pipeline, seguridad, cambios globales).

Reglas para ramas temporales:

- Vida ideal: menor a 24 horas.
- Límite máximo: 48 horas.
- Si supera el límite, dividir cambios o recrear rama desde main.

## 4. Convención de nombres de ramas

Formato:

infra/<descripcion-en-kebab-case>

Sub-formatos recomendados:

- infra/add-<descripcion>
- infra/fix-<descripcion>
- infra/update-<descripcion>
- infra/pipeline-<descripcion>
- infra/scale-<descripcion>

Ejemplos:

- infra/add-worker-liveness-probe
- infra/fix-vote-readiness-timeout
- infra/update-kafka-image-tag
- infra/pipeline-add-helm-lint
- infra/scale-worker-replicas-to-3

## 5. Flujo operativo estándar

1. Sincronizar rama principal:

   git checkout main
   git pull origin main

2. Crear rama temporal:

   git checkout -b infra/<descripcion>

3. Realizar cambios pequeños y atómicos.

4. Validar localmente (mínimo recomendado):

   - helm lint del chart afectado.
   - helm template del chart afectado.
   - revisión de diferencias con git diff.

5. Commit selectivo:

   git add <archivo>
   git commit -m "infra(scope): descripcion"

6. Subir rama:

   git push -u origin infra/<descripcion>

7. Si la rama dura más de 1 día, rebase contra main:

   git fetch origin
   git rebase origin/main
   git push --force-with-lease

Regla: force-with-lease solo en ramas temporales.

8. Abrir Pull Request hacia main.

9. Merge recomendado: Squash and Merge.

## 6. Convención de commits

Formato:

<tipo>(<scope>): <descripcion>

Tipos permitidos:

- infra
- fix
- scale
- update
- pipeline
- docs

Scopes sugeridos:

- vote
- worker
- result
- kafka
- postgres
- global

Ejemplos:

- infra(worker): add liveness probe
- fix(postgres): set max_connections to 100
- scale(result): increase replicaCount to 2
- update(kafka): bump image tag to 3.7.0
- pipeline(global): add helm lint check
- docs(global): document rollback procedure

Regla adicional recomendada:

- Incluir referencia de ticket o incidente en PR o commit.

## 7. Pull Requests

Un PR de ops debe incluir:

- Que cambia.
- Por que cambia.
- Entornos afectados.
- Riesgo e impacto.
- Plan de rollback.

Tamaño recomendado:

- Ideal: 1 a 3 archivos.
- Aceptable: 4 a 6 archivos si es un cambio coherente.
- Mayor a 6 archivos: dividir en PRs.

Regla de enfoque:

- Un servicio por PR, salvo cambios globales justificados.

## 8. Reglas de protección de main (GitHub)

Configurar branch protection con:

- Require a pull request before merging: enabled.
- Required approvals: 1 (o 2 para cambios críticos con CODEOWNERS).
- Require status checks to pass before merging: enabled.
- Dismiss stale approvals when new commits are pushed: enabled.
- Require conversation resolution before merging: enabled.
- Do not allow bypassing the above settings: enabled.
- Force pushes to main: disabled.

## 9. Entornos sin ramas separadas

Los entornos se gestionan con archivos de valores, no con ramas.

Estructura recomendada por chart:

- values.yaml
- values-staging.yaml
- values-production.yaml

Ejemplo de despliegue:

staging:

helm upgrade --install worker worker/chart -f worker/chart/values.yaml -f worker/chart/values-staging.yaml

production:

helm upgrade --install worker worker/chart -f worker/chart/values.yaml -f worker/chart/values-production.yaml

## 10. Política de imágenes y secretos

Imágenes:

- Prohibido latest en producción.
- Recomendado: tag inmutable o digest.

Secretos:

- Prohibido hardcodear secretos en YAML.
- Activar escaneo de secretos en PR.
- Usar mecanismo externo de gestión de secretos.

## 11. Manejo de conflictos

git fetch origin
git rebase origin/main

Resolver conflictos, luego:

git add <archivo>
git rebase --continue
git push --force-with-lease

## 12. Incidentes urgentes en producción

Flujo igual al normal, con prioridad alta:

1. Crear rama desde main.
2. Aplicar fix mínimo.
3. Abrir PR con etiqueta urgent.
4. Revisión prioritaria.
5. Merge y despliegue.
6. Validar salud del servicio.
7. Si falla, rollback inmediato.

## 13. Rollback operativo

Orden recomendado:

1. Revertir commit en main si el problema viene del cambio de Git:

   git checkout main
   git pull origin main
   git revert <commit_sha>
   git push origin main

2. Si el incidente exige respuesta inmediata, ejecutar rollback de release (Helm) segun runbook del entorno.

3. Validar post-rollback:

- estado de pods
- eventos recientes
- probes
- logs del servicio
- conectividad con dependencias (Kafka/PostgreSQL)

## 14. Que no hacer

- Push directo a main.
- Ramas de mas de 48 horas.
- Mezclar cambios no relacionados en una rama.
- Mezclar cambios de app y ops sin justificacion.
- Secretos en texto plano.
- latest en produccion.
- Cambios manuales en cluster sin reflejarlos en Git.

## 15. Referencia rapida

Sincronizar:

git checkout main
git pull origin main

Crear rama:

git checkout -b infra/<descripcion>

Commit:

git add <archivo>
git commit -m "infra(scope): descripcion"

Push:

git push -u origin infra/<descripcion>

Rebase:

git fetch origin
git rebase origin/main
git push --force-with-lease

Rollback:

git checkout main
git pull origin main
git revert <commit_sha>
git push origin main
