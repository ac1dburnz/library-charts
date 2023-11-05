{{- define "tc.v1.common.lib.cnpg.cluster.bootstrap.standalone" -}}
  {{- $objectData := .objectData -}}
  {{- $cnpgClusterName := (include "tc.v1.common.lib.cnpg.clusterName" (dict "objectData" $objectData)) -}}

  {{- $initdb := dict -}}
  {{- if $objectData.initdb -}}
    {{- $keysToDrop := (list "postInitApplicationSQL" "database" "owner" "secret")-}}
    {{- range $key := $keysToDrop -}}
      {{- $initdb = omit ($objectData.initdb $keys) -}}
    {{- end -}}
  {{- end }}
initdb:
  secret:
    name: {{ printf "%s-user" $cnpgClusterName }}
  database: {{ $objectData.database }}
  owner: {{ $objectData.user }}
  {{- range $k, $v := $initDB }}
    {{ $key }}: {{ $val | quote }}
  {{- end -}}

  {{- $postInitApplicationSQL := $objectData.initdb.postInitApplicationSQL -}}
  {{- if eq $objectData.type "postgis" -}}
    {{- $postInitApplicationSQL = concat $postInitApplicationSQL (list
      "CREATE EXTENSION IF NOT EXISTS postgis;"
      "CREATE EXTENSION IF NOT EXISTS postgis_topology;"
      "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;"
      "CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;") -}}
  {{- end -}}

  {{- if eq $objectData.type "timescaledb" -}}
    {{- $postInitApplicationSQL = concat $postInitApplicationSQL (list
      "CREATE EXTENSION IF NOT EXISTS timescaledb;") -}}
  {{- end -}}

  {{- if $postInitApplicationSQL }}
  postInitApplicationSQL:
    {{- range $v := $postInitApplicationSQL }}
    - {{ $v }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "tc.v1.common.lib.cnpg.cluster.bootstrap.recovery" }}
  {{- $objectData := .objectData -}}
  {{- $cnpgClusterName := (include "tc.v1.common.lib.cnpg.clusterName" (dict "objectData" $objectData)) -}}
  {{- include "tc.v1.common.lib.cnpg.cluster.recovery.validation" (dict "objectData" $objectData) }}
recovery:
  secret:
    name: {{ printf "%s-user" $cnpgClusterName }}
  database: {{ $objectData.database }}
  owner: {{ $objectData.user }}
  {{- if $objectData.recovery.pitrTarget -}}
    {{- with $objectData.recovery.pitrTarget.time }}
  recoveryTarget:
    targetTime: {{ . }}
    {{- end -}}
  {{- end -}}
  {{- if eq $objectData.recovery.method "backup" -}}
  backup:
    name: {{ $objectData.recovery.backupName }}
  {{- end -}}
  {{- if eq $objectData.recovery.method "object_store" -}}
  source: objectStoreRecoveryCluster
  {{- end -}}
{{- end -}}

{{- define "tc.v1.common.lib.cnpg.cluster.bootstrap.recovery.externalCluster" }}
  {{- $objectData := .objectData -}}
  {{- $cnpgClusterName := (include "tc.v1.common.lib.cnpg.clusterName" (dict "objectData" $objectData)) -}}

  {{- if eq $objectData.recovery.method "object_store" }}
externalClusters:
  - name: objectStoreRecoveryCluster
    barmanObjectStore:
      serverName: {{ $objectData.recovery.serverName }}
      {{- $data := dict "chartFullname" $cnpgClusterName "scope" $objectData.recovery "secretSuffix" "-recovery" -}}
      {{- include "tc.v1.common.lib.cnpg.cluster.barmanObjectStoreConfig" $data | nindent 6 }}
  {{- end -}}
{{- end -}}