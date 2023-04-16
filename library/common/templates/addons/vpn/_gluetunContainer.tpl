{{/*
The gluetun sidecar container to be inserted.
*/}}
{{- define "tc.v1.common.addon.vpn.gluetun.container" -}}
enabled: true
imageSelector: gluetunImage
probes:
{{- if $.Values.addons.vpn.livenessProbe }}
  liveness:
  {{- toYaml . | nindent 2 }}
{{- else }}
  liveness:
    enabled: false
{{- end }}
  readiness:
    enabled: false
  startup:
    enabled: false
securityContext:
  runAsUser: 0
  runAsNonRoot: false
  readOnlyRootFilesystem: false
  runAsGroup: 568
  capabilities:
    add:
      - NET_ADMIN
      - NET_RAW
      - MKNOD
      - SYS_MODULE

env:
  DNS_KEEP_NAMESERVER: on
  DOT: off
{{- if .Values.addons.vpn.killSwitch }}
  FIREWALL: "on"
  {{- $excludednetworksv4 := "172.16.0.0/12" -}}
  {{- range .Values.addons.vpn.excludedNetworks_IPv4 -}}
    {{- $excludednetworksv4 = ( printf "%v,%v" $excludednetworksv4 . ) -}}
  {{- end }}

{{- if .Values.addons.vpn.excludedNetworks_IPv6 -}}
  {{- $excludednetworksv6 := "" -}}
  {{- range .Values.addons.vpn.excludedNetworks_IPv4 -}}
    {{- $excludednetworksv6 = ( printf "%v,%v" $excludednetworksv6 . ) -}}
  {{- end }}
  FIREWALL_OUTBOUND_SUBNETS: {{ ( printf "%v,%v" $excludednetworksv4 $excludednetworksv6 ) | quote }}
{{- else -}}
  FIREWALL_OUTBOUND_SUBNETS: {{ $excludednetworksv4 | quote }}
{{- end -}}
{{- else -}}
  FIREWALL: "off"
{{- end -}}

{{- with $.Values.addons.vpn.env }}
  {{- . | toYaml | nindent 2 }}
{{- end -}}

{{- range $envList := $.Values.addons.vpn.envList -}}
  {{- if and $envList.name $envList.value }}
  {{ $envList.name }}: {{ $envList.value | quote }}
  {{- else -}}
    {{- fail "Please specify name/value for VPN environment variable" -}}
  {{- end -}}
{{- end -}}

{{- with $.Values.addons.vpn.args }}
args:
  {{- . | toYaml | nindent 2 }}
{{- end }}
{{- end -}}
