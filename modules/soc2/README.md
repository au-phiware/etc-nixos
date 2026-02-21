# SOC2 Compliance Modules

These modules implement SOC2 compliance requirements for work laptops.

## Included Components

- **CrowdStrike Falcon** - Endpoint detection and response (EDR)
- **Cloudflare WARP** - Zero Trust network access
- **Microsoft Intune** - Mobile device management
- **1Password** - Password manager

## Usage

To enable on a work machine, add to your host configuration:

```nix
imports = [
  ./modules/soc2/default.nix
];

crowdstrike = {
  cid = "YOUR-CID-HERE";  # Replace with your actual CID
};
```

### Managing Secrets

The CrowdStrike CID should not be committed to git. Options for managing it:

1. **Separate secrets file** (not in git):
   ```nix
   # hosts/work-laptop.nix
   imports = [
     ./modules/soc2/default.nix
     ./secrets.nix  # Git-ignored file with CID
   ];
   ```

2. **Environment variable** during build:
   ```nix
   crowdstrike.cid = builtins.getEnv "CROWDSTRIKE_CID";
   ```

3. **Use a secrets manager** like sops-nix or agenix
