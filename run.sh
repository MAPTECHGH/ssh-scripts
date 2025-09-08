#!/bin/bash

# MAPTECH SSH Script Runner
# Developer: M-AVETCH IT SERVICES - t.me/maptechgh
# Website: https://ssh.maptechdata.com

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
API_URL="https://ssh.maptechdata.com/api"
SCRIPT_NAME="MAPTECH SSH Script Runner"
VERSION="1.0.0"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print header
print_header() {
    clear
    print_color $BLUE "╔══════════════════════════════════════════════════════════════╗"
    print_color $BLUE "║                    MAPTECH SSH SCRIPTS                       ║"
    print_color $BLUE "║                   Premium VPS Solutions                      ║"
    print_color $BLUE "║                                                              ║"
    print_color $BLUE "║               Developer: M-AVETCH IT SERVICES                ║"
    print_color $BLUE "║                  Telegram: t.me/maptechgh                    ║"
    print_color $BLUE "╚══════════════════════════════════════════════════════════════╝"
    echo
}

# Function to print loading animation
loading_animation() {
    local message=$1
    local duration=${2:-3}
    
    for i in $(seq 1 $duration); do
        echo -ne "\r${CYAN}${message}$(printf "%*s" $i | tr ' ' '.')${NC}"
        sleep 1
    done
    echo
}

# Function to validate access code format
validate_code() {
    local code=$1
    if [[ $code =~ ^[0-9]{6}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to get system info
get_system_info() {
    echo "System Information:"
    echo "  OS: $(uname -s)"
    echo "  Architecture: $(uname -m)"
    echo "  Kernel: $(uname -r)"
    if command -v lsb_release &> /dev/null; then
        echo "  Distribution: $(lsb_release -d | cut -f2)"
    fi
    echo "  Hostname: $(hostname)"
    echo "  IP Address: $(curl -s ifconfig.me 2>/dev/null || echo "Unable to detect")"
    echo
}

# Function to read input from terminal (simplified since stdin is redirected)
read_from_terminal() {
    local prompt=$1
    local input_var=$2
    
    echo -n "$prompt"
    read -r "$input_var"
}

# Main function
main() {
    print_header
    
    # Get payment reference from argument
    local reference=$1
    
    if [ -z "$reference" ]; then
        print_color $RED "❌ Error: Payment reference is required"
        echo
        print_color $YELLOW "Usage: curl -sSL https://ssh.maptechdata.com/run.sh | bash -s <PAYMENT_REFERENCE>"
        echo
        print_color $CYAN "💡 Get your payment reference from the Telegram bot after successful payment."
        exit 1
    fi
    
    print_color $GREEN "🚀 Welcome to MAPTECH SSH Script Runner v${VERSION}"
    echo
    print_color $CYAN "📋 Payment Reference: ${reference}"
    echo
    
    # Show system info
    get_system_info
    
    # Get access code from user
    local access_code=""
    local attempts=0
    local max_attempts=3
    
    while [ $attempts -lt $max_attempts ]; do
        print_color $YELLOW "🔑 Please enter your 6-digit access code:"
        print_color $CYAN "   (Get this from the Telegram bot using 'Get Access Code' button)"
        
        # Use the fixed input reading function
        read_from_terminal "   Access Code: " access_code
        
        if validate_code "$access_code"; then
            break
        else
            attempts=$((attempts + 1))
            remaining=$((max_attempts - attempts))
            
            if [ $remaining -gt 0 ]; then
                print_color $RED "❌ Invalid code format. Please enter exactly 6 digits."
                print_color $YELLOW "   Attempts remaining: ${remaining}"
                echo
            else
                print_color $RED "❌ Maximum attempts exceeded. Please try again later."
                exit 1
            fi
        fi
    done
    
    echo
    loading_animation "🔐 Verifying access code" 3
    
    # Verify access code and get script
    local temp_script=$(mktemp)
    local http_code
    
    http_code=$(curl -s -w "%{http_code}" -o "$temp_script" \
        -X GET \
        "${API_URL}/execute.php?ref=${reference}&code=${access_code}")
    
    if [ "$http_code" != "200" ]; then
        print_color $RED "❌ Access verification failed (HTTP: $http_code)"
        
        if [ -f "$temp_script" ]; then
            local error_msg=$(head -n 10 "$temp_script" | grep -o 'ERROR:.*' | head -n 1)
            if [ ! -z "$error_msg" ]; then
                print_color $RED "   Reason: ${error_msg#ERROR: }"
            fi
        fi
        
        echo
        print_color $YELLOW "💡 Possible reasons:"
        print_color $YELLOW "   • Invalid or expired access code"
        print_color $YELLOW "   • Code doesn't match your IP address"
        print_color $YELLOW "   • Payment not completed or expired"
        echo
        print_color $CYAN "🔄 Get a new access code from the Telegram bot and try again."
        
        rm -f "$temp_script"
        exit 1
    fi
    
    # Check if the response contains an error
    if grep -q "^# ERROR:" "$temp_script"; then
        local error_msg=$(grep "^# ERROR:" "$temp_script" | head -n 1 | sed 's/^# ERROR: //')
        print_color $RED "❌ Script execution failed: $error_msg"
        
        rm -f "$temp_script"
        exit 1
    fi
    
    print_color $GREEN "✅ Access code verified successfully!"
    echo
    
    # Extract script information from comments
    local script_name=$(grep "^# MAPTECH SSH Script -" "$temp_script" | sed 's/^# MAPTECH SSH Script - //' || echo "Unknown Script")
    local exec_time=$(grep "^# Executed on:" "$temp_script" | sed 's/^# Executed on: //' || echo "Unknown")
    
    print_color $CYAN "📄 Script: $script_name"
    print_color $CYAN "⏰ Execution Time: $exec_time"
    echo
    
    # Ask for confirmation using the fixed input function
    print_color $YELLOW "⚠️  You are about to execute a script on your system."
    print_color $YELLOW "   Please ensure you trust this script before proceeding."
    echo
    
    local confirm=""
    read_from_terminal "Do you want to continue? (y/N): " confirm
    
    if [[ ! $confirm =~ ^[Yy]([Ee][Ss])?$ ]]; then
        print_color $YELLOW "❌ Script execution cancelled by user."
        rm -f "$temp_script"
        exit 0
    fi
    
    echo
    loading_animation "🚀 Preparing to execute script" 2
    
    print_color $GREEN "▶️  Executing script..."
    print_color $PURPLE "════════════════════════════════════════════════════════════════"
    echo
    
    # Make script executable and run it
    chmod +x "$temp_script"
    
    # Execute the script and capture exit code
    if bash "$temp_script"; then
        local exit_code=$?
        echo
        print_color $PURPLE "════════════════════════════════════════════════════════════════"
        print_color $GREEN "✅ Script executed successfully!"
        
        # Cleanup
        rm -f "$temp_script"
        
        echo
        print_color $CYAN "🎉 Thank you for using MAPTECH SSH Scripts!"
        print_color $CYAN "💬 For support, contact us on Telegram: t.me/maptechgh"
        print_color $CYAN "🌐 Website: https://ssh.maptechdata.com"
        
        exit $exit_code
    else
        local exit_code=$?
        echo
        print_color $PURPLE "════════════════════════════════════════════════════════════════"
        print_color $RED "❌ Script execution failed with exit code: $exit_code"
        
        # Cleanup
        rm -f "$temp_script"
        
        echo
        print_color $YELLOW "💡 If you continue to experience issues:"
        print_color $YELLOW "   • Check your VPS specifications"
        print_color $YELLOW "   • Ensure you have sufficient permissions"
        print_color $YELLOW "   • Contact support on Telegram: t.me/maptechgh"
        
        exit $exit_code
    fi
}

# Handle script interruption
trap 'print_color $RED "\n❌ Script interrupted by user. Cleaning up..."; rm -f "$temp_script" 2>/dev/null; exit 130' INT TERM

# Check if running as root (recommended)
if [ "$EUID" -ne 0 ]; then
    echo
    print_color $YELLOW "⚠️  Warning: Not running as root."
    print_color $YELLOW "   Some scripts may require root privileges to function properly."
    print_color $YELLOW "   Consider running with 'sudo' if you encounter permission issues."
    echo
    sleep 2
fi

# Check internet connectivity
if ! curl -s --head --connect-timeout 5 https://ssh.maptechdata.com > /dev/null 2>&1 && \
   ! wget -q --spider --timeout=5 https://ssh.maptechdata.com > /dev/null 2>&1; then
    print_color $RED "❌ Error: Cannot connect to MAPTECH servers."
    print_color $RED "   Please check your internet connection and try again."
    exit 1
fi

# Run main function with all arguments
main "$@"
