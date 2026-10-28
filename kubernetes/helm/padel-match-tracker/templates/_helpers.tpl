{{/* מייצר שם בסיסי ליישום. */}}
{{- define "padel-match-tracker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* מייצר שם מלא למשאבי ההפצה. */}}
{{- define "padel-match-tracker.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "padel-match-tracker.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/* מגדיר תוויות משותפות לכל משאבי היישום. */}}
{{- define "padel-match-tracker.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "padel-match-tracker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* מגדיר תוויות יציבות לחיבור בין שירותים לפודים. */}}
{{- define "padel-match-tracker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "padel-match-tracker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
