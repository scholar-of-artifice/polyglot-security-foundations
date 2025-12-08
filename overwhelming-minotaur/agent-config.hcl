# define where the Vault server is
vault {
    address = "http://vault:8200"
}

# define how to authenticate (Auto-Auth)
auto_auth {
    method "approle" {
        mount_path = "auth/approle"
        config = {
            # the agent reads these files from the container's file system
            role_id_file_path = "/app/secrets/role_id"
            secret_id_file_path = "/app/secrets/secret_id"
            remove_secret_id_file_after_reading = true
        }
    }
    # store the token in a temporary file once logged in
    sink "file" {
        config = {
            path = "/app/secrets/vault_token"
        }
    }
}

# define the template
# this queries the pki engine and formats the output into files

# verify the app will have the Root CA
template {
    destination = "/app/certs/ca.crt"
    contents = <<EOH
{{- with secret "pki/issue/overwhelming-minotaur-role" "common_name=overwhelming-minotaur" -}}
{{ .Data.issuing_ca }}
{{- end -}}
EOH
}

# query the pki engine and formats the output into files
template {
    destination = "/app/certs/overwhelming-minotaur.crt"
    contents = <<EOH
{{- with secret "pki/issue/overwhelming-minotaur-role" "common_name=overwhelming-minotaur" "ttl=24h" -}}
{{ .Data.certificate }}
{{ .Data.issuing_ca }}
{{- end -}}
EOH
}

template {
    destination = "/app/certs/overwhelming-minotaur.key"
    contents = <<EOH
{{- with secret "pki/issue/overwhelming-minotaur-role" "common_name=overwhelming-minotaur" "ttl=24h" -}}
{{ .Data.private_key }}
{{- end -}}
EOH
}

