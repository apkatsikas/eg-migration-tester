# EG Migration Tester

Scripts for validating Envoy Gateway traffic before and during migration from nginx ingress.

## Prerequisites

### AWS SSO Login
```bash
aws sso login --profile foobar
```

### Switch to the correct cluster context

## Scripts

### test-eg.sh
One-shot request to a hostname via the EG NLB, bypassing DNS. Useful for validating
a route with weight 0 before cutover.

```bash
./test-eg.sh <hostname> [route] [creds]
```

Example:
```bash
./test-eg.sh goldilocks.pelo.tech /namespaces admin:password
```

### health-loop.sh
Continuous health check against a hostname, logging status code and response time.
Use this during cutover to monitor for errors.

```bash
./health-loop.sh <hostname> [route] [creds]
```

Example:
```bash
./health-loop.sh goldilocks.pelo.tech /namespaces admin:password
```

Logs are written to `<hostname>-health.log` in the current directory.

### verify-cutover.sh
Confirms that a hostname is resolving to the EG NLB after cutover by comparing
DNS resolution against the NLB's IPs.

```bash
./verify-cutover.sh <hostname>
```

Example:
```bash
./verify-cutover.sh goldilocks.pelo.tech
```

## Local Testing via /etc/hosts

To test in a browser or with curl before DNS cutover, temporarily point the hostname
at the EG NLB IP by adding an entry to `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

Add:
```
<nlb-ip> <hostname>
# e.g. 44.229.215.17 goldilocks.pelo.tech
```

Verify it's working:
```bash
curl -v https://<hostname> 2>&1 | grep "Connected to"
```

**Important:** Remove the entry when done — leaving it in place will prevent you
from seeing the real DNS state after cutover.

```bash
# Remove the line from /etc/hosts when finished testing
sudo nano /etc/hosts
```

Note: `verify-cutover.sh` uses `dig` which bypasses `/etc/hosts`, so it will always
reflect real DNS state regardless of local overrides.

## Migration Steps

1. Deploy ListenerSet + HTTPRoute with EG weight 0, nginx weight 100
2. Validate EG route with `test-eg.sh`
3. Start `health-loop.sh` against the live hostname (nginx traffic)
4. Flip weights: EG to 100, nginx to 0
5. Monitor `health-loop.sh` output for errors
6. Run `verify-cutover.sh` to confirm DNS is resolving to EG NLB
