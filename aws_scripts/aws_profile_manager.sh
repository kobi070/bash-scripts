#!/bin/bash

# AWS Profile Manager
# Manage AWS CLI profiles: add, edit, delete, view, list, and switch.
# Works both interactively (menu-driven) and non-interactively (CLI flags).
#
# Respects AWS_CONFIG_FILE and AWS_SHARED_CREDENTIALS_FILE for safe testing.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_FILE="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
CREDENTIALS_FILE="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"

print_header()  { echo -e "\n${BLUE}=== $1 ===${NC}\n"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error()   { echo -e "${RED}✗ $1${NC}" >&2; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

usage() {
    cat <<EOF
Usage: $0 [command] [options]

Manage AWS CLI profiles. Run with no arguments for interactive mode.

Commands:
  list                      List all profiles (marks default)
  view    -p NAME           Show profile configuration (secrets masked)
          [--json]          Output as JSON (requires jq)
          [--show-secrets]  Do not mask secret keys
  add     -p NAME           Add a new profile
          [--access-key ID --secret-key KEY]   Access key credentials
          [--sso-start-url URL --sso-region R --sso-account-id ID --sso-role-name ROLE]
          [--role-arn ARN --source-profile P]  Assume-role profile
          [--region REGION] [--output FORMAT]
          [--force]         Overwrite if profile exists
  edit    -p NAME [...]     Update only the given keys (same options as add)
  delete  -p NAME [--yes]   Delete a profile (backs up files first)
  switch  -p NAME           Switch active profile
          [--persist]       Copy profile into [default] (default behavior)
          [--env]           Print 'export AWS_PROFILE=NAME' for eval/source
          [--validate]      Verify with 'aws sts get-caller-identity'
  interactive               Launch interactive menu (same as no arguments)
  -h, --help                Show this help

Examples:
  $0 list
  $0 add -p dev --access-key AKIA... --secret-key xxx --region us-east-1
  $0 add -p prod --role-arn arn:aws:iam::123456789012:role/Admin --source-profile dev
  $0 switch -p dev --validate
  eval "\$($0 switch -p dev --env)"
  $0 delete -p old-profile --yes
EOF
    exit "${1:-0}"
}

check_tools() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed or not in PATH."
        echo "Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
}

# ---------- helpers ----------

# List profile names, one per line.
get_profiles() {
    if aws configure list-profiles &> /dev/null; then
        aws configure list-profiles
    else
        # Fallback for AWS CLI v1: parse section headers
        {
            [[ -f "$CONFIG_FILE" ]] && sed -n 's/^\[profile \(.*\)\]$/\1/p; s/^\[\(default\)\]$/\1/p' "$CONFIG_FILE"
            [[ -f "$CREDENTIALS_FILE" ]] && sed -n 's/^\[\(.*\)\]$/\1/p' "$CREDENTIALS_FILE"
        } | sort -u
    fi
}

profile_exists() {
    get_profiles | grep -qx "$1"
}

# Mask a secret: show first 4 and last 4 chars.
mask_secret() {
    local s="$1"
    if [[ ${#s} -le 8 ]]; then
        echo "****"
    else
        echo "${s:0:4}****${s: -4}"
    fi
}

# Read a config value for a profile; empty if unset.
get_value() {
    local profile="$1" key="$2"
    aws configure get "$key" --profile "$profile" 2>/dev/null || true
}

set_value() {
    local profile="$1" key="$2" value="$3"
    aws configure set "$key" "$value" --profile "$profile"
}

backup_files() {
    local ts
    ts=$(date +%Y%m%d%H%M%S)
    local f
    for f in "$CONFIG_FILE" "$CREDENTIALS_FILE"; do
        if [[ -f "$f" ]]; then
            cp "$f" "${f}.bak.${ts}"
        fi
    done
    print_success "Backed up config files (suffix .bak.${ts})"
}

require_profile_arg() {
    if [[ -z "$PROFILE" ]]; then
        print_error "Profile name required (-p NAME)."
        exit 1
    fi
}

validate_profile() {
    local profile="$1"
    print_header "Validating profile '$profile'"
    if aws sts get-caller-identity --profile "$profile" --output text 2>/dev/null; then
        print_success "Profile '$profile' is valid."
    else
        print_error "Validation failed for profile '$profile'."
        return 1
    fi
}

# ---------- commands ----------

PROFILE_KEYS=(aws_access_key_id aws_secret_access_key region output \
    sso_start_url sso_region sso_account_id sso_role_name role_arn source_profile)

cmd_list() {
    print_header "AWS Profiles"
    local profiles current
    profiles=$(get_profiles)
    if [[ -z "$profiles" ]]; then
        print_warning "No profiles configured."
        return 0
    fi
    current="${AWS_PROFILE:-default}"
    while IFS= read -r p; do
        local marker=" "
        [[ "$p" == "$current" ]] && marker="*"
        local region
        region=$(get_value "$p" region)
        printf " %s %-25s %s\n" "$marker" "$p" "${region:+(region: $region)}"
    done <<< "$profiles"
    echo ""
    echo "  * = active profile (AWS_PROFILE or default)"
}

cmd_view() {
    require_profile_arg
    if ! profile_exists "$PROFILE"; then
        print_error "Profile '$PROFILE' does not exist."
        exit 1
    fi

    local key value
    if [[ "$JSON_OUTPUT" == true ]]; then
        if ! command -v jq &> /dev/null; then
            print_error "jq is required for --json output."
            exit 1
        fi
        local json="{}"
        for key in "${PROFILE_KEYS[@]}"; do
            value=$(get_value "$PROFILE" "$key")
            [[ -z "$value" ]] && continue
            if [[ "$SHOW_SECRETS" != true && "$key" == "aws_secret_access_key" ]]; then
                value=$(mask_secret "$value")
            elif [[ "$SHOW_SECRETS" != true && "$key" == "aws_access_key_id" ]]; then
                value=$(mask_secret "$value")
            fi
            json=$(jq --arg k "$key" --arg v "$value" '. + {($k): $v}' <<< "$json")
        done
        jq --arg p "$PROFILE" '{profile: $p, config: .}' <<< "$json"
    else
        print_header "Profile: $PROFILE"
        for key in "${PROFILE_KEYS[@]}"; do
            value=$(get_value "$PROFILE" "$key")
            [[ -z "$value" ]] && continue
            if [[ "$SHOW_SECRETS" != true && ( "$key" == "aws_secret_access_key" || "$key" == "aws_access_key_id" ) ]]; then
                value=$(mask_secret "$value")
            fi
            printf "  %-22s = %s\n" "$key" "$value"
        done
    fi
}

# Apply any provided key options to a profile.
apply_key_options() {
    local profile="$1"
    [[ -n "$ACCESS_KEY" ]]      && set_value "$profile" aws_access_key_id "$ACCESS_KEY"
    [[ -n "$SECRET_KEY" ]]      && set_value "$profile" aws_secret_access_key "$SECRET_KEY"
    [[ -n "$REGION" ]]          && set_value "$profile" region "$REGION"
    [[ -n "$OUTPUT" ]]          && set_value "$profile" output "$OUTPUT"
    [[ -n "$SSO_START_URL" ]]   && set_value "$profile" sso_start_url "$SSO_START_URL"
    [[ -n "$SSO_REGION" ]]      && set_value "$profile" sso_region "$SSO_REGION"
    [[ -n "$SSO_ACCOUNT_ID" ]]  && set_value "$profile" sso_account_id "$SSO_ACCOUNT_ID"
    [[ -n "$SSO_ROLE_NAME" ]]   && set_value "$profile" sso_role_name "$SSO_ROLE_NAME"
    [[ -n "$ROLE_ARN" ]]        && set_value "$profile" role_arn "$ROLE_ARN"
    [[ -n "$SOURCE_PROFILE" ]]  && set_value "$profile" source_profile "$SOURCE_PROFILE"
    return 0
}

any_key_option_given() {
    [[ -n "$ACCESS_KEY$SECRET_KEY$REGION$OUTPUT$SSO_START_URL$SSO_REGION$SSO_ACCOUNT_ID$SSO_ROLE_NAME$ROLE_ARN$SOURCE_PROFILE" ]]
}

prompt_profile_values() {
    echo "Leave any field empty to skip it."
    read -rp "AWS Access Key ID: " ACCESS_KEY
    if [[ -n "$ACCESS_KEY" ]]; then
        read -rsp "AWS Secret Access Key: " SECRET_KEY
        echo ""
    fi
    read -rp "Region (e.g. us-east-1): " REGION
    read -rp "Output format (json/table/text): " OUTPUT
    read -rp "Role ARN (for assume-role profile): " ROLE_ARN
    if [[ -n "$ROLE_ARN" ]]; then
        read -rp "Source profile: " SOURCE_PROFILE
    fi
    read -rp "SSO start URL (for SSO profile): " SSO_START_URL
    if [[ -n "$SSO_START_URL" ]]; then
        read -rp "SSO region: " SSO_REGION
        read -rp "SSO account ID: " SSO_ACCOUNT_ID
        read -rp "SSO role name: " SSO_ROLE_NAME
    fi
}

cmd_add() {
    require_profile_arg
    if profile_exists "$PROFILE" && [[ "$FORCE" != true ]]; then
        print_error "Profile '$PROFILE' already exists. Use 'edit' or add --force."
        exit 1
    fi
    if ! any_key_option_given; then
        if [[ "$INTERACTIVE" == true ]]; then
            prompt_profile_values
        else
            print_error "No configuration options provided. See --help."
            exit 1
        fi
    fi
    if ! any_key_option_given; then
        print_error "Nothing to configure for profile '$PROFILE'."
        exit 1
    fi
    apply_key_options "$PROFILE"
    print_success "Profile '$PROFILE' added."
    if [[ "$VALIDATE" == true ]]; then
        validate_profile "$PROFILE"
    fi
}

cmd_edit() {
    require_profile_arg
    if ! profile_exists "$PROFILE"; then
        print_error "Profile '$PROFILE' does not exist. Use 'add' to create it."
        exit 1
    fi
    if ! any_key_option_given; then
        if [[ "$INTERACTIVE" == true ]]; then
            prompt_profile_values
        else
            print_error "No options to update provided. See --help."
            exit 1
        fi
    fi
    if ! any_key_option_given; then
        print_warning "Nothing to update for profile '$PROFILE'."
        return 0
    fi
    backup_files
    apply_key_options "$PROFILE"
    print_success "Profile '$PROFILE' updated."
}

# Remove a section from an INI-style file.
# Args: file, section header (e.g. "profile dev" or "dev")
remove_ini_section() {
    local file="$1" section="$2"
    [[ -f "$file" ]] || return 0
    awk -v section="[$section]" '
        $0 == section { skip = 1; next }
        /^\[/ { skip = 0 }
        !skip { print }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

cmd_delete() {
    require_profile_arg
    if ! profile_exists "$PROFILE"; then
        print_error "Profile '$PROFILE' does not exist."
        exit 1
    fi
    if [[ "$PROFILE" == "default" ]]; then
        print_warning "You are deleting the 'default' profile."
    fi
    if [[ "$ASSUME_YES" != true ]]; then
        if [[ "$INTERACTIVE" == true || -t 0 ]]; then
            read -rp "Delete profile '$PROFILE'? [y/N]: " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                print_warning "Aborted."
                return 0
            fi
        else
            print_error "Refusing to delete non-interactively without --yes."
            exit 1
        fi
    fi
    backup_files
    if [[ "$PROFILE" == "default" ]]; then
        remove_ini_section "$CONFIG_FILE" "default"
    else
        remove_ini_section "$CONFIG_FILE" "profile $PROFILE"
        remove_ini_section "$CONFIG_FILE" "$PROFILE"
    fi
    remove_ini_section "$CREDENTIALS_FILE" "$PROFILE"
    print_success "Profile '$PROFILE' deleted."
}

cmd_switch() {
    require_profile_arg
    if ! profile_exists "$PROFILE"; then
        print_error "Profile '$PROFILE' does not exist."
        exit 1
    fi

    if [[ "$ENV_MODE" == true ]]; then
        # Only the export line goes to stdout so eval works cleanly.
        echo "export AWS_PROFILE=$PROFILE"
    else
        backup_files
        local key value
        for key in "${PROFILE_KEYS[@]}"; do
            value=$(get_value "$PROFILE" "$key")
            if [[ -n "$value" ]]; then
                set_value default "$key" "$value"
            fi
        done
        print_success "Profile '$PROFILE' copied to [default]. It is now the active default."
        print_warning "For session-only switching, use: eval \"\$($0 switch -p $PROFILE --env)\""
    fi

    if [[ "$VALIDATE" == true ]]; then
        validate_profile "$PROFILE"
    fi
}

# ---------- interactive mode ----------

# Prompt user to pick a profile by number; sets PROFILE.
select_profile() {
    local profiles=()
    while IFS= read -r p; do
        profiles+=("$p")
    done < <(get_profiles)
    if [[ ${#profiles[@]} -eq 0 ]]; then
        print_warning "No profiles configured."
        return 1
    fi
    echo ""
    local i
    for i in "${!profiles[@]}"; do
        printf "  %2d) %s\n" "$((i + 1))" "${profiles[$i]}"
    done
    local choice
    read -rp "Select profile [1-${#profiles[@]}]: " choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#profiles[@]} )); then
        print_error "Invalid selection."
        return 1
    fi
    PROFILE="${profiles[$((choice - 1))]}"
}

reset_options() {
    PROFILE="" ACCESS_KEY="" SECRET_KEY="" REGION="" OUTPUT=""
    SSO_START_URL="" SSO_REGION="" SSO_ACCOUNT_ID="" SSO_ROLE_NAME=""
    ROLE_ARN="" SOURCE_PROFILE=""
    FORCE=false ASSUME_YES=false JSON_OUTPUT=false SHOW_SECRETS=false
    ENV_MODE=false VALIDATE=false
}

interactive_menu() {
    INTERACTIVE=true
    print_header "AWS Profile Manager"
    while true; do
        echo ""
        echo "  1) List profiles"
        echo "  2) View profile"
        echo "  3) Add profile"
        echo "  4) Edit profile"
        echo "  5) Delete profile"
        echo "  6) Switch profile"
        echo "  7) Quit"
        local choice
        read -rp "Choose an option [1-7]: " choice
        reset_options
        case "$choice" in
            1) cmd_list ;;
            2) select_profile && cmd_view ;;
            3)
                read -rp "New profile name: " PROFILE
                if [[ -n "$PROFILE" ]]; then cmd_add; else print_error "Profile name required."; fi
                ;;
            4) select_profile && cmd_edit ;;
            5) select_profile && cmd_delete ;;
            6)
                if select_profile; then
                    local mode
                    read -rp "Switch mode - persist to [default] or print env export? [P/e]: " mode
                    [[ "$mode" =~ ^[Ee]$ ]] && ENV_MODE=true
                    cmd_switch
                fi
                ;;
            7) echo "Bye."; break ;;
            *) print_error "Invalid option." ;;
        esac
    done
}

# ---------- main ----------

main() {
    check_tools

    INTERACTIVE=false
    reset_options
    local command=""

    if [[ $# -eq 0 ]]; then
        interactive_menu
        return 0
    fi

    command="$1"
    shift

    case "$command" in
        -h|--help) usage 0 ;;
        interactive) interactive_menu; return 0 ;;
        list|view|add|edit|delete|switch) ;;
        *)
            print_error "Unknown command: $command"
            usage 1
            ;;
    esac

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--profile)     PROFILE="$2"; shift 2 ;;
            --access-key)     ACCESS_KEY="$2"; shift 2 ;;
            --secret-key)     SECRET_KEY="$2"; shift 2 ;;
            --region)         REGION="$2"; shift 2 ;;
            --output)         OUTPUT="$2"; shift 2 ;;
            --sso-start-url)  SSO_START_URL="$2"; shift 2 ;;
            --sso-region)     SSO_REGION="$2"; shift 2 ;;
            --sso-account-id) SSO_ACCOUNT_ID="$2"; shift 2 ;;
            --sso-role-name)  SSO_ROLE_NAME="$2"; shift 2 ;;
            --role-arn)       ROLE_ARN="$2"; shift 2 ;;
            --source-profile) SOURCE_PROFILE="$2"; shift 2 ;;
            --force)          FORCE=true; shift ;;
            --yes)            ASSUME_YES=true; shift ;;
            --json)           JSON_OUTPUT=true; shift ;;
            --show-secrets)   SHOW_SECRETS=true; shift ;;
            --env)            ENV_MODE=true; shift ;;
            --persist)        ENV_MODE=false; shift ;;
            --validate)       VALIDATE=true; shift ;;
            -h|--help)        usage 0 ;;
            *)
                print_error "Unknown option: $1"
                usage 1
                ;;
        esac
    done

    case "$command" in
        list)   cmd_list ;;
        view)   cmd_view ;;
        add)    cmd_add ;;
        edit)   cmd_edit ;;
        delete) cmd_delete ;;
        switch) cmd_switch ;;
    esac
}

main "$@"
