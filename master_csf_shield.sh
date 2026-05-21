#!/bin/bash

# ====================================================================================
# Script Name : cPanel CSF/LFD Triple-Layer Security Installer
# Created By  : Jobair Alam Bipul
# Version     : 1.3
# Disclaimer  : USE AT YOUR OWN RISK. This script modifies low-level firewall 
#               configurations. Always test on a staging server first.
#
# WHAT THIS SCRIPT DOES:
# 1. Backs up /etc/csf/csf.conf and /usr/local/csf/bin/regex.custom.pm with timestamps.
# 2. Automatically detects and configures the correct cPanel Apache domlogs path.
# 3. Removes old instances of the shield to prevent duplicate configuration bloat.
# 4. Injects a custom Perl regex matching engine directly above the file closing marker.
# 5. Restarts CSF and LFD automatically to apply the changes smoothly.
#
# WHAT IS PROTECTED:
# - Layer 1 [XMLRPC]: Blocks IPs aggressively flooding xmlrpc.php (Limit: 5 hits).
# - Layer 2 [WPLOGIN]: Blocks IPs performing brute-force login attacks (Limit: 10 hits).
# - Layer 3 [XPLSCAN]: Blocks automated vulnerability bots fishing for common root 
#   backdoors (e.g., shell.php, 1.php, wp-blog.php) that generate 404 errors (Limit: 5 hits).
#   It dynamically extracts the targeted filename and logs it with the ban comment.
# ====================================================================================

# Configuration Paths
CSF_CONF="/etc/csf/csf.conf"
REGEX_PM="/usr/local/csf/bin/regex.custom.pm"

clear
echo "====================================================================="
echo "       cPanel CSF/LFD Triple-Layer Security Installer                "
echo "       Developed by: Jobair Alam Bipul                               "
echo "====================================================================="
echo " [!] DISCLAIMER: Use at your own risk!"
echo " [!] This script modifies low-level firewall configurations."
echo " [!] Monitor /var/log/lfd.log closely for any false positives."
echo "====================================================================="
echo ""
echo "[-] What is protected by this shield:"
echo "    -> Layer 1: WP XML-RPC Floods (Max 5 hits)"
echo "    -> Layer 2: WP Brute-Force Login Attacks (Max 10 hits)"
echo "    -> Layer 3: Root Exploit & Backdoor Scanners (Max 5 hits)"
echo "                (Logs the exact file they tried to guess)"
echo "====================================================================="
echo ""

# 1. Verify CSF is installed on the machine
if [ ! -f "$CSF_CONF" ] || [ ! -f "$REGEX_PM" ]; then
    echo "[!] Error: CSF/LFD does not appear to be installed on this server."
    echo "[!] Please install ConfigServer Security & Firewall before running this script."
    exit 1
fi

# 2. Create timestamped backups for safety
echo "[+] Creating configuration backups..."
cp "$CSF_CONF" "${CSF_CONF}.bak_master_$(date +%F_%H%M%S)"
cp "$REGEX_PM" "${REGEX_PM}.bak_master_$(date +%F_%H%M%S)"

# 3. Detect and configure the correct cPanel log path
echo "[+] Configuring custom log path tracking..."
sed -i '/^CUSTOM1_LOG =/d' "$CSF_CONF"

if [ -d "/var/log/apache2/domlogs" ]; then
    # EA4 / Modern cPanel path
    echo 'CUSTOM1_LOG = "/var/log/apache2/domlogs/*/*"' >> "$CSF_CONF"
    echo "    -> Set to: /var/log/apache2/domlogs/*/*"
else
    # Legacy / Alternative path fallback
    echo 'CUSTOM1_LOG = "/usr/local/apache/domlogs/*/*"' >> "$CSF_CONF"
    echo "    -> Set to: /usr/local/apache/domlogs/*/*"
fi

# 4. Strip out any old or partial instances of the shield to prevent duplicate bloat
sed -i '/# START_WP_SHIELD/,/# END_WP_SHIELD/d' "$REGEX_PM"

# 5. Build the complete three-tier rule block
read -r -d '' MASTER_SHIELD << 'EOF'
# START_WP_SHIELD
# CUSTOM SHIELD: Block IP if hitting XML-RPC aggressively
if (($globlogs{CUSTOM1_LOG}{$lgfile}) and ($line =~ /(\S+).*] "\w*(?: GET|POST) \/xmlrpc\.php[^"]*" \d+/)) {
    return ("WP XMLRPC Attack Blocked",$1,"XMLRPC","5","80,443","1");
}

# CUSTOM SHIELD: Block IP if hitting WP-LOGIN aggressively
if (($globlogs{CUSTOM1_LOG}{$lgfile}) and ($line =~ /(\S+).*] "\w*(?: GET|POST) \/wp-login\.php[^"]*" \d+/)) {
    return ("WP Login Attack Blocked",$1,"WPLOGIN","10","80,443","1");
}

# CUSTOM SHIELD: Block explicit root backdoor scanning & show the malicious file in logs
if (($globlogs{CUSTOM1_LOG}{$lgfile}) and ($line =~ /(\S+).*] "\w* GET \/((?:1|file|php|admin|wp-blog|shell|ws|config|db|sql|index[0-9])\.php)[^"]*" 404 \d+/)) {
    return ("Exploit Scanner Blocked [File: $2]",$1,"XPLSCAN","5","80,443","1");
}
# END_WP_SHIELD
EOF

# 6. Safely inject the master block right above the Perl terminal line "1;"
echo "[+] Injecting firewall match conditions into custom regex patterns..."
sed -i "/^1;/i \\$MASTER_SHIELD\n" "$REGEX_PM"

# 7. Restart services to load everything into the active firewall engine
echo "[+] Reloading CSF Firewall profiles..."
csf -r

echo "[+] Restarting Login Failure Daemon (LFD)..."
systemctl restart lfd

echo "====================================================================="
echo " Deployment Successful! All 3 layers are now active. "
echo "====================================================================="
echo " IMPORTANT POST-INSTALLATION TASKS:"
echo " 1. Monitor live blocks: tail -f /var/log/lfd.log"
echo " 2. Check for blocks via: grep -E 'XMLRPC|WPLOGIN|XPLSCAN' /var/log/lfd.log"
echo " 3. If a legitimate user is blocked, whitelist via: csf -a [USER_IP]"
echo ""
echo " Thanks for using this script! Stay secure."
echo "====================================================================="
