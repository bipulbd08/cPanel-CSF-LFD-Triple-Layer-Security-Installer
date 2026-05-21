# cPanel CSF/LFD Triple-Layer Security Shield

An automated, one-click server administration script designed to inject advanced, lightweight security layers directly into the ConfigServer Security & Firewall (CSF/LFD) custom regex matching engine on cPanel/AlmaLinux environments.

Developed by **Jobair Alam Bipul** (cPanel Certified Server Administrator & Imunify360 Security Expert).

---

## ⚠️ Disclaimer
**USE AT YOUR OWN RISK.** This script modifies low-level system firewall rules and regex filtering arrays. Always test the deployment in a staging environment before running it on a production server cluster. Check logs regularly to evaluate and prevent potential false positives based on your hosting clients' traffic patterns.

---

## 🛡️ What It Protects
This script shields your server at the network layer against three of the most resource-intensive web security threats hitting cPanel shared hosting nodes:

1. **WordPress XML-RPC Protective Layer (`XMLRPC`)**
   * **The Threat:** Aggressive automated botnets flooding `xmlrpc.php` to execute rapid pingback loops or login processing, quickly flattening Apache/PHP worker pools.
   * **The Defense:** Drops the connection permanently if an IP sends more than **5 hits** to this endpoint within the tracking cycle.

2. **WordPress Authentication Layer (`WPLOGIN`)**
   * **The Threat:** High-frequency dictionary attacks hitting `wp-login.php` across multiple accounts, generating excessive system load trying to process PHP login handling.
   * **The Defense:** Instantly bans any remote IP that attempts to hit a WordPress login handler more than **10 times**.

3. **Backdoor & Exploit Vulnerability Scanner Layer (`XPLSCAN`)**
   * **The Threat:** Attackers scanning web directories trying to discover uploaded malicious shells, unpatched configuration files, or script backups (e.g., `1.php`, `shell.php`, `wp-blog.php`). Even when files don't exist, rendering heavy WordPress `404 Not Found` themes destroys CPU core capacity.
   * **The Defense:** Monitors root-level scans for known vulnerability paths. If a scanner logs **5 layout errors (404s)**, the script extracts the specific file targeted, adds it as a comment, and drops the IP at the firewall layer.

---

## ⚙️ What the Automation Logic Accomplishes
When executed, the installer completes several critical backend configurations natively:
* **System Backups:** Instantly builds timestamped safety snapshots of `/etc/csf/csf.conf` and `/usr/local/csf/bin/regex.custom.pm`.
* **Path Detection:** Automatically determines whether your server runs modern EasyApache 4 log trees (`/var/log/apache2/domlogs/*/*`) or legacy frameworks, routing the `CUSTOM1_LOG` feed correctly.
* **Idempotent Cleansing:** Wipes out any previous instances of its own block markers if rerun, ensuring zero configuration bloat.
* **Warm Profile Reloads:** Injects the Perl matching arrays safely directly above the file execution terminal (`1;`) and recycles CSF/LFD to execute rules live without connection dropping.

---

## 🚀 One-Click Installation

Clone or download the installation utility to your root folder, assign execution flags, and deploy:

```bash
cd /root
wget [https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME/main/master_csf_shield.sh](https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME/main/master_csf_shield.sh)
chmod +x master_csf_shield.sh
./master_csf_shield.sh
