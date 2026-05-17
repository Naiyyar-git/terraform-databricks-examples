# AWS Private Link POC — handoff from Azure lakehouse

Use this document in a **separate Cursor chat** (e.g. named `aws-privatelink`).  
Attach with: `@docs/aws-poc-handoff.md` and `@examples/aws-databricks-modular-privatelink`.

**Do not** assume Azure paths, `ARM_*`, or Entra unless the user asks.

---

## 1. Goal

- **Done on Azure:** Path B workspace-only lakehouse POC (Terraform + Jenkins, VNet injection, SCIM entitlements, SQL smoke test).
- **Next on AWS:** Databricks E2 workspace POC with **Private Link / VPC interface endpoints**.
- **Phase 1 scope:** **Classic (back-end)** — REST + SCC relay endpoints (`privatelink.tf` in modular-privatelink).
- **Later (optional):** Inbound (front-end UI private), outbound serverless NCC (`aws-serverless-privatelink-to-cloud-service`).
- **Same operating style:** Terraform plan → apply, optional Jenkins, collapsible checklist testing.

Reference: [Private Link concepts (Databricks on AWS)](https://docs.databricks.com/aws/en/security/network/concepts/privatelink-concepts)

---

## 2. Azure POC — what was built (facts)

| Item | Value (examples; suffix may change on recreate) |
|------|--------------------------------------------------|
| Fork | `https://github.com/Naiyyar-git/terraform-databricks-examples` |
| Terraform root (Azure) | `examples/adb-lakehouse` |
| Jenkins job / workspace | `databricks-lakehouse` → `~/.jenkins/workspace/databricks-lakehouse` |
| Spoke RG | `adb-3jzudx-rg` |
| Workspace | `db_lh_example_ws` |
| Workspace URL | `https://adb-7405609303339118.18.azuredatabricks.net` |
| Region | West US 2 |
| Network | VNet injection: private + public subnets, NSG, **NAT Gateway** (main ongoing cost) |
| Path | **B** — Unity Catalog modules commented out; Jenkins Phases 2–3 commented out |
| Login | **Microsoft Entra ID** only (not Google) |
| Primary user | `naiyyar@outlook.com` |
| Entitlements file | `examples/adb-lakehouse/workspace-users.tf` |
| Azure guide (local) | `~/Downloads/README_2.html` (not in fork unless copied) |

---

## 3. Patterns to reuse on AWS

### Terraform & Git

- `git pull` at **repo root** (`terraform-databricks-examples`).
- `terraform plan` / `apply` only inside the **target example folder** (e.g. `examples/aws-databricks-modular-privatelink`).
- Wrong folder symptom: `Error: No configuration files`.
- `terraform init` — first time in that folder, or when providers/backend change; **not** every plan.
- Jenkins workspace state ≠ Git clone state unless **remote backend** is configured.
- After local `apply`, Jenkins plan may show **No changes** — correct.

### Identity & entitlements

- **Cloud IAM/RBAC ≠ Databricks workspace entitlements.**
- **Two-step pattern on Azure (mirror on AWS):**
  1. `databricks_user` — `workspace_access`, `databricks_sql_access` → fix “Unable to view page”.
  2. `admins` group + `allow_cluster_create` → Admin UI + create SQL warehouse / clusters.
- Databricks Admin **user invite** does not replace account/IdP login (Gmail on Azure needed **Entra guest**, not just UI invite).

### Operations & cost

- Smart checklist: Layers 0–5 (infra → login → terraform drift → compute → scope → destroy).
- Stop SQL warehouses when idle.
- Azure POC cost ~**$1.72** MTD was mostly **NAT + public IP**, not `SELECT 1` — check cloud **billing console**, not Databricks Admin Billing tab.
- `terraform destroy` is repeatable; new apply may change RG suffix / workspace URL.

### Azure did **not** include

- Private Link (only VNet injection).
- Hub VNet / Unity Catalog (Path B).

---

## 4. Azure → AWS mapping

| Azure | AWS |
|-------|-----|
| Subscription + `ARM_*` | AWS account + IAM user/role (`AWS_ACCESS_KEY_ID`, etc.) |
| `azurerm` | `hashicorp/aws` |
| `examples/adb-lakehouse` | `examples/aws-databricks-modular-privatelink` (PL focus) |
| VNet + subnets + NAT | VPC + subnets + NAT/IGW per module |
| Entra ID | IAM Identity Center / SSO or Databricks account login |
| `accounts.azuredatabricks.net` (MSA UC block) | Databricks **AWS E2 account** + account-level SP |
| No Private Link | `aws_vpc_endpoint` + `databricks_mws_vpc_endpoint` |
| `workspace-users.tf` | Same resources; workspace/account provider auth differs |
| Azure Cost analysis on RG | AWS Cost Explorer |

---

## 5. AWS repo entry points

| Path | Use |
|------|-----|
| `examples/aws-databricks-modular-privatelink/` | **Primary** — VPC, IAM, `privatelink.tf`, `mws_workspace` modules |
| `examples/aws-workspace-basic/` | Minimal workspace only (no PL) — fallback learning |
| `examples/aws-exfiltration-protection/` | Hub/spoke + `enable_private_link` variable |
| `examples/aws-serverless-privatelink-to-cloud-service/` | Outbound serverless PL (not S3-first; see its README) |
| `examples/aws-remote-backend-infra/` | Optional S3 remote state |
| `examples/adb-lakehouse/workspace-users.tf` | **Pattern only** for entitlements |

Key files in modular-privatelink:

- `privatelink.tf` — `aws_vpc_endpoint` (backend_rest, backend_relay) + `databricks_mws_vpc_endpoint`
- `vpc.tf`, `iam.tf`, `main.tf` — workspace + network

---

## 6. AWS prep checklist

| # | Task |
|---|------|
| 1 | AWS account with admin IAM; pick one **region** |
| 2 | Databricks on **AWS E2**; note **account ID** |
| 3 | Confirm **Enterprise** / Private Link eligibility if required |
| 4 | Databricks **account-level** service principal (client ID + secret) |
| 5 | Env vars: `TF_VAR_databricks_account_id`, `TF_VAR_databricks_account_client_id`, `TF_VAR_databricks_account_client_secret` + AWS credentials |
| 6 | `git pull` at repo root; `cd examples/aws-databricks-modular-privatelink` |
| 7 | Customize `terraform.tfvars` / `main.tf` locals → **one** workspace (trim multi-workspace sample) |
| 8 | `terraform init` → `plan` → `apply` (**new state** — do not reuse `adb-lakehouse` state) |
| 9 | Add `workspace-users.tf` (or equivalent) for human entitlements |
| 10 | Validate endpoints + private DNS; smoke test SQL/notebook |
| 11 | Watch **VPC endpoint + NAT** cost in Cost Explorer |

---

## 7. AWS testing checklist (mirror Azure)

| Layer | Pass criteria |
|-------|----------------|
| **0** | VPC, subnets, endpoints, workspace in AWS console; Jenkins SUCCESS if used |
| **1** | User reaches workspace home; entitlements applied |
| **1E** | Admin / PL-specific UI (depends on inbound PL config) |
| **2** | `terraform plan` → 0 changes |
| **3** | `SELECT 1` or `spark.range(10).show()` |
| **4** | Document which PL types are enabled (inbound / classic / outbound) |
| **5** | Stop compute; `terraform destroy` |

---

## 8. Jenkins (optional)

Clone Azure pipeline pattern:

- New job e.g. `databricks-aws-privatelink`
- `dir('examples/aws-databricks-modular-privatelink')` for init/plan/apply
- Credentials: `AWS_*` + Databricks account vars (not `ARM_*`)

---

## 9. Explicit non-goals for this chat

- Re-implement full Azure `adb-lakehouse` (ADF, Key Vault bundle) on AWS unless asked.
- Unity Catalog on day one unless user opts into `aws-workspace-uc-simple`.
- Copy Azure resource names or Entra/Gmail troubleshooting unless relevant.
- Use `examples/adb-lakehouse/terraform.tfstate` for AWS.

---

## 10. Suggested first message (AWS chat)

```text
@docs/aws-poc-handoff.md
@examples/aws-databricks-modular-privatelink

New thread: AWS Private Link POC only. Follow the handoff.
Start with §6 prep checklist, trim to one workspace, then outline plan before apply.
```

---

## 11. Azure chat name (for user)

Keep the other Cursor chat named e.g. **`azure-lakehouse-poc`** for Azure-only work. This file is for **`aws-privatelink`** (or similar) only.
