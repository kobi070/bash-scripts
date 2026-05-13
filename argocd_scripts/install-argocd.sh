#!/bin/bash

# Function to prompt user for installation choice
function prompt_installation_choice() {
    if [ -n "$1" ]; then
        return "$1"
    fi
    echo "Choose installation option:"
    echo "1. Install/Reinstall all components (ArgoCD)"
    echo "2. Validate / Show access to ArgoCD"
    read -rp "Enter your choice (1 or 2): " choice
    return "$choice"
}

# Function to run a command with retries
function run_command() {
    local description=$1
    shift
    local retries=3
    local sleep_duration=10

    for ((i=1; i<=retries; i++)); do
        echo "Running: $description (Attempt $i of $retries)"
        if "$@"; then
            return 0
        fi
        echo "Retry $i of $retries failed. Retrying in $sleep_duration seconds..."
        sleep $sleep_duration
    done

    echo "Error: $description failed after $retries attempts."
    exit 1
}

# Function to check if all pods are running
check_pods() {
  PODSLABEL=$1
  NAMESPACE=$2
  DESCRIPTION=$3

  local retries=5
  local count=0

  while [ $count -lt $retries ]; do
    echo "Checking $DESCRIPTION ... Attempt $((count+1)) of $retries"

    # Get the status of all pods in the namespace
    pods_status=$(kubectl get pods -n $NAMESPACE -l $PODSLABEL -o jsonpath="{.items[*].status.phase}")

    # Check if all pods are running
    if [[ "$pods_status" == *"Pending"* ]] || [[ "$pods_status" == *"Failed"* ]] || [[ "$pods_status" == *"Unknown"* ]]; then
      echo "Some pods are not in Running state yet. Waiting..."
      sleep 10
    else
      echo "All pods are in Running state."
      return 0
    fi

    count=$((count + 1))
  done

  echo "Some pods are still not in Running state after $retries attempts."
  return 1
}

function create_namespace () {
    local namespace=$1
    local description=$2
    run_command "$description" kubectl create namespace "$namespace" || {
        # If it failed, check if it was because it already exists
        if kubectl get namespace "$namespace" &> /dev/null; then
            echo "Namespace '$namespace' already exists - skipping"
            return 0
        fi
        return 1
    }
}

# Function to install ArgoCD
function install_argoCD() {
    echo "Installing ArgoCD..."
    run_command "Downloading ArgoCD binary" curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    run_command "Add ArgoCD to bin folder" sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    run_command "Removing tar file" rm argocd-linux-amd64
    create_namespace "argocd" "Creating ArgoCD namespace"
    run_command "Applying ArgoCD manifest" kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    run_command "Patch svc/argocd-server to type LB" kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
}

# Function to validate installation and output endpoints
function validate_installation() {
    echo "Validating ArgoCD installation..."
    check_pods "app.kubernetes.io/part-of=argocd" "argocd" "Checking ArgoCD PODS Status"
    ingress_ip=$(kubectl get svc/argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    # if ingress_ip is empty retry check after 5 seconds for 3 times and update the user on the process status
    if [ -z "$ingress_ip" ]; then
        for i in {1..3}; do
            echo "Waiting for ArgoCD Ingress Gateway IP... retry $i/3"
            sleep 5
            ingress_ip=$(kubectl get svc/argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
            if [ ! -z "$ingress_ip" ]; then
                break
            fi
        done
        #   if Loop ends and ingress_ip is still empty, then update the user on the process status
        if [ -z "$ingress_ip" ]; then
            echo "ArgoCD LB not found yet - please run the command again manually to get the IP."
            echo "kubectl get svc/argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
        else
            echo "ArgoCD LB Addr: $ingress_ip"
        fi
    fi

    # Get ArgoCD Password
    echo "Access the following URL for ArgoCD:"
    echo "ArgoCD: https://$ingress_ip/"
    echo "Getting ArgoCD initial admin Password"
    PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d; echo)
    # if PASSWORD is empty or not found retry check after 5 seconds for 3 times and update the user on the process status
    if [ -z "$PASSWORD" ]; then
        for i in {1..3}; do
            echo "Waiting for ArgoCD Password... retry $i/3"
            sleep 5
            PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d; echo)
            if [ ! -z "$PASSWORD" ]; then
                echo "Password retrived successfully"
            fi
        done
        #   if Loop ends and PASSWORD is still empty, then update the user on the process status
        if [ -z "$PASSWORD" ]; then
            echo "ArgoCD Password not found yet - please run the command again manually to get the Password."
            echo "kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d; echo"
        fi
    fi
    echo "USER: admin"
    if [ -t 1 ]; then
        echo "PASSWORD: $PASSWORD"
    else
        echo "WARNING: Non-interactive terminal detected. Password hidden for security."
        echo "To retrieve the password, run: kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d; echo"
    fi
}

# Main script execution
prompt_installation_choice "$1"
choice=$?

if [ "$choice" -eq 1 ]; then
    install_argoCD
    validate_installation
elif [ "$choice" -eq 2 ]; then
    validate_installation
else
    echo "Invalid choice. Exiting."
    exit 1
fi
