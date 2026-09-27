{{/*
Common helpers.
*/}}

{{- define "omni.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "omni.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "omni.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "omni.labels" -}}
helm.sh/chart: {{ include "omni.chart" . }}
{{ include "omni.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "omni.selectorLabels" -}}
app.kubernetes.io/name: {{ include "omni.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "omni.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "omni.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Component-specific names.
*/}}
{{- define "omni.web.fullname" -}}{{ include "omni.fullname" . }}-web{{- end }}
{{- define "omni.arqWorker.fullname" -}}{{ include "omni.fullname" . }}-arq-worker{{- end }}
{{- define "omni.ariManager.fullname" -}}{{ include "omni.fullname" . }}-ari-manager{{- end }}
{{- define "omni.campaignOrchestrator.fullname" -}}{{ include "omni.fullname" . }}-campaign-orchestrator{{- end }}
{{- define "omni.ui.fullname" -}}{{ include "omni.fullname" . }}-ui{{- end }}
{{- define "omni.coturn.fullname" -}}{{ include "omni.fullname" . }}-coturn{{- end }}
{{- define "omni.migrate.fullname" -}}{{ include "omni.fullname" . }}-migrate{{- end }}

{{- define "omni.configMapName" -}}{{ include "omni.fullname" . }}-config{{- end }}
{{- define "omni.secretName" -}}
{{- if .Values.secrets.existingSecret -}}
{{- .Values.secrets.existingSecret -}}
{{- else -}}
{{- include "omni.fullname" . }}-secret
{{- end -}}
{{- end }}

{{/*
Image reference.
*/}}
{{- define "omni.image" -}}
{{- $registry := .Values.image.registry | default "docker.io" -}}
{{- printf "%s/%s:%s" $registry .Values.image.repository .Values.image.tag -}}
{{- end }}

{{- define "omni.ui.image" -}}
{{- $registry := .Values.ui.image.registry | default "docker.io" -}}
{{- printf "%s/%s:%s" $registry .Values.ui.image.repository .Values.ui.image.tag -}}
{{- end }}

{{- define "omni.coturn.image" -}}
{{- $registry := .Values.coturn.image.registry | default "docker.io" -}}
{{- printf "%s/%s:%s" $registry .Values.coturn.image.repository .Values.coturn.image.tag -}}
{{- end }}

{{/*
Subchart enabling — flips top-level chart-dependency `enabled` flags from mode.
Called from each template via `include "omni.deps.resolved" .` (no-op output).
*/}}
{{- define "omni.deps.resolved" -}}
{{- /* compute whether internal deps are enabled */ -}}
{{- end }}

{{/*
In-cluster service references for internal deps.
*/}}
{{- define "omni.postgresHost" -}}{{ .Release.Name }}-postgresql{{- end }}
{{- define "omni.redisHost" -}}{{ .Release.Name }}-redisinternal-master{{- end }}
{{- define "omni.minioHost" -}}{{ .Release.Name }}-minio{{- end }}

{{/*
Resolved passwords for the bundled internal deps.
Precedence: explicit value in values.yaml wins; else reuse the value already
stored in the Secret (so `helm upgrade` does NOT rotate the password and desync a
running datastore); else generate a fresh one. `lookup` returns empty during
`helm template` (no cluster), so dry renders get a throwaway random value — fine.
Each is materialized in exactly one place (the dep's Secret); every other
reference is a secretKeyRef, so the generated value is stable within a render.
*/}}
{{- define "omni.postgresPassword" -}}
{{- if .Values.postgresql.auth.password -}}
{{- .Values.postgresql.auth.password -}}
{{- else -}}
{{- $s := lookup "v1" "Secret" .Release.Namespace (printf "%s-postgresql" .Release.Name) -}}
{{- if and $s $s.data (index $s.data "password") -}}
{{- index $s.data "password" | b64dec -}}
{{- else -}}
{{- randAlphaNum 24 -}}
{{- end -}}
{{- end -}}
{{- end }}

{{- define "omni.redisPassword" -}}
{{- if .Values.redisinternal.auth.password -}}
{{- .Values.redisinternal.auth.password -}}
{{- else -}}
{{- $s := lookup "v1" "Secret" .Release.Namespace (printf "%s-redisinternal" .Release.Name) -}}
{{- if and $s $s.data (index $s.data "redis-password") -}}
{{- index $s.data "redis-password" | b64dec -}}
{{- else -}}
{{- randAlphaNum 24 -}}
{{- end -}}
{{- end -}}
{{- end }}

{{- define "omni.minioRootPassword" -}}
{{- if .Values.minio.auth.rootPassword -}}
{{- .Values.minio.auth.rootPassword -}}
{{- else -}}
{{- $s := lookup "v1" "Secret" .Release.Namespace (printf "%s-minio" .Release.Name) -}}
{{- if and $s $s.data (index $s.data "root-password") -}}
{{- index $s.data "root-password" | b64dec -}}
{{- else -}}
{{- randAlphaNum 24 -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Default DATABASE_URL when database.mode=internal.
The bundled Postgres (templates/internal-postgres.yaml) stores the app-user
password in the <release>-postgresql Secret under key `password`; omni.dbEnv
projects it into $(POSTGRES_PASSWORD), which this URL interpolates at runtime.
Auth username/database default to `omni` (see values.postgresql.auth).
*/}}
{{- define "omni.databaseUrl" -}}
{{- if eq .Values.database.mode "internal" -}}
postgresql+asyncpg://{{ .Values.postgresql.auth.username }}:$(POSTGRES_PASSWORD)@{{ include "omni.postgresHost" . }}:5432/{{ .Values.postgresql.auth.database }}
{{- else -}}
$(DATABASE_URL)
{{- end -}}
{{- end }}

{{- define "omni.redisUrl" -}}
{{- if eq .Values.redis.mode "internal" -}}
redis://:$(REDIS_PASSWORD)@{{ include "omni.redisHost" . }}:6379
{{- else -}}
$(REDIS_URL)
{{- end -}}
{{- end }}

{{/*
Database / Redis connection env for backend workloads (web, arq, singletons,
migrate).

ORDER IS LOAD-BEARING. POSTGRES_PASSWORD / REDIS_PASSWORD are declared BEFORE
DATABASE_URL / REDIS_URL because Kubernetes only expands a $(VAR) reference to
an env var defined *earlier* in the same container's env list — a forward
reference is left as the literal string "$(VAR)". DATABASE_URL / REDIS_URL
embed $(POSTGRES_PASSWORD) / $(REDIS_PASSWORD) (see omni.databaseUrl /
omni.redisUrl), so the password vars must come first or the composed URLs
ship with a literal "$(POSTGRES_PASSWORD)" as the password.
*/}}
{{- define "omni.dbEnv" -}}
{{- if eq .Values.database.mode "internal" }}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-postgresql
      key: password
{{- end }}
{{- if eq .Values.redis.mode "internal" }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-redisinternal
      key: redis-password
{{- end }}
- name: DATABASE_URL
  value: {{ include "omni.databaseUrl" . | quote }}
- name: REDIS_URL
  value: {{ include "omni.redisUrl" . | quote }}
{{- if eq .Values.storage.mode "internalMinio" }}
{{- /* Internal MinIO creds come from the <release>-minio secret, the same
       source the MinIO server uses (no ordering constraint — no composition). */}}
- name: MINIO_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-minio
      key: root-user
- name: MINIO_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-minio
      key: root-password
{{- end }}
{{- end }}

{{/*
Common env block for backend workloads (web, arq, singletons, migrate).
References the ConfigMap + Secret via envFrom. DATABASE_URL and REDIS_URL
are added inline because they may need composition from subchart secrets.
*/}}
{{- define "omni.backendEnvFrom" -}}
- configMapRef:
    name: {{ include "omni.configMapName" . }}
- secretRef:
    name: {{ include "omni.secretName" . }}
{{- end }}
