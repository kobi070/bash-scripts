#!/bin/bash

# Script to check whether ArgoCD application(s) are Degraded and list which
# resources/services are degraded (or any non-Healthy state with --show-all).
# Useful for CI gates and monitoring: exits 1 when degraded resources are found
# (use --warn-only to always exit 0 and only print warnings).
#
# Usage: ./argocd_app_degraded.sh <app_name> [options]
#        ./argocd_app_degraded.sh --all [options]
# Options:
#   --all        Check every application visible to the current ArgoCD user
#   --show-all   Report every non-Healthy state (Degraded, Missing, Progressing,
#                Unknown, Suspended) instead of only Degraded
#   --warn-only  Always exit 0; unhealthy findings are printed as warnings
#   --json       Output results as JSON instead of a table
#   -h, --help   Show this help
#
# Exit codes:
#   0 - all checked apps healthy (or --warn-only given)
#   1 - at least one degraded/unhealthy resource or app found
#   2 - usage error / missing tools
#
# Example: ./argocd_app_degraded.sh my-app
# Example: ./argocd_app_degraded.sh --all --show-all --json
# Example (CI, non-blocking): ./argocd_app_degraded.sh my-app --warn-only

set -euo pipefail

usage() {
    echo "Usage: $0 <app_name> [options]"
    echo "       $0 --all [options]"
    echo ""
    echo "Options:"
    echo "  --all        Check all ArgoCD applications"
    echo "  --show-all   Report all non-Healthy states, not only Degraded"
    echo "  --warn-only  Always exit 0 (print warnings instead of failing)"
    echo "  --json       JSON output"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Exit codes: 0 healthy, 1 unhealthy found, 2 usage/tool error"
    exit 2
}

APP_NAME=""
ALL_APPS=false
SHOW_ALL=false
WARN_ONLY=false
JSON_OUT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        --all) ALL_APPS=true ;;
        --show-all) SHOW_ALL=true ;;
        --warn-only) WARN_ONLY=true ;;
        --json) JSON_OUT=true ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            usage
            ;;
        *)
            if [[ -n "$APP_NAME" ]]; then
                echo "Error: Only one app name is supported (use --all for all apps)." >&2
                usage
            fi
            APP_NAME=$1
            ;;
    esac
    shift
done

if [[ "$ALL_APPS" == false && -z "$APP_NAME" ]]; then
    echo "Error: Provide an app name or --all." >&2
    usage
fi
if [[ "$ALL_APPS" == true && -n "$APP_NAME" ]]; then
    echo "Error: Use either an app name or --all, not both." >&2
    usage
fi

# Check for required tools
for tool in argocd jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: '$tool' is not installed or not in PATH." >&2
        exit 2
    fi
done

# Check if authenticated or if ARGOCD_AUTH_TOKEN is set
if ! argocd account get-user-info &> /dev/null; then
    if [ -z "${ARGOCD_AUTH_TOKEN:-}" ] && [ -z "${ARGOCD_OPTS:-}" ]; then
        echo "Warning: Not logged into ArgoCD. Ensure ARGOCD_AUTH_TOKEN or ARGOCD_OPTS is set, or run 'argocd login'." >&2
    fi
fi

# jq filter for which health states count as "unhealthy"
if [[ "$SHOW_ALL" == true ]]; then
    HEALTH_FILTER='.health.status != null and .health.status != "Healthy"'
else
    HEALTH_FILTER='.health.status == "Degraded"'
fi

# Collect findings as JSON array of per-app objects
RESULTS="[]"
UNHEALTHY_FOUND=false

check_app() {
    local app=$1
    local app_json app_health unhealthy_resources

    if ! app_json=$(argocd app get "$app" -o json 2>&1); then
        echo "Error: failed to get app '$app': $app_json" >&2
        exit 2
    fi

    app_health=$(echo "$app_json" | jq -r '.status.health.status // "Unknown"')
    unhealthy_resources=$(echo "$app_json" | jq --arg mode "$SHOW_ALL" \
        "[.status.resources[]? | select($HEALTH_FILTER) | {
            kind: .kind,
            namespace: (.namespace // \"-\"),
            name: .name,
            health: .health.status,
            message: (.health.message // \"\")
        }]")

    local count
    count=$(echo "$unhealthy_resources" | jq 'length')
    local app_unhealthy=false
    if [[ "$count" -gt 0 ]]; then
        app_unhealthy=true
    elif [[ "$SHOW_ALL" == true && "$app_health" != "Healthy" ]]; then
        app_unhealthy=true
    elif [[ "$SHOW_ALL" == false && "$app_health" == "Degraded" ]]; then
        app_unhealthy=true
    fi

    if [[ "$app_unhealthy" == true ]]; then
        UNHEALTHY_FOUND=true
    fi

    RESULTS=$(echo "$RESULTS" | jq \
        --arg app "$app" \
        --arg health "$app_health" \
        --argjson res "$unhealthy_resources" \
        '. + [{app: $app, appHealth: $health, degraded: $res}]')
}

if [[ "$ALL_APPS" == true ]]; then
    APP_LIST=$(argocd app list -o name 2>/dev/null)
    if [[ -z "$APP_LIST" ]]; then
        echo "No ArgoCD applications found." >&2
        exit 0
    fi
    while IFS= read -r app; do
        [[ -z "$app" ]] && continue
        check_app "$app"
    done <<< "$APP_LIST"
else
    check_app "$APP_NAME"
fi

# Output
if [[ "$JSON_OUT" == true ]]; then
    echo "$RESULTS" | jq .
else
    if [[ "$UNHEALTHY_FOUND" == false ]]; then
        if [[ "$SHOW_ALL" == true ]]; then
            echo "OK: All checked applications are Healthy."
        else
            echo "OK: No Degraded applications or resources found."
        fi
    else
        echo "$RESULTS" | jq -r '
            .[] | select((.degraded | length) > 0 or .appHealth != "Healthy") |
            "App: \(.app)  (health: \(.appHealth))",
            (if (.degraded | length) > 0 then
                (["KIND","NAMESPACE","NAME","HEALTH","MESSAGE"],
                 (.degraded[] | [.kind, .namespace, .name, .health, .message]))
                | @tsv
            else
                "  (no resource-level details; app-level health is \(.appHealth))"
            end),
            ""
        ' | column -t -s $'\t'
    fi
fi

if [[ "$UNHEALTHY_FOUND" == true ]]; then
    if [[ "$WARN_ONLY" == true ]]; then
        echo "Warning: unhealthy resources found (exiting 0 due to --warn-only)." >&2
        exit 0
    fi
    exit 1
fi
exit 0
