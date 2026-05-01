{{- define "gitlabPrereqs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gitlabPrereqs.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "gitlabPrereqs.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "gitlabPrereqs.labels" -}}
app.kubernetes.io/name: {{ include "gitlabPrereqs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: {{ .Values.global.partOf }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "gitlabPrereqs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gitlabPrereqs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "gitlabPrereqs.resourcePrefix" -}}
{{- default .Release.Name .Values.resourcePrefix | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gitlabPrereqs.postgresqlName" -}}
{{- printf "%s-postgresql" (include "gitlabPrereqs.resourcePrefix" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gitlabPrereqs.valkeyName" -}}
{{- printf "%s-valkey" (include "gitlabPrereqs.resourcePrefix" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gitlabPrereqs.minioName" -}}
{{- printf "%s-minio" (include "gitlabPrereqs.resourcePrefix" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
