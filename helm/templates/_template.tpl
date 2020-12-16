{{- define "firstimage" -}}
  {{- $registry := .Values.timescale.registry -}}
  {{- $repository := .Values.timescale.repository -}}
  {{- $tag := .Values.timescale.tag -}}
  {{- $registry -}}/{{- $repository -}}:{{- $tag -}}
{{- end -}}

