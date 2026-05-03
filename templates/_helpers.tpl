{{- define "valkey-operator.fullname" -}}
{{- printf "%s-%s" .Release.Name "valkey-operator" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "valkey-operator.labels" -}}
helm.sh/chart: {{ include "valkey-operator.chart" . }}
app.kubernetes.io/name: {{ include "valkey-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "valkey-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "valkey-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "valkey-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "valkey-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "valkey-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "valkey-operator.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}