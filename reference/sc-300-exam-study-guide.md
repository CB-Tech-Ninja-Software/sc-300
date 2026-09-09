# SC-300: Microsoft Identity and Access Administrator — Canonical Exam Study Guide

Sourced directly from Microsoft Learn (the official, authoritative source), fetched and
cross-verified across two independent fetches on 2026-09-01:
- https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/sc-300
  (skills-measured version dated "as of April 27, 2026" — the current version as of this writing)
- https://learn.microsoft.com/en-us/credentials/certifications/identity-and-access-administrator/
  (exam logistics page)

**Integrity note (same standard as the Okta apps this project follows):** No leaked exam dumps,
no braindump content of any kind. All quiz questions, flashcards, scenarios, and reference notes
in this app are original, textbook-style content written against the *topics* Microsoft publishes
here — never actual/leaked exam questions. This is a hard rule for all content generation.

---

## 1. Exam Logistics

- **Certification:** Microsoft Certified: Identity and Access Administrator Associate
- **Exam code:** SC-300
- **Duration:** 100 minutes
- **Passing score:** 700 (on Microsoft's standard 1–1000 scaled scoring)
- **Level:** Intermediate (Associate)
- **Renewal:** Every 12 months (free online renewal assessment)
- **Retake policy:** 24 hours after a failed first attempt; longer waits for subsequent retakes
- **Proctored:** Yes (in-person or online via Pearson VUE)
- **Approximate price:** ~$165 USD at Microsoft's standard list price for most regions (price
  varies by country/region — treat this as directional, not authoritative; Microsoft does not
  publish a single global price on the logistics page itself)
- **Question count:** Not published by Microsoft. Question types include multiple choice,
  drag-and-drop, and interactive/case-study formats. This app's mock exam uses a designed
  round number (60 questions / 100 minutes) as a study-pacing target, NOT a claim about the
  real exam's actual question count.
- **Audience:** Identity and access administrators who design, implement, and operate an
  organization's identity and access management using Microsoft Entra — configuring identities
  across their lifecycle for users, devices, Azure resources, and applications, applying Zero
  Trust principles. Assumes familiarity with Azure, Microsoft 365, Active Directory Domain
  Services (AD DS), PowerShell, and Kusto Query Language (KQL).

---

## 2. Skill Domains & Weights

Microsoft's own page contains an internal inconsistency (confirmed identical across 2 independent
fetches, so this is a real discrepancy in Microsoft's published content, not a fetch error): the
**"Skills at a glance" summary table** lists "Implement authentication and access management" at
**25–30%**, while that domain's own detailed section header lower on the same page lists it at
**20–25%** — matching the other three domains. All four domains are otherwise stated as 20–25%.

**Resolution used by this app:** 25% is the one value that falls inside *every* published range
for all four domains simultaneously (it's the top of the 20–25% range and the bottom of the
25–30% range). This app therefore treats all four domains as **equally weighted at 25% each**
for question/content distribution — defensible against every version of Microsoft's own stated
ranges, and sums cleanly to 100%.

| # | Domain | Weight used |
|---|--------|-------------|
| 1 | Implement and manage user identities | 25% |
| 2 | Implement authentication and access management | 25% |
| 3 | Plan and implement workload identities | 25% |
| 4 | Plan and automate identity governance | 25% |

(Officially published ranges: all "20–25%", except domain 2's summary-table figure of "25–30%".)

---

## 3. Full Topic Breakdown

### Domain 1 — Implement and manage user identities (25%)

**Configure and manage a Microsoft Entra tenant**
- Configure and manage built-in and custom Microsoft Entra roles
- Recommend when to use administrative units
- Configure and manage administrative units
- Evaluate effective permissions for Microsoft Entra roles
- Configure and manage domains in Microsoft Entra ID and Microsoft 365
- Configure Company branding settings
- Configure tenant properties, user settings, group settings, and device settings

**Create, configure, and manage Microsoft Entra identities**
- Create, configure, and manage users
- Create, configure, and manage groups
- Manage custom security attributes
- Automate bulk operations by using the Microsoft Entra admin center and PowerShell
- Manage device join and device registration in Microsoft Entra ID
- Assign, modify, and report on licenses

**Implement and manage identities for external users and tenants**
- Manage External collaboration settings in Microsoft Entra ID
- Invite external users, individually or in bulk
- Manage external user accounts in Microsoft Entra ID
- Implement Cross-tenant access settings
- Implement and manage cross-tenant synchronization
- Configure external identity providers, including protocols such as SAML and WS-Fed

**Implement and manage hybrid identity**
- Implement and manage Microsoft Entra Connect Sync
- Implement and manage Microsoft Entra Cloud Sync
- Implement and manage password hash synchronization
- Implement and manage pass-through authentication
- Implement and manage seamless single sign-on (SSO)
- Migrate from AD FS to other authentication and authorization mechanisms
- Implement and manage Microsoft Entra Connect Health

### Domain 2 — Implement authentication and access management (25%)

**Plan, implement, and manage Microsoft Entra user authentication**
- Plan for authentication
- Implement and manage authentication methods, including certificate-based authentication,
  Temporary Access Pass, OAuth 2.0 tokens, Microsoft Authenticator, and passkeys (FIDO2)
- Implement and manage tenant-wide multifactor authentication (MFA) settings
- Configure and deploy self-service password reset (SSPR)
- Implement and manage Windows Hello for Business
- Disable accounts and revoke user sessions
- Implement and manage Microsoft Entra password protection
- Enable Microsoft Entra Kerberos authentication for hybrid identities

**Plan, implement, and manage Microsoft Entra Conditional Access**
- Plan Conditional Access policies
- Implement Conditional Access policy assignments
- Implement Conditional Access policy controls
- Test and troubleshoot Conditional Access policies
- Implement session management
- Implement device-enforced restrictions
- Implement continuous access evaluation
- Configure authentication context
- Implement protected actions
- Create a Conditional Access policy from a template

**Manage risk by using Microsoft Entra ID Protection**
- Implement and manage user risk by using Microsoft Entra ID Protection or Conditional Access
  policies
- Implement and manage sign-in risk by using Microsoft Entra ID Protection or Conditional
  Access policies
- Implement and manage multifactor authentication registration by using authentication methods
  and registration campaigns
- Monitor, investigate and remediate risky users and risky sign-ins
- Monitor, investigate, and remediate risky workload identities

**Implement Global Secure Access**
- Deploy Global Secure Access clients
- Deploy and manage Private Access
- Deploy and manage Internet Access
- Deploy and manage Internet Access for Microsoft 365

### Domain 3 — Plan and implement workload identities (25%)

**Plan and implement identities for applications and Azure workloads**
- Select appropriate identities for applications and Azure workloads, including managed
  identities, service principals, user accounts, and managed service accounts
- Create managed identities
- Assign a managed identity to an Azure resource
- Use a managed identity assigned to an Azure resource to access other Azure resources

**Plan, implement, and monitor the integration of enterprise applications**
- Plan and implement settings for enterprise applications, including application-level and
  tenant-level settings
- Assign appropriate Microsoft Entra roles to users to manage enterprise applications
- Design and implement integration for on-premises apps by using Microsoft Entra Application Proxy
- Design and implement integration for software as a service (SaaS) apps
- Assign, classify, and manage users, groups, and app roles for enterprise applications
- Configure and manage user and admin consent
- Create and manage application collections

**Plan and implement app registrations**
- Plan for app registrations
- Create app registrations
- Configure app authentication
- Configure API permissions
- Create app roles

**Manage and monitor app access by using Microsoft Defender for Cloud Apps**
- Configure and analyze cloud discovery results by using Defender for Cloud Apps
- Configure connected apps
- Implement application-enforced restrictions
- Configure Conditional Access app control
- Create access and session policies in Defender for Cloud Apps
- Implement and manage policies for OAuth apps
- Manage the Cloud app catalog

### Domain 4 — Plan and automate identity governance (25%)

**Plan and implement entitlement management in Microsoft Entra**
- Plan entitlements
- Create and configure catalogs
- Create and configure access packages
- Manage access requests
- Implement and manage terms of use (ToU)
- Manage the lifecycle of external users
- Configure and manage connected organizations

**Plan, implement, and manage access reviews in Microsoft Entra**
- Plan for access reviews
- Create and configure access reviews
- Monitor access review activity
- Manually respond to access review activity

**Plan and implement privileged access**
- Plan and manage Microsoft Entra roles in Microsoft Entra Privileged Identity Management (PIM),
  including settings and assignments
- Plan and manage Azure resources in PIM, including settings and assignments
- Plan and configure PIM for Groups
- Manage the PIM request and approval process
- Analyze PIM audit history and reports
- Create and manage break-glass accounts

**Monitor identity activity by using logs, workbooks, and reports**
- Review and analyze sign-in, audit, and provisioning logs by using the Microsoft Entra admin
  center
- Configure diagnostic settings, including configuring destinations such as Log Analytics
  workspaces, storage accounts, and Azure Event Hubs
- Monitor Microsoft Entra ID by using KQL queries in Log Analytics
- Analyze Microsoft Entra ID by using workbooks and reporting
- Monitor and improve the security posture by using Identity Secure Score

---

## 4. Reference Documentation (for Reference Library sourceUrls)

Only use real, WebFetch-verified Microsoft Learn / Microsoft Docs URLs for reference notes —
same standard as the Okta apps. Good starting points (verify each URL before citing it):
- https://learn.microsoft.com/en-us/entra/identity/ (Microsoft Entra ID docs root)
- https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/
- https://learn.microsoft.com/en-us/entra/external-id/
- https://learn.microsoft.com/en-us/entra/identity/hybrid/
- https://learn.microsoft.com/en-us/entra/identity/authentication/
- https://learn.microsoft.com/en-us/entra/identity/conditional-access/
- https://learn.microsoft.com/en-us/entra/id-protection/
- https://learn.microsoft.com/en-us/entra/global-secure-access/
- https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/
- https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/
- https://learn.microsoft.com/en-us/entra/identity-platform/ (app registrations, API permissions)
- https://learn.microsoft.com/en-us/defender-cloud-apps/
- https://learn.microsoft.com/en-us/entra/id-governance/
- https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/
