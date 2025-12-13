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

# combine certs into one file to ensure they belong to the same pairing
template {
    destination = "/app/certs/siege-leviathan.pem"
    contents = <<EOH
{{- with secret "pki/issue/siege-leviathan-role" "common_name=siege-leviathan" "ttl=24h" -}}
{{ .Data.certificate }}
{{ .Data.private_key }}
{{ .Data.issuing_ca }}
{{- end -}}
EOH
}



